import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/rating_model.dart';

/// Loads vendor reviews from `ratings` (by vendor_id or vendor product ids).
class VendorReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<RatingModel>> watchVendorReviews(String vendorId) async* {
    await for (final snap in _db
        .collection('ratings')
        .where('vendor_id', isEqualTo: vendorId)
        .snapshots()) {
      var docs = snap.docs;
      if (docs.isEmpty) {
        try {
          docs = await _loadByProductIds(vendorId);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[VendorReviewService] product fallback: $e');
          }
        }
      }
      yield _mapVisible(docs);
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadByProductIds(
    String vendorId,
  ) async {
    final products = await _db
        .collection('products')
        .where('vendor_id', isEqualTo: vendorId)
        .limit(80)
        .get();
    final ids = products.docs.map((d) => d.id).toList();
    if (ids.isEmpty) return [];

    final all = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.skip(i).take(10).toList();
      final snap = await _db
          .collection('ratings')
          .where('product_id', whereIn: chunk)
          .get();
      all.addAll(snap.docs);
    }
    return all;
  }

  List<RatingModel> _mapVisible(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final list = <RatingModel>[];
    for (final doc in docs) {
      final data = doc.data();
      if (data['hidden'] == true) continue;
      final status = (data['status'] ?? 'approved').toString();
      if (status == 'rejected' || status == 'hidden') continue;
      try {
        list.add(RatingModel.fromFirestore(data, doc.id));
      } catch (e) {
        if (kDebugMode) debugPrint('[VendorReviewService] parse ${doc.id}: $e');
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
