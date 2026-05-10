import 'package:quick_grocery_admin/view/home/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginService extends ChangeNotifier {
  bool isLoading = false;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> signIn(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    try {
      // Check if the email exists in the Firestore admins collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: emailController.text)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Access Denied"),
            content: Text("You are not an admin. Please contact support."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
        isLoading = false;
        notifyListeners();
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );
      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {}
  }
}
