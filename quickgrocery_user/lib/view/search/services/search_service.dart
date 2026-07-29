import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/models/product.dart';

class SearchService extends ChangeNotifier {
  List<ProductModel>? productsList;
  List<ProductModel>? filteredProductsList;

  void resetSessionForLogout() {
    productsList = null;
    filteredProductsList = null;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    if (productsList == null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('products')
            .orderBy(FieldPath.documentId)
            .limit(300)
            .get();

        productsList = snapshot.docs
            .map((doc) {
              return ProductModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            })
            .where((p) => p.isAvailable)
            .toList();

        filteredProductsList = productsList;
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> addFavorite(String id) async {
    await FirebaseFirestore.instance.collection('products').doc(id).update({
      "favorites": FieldValue.arrayUnion([
        FirebaseAuth.instance.currentUser!.uid,
      ]),
    });
  }

  Future<void> removeFavorite(String id) async {
    await FirebaseFirestore.instance.collection('products').doc(id).update({
      "favorites": FieldValue.arrayRemove([
        FirebaseAuth.instance.currentUser!.uid,
      ]),
    });
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      filteredProductsList = productsList; // Reset to full list
    } else {
      filteredProductsList = productsList
          ?.where(
            (product) =>
                product.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    notifyListeners();
  }
}
