import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/models/product.dart';

class WishlistService extends ChangeNotifier {
  List<ProductModel>? wishlistProducts;
  bool isLoading = false;

  void resetSessionForLogout() {
    wishlistProducts = null;
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchWishlistProducts() async {
    isLoading = true;
    notifyListeners();

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        wishlistProducts = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('is_favorite', arrayContains: currentUserId)
          .get();

      wishlistProducts = snapshot.docs.map((doc) {
        return ProductModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching wishlist products: $e");
      wishlistProducts = [];
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromWishlist(BuildContext context, String id) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(id).update({
        "is_favorite": FieldValue.arrayRemove([
          FirebaseAuth.instance.currentUser!.uid,
        ]),
      });

      // Remove from local list
      wishlistProducts?.removeWhere((product) => product.id == id);
      notifyListeners();

      AppSnackBar.success(
        context.l10n.product_removed_favorite,
        context: context,
      );
    } catch (e) {
      debugPrint("Error removing from wishlist: $e");
      AppSnackBar.error(
        context.l10n.failedToRemoveProduct,
        context: context,
      );
    }
  }

  void refreshWishlist() {
    wishlistProducts = null;
    fetchWishlistProducts();
  }
}
