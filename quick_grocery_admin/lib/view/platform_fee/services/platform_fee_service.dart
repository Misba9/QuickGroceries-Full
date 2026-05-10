import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlatformFeeService extends ChangeNotifier {
  bool isLoading = false;

  TextEditingController platformFeeController = TextEditingController();

  // Document ID
  final String platformFeeDocId = 'r6ArqhMeZYDJnpFo6EJP';

  Future<void> fetchCharges() async {
    try {
      isLoading = true;
      notifyListeners();

      // Fetch platform fee document
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('delivery_charge')
          .doc(platformFeeDocId)
          .get();

      // Extract data
      if (snapshot.exists) {
        var doc = snapshot.data() as Map<String, dynamic>;
        platformFeeController.text = (doc['amount'] ?? 0).toString();
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching platform fee: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCharges(BuildContext context) async {
    try {
      // Validate input
      if (platformFeeController.text.isEmpty) {
        showValidationDialog(context, "Platform fee cannot be empty.");
        return;
      }

      // Parse value
      double? platformFee = double.tryParse(platformFeeController.text);

      if (platformFee == null || platformFee < 0) {
        showValidationDialog(
          context,
          "Please enter a valid platform fee amount.",
        );
        return;
      }

      isLoading = true;
      notifyListeners();

      // Update platform fee document
      await FirebaseFirestore.instance
          .collection('delivery_charge')
          .doc(platformFeeDocId)
          .update({'amount': platformFee});

      isLoading = false;
      notifyListeners();
      showSuccessDialog(context, "Platform fee updated successfully!");
    } catch (e) {
      isLoading = false;
      notifyListeners();
      showValidationDialog(context, "Error updating platform fee: $e");
    }
  }

  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("Success", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void showValidationDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                "Validation Error",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Text("OK", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    platformFeeController.dispose();
    super.dispose();
  }
}
