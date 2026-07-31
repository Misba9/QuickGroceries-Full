import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/firebase/firebase_auth_readiness.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';
import 'package:quickgrocery/core/firebase/phone_auth_debug_test_numbers.dart';
import 'package:quickgrocery/core/firebase/phone_auth_network.dart';
import 'package:quickgrocery/core/firebase/phone_auth_request_guard.dart';
import 'package:quickgrocery/core/firebase/phone_auth_user_messages.dart';
import 'package:quickgrocery/core/auth/auth_session_log.dart';
import 'package:quickgrocery/core/auth/auth_session_manager.dart';
import 'package:quickgrocery/core/auth/auth_sign_in_coordinator.dart';
import 'package:quickgrocery/core/auth/phone_auth_flow_log.dart';
import 'package:quickgrocery/core/auth/phone_sign_in_navigation.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/user/user_profile_cache.dart';
import 'package:quickgrocery/core/user/user_profile_repository.dart';
import 'package:quickgrocery/view/auth/screens/otp_screen.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_shell.dart';
import 'package:quickgrocery/view/refer/services/refer_earn_service.dart';

class AuthService extends ChangeNotifier {
  bool _isVisible = false;
  File? image;
  final UserProfileRepository _profileRepo = UserProfileRepository();
  final PhoneAuthRequestGuard _otpGuard = PhoneAuthRequestGuard();

  bool get isVisible => _isVisible;
  String _verificationId = '';
  int? _resendToken;
  bool _phoneVerificationSettled = false;
  bool isLoading = false;
  String? phoneAuthError;
  PhoneAuthUserMessage? phoneAuthErrorInfo;
  bool phoneAuthNeedsRetry = false;

  /// Remaining OTP cooldown seconds (login Continue + resend).
  int otpCooldownSeconds = 0;
  Timer? _cooldownTicker;
  bool _guardRestored = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? selectedGender; // 'male' or 'female'

  TextEditingController mobileController = TextEditingController();
  TextEditingController opController = TextEditingController();
  TextEditingController referralCodeController = TextEditingController();

  final ReferEarnService _referEarnService = ReferEarnService();
  String? _pendingReferralCode;

  bool get isOtpCooldownActive => otpCooldownSeconds > 0;

  bool get canRequestOtp =>
      !isLoading && !_otpGuard.isRequestInFlight && !isOtpCooldownActive;

  void setGender(String gender) async {
    selectedGender = gender;
    final pref = await SharedPreferences.getInstance();
    pref.setString('user_gender', gender);
    notifyListeners();
  }

  void onVisibleChange() {
    _isVisible = !_isVisible;
    notifyListeners();
  }

  /// Loads a referral code saved by [handleReferralAfterInstall] in main.dart
  /// (HTTPS / custom-scheme deep links via `app_links`).
  Future<void> handleReferralAfterInstall() async {
    final pref = await SharedPreferences.getInstance();
    final code = pref.getString('pending_referral_code')?.trim() ?? '';
    if (code.isEmpty) return;
    _pendingReferralCode = code;
    if (referralCodeController.text.trim().isEmpty) {
      referralCodeController.text = code;
    }
  }

  Future<String?> applyPendingReferralCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final code = referralCodeController.text.trim().isNotEmpty
        ? referralCodeController.text.trim()
        : (_pendingReferralCode ?? '');
    if (code.isEmpty) return null;

