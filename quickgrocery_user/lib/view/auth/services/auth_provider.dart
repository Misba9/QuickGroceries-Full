import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> verifyPhoneNumber(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    await _auth.verifyPhoneNumber(
      phoneNumber: "+91${mobileController.text}",
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        isLoading = false;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone auth failed: ${e.code} — ${e.message ?? ""}'),
          ),
        );
        log("Failed to verify phone number: ${e.code} ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        opController.clear();
        log("OTP code sent to phone.");
        isLoading = false;
        notifyListeners();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OtpAuthScreen()),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        isLoading = false;
        notifyListeners();
        log("Auto retrieval timeout.");
      },
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Phone auth failed'),
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
    if (mobileController.text.length < 10) return;
    isLoading = true;
    notifyListeners();
    await _auth.verifyPhoneNumber(
      phoneNumber: "+91${mobileController.text}",
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        isLoading = false;
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone auth failed: ${e.code} — ${e.message ?? ""}'),
            ),
          );
        }
        log("Resend OTP failed: ${e.code} ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        opController.clear();
        isLoading = false;
        notifyListeners();
        log("OTP resent.");
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        isLoading = false;
        notifyListeners();
      },
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
