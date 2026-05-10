import 'dart:developer';
import 'package:quick_grocery_admin/model/rating_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RatingService extends ChangeNotifier {
  bool isLoading = false;
  TextEditingController userNameController = TextEditingController();
  TextEditingController reviewController = TextEditingController();
  double selectedRating = 0.0;

  void setRating(double rating) {
    selectedRating = rating;
    notifyListeners();
  }

  Future<void> addRating(BuildContext context, String productId, String productName) async {
    if (userNameController.text.isEmpty) {
      showValidationDialog(context, "User name cannot be empty.");
      return;
    }
    if (selectedRating == 0.0) {
      showValidationDialog(context, "Please select a rating.");
      return;
    }
    if (reviewController.text.isEmpty) {
      showValidationDialog(context, "Review cannot be empty.");
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('ratings')
          .add({
            'id': "",
            'product_id': productId,
            'product_name': productName,
            'rating': selectedRating,
            'review': reviewController.text,
            'user_name': userNameController.text,
            'user_id': '', // Admin added rating, so no user_id
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });

      String ratingId = docRef.id;
      await docRef.update({"id": ratingId});

      isLoading = false;
      notifyListeners();
      showSuccessDialog(context);
      resetFields();
    } catch (e) {
      log(e.toString());
      isLoading = false;
      notifyListeners();
      showValidationDialog(context, "Error adding rating: ${e.toString()}");
    }
  }

  Future<List<RatingModel>> fetchRatingsByProduct(String productId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('product_id', isEqualTo: productId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return RatingModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      log(e.toString());
      return [];
    }
  }

  Future<void> deleteRating(BuildContext context, String ratingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ratings')
          .doc(ratingId)
          .delete();
      showSuccessDialog(context, "Rating deleted successfully!");
    } catch (e) {
      log(e.toString());
      showValidationDialog(context, "Error deleting rating: ${e.toString()}");
    }
  }

  void resetFields() {
    userNameController.clear();
    reviewController.clear();
    selectedRating = 0.0;
    notifyListeners();
  }

  void showSuccessDialog(BuildContext context, [String? message]) {
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
          content: Text(message ?? "Rating added successfully!"),
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
    userNameController.dispose();
    reviewController.dispose();
    super.dispose();
  }
}

