import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/models/promo_model.dart';
import 'package:quickgrocery/view/category/data/services/promo_service.dart';

/// Repository for the admin-driven `promos` collection.
///
/// Applies client-side `isActive` filtering + `priority` sort so legacy
/// documents missing those fields still render.
class PromoRepository {
  PromoRepository(this._service);

  final PromoService _service;

  Stream<List<PromoModel>> watchActivePromos({int? limit}) {
    return _service.watchActivePromos(limit: limit).map(_map).handleError(
      (Object e, StackTrace _) {
        if (kDebugMode) debugPrint('[Promos] stream error: $e');
        return <PromoModel>[];
      },
    );
  }

  List<PromoModel> _map(QuerySnapshot<Map<String, dynamic>> snap) {
    final parsed = <PromoModel>[];
    for (final d in snap.docs) {
      try {
        parsed.add(PromoModel.fromFirestore(d.data(), d.id));
      } catch (e) {
        if (kDebugMode) debugPrint('[Promos] parse failed for ${d.id}: $e');
      }
    }
    final out = parsed
        .where((p) => p.isActive)
        .where((p) => p.mediaUrl.isNotEmpty || p.title.isNotEmpty)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    if (kDebugMode) {
      debugPrint(
        '[Promos] raw=${snap.docs.length} parsed=${parsed.length} → showing=${out.length}',
      );
    }
    return out;
  }
}
