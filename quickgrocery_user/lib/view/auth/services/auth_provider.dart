import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickgrocery/core/firebase/firebase_auth_readiness.dart';
import 'package:quickgrocery/core/firebase/firebase_config_audit.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';
import 'package:quickgrocery/core/auth/phone_auth_coordinator.dart';
import 'package:quickgrocery/core/auth/phone_auth_log.dart';
import 'package:quickgrocery/core/user/user_profile_cache.dart';
import 'package:quickgrocery/core/user/user_profile_repository.dart';
import 'package:quickgrocery/view/auth/screens/customer_profile_add_screen.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_shell.dart';
import 'package:quickgrocery/view/refer/services/refer_earn_service.dart';

class AuthService extends ChangeNotifier {
  bool _isVisible = false;
  File? image;
  final UserProfileRepository _profileRepo = UserProfileRepository();

  bool get isVisible => _isVisible;
  String _verificationId = '';
  int? _resendToken;
  bool isLoading = false;
  bool _phoneVerifyInFlight = false;
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

  // Handle Referral
  Future<void> handleReferralAfterInstall() async {
    final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks
        .instance
        .getInitialLink();

    if (initialLink != null) {
      final Uri deepLink = initialLink.link;
      _captureReferralFromUri(deepLink);
    }

    FirebaseDynamicLinks.instance.onLink
        .listen((PendingDynamicLinkData data) {
          _captureReferralFromUri(data.link);
        })
        .onError((error) {
          print("Dynamic Link Error: $error");
        });
  }

  void _captureReferralFromUri(Uri deepLink) {
    final code = deepLink.queryParameters['code'] ??
        deepLink.queryParameters['ref'] ??
        '';
    if (code.trim().isEmpty) return;
    _pendingReferralCode = code.trim();
    if (referralCodeController.text.trim().isEmpty) {
      referralCodeController.text = code.trim();
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
      print('Error uploading image: $e');
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

  void _finishPhoneSignIn() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      FirebasePhoneAuthLogger.warn('_finishPhoneSignIn: currentUser null');
      return;
    }

    PhoneAuthLog.signInSuccess(uid: user.uid);
    PhoneAuthLog.sessionStored();
    PhoneAuthCoordinator.clearAuthRoutes();
    PhoneAuthLog.navigateHome();
    unawaited(_profileRepo.hydrateLocal(user.uid));
  }

  void _resetPhoneVerifyState({String? error}) {
    _phoneVerifyInFlight = false;
    isLoading = false;
    if (error != null) _setPhoneAuthError(error);
    notifyListeners();
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
    if (_phoneVerifyInFlight || isLoading) {
      PhoneAuthLog.duplicateTapIgnored('verifyPhoneNumber');
      return;
    }

    PhoneAuthLog.continueTapped();
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

    PhoneAuthLog.verifyPhoneCalled();
    await _startPhoneVerification(
      phoneNumber: phoneNumber,
      navigateToOtpOnCodeSent: true,
    );
  }

