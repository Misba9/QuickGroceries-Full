import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/view/home/data/services/banner_service.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';

class BannerRepository {
  BannerRepository(this._service);
  final HomeBannerService _service;

  Stream<List<BannerModel>> watchActiveBanners({int? limit}) {
    return _service
        .watchActiveBanners(limit: limit)
        .map(_mapSnapshot)
        .handleError((Object error, StackTrace stackTrace) {
          if (kDebugMode) {
            debugPrint('[Banners] stream error: $error');
          }
          throw HomeFailure(
            'Failed to load banners.',
            code: _codeOf(error),
            cause: error,
          );
        });
  }

  List<BannerModel> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final raw = snap.docs.length;
    final parsed = <BannerModel>[];
    var parseFailures = 0;
    for (final doc in snap.docs) {
      try {
        parsed.add(BannerModel.fromFirestore(doc.data(), doc.id));
      } catch (e) {
        parseFailures++;
        if (kDebugMode) {
          debugPrint(
            '[Banners] failed to parse doc ${doc.id}: $e',
          );
        }
      }
    }

    final inactive = parsed.where((b) => !b.isActive).length;
    final noMedia = parsed.where((b) => !b.hasPromoMedia).length;

    final items = parsed
        .where((b) => b.isActive)
        .where((b) => b.hasPromoMedia)
        .toList();
    items.sort((a, b) => a.priority.compareTo(b.priority));

    if (kDebugMode) {
      debugPrint(
        '[Banners] raw=$raw parsed=${parsed.length} '
        'inactive=$inactive noMedia=$noMedia '
        'parseFailures=$parseFailures → showing=${items.length}',
      );
      if (items.isEmpty && raw > 0) {
        debugPrint(
          '[Banners] All $raw doc(s) were filtered out. '
          'Check `isActive` plus `image` / `video` / `thumbnailUrl`.',
        );
      }
    }
    return items;
  }

  String? _codeOf(Object error) {
    if (error is FirebaseException) return error.code;
    return null;
  }
}
