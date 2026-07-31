import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/core/startup/startup_isolate_parse.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/view/home/data/services/category_service.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';
import 'package:rxdart/rxdart.dart';

class CategoryRepository {
  CategoryRepository(this._service);
  final HomeCategoryService _service;

  /// Shared Firestore subscription for the default Home categories rail.
  Stream<List<CategoryModel>>? _sharedActive;

  /// Realtime stream of active categories ready for UI consumption.
  Stream<List<CategoryModel>> watchActiveCategories({int? limit}) {
    if (limit != null && limit > 0) {
      return _mapStream(_service.watchActiveCategories(limit: limit));
    }
    return _sharedActive ??=
        _mapStream(_service.watchActiveCategories()).shareReplay(maxSize: 1);
  }

  Stream<List<CategoryModel>> _mapStream(
    Stream<QuerySnapshot<Map<String, dynamic>>> raw,
  ) {
    return raw
        .asyncMap(StartupIsolateParse.parseCategoriesFromSnapshot)
        .handleError((Object error, StackTrace stackTrace) {
          throw HomeFailure(
            'Failed to load categories.',
            code: _codeOf(error),
            cause: error,
          );
        });
  }

  Future<List<CategoryModel>> fetchActiveCategories({int? limit}) async {
    try {
      final snap = await _service.fetchActiveCategories(limit: limit);
      return StartupIsolateParse.parseCategoriesFromSnapshot(snap);
    } catch (e) {
      throw HomeFailure(
        'Failed to load categories.',
        code: _codeOf(e),
        cause: e,
      );
    }
  }

  String? _codeOf(Object error) {
    if (error is FirebaseException) return error.code;
    return null;
  }
}
