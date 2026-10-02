import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quickgrocery/core/startup/startup_isolate_parse.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/view/home/data/services/banner_service.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';
import 'package:rxdart/rxdart.dart';

class BannerRepository {
  BannerRepository(this._service);
  final HomeBannerService _service;

  /// Single Firestore `banners` subscription shared by Home + Offers consumers.
  Stream<List<BannerModel>>? _sharedActive;

  Stream<List<BannerModel>> watchActiveBanners({int? limit}) {
    if (limit != null && limit > 0) {
      return _mapStream(_service.watchActiveBanners(limit: limit));
    }
    return _sharedActive ??=
        _mapStream(_service.watchActiveBanners()).shareReplay(maxSize: 1);
  }

  Stream<List<BannerModel>> _mapStream(
    Stream<QuerySnapshot<Map<String, dynamic>>> raw,
  ) {
    return raw
        .asyncMap(StartupIsolateParse.parseBannersFromSnapshot)
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

  Future<List<BannerModel>> fetchActiveBanners({int? limit}) async {
    try {
      final snap = await _service.fetchActiveBanners(limit: limit);
      return StartupIsolateParse.parseBannersFromSnapshot(snap);
    } catch (e) {
      if (kDebugMode) debugPrint('[Banners] fetch error: $e');
      return const [];
    }
  }

  String? _codeOf(Object error) {
    if (error is FirebaseException) return error.code;
    return null;
  }
}
