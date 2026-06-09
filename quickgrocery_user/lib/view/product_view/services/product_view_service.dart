// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/models/rating_model.dart';

class ProductViewService extends ChangeNotifier {
  bool isFavorite = false;
  List<ProductModel>? similorProducts;
  int _itemCount = 1;
  List<RatingModel>? ratings;
  double averageRating = 0.0;
  int totalRatings = 0;

  int get itemCount => _itemCount;

  void onItemAdd() {
    _itemCount++;
    notifyListeners();
  }

  void onItemRemove() {
    if (_itemCount > 1) {
      _itemCount--;
      notifyListeners();
    }
  }

  Future<void> getSimilarProducts(String category, String id) async {
    if (similorProducts == null) {
      CollectionReference collectionRef = FirebaseFirestore.instance.collection(
        'products',
      );
      QuerySnapshot querySnapshot = await collectionRef
          .where('category', isEqualTo: category)
          .get();

      similorProducts = querySnapshot.docs.map((doc) {
        return ProductModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      notifyListeners();
      if (similorProducts != null) {
        var itemsToRemove = [];

        for (var item in similorProducts!) {
          if (item.id == id) {
            itemsToRemove.add(item);
          }
        }

        similorProducts!.removeWhere((item) => itemsToRemove.contains(item));
        notifyListeners();
      }
    }
  }

  Future<void> favoriteAdd(BuildContext context, String id) async {
    isFavorite = !isFavorite;
    notifyListeners();
    if (isFavorite == true) {
      await FirebaseFirestore.instance.collection('products').doc(id).update({
        "is_favorite": FieldValue.arrayUnion([
          FirebaseAuth.instance.currentUser!.uid,
        ]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.product_added_favorite)),
      );
    } else {
      await FirebaseFirestore.instance.collection('products').doc(id).update({
        "is_favorite": FieldValue.arrayRemove([
          FirebaseAuth.instance.currentUser!.uid,
        ]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.product_removed_favorite)),
      );
    }
  }

  Future<void> getProductRatings(String productId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('product_id', isEqualTo: productId)
          .get();

      ratings = querySnapshot.docs.map((doc) {
        return RatingModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Calculate average rating
      if (ratings != null && ratings!.isNotEmpty) {
        totalRatings = ratings!.length;
        double sum = ratings!.fold(0.0, (sum, rating) => sum + rating.rating);
        averageRating = sum / totalRatings;
      } else {
        totalRatings = 0;
        averageRating = 0.0;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching ratings: $e');
      ratings = [];
      averageRating = 0.0;
      totalRatings = 0;
      notifyListeners();
    }
  }
}