    try {
      final result = await _referEarnService.applyReferralCode(code);
      if (!result.ok) {
        log('Referral apply: ${result.message}');
        return result.message;
      }
    } catch (e, st) {
      log('applyReferralCode failed', error: e, stackTrace: st);
    } finally {
      _pendingReferralCode = null;
    }
    return null;
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      image = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<String> uploadImageToStorage(File imageFile) async {
    try {
      isLoading = true;
      notifyListeners();
      Reference storageRef = FirebaseStorage.instance.ref().child(
        'product_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('Error uploading image: $e');
      return '';
    }
  }

  /// Pre-fill onboarding fields from cache / Firestore (returning users).
  Future<void> hydrateProfileFromCache() async {
    final pref = await SharedPreferences.getInstance();
    final pending = pref.getString('pending_referral_code');
    if (pending != null &&
        pending.isNotEmpty &&
        referralCodeController.text.trim().isEmpty) {
      referralCodeController.text = pending;
      _pendingReferralCode = pending;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _profileRepo.hydrateLocal(uid);
    }
    final cached = await UserProfileCache.readProfile();
    if (cached['name']!.isNotEmpty) {
      nameController.text = cached['name']!;
    }
    if (cached['email']!.isNotEmpty) {
      emailController.text = cached['email']!;
    }
    if (cached['phone']!.isNotEmpty) {
      mobileController.text = cached['phone']!;
    } else {
      final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
      if (phone != null && phone.length >= 10) {
        mobileController.text = phone.replaceAll(RegExp(r'\D'), '').substring(
              phone.replaceAll(RegExp(r'\D'), '').length - 10,
            );
      }
    }
    if (cached['gender']!.isNotEmpty) {
      selectedGender = cached['gender'];
    }
    notifyListeners();
  }

  void _markPhoneVerificationSettled() {
    _phoneVerificationSettled = true;
    _verificationId = '';
    _resendToken = null;
    isLoading = false;
    _otpGuard.endRequest();
  }

  /// Clears OTP / profile form state so the next account starts fresh.
  void resetSessionForLogout() {
    _phoneVerificationSettled = false;
    _verificationId = '';
    _resendToken = null;
    isLoading = false;
    phoneAuthError = null;
    phoneAuthErrorInfo = null;
    phoneAuthNeedsRetry = false;
    _otpGuard.endRequest();
    _stopCooldownTicker();
    otpCooldownSeconds = 0;
    mobileController.clear();
    opController.clear();
    nameController.clear();
    emailController.clear();
    referralCodeController.clear();
    selectedGender = null;
    image = null;
    _pendingReferralCode = null;
    _isVisible = false;
    notifyListeners();
  }

  void _notifyPhoneSignInComplete(User user) {
    AuthSignInCoordinator.notifyPhoneSignInComplete();
    PhoneAuthFlowLog.navigation('sign_in_complete uid=${user.uid}');
  }

  /// Persists session, hydrates profile, pops auth routes, kicks bootstrap.
  Future<void> _finishPhoneSignIn(User user) async {
    try {
      AuthSessionLog.otpVerified(uid: user.uid);
      await AuthSessionManager.ensureCacheMatchesUser(user.uid);
      PhoneAuthFlowLog.sessionSaveStarted(uid: user.uid);

      await user.reload();
      await user.getIdToken(true);

      PhoneAuthFlowLog.sessionSaved(uid: user.uid);
      AuthSessionLog.newSessionCreated(uid: user.uid);

      await _profileRepo.hydrateLocal(user.uid);
      PhoneAuthFlowLog.profileLoaded(uid: user.uid);
    } catch (e, st) {
      PhoneAuthFlowLog.exception('finishPhoneSignIn', e, st);
      unawaited(_profileRepo.hydrateLocal(user.uid));
    } finally {
      _markPhoneVerificationSettled();
      _notifyPhoneSignInComplete(user);
      await PhoneSignInNavigation.clearAuthRoutesWhenReady();
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> ensurePhoneAuthGuardReady() async {
    if (_guardRestored) {
      _syncCooldownFromGuard();
      return;
    }
    await _otpGuard.restore();
    _guardRestored = true;
    _syncCooldownFromGuard();
  }

  void _syncCooldownFromGuard() {
    final remaining = _otpGuard.cooldownRemainingSeconds;
    if (remaining <= 0) {
      otpCooldownSeconds = 0;
      _stopCooldownTicker();
      return;
    }
    otpCooldownSeconds = remaining;
    _ensureCooldownTicker();
    notifyListeners();
  }

  void _ensureCooldownTicker() {
    if (_cooldownTicker?.isActive ?? false) return;
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _otpGuard.cooldownRemainingSeconds;
      if (remaining <= 0) {
        otpCooldownSeconds = 0;
        _stopCooldownTicker();
        notifyListeners();
        return;
      }
      if (otpCooldownSeconds != remaining) {
        otpCooldownSeconds = remaining;
        notifyListeners();
      }
    });
  }

  void _stopCooldownTicker() {
    _cooldownTicker?.cancel();
    _cooldownTicker = null;
  }

  Future<void> _beginCooldown(Duration duration) async {
    await _otpGuard.startCooldown(duration: duration);
    _syncCooldownFromGuard();
  }

  void clearPhoneAuthError() {
    phoneAuthError = null;
    phoneAuthErrorInfo = null;
    phoneAuthNeedsRetry = false;
    notifyListeners();
  }

  void _setPhoneAuthError(
    PhoneAuthUserMessage info, {
    bool needsRetry = false,
  }) {
    phoneAuthErrorInfo = info;
    phoneAuthError = info.display;
    phoneAuthNeedsRetry = needsRetry;
    FirebasePhoneAuthLogger.error(
      'user_error code=${info.code} title=${info.title} message=${info.message}',
    );
    notifyListeners();
  }

  Future<void> verifyPhoneNumber(BuildContext context) async {
    await ensurePhoneAuthGuardReady();

    if (!canRequestOtp) {
      if (isLoading || _otpGuard.isRequestInFlight) {
        FirebasePhoneAuthLogger.warn(
          'verifyPhoneNumber ignored — request already in flight',
        );
        return;
      }
      if (isOtpCooldownActive) {
        _setPhoneAuthError(PhoneAuthUserMessages.cooldownActive);
        return;
      }
      return;
    }

    AuthSessionManager.prepareNewLogin();
    clearPhoneAuthError();

    final phoneNumber = FirebaseAuthReadiness.normalizePhoneNumber(
      mobileController.text,
    );
    AuthSessionLog.newLoginStarted(phone: phoneNumber);

    if (phoneNumber == null) {
      _setPhoneAuthError(PhoneAuthUserMessages.invalidLocalPhone);
      return;
    }

    FirebasePhoneAuthLogger.info(
      'verification_started phone=$phoneNumber debugTest='
      '${PhoneAuthDebugTestNumbers.isTestNumber(phoneNumber)}',
    );

    if (!await PhoneAuthNetwork.hasConnection()) {
      _setPhoneAuthError(PhoneAuthUserMessages.noInternet, needsRetry: true);
      return;
    }

    final block = _otpGuard.blockReason(phoneE164: phoneNumber);
    if (block != null) {
      FirebasePhoneAuthLogger.warn('verifyPhoneNumber blocked reason=$block');
      if (block == 'cooldown') {
        _setPhoneAuthError(PhoneAuthUserMessages.cooldownActive);
      }
      return;
    }

    final readinessError = await FirebaseAuthReadiness.ensurePhoneAuthReady();
    if (readinessError != null) {
      FirebasePhoneAuthLogger.error(
        'verifyPhoneNumber blocked by ensurePhoneAuthReady: $readinessError',
      );
      _setPhoneAuthError(
        PhoneAuthUserMessage(
          title: 'Phone Login Unavailable',
          message: readinessError,
          code: 'readiness',
        ),
        needsRetry: true,
      );
      return;
    }

    if (!context.mounted) return;

    await FirebasePhoneAuthLogger.logVerifyPhoneSnapshot(
      phase: 'BEFORE verifyPhoneNumber',
      phoneNumber: phoneNumber,
    );

    if (!context.mounted) return;
    await _startPhoneVerification(
      context: context,
      phoneNumber: phoneNumber,
      navigateToOtpOnCodeSent: true,
    );
  }

  Future<void> _startPhoneVerification({
    required BuildContext context,
    required String phoneNumber,
    int? forceResendingToken,
    bool navigateToOtpOnCodeSent = false,
  }) async {
    _phoneVerificationSettled = false;
    isLoading = true;
    phoneAuthNeedsRetry = false;
    notifyListeners();

    await _otpGuard.beginRequest(phoneNumber);

    FirebasePhoneAuthLogger.info(
      'verifyPhoneNumber start phone=$phoneNumber '
      'resend=${forceResendingToken != null}',
    );

    Timer? watchdog;
    watchdog = Timer(const Duration(seconds: 90), () {
      if (!isLoading) return;
      FirebasePhoneAuthLogger.warn('watchdog timeout — resetting loading state');
      isLoading = false;
      _otpGuard.endRequest();
      _setPhoneAuthError(PhoneAuthUserMessages.timedOut, needsRetry: true);
    });

    try {
      FirebasePhoneAuthLogger.info(
        'CALLING FirebaseAuth.verifyPhoneNumber phone=$phoneNumber',
      );
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (_phoneVerificationSettled) return;
          FirebasePhoneAuthLogger.info('verification_completed (auto-retrieval)');
          watchdog?.cancel();
          var succeeded = false;
          try {
            final cred = await _auth.signInWithCredential(credential);
            final user = cred.user;
            if (user != null) {
              FirebasePhoneAuthLogger.info(
                'otp_verified (auto) uid=${user.uid}',
              );
              PhoneAuthFlowLog.otpVerificationSuccess(uid: user.uid);
              await _finishPhoneSignIn(user);
              succeeded = true;
            }
          } catch (e, st) {
            FirebasePhoneAuthLogger.error(
              'auto sign-in failed: $e',
              error: e,
              stackTrace: st,
            );
            PhoneAuthFlowLog.otpVerificationFailed(error: e, stack: st);
            log('Auto phone sign-in failed', error: e, stackTrace: st);
            if (e is FirebaseAuthException) {
              _setPhoneAuthError(PhoneAuthUserMessages.fromException(e));
            }
          } finally {
            isLoading = false;
            _otpGuard.endRequest();
            if (!succeeded) notifyListeners();
          }
        },
        verificationFailed: (FirebaseAuthException e) async {
          if (_phoneVerificationSettled) return;
          watchdog?.cancel();
          isLoading = false;
          _otpGuard.endRequest();
          FirebasePhoneAuthLogger.logAuthException(
            'verificationFailed',
            e,
            stackTrace: StackTrace.current,
          );
          await FirebasePhoneAuthLogger.logVerifyPhoneSnapshot(
            phase: 'verificationFailed',
            phoneNumber: phoneNumber,
          );

          final info = PhoneAuthUserMessages.fromException(e);
          final needsRetry = e.code == 'network-request-failed' ||
              e.code == 'captcha-check-failed' ||
              e.code == 'internal-error';

          if (e.code == 'too-many-requests' || e.code == 'quota-exceeded') {
            await _beginCooldown(
              PhoneAuthRequestGuard.tooManyRequestsCooldown,
            );
          }

          _setPhoneAuthError(info, needsRetry: needsRetry);
          log(
            'verificationFailed: ${e.code} ${e.message}',
            error: e,
            stackTrace: StackTrace.current,
          );

          // OTP screen has no error banner — surface via snackbar on resend.
          if (context.mounted && !navigateToOtpOnCodeSent) {
            AppSnackBar.error(info.display, context: context);
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          if (_phoneVerificationSettled) return;
          watchdog?.cancel();
          _verificationId = verificationId;
          _resendToken = resendToken;
          opController.clear();
          isLoading = false;
          _otpGuard.endRequest();
          phoneAuthError = null;
          phoneAuthErrorInfo = null;
          phoneAuthNeedsRetry = false;

          FirebasePhoneAuthLogger.info(
            'otp_sent verificationId=${verificationId.substring(0, 8)}… '
            'phone=$phoneNumber resendToken=${resendToken != null}',
          );

          await _beginCooldown(PhoneAuthRequestGuard.cooldownDuration);
          notifyListeners();

          if (!context.mounted) return;

          if (navigateToOtpOnCodeSent) {
            Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: AppRoutes.otp),
                builder: (context) => const OtpAuthScreen(),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (_phoneVerificationSettled) return;
          _verificationId = verificationId;
          FirebasePhoneAuthLogger.info(
            'codeAutoRetrievalTimeout '
            'verificationId=${verificationId.substring(0, 8)}…',
          );
          isLoading = false;
          _otpGuard.endRequest();
          notifyListeners();
        },
      );
      FirebasePhoneAuthLogger.info(
        'FirebaseAuth.verifyPhoneNumber SDK call returned (await completed); '
        'waiting for verificationFailed/codeSent callbacks',
      );
      await FirebasePhoneAuthLogger.logVerifyPhoneSnapshot(
        phase: 'AFTER verifyPhoneNumber await',
        phoneNumber: phoneNumber,
      );
    } catch (e, st) {
      watchdog.cancel();
      isLoading = false;
      _otpGuard.endRequest();
      if (e is FirebaseAuthException) {
        FirebasePhoneAuthLogger.logAuthException(
          'verifyPhoneNumber catch',
          e,
          stackTrace: st,
        );
        final info = PhoneAuthUserMessages.fromException(e);
        if (e.code == 'too-many-requests' || e.code == 'quota-exceeded') {
          await _beginCooldown(PhoneAuthRequestGuard.tooManyRequestsCooldown);
        }
        _setPhoneAuthError(
          info,
          needsRetry: e.code == 'network-request-failed',
        );
      } else {
        FirebasePhoneAuthLogger.error(
          'verifyPhoneNumber catch non-FirebaseAuthException: $e',
          error: e,
          stackTrace: st,
        );
        _setPhoneAuthError(
          PhoneAuthUserMessage(
            title: 'Sign-In Failed',
            message: 'Phone verification failed. Please try again.',
            code: 'unknown',
          ),
          needsRetry: true,
        );
      }
      log('verifyPhoneNumber threw', error: e, stackTrace: st);
    }
  }

