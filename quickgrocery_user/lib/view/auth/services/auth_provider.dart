import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickgrocery/core/firebase/firebase_auth_readiness.dart';
import 'package:quickgrocery/core/firebase/firebase_config_audit.dart';
import 'package:quickgrocery/view/auth/screens/customer_profile_add_screen.dart';
import 'package:quickgrocery/view/auth/screens/otp_screen.dart';
import 'package:quickgrocery/view/home/screens/landing_screen.dart';

class AuthService extends ChangeNotifier {
  bool _isVisible = false;
  File? image;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get isVisible => _isVisible;
  String _verificationId = '';
  int? _resendToken;
  bool isLoading = false;
  String? phoneAuthError;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? selectedGender; // 'male' or 'female'

  TextEditingController mobileController = TextEditingController();
  TextEditingController opController = TextEditingController();

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
      if (deepLink.queryParameters.containsKey('ref')) {
        String referrerId = deepLink.queryParameters['ref']!;
        saveReferral(referrerId);
      }
    }

    FirebaseDynamicLinks.instance.onLink
        .listen((PendingDynamicLinkData data) {
          final Uri deepLink = data.link;
          if (deepLink.queryParameters.containsKey('ref')) {
            String referrerId = deepLink.queryParameters['ref']!;
            saveReferral(referrerId);
          }
        })
        .onError((error) {
          print("Dynamic Link Error: $error");
        });
  }

  Future<void> saveReferral(String referrerId) async {
    await FirebaseFirestore.instance
        .collection('customers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({'referred_by': referrerId}, SetOptions(merge: true));

    print("Referral saved! New user referred by: $referrerId");
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
      _setPhoneAuthError(readinessError);
      return;
    }

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
    isLoading = true;
    notifyListeners();

    FirebaseAuthReadiness.log(
      'verifyPhoneNumber start phone=$phoneNumber resend=${forceResendingToken != null}',
    );
    if (kDebugMode) {
      FirebaseAuthReadiness.log(FirebaseConfigAudit.emulatorTestNumberHint());
    }

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
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          FirebaseAuthReadiness.log('verificationCompleted (auto)');
          watchdog?.cancel();
          if (!context.mounted) return;
          try {
            await _auth.signInWithCredential(credential);
            FirebaseAuthReadiness.log('auto sign-in succeeded');
          } catch (e, st) {
            FirebaseAuthReadiness.log('auto sign-in failed: $e');
            log('Auto phone sign-in failed', error: e, stackTrace: st);
          } finally {
            isLoading = false;
            notifyListeners();
          }
        },
        verificationFailed: (FirebaseAuthException e) async {
          watchdog?.cancel();
          isLoading = false;
          FirebaseAuthReadiness.log(
            'verificationFailed: ${FirebaseConfigAudit.formatAuthException(e)}',
          );
          final message = await _phoneAuthErrorMessage(e);
          _setPhoneAuthError(message);
          log('verificationFailed: ${e.code} ${e.message}', error: e);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          watchdog?.cancel();
          _verificationId = verificationId;
          _resendToken = resendToken;
          opController.clear();
          isLoading = false;
          clearPhoneAuthError();
          FirebaseAuthReadiness.log(
            'codeSent verificationId=${verificationId.substring(0, 8)}…',
          );
          notifyListeners();

          if (!context.mounted) return;

          if (navigateToOtpOnCodeSent) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OtpAuthScreen()),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          FirebaseAuthReadiness.log('codeAutoRetrievalTimeout');
          isLoading = false;
          notifyListeners();
        },
      );
    } catch (e, st) {
      watchdog.cancel();
      isLoading = false;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
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
        return FirebaseConfigAudit.messageForAuthException(e);
      default:
        return FirebaseConfigAudit.formatAuthException(e);
    }
  }

  /// Returns `true` if sign-in succeeded and navigation was performed.
  /// Returns `false` for an invalid OTP (caller should shake UI / show error).
  Future<bool> signInWithOTP(String smsCode, BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null && context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const CustomerDetailsAddScreen(),
          ),
          (Route<dynamic> route) => false,
        );
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
            content: Text("Unexpected error: $e"),
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

  Future<bool> doesMobileNumberExist() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('customers')
          .where('phone', isEqualTo: mobileController.text)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking mobile number existence: $e');
      return false;
    }
  }

  void checkMobileNumber(BuildContext context) async {
    if (mobileController.text.isNotEmpty) {
      bool exists = await doesMobileNumberExist();
      final pref = await SharedPreferences.getInstance();
      if (exists) {
        pref.setBool('isUserExist', true);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LandingScreen()),
          (Route<dynamic> route) => false,
        );
        await handleReferralAfterInstall();

        isLoading = false;
        notifyListeners();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CustomerDetailsAddScreen(),
          ),
        );
        await handleReferralAfterInstall();

        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> registerUser(BuildContext context) async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter name"),
          backgroundColor: Colors.red,
        ),
      );
    } else if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select gender"),
          backgroundColor: Colors.red,
        ),
      );
    } else if (image == null) {
      final pref = await SharedPreferences.getInstance();

      isLoading = true;
      notifyListeners();
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
            'profile_image': '',
            'name': nameController.text,
            'email': emailController.text,
            'phone': mobileController.text,
            'uid': FirebaseAuth.instance.currentUser!.uid,
            'created_date': DateTime.now().toString(),
            "fcm_token": "",
            "gender": selectedGender,
          });
      // Store gender in SharedPreferences
      await pref.setString('user_gender', selectedGender!);
      pref.setBool('isUserExist', true);
      isLoading = false;
      notifyListeners();
      await handleReferralAfterInstall();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
        (Route<dynamic> route) =>
            false, // This condition removes all previous routes.
      );
    } else {
      final pref = await SharedPreferences.getInstance();
      String imageUrl = await uploadImageToStorage(image!);
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
            'profile_image': imageUrl,
            'name': nameController.text,
            'email': emailController.text,
            'phone': mobileController.text,
            'uid': FirebaseAuth.instance.currentUser!.uid,
            'created_date': DateTime.now().toString(),
            "fcm_token": "",
            "gender": selectedGender,
          });
      // Store gender in SharedPreferences
      await pref.setString('user_gender', selectedGender!);
      pref.setBool('isUserExist', true);
      isLoading = false;
      notifyListeners();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
        (Route<dynamic> route) =>
            false, // This condition removes all previous routes.
      );
    }
  }
}
