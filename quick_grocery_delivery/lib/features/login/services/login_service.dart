import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginService extends ChangeNotifier {
  bool isLoading = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();
      // Query Firestore to check if the document exists with matching email and password
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('delivery_boys')
          .where('email', isEqualTo: emailController.text.trim())
          .where('password', isEqualTo: passwordController.text.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String deliveryBoyId = querySnapshot.docs.first.id;
        // Save the delivery boy's ID in shared preferences for later access
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('deliveryBoyId', deliveryBoyId);
        // Credentials match, proceed with login
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login successful!")));
        isLoading = false;
        notifyListeners();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        // Navigate to the home screen or dashboard
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        isLoading = false;
        notifyListeners();
        // Credentials do not match
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid email or password.")),
        );
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }
}