  /// Returns `true` if sign-in succeeded and navigation was performed.
  /// Returns `false` for an invalid OTP (caller should shake UI / show error).
  Future<bool> signInWithOTP(String smsCode, BuildContext context) async {
    if (isLoading) {
      FirebasePhoneAuthLogger.warn('signInWithOTP ignored — already loading');
      return false;
    }

    if (_verificationId.isEmpty) {
      if (context.mounted) {
        final info = PhoneAuthUserMessages.otpSessionExpired;
        AppSnackBar.error(info.display, context: context);
      }
      return false;
    }

    if (!await PhoneAuthNetwork.hasConnection()) {
      if (context.mounted) {
        AppSnackBar.error(
          PhoneAuthUserMessages.noInternet.display,
          context: context,
        );
      }
      return false;
    }

    var succeeded = false;
    try {
      isLoading = true;
      notifyListeners();

      PhoneAuthFlowLog.otpVerificationStarted(
        verificationIdPrefix: _verificationId.length >= 8
            ? _verificationId.substring(0, 8)
            : _verificationId,
      );
      FirebasePhoneAuthLogger.info('otp_verify_started');

      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      final UserCredential userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw FirebaseAuthException(
                code: 'network-request-failed',
                message:
                    'Sign-in timed out. Check your connection and try again.',
              );
            },
          );