  Future<void> _startPhoneVerification({
    required String phoneNumber,
    int? forceResendingToken,
    bool navigateToOtpOnCodeSent = false,
  }) async {
    _phoneVerifyInFlight = true;
    isLoading = true;
    notifyListeners();

    FirebaseAuthReadiness.log(
      'verifyPhoneNumber start phone=$phoneNumber resend=${forceResendingToken != null}',
    );

    Timer? watchdog;
    watchdog = Timer(const Duration(seconds: 90), () {
      if (!_phoneVerifyInFlight) return;
      FirebaseAuthReadiness.log('watchdog timeout — resetting loading state');
      _resetPhoneVerifyState(
        error:
            'Phone verification timed out. Check network and try again.',
      );
    });

    void onCodeReady() {
      watchdog?.cancel();
      _phoneVerifyInFlight = false;
      isLoading = false;
      clearPhoneAuthError();
      notifyListeners();
      if (navigateToOtpOnCodeSent) {
        PhoneAuthLog.otpScreenOpened();
        PhoneAuthCoordinator.openOtpScreen();
      }
    }

    try {
      FirebasePhoneAuthLogger.info(
        'CALLING FirebaseAuth.verifyPhoneNumber phone=$phoneNumber',
      );
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          PhoneAuthLog.verificationCompleted();
          watchdog?.cancel();
          try {
            isLoading = true;
            notifyListeners();
            await _auth.signInWithCredential(credential);
            FirebaseAuthReadiness.log('auto sign-in succeeded');
            _finishPhoneSignIn();
          } catch (e, st) {
            FirebaseAuthReadiness.log('auto sign-in failed: $e');
            log('Auto phone sign-in failed', error: e, stackTrace: st);
            if (e is FirebaseAuthException) {
              _setPhoneAuthError(await _phoneAuthErrorMessage(e));
            }
          } finally {
            _phoneVerifyInFlight = false;
            isLoading = false;
            notifyListeners();
          }
        },
        verificationFailed: (FirebaseAuthException e) async {
          PhoneAuthLog.verificationFailed(e.code);
          watchdog?.cancel();
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
          _resetPhoneVerifyState(error: message);
          log('verificationFailed: ${e.code} ${e.message}', error: e, stackTrace: StackTrace.current);
        },
        codeSent: (String verificationId, int? resendToken) {
          PhoneAuthLog.codeSent();
          _verificationId = verificationId;
          _resendToken = resendToken;
          opController.clear();
          FirebasePhoneAuthLogger.info(
            'codeSent verificationId=${verificationId.substring(0, 8)}… '
            'phone=$phoneNumber resendToken=${resendToken != null}',
          );
          onCodeReady();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          PhoneAuthLog.codeAutoRetrievalTimeout();
          _verificationId = verificationId;
          FirebaseAuthReadiness.log('codeAutoRetrievalTimeout');
          if (navigateToOtpOnCodeSent && !PhoneAuthCoordinator.isOtpRouteOpen) {
            onCodeReady();
          } else {
            watchdog?.cancel();
            _phoneVerifyInFlight = false;
            isLoading = false;
            notifyListeners();
          }
        },
      );
      FirebasePhoneAuthLogger.info(
        'FirebaseAuth.verifyPhoneNumber SDK call returned; waiting for callbacks',
      );
      await FirebasePhoneAuthLogger.logVerifyPhoneSnapshot(
        phase: 'AFTER verifyPhoneNumber await',
        phoneNumber: phoneNumber,
      );
    } catch (e, st) {
      watchdog.cancel();
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
      _resetPhoneVerifyState(error: message);
      log('verifyPhoneNumber threw', error: e, stackTrace: st);
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
    if (isLoading) {
      PhoneAuthLog.duplicateTapIgnored('signInWithOTP');
      return false;
    }

    if (_verificationId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'OTP session expired. Go back and request a new code.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    PhoneAuthLog.otpEntered();

    try {
      isLoading = true;
      notifyListeners();

      PhoneAuthLog.credentialCreated();
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

      if (userCredential.user != null) {
        _finishPhoneSignIn();
        isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();
      final code = e.code;
      if (code == 'invalid-verification-code' ||
          code == 'invalid-verification-id' ||
          code == 'session-expired') {
        return false;
      }
      if (context.mounted) {
        final message = await _phoneAuthErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.unexpectedError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Resend OTP using Firebase [forceResendingToken] when available.
  Future<void> resendOtp(BuildContext context) async {
    if (_phoneVerifyInFlight || isLoading) return;

    final phoneNumber = FirebaseAuthReadiness.normalizePhoneNumber(
      mobileController.text,
    );
    if (phoneNumber == null) return;

    await _startPhoneVerification(
      phoneNumber: phoneNumber,
      forceResendingToken: _resendToken,
      navigateToOtpOnCodeSent: false,
    );
  }

  Future<void> registerUser(BuildContext context) async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterName),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseSelectGender),
          backgroundColor: Colors.red,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(referralMsg),
            backgroundColor: Colors.orange,
          ),
        );
      }
      AppBootstrapShell.markOnboardingComplete(context);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
