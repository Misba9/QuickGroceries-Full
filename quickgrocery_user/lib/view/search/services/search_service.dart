import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/catalog/product_search.dart';
import 'package:quickgrocery/core/startup/startup_isolate_parse.dart';
import 'package:quickgrocery/models/product.dart';

class SearchService extends ChangeNotifier {
  List<ProductModel>? productsList;
  List<ProductModel>? filteredProductsList;
  Timer? _debounce;
  String _lastQuery = '';

  void resetSessionForLogout() {
    _debounce?.cancel();
    productsList = null;
    filteredProductsList = null;
    _lastQuery = '';
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    if (productsList == null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('products')
            .orderBy(FieldPath.documentId)
            .limit(300)
            .get();

        productsList =
            await StartupIsolateParse.parseProductsFromUntypedSnapshot(
          snapshot,
          onlyAvailable: true,
        );

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
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _applySearch('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _applySearch(trimmed);
    });
  }

  void _applySearch(String query) {
    _lastQuery = query;
    if (query.isEmpty) {
      filteredProductsList = productsList;
    } else {
      filteredProductsList = productsList
          ?.where(
            (product) => productMatchesSearchQuery(
              query,
              name: product.name,
              category: product.category,
              subcategory: product.subcategory,
              brand: product.brand,
              sku: product.sku,
              barcode: product.barcode,
              description: product.description,
            ),
          )
          .toList();
    }
    notifyListeners();
  }

  String get lastQuery => _lastQuery;
}
