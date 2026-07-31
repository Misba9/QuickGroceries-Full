import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/analytics/search_analytics_logger.dart';
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

  /// Live typing filter (debounced). Logs after pause with rate-limit.
  void searchProducts(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _applySearch('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _applySearch(trimmed, logSource: 'live', forceLog: false);
    });
  }

  /// Committed search (keyboard submit, voice, recent chip). Always logged.
  void commitSearch(String query, {String source = 'typed'}) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _applySearch(trimmed, logSource: source, forceLog: true);
  }

  void _applySearch(
    String query, {
    String? logSource,
    bool forceLog = false,
  }) {
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

    if (logSource != null && query.trim().length >= 2) {
      final results = filteredProductsList ?? const <ProductModel>[];
      unawaited(
        SearchAnalyticsLogger.log(
          query: query,
          resultCount: results.length,
          source: logSource,
          topResultIds: results.map((p) => p.id).where((id) => id.isNotEmpty).toList(),
          topResultNames:
              results.map((p) => p.name).where((n) => n.isNotEmpty).toList(),
          catalogSampleSize: productsList?.length ?? 0,
          force: forceLog,
        ),
      );
    }
  }

  String get lastQuery => _lastQuery;
}