      final user = userCredential.user;
      if (user != null) {
        FirebasePhoneAuthLogger.info('otp_verified uid=${user.uid}');
        PhoneAuthFlowLog.otpVerificationSuccess(uid: user.uid);
        await _finishPhoneSignIn(user);
        succeeded = true;
        return true;
      }
    } on FirebaseAuthException catch (e, st) {
      FirebasePhoneAuthLogger.logAuthException(
        'signInWithOTP',
        e,
        stackTrace: st,
      );
      PhoneAuthFlowLog.otpVerificationFailed(error: e, stack: st);
      final code = e.code;
      if (code == 'invalid-verification-code' ||
          code == 'invalid-verification-id' ||
          code == 'session-expired') {
        return false;
      }
      if (context.mounted) {
        final message = PhoneAuthUserMessages.fromException(e).display;
        AppSnackBar.error(message, context: context);
      }
      return false;
    } catch (e, st) {
      PhoneAuthFlowLog.otpVerificationFailed(error: e, stack: st);
      FirebasePhoneAuthLogger.error(
        'signInWithOTP unexpected: $e',
        error: e,
        stackTrace: st,
      );
      if (context.mounted) {
        AppSnackBar.error(
          context.l10n.unexpectedError(e.toString()),
          context: context,
        );
      }
    } finally {
      isLoading = false;
      // Avoid rebuilding OTP after success — shell + route pop handle navigation.
      if (!succeeded) notifyListeners();
    }
    return false;
  }

  /// Resend OTP using Firebase [forceResendingToken] when available.
  Future<void> resendOtp(BuildContext context) async {
    await ensurePhoneAuthGuardReady();

    if (!canRequestOtp) {
      FirebasePhoneAuthLogger.warn(
        'resendOtp ignored loading=$isLoading cooldown=$otpCooldownSeconds',
      );
      return;
    }

    final phoneNumber = FirebaseAuthReadiness.normalizePhoneNumber(
      mobileController.text,
    );
    if (phoneNumber == null) return;

    if (!await PhoneAuthNetwork.hasConnection()) {
      if (context.mounted) {
        AppSnackBar.error(
          PhoneAuthUserMessages.noInternet.display,
          context: context,
        );
      }
      return;
    }

    FirebasePhoneAuthLogger.info('otp_resend_started phone=$phoneNumber');

    if (!context.mounted) return;
    await _startPhoneVerification(
      context: context,
      phoneNumber: phoneNumber,
      forceResendingToken: _resendToken,
    );
  }

  Future<void> registerUser(BuildContext context) async {
    if (nameController.text.trim().isEmpty) {
      AppSnackBar.error(context.l10n.pleaseEnterName, context: context);
      return;
    }
    if (selectedGender == null) {
      AppSnackBar.error(context.l10n.pleaseSelectGender, context: context);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    isLoading = true;
    notifyListeners();

    try {
      var imageUrl = '';
      if (image != null) {
        imageUrl = await uploadImageToStorage(image!);
      }

      await _profileRepo.saveProfile(
        uid: uid,
        markComplete: true,
        fields: {
          'profile_image': imageUrl,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': mobileController.text.trim(),
          'gender': selectedGender,
          'created_date': FieldValue.serverTimestamp(),
        },
      );

      final pref = await SharedPreferences.getInstance();
      await pref.setString('user_gender', selectedGender!);
      await pref.setBool('isUserExist', true);

      await handleReferralAfterInstall();
      await _referEarnService.ensureReferralCode(
        name: nameController.text.trim(),
      );
      final referralMsg = await applyPendingReferralCode();
      await pref.remove('pending_referral_code');

      if (!context.mounted) return;
      if (referralMsg != null) {
        AppSnackBar.info(referralMsg, context: context);
      }
      AppBootstrapShell.markOnboardingComplete(context);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
