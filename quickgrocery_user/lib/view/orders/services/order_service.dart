// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/models/order_model.dart';

class OrderService extends ChangeNotifier {
  List<OrderModel>? orders;
  List<OrderModel> deliveredOrders = [];
  List<OrderModel> upmcomingedOrders = [];
  List<OrderModel> cancellOrders = [];
  Future<void> getOrders() async {
    try {
      orders = []; // or null if you handle null in UI
      deliveredOrders.clear();
      upmcomingedOrders.clear();
      cancellOrders.clear();

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('uuid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      orders = snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      for (var item in orders!) {
        if (!item.isCancelled && item.isDelivered) {
          deliveredOrders.add(item);
        } else if (!item.isDelivered && !item.isCancelled) {
          upmcomingedOrders.add(item);
        } else if (item.isCancelled) {
          cancellOrders.add(item);
        }
      }

      // Newest first in all sections
      deliveredOrders.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      upmcomingedOrders.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      cancellOrders.sort((a, b) => b.createdDate.compareTo(a.createdDate));

      notifyListeners();
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  Future<void> cancellOrder(BuildContext context, String id) async {
    await FirebaseFirestore.instance.collection('orders').doc(id).update({
      "isCancelled": true,
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Order Cancelled by you!")));
    getOrders();
  }

  void showReviewDialog(BuildContext context, String id) {
    double rating = 0;
    TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Leave a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                    onPressed: () {
                      rating = index + 1.0;
                      (context as Element).markNeedsBuild();
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),
              // Review TextField
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Write your review',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String review = reviewController.text;
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(id)
                    .set({
                      'is_rated': true,
                      'star': rating,
                    }, SetOptions(merge: true));
                getOrders();

                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
