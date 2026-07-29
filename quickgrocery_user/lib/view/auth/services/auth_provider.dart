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
import 'package:quickgrocery/core/firebase/firebase_config_audit.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';
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

  bool get isVisible => _isVisible;
  String _verificationId = '';
  int? _resendToken;
  bool _phoneVerificationSettled = false;
  bool isLoading = false;
  String? phoneAuthError;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? selectedGender; // 'male' or 'female'

  TextEditingController mobileController = TextEditingController();
  TextEditingController opController = TextEditingController();
  TextEditingController referralCodeController = TextEditingController();

  final ReferEarnService _referEarnService = ReferEarnService();
  String? _pendingReferralCode;

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
  }

  /// Clears OTP / profile form state so the next account starts fresh.
  void resetSessionForLogout() {
    _phoneVerificationSettled = false;
    _verificationId = '';
    _resendToken = null;
    isLoading = false;
    phoneAuthError = null;
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

  void clearPhoneAuthError() {
    phoneAuthError = null;
    notifyListeners();
  }

  void _setPhoneAuthError(String message) {
    phoneAuthError = message;
    FirebaseAuthReadiness.log('error: $message');
    notifyListeners();
  }

  Future<void> verifyPhoneNumber(BuildContext context) async {
    if (isLoading) return;

    AuthSessionManager.prepareNewLogin();
    AuthSessionLog.newLoginStarted(
      phone: FirebaseAuthReadiness.normalizePhoneNumber(mobileController.text),
    );
    clearPhoneAuthError();

    final phoneNumber = FirebaseAuthReadiness.normalizePhoneNumber(
      mobileController.text,
    );
    if (phoneNumber == null) {
      _setPhoneAuthError('Please enter a valid 10-digit mobile number.');
      return;
    }

    final readinessError = await FirebaseAuthReadiness.ensurePhoneAuthReady();
    if (readinessError != null) {
      FirebasePhoneAuthLogger.error(
        'verifyPhoneNumber blocked by ensurePhoneAuthReady: $readinessError',
      );
      _setPhoneAuthError(readinessError);
      return;
    }

    if (!context.mounted) return;

    await FirebasePhoneAuthLogger.logVerifyPhoneSnapshot(
      phase: 'BEFORE verifyPhoneNumber',
      phoneNumber: phoneNumber,
    );

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
    notifyListeners();

    FirebaseAuthReadiness.log(
      'verifyPhoneNumber start phone=$phoneNumber resend=${forceResendingToken != null}',
    );

    Timer? watchdog;
    watchdog = Timer(const Duration(seconds: 90), () {
      if (!isLoading) return;
      FirebaseAuthReadiness.log('watchdog timeout — resetting loading state');
      isLoading = false;
      _setPhoneAuthError(
        'Phone verification timed out. Check network and iOS Firebase setup, then try again.',
      );
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
          FirebaseAuthReadiness.log('verificationCompleted (auto)');
          watchdog?.cancel();
          var succeeded = false;
          try {
            final cred = await _auth.signInWithCredential(credential);
            final user = cred.user;
            if (user != null) {
              FirebaseAuthReadiness.log('auto sign-in succeeded uid=${user.uid}');
              PhoneAuthFlowLog.otpVerificationSuccess(uid: user.uid);
              await _finishPhoneSignIn(user);
              succeeded = true;
            }
          } catch (e, st) {
            FirebaseAuthReadiness.log('auto sign-in failed: $e');
            PhoneAuthFlowLog.otpVerificationFailed(error: e, stack: st);
            log('Auto phone sign-in failed', error: e, stackTrace: st);
          } finally {
            isLoading = false;
            if (!succeeded) notifyListeners();
          }
        },
        verificationFailed: (FirebaseAuthException e) async {
          if (_phoneVerificationSettled) return;
          watchdog?.cancel();
          isLoading = false;
          FirebasePhoneAuthLogger.logAuthException(
            'verificationFailed',
            e,
            stackTrace: StackTrace.current,
          );
          await FirebasePhoneAuthLogger.logVerifyPhoneSnapshot(
            phase: 'verificationFailed',
            phoneNumber: phoneNumber,
          );
          final message = await _phoneAuthErrorMessage(e);
          _setPhoneAuthError(message);
          log('verificationFailed: ${e.code} ${e.message}', error: e, stackTrace: StackTrace.current);
          // Login screen already shows [phoneAuthError] banner — avoid duplicate snackbar.
          if (context.mounted && navigateToOtpOnCodeSent) {
            AppSnackBar.error(message, context: context);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (_phoneVerificationSettled) return;
          watchdog?.cancel();
          _verificationId = verificationId;
          _resendToken = resendToken;
          opController.clear();
          isLoading = false;
          clearPhoneAuthError();
          FirebasePhoneAuthLogger.info(
            'codeSent verificationId=${verificationId.substring(0, 8)}… '
            'phone=$phoneNumber resendToken=${resendToken != null}',
          );
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
          FirebaseAuthReadiness.log('codeAutoRetrievalTimeout');
          isLoading = false;
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
      if (e is FirebaseAuthException) {
        FirebasePhoneAuthLogger.logAuthException(
          'verifyPhoneNumber catch',
          e,
          stackTrace: st,
        );
      } else {
        FirebasePhoneAuthLogger.error(
          'verifyPhoneNumber catch non-FirebaseAuthException: $e',
          error: e,
          stackTrace: st,
        );
      }
      final message = e is FirebaseAuthException
          ? await _phoneAuthErrorMessage(e)
          : 'Phone verification failed: $e';
      if (e is FirebaseAuthException) {
        FirebaseAuthReadiness.log(
          'verifyPhoneNumber exception: ${FirebaseConfigAudit.formatAuthException(e)}',
        );
      }
      _setPhoneAuthError(message);
      log('verifyPhoneNumber threw', error: e, stackTrace: st);
      if (context.mounted) {
        AppSnackBar.error(message, context: context);
      }
    }
  }

  Future<String> _phoneAuthErrorMessage(FirebaseAuthException e) async {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Use a valid 10-digit Indian mobile number.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later or contact support.';
      case 'missing-client-identifier':
      case 'app-not-authorized':
      case 'invalid-app-credential':
      case 'invalid-cert-hash':
      case 'captcha-check-failed':
      case 'internal-error':
        return FirebaseConfigAudit.messageForAuthException(e);
      default:
        return FirebaseConfigAudit.formatAuthException(e);
    }
  }

  /// Returns `true` if sign-in succeeded and navigation was performed.
  /// Returns `false` for an invalid OTP (caller should shake UI / show error).
  Future<bool> signInWithOTP(String smsCode, BuildContext context) async {
    if (_verificationId.isEmpty) {
      if (context.mounted) {
        AppSnackBar.error(
          'OTP session expired. Go back and request a new code.',
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
                message: 'Sign-in timed out. Check your connection and try again.',
              );
            },
          );

      final user = userCredential.user;
      if (user != null) {
        PhoneAuthFlowLog.otpVerificationSuccess(uid: user.uid);
        await _finishPhoneSignIn(user);
        succeeded = true;
        return true;
      }
    } on FirebaseAuthException catch (e, st) {
      PhoneAuthFlowLog.otpVerificationFailed(error: e, stack: st);
      final code = e.code;
      if (code == 'invalid-verification-code' ||
          code == 'invalid-verification-id' ||
          code == 'session-expired') {
        return false;
      }
      if (context.mounted) {
        final message = await _phoneAuthErrorMessage(e);
        AppSnackBar.error(message, context: context);
      }
      return false;
    } catch (e, st) {
      PhoneAuthFlowLog.otpVerificationFailed(error: e, stack: st);
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
    if (isLoading) return;

    final phoneNumber = FirebaseAuthReadiness.normalizePhoneNumber(
      mobileController.text,
    );
    if (phoneNumber == null) return;

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
