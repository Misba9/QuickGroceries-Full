import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/view/home/data/services/category_service.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';

class CategoryRepository {
  CategoryRepository(this._service);
  final HomeCategoryService _service;

  /// Realtime stream of active categories ready for UI consumption.
  Stream<List<CategoryModel>> watchActiveCategories({int? limit}) {
    return _service
        .watchActiveCategories(limit: limit)
        .map(_mapSnapshot)
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
      return _mapSnapshot(snap);
    } catch (e) {
      throw HomeFailure(
        'Failed to load categories.',
        code: _codeOf(e),
        cause: e,
      );
    }
  }

  List<CategoryModel> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final items = snap.docs
        .map((d) => CategoryModel.fromFirestore(d.data(), d.id))
        // Filter inactive client-side so legacy docs (no `isActive`) survive.
        .where((c) => c.isActive)
        .toList();
    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  String? _codeOf(Object error) {
    if (error is FirebaseException) return error.code;
    return null;
  }
}
