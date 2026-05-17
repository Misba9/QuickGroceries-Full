import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/models/combo_offer_model.dart';
import 'package:quickgrocery/models/product.dart';

/// Firestore access for `combo_offers/`.
class ComboOfferService {
  ComboOfferService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const _collection = 'combo_offers';

  Stream<List<ComboOfferModel>> watchActiveCombos() {
    return _db.collection(_collection).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => ComboOfferModel.fromFirestore(d.data(), d.id))
          .where((c) => c.isActive && c.isScheduleOk)
          .toList();
      list.sort((a, b) => b.priority.compareTo(a.priority));
      return list;
    });
  }

  Future<void> incrementViewCount(String comboId) async {
    try {
      await _db.collection(_collection).doc(comboId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  Future<List<ProductModel>> fetchProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final out = <ProductModel>[];
    for (final id in ids) {
      try {
        final doc = await _db.collection('products').doc(id).get();
        if (doc.exists && doc.data() != null) {
          out.add(ProductModel.fromFirestore(doc.data()!, doc.id));
        }
      } catch (_) {}
    }
    return out;
  }

  Future<void> incrementOrderCount(String comboId) async {
    try {
      await _db.collection(_collection).doc(comboId).update({
        'orderCount': FieldValue.increment(1),
        'stock': FieldValue.increment(-1),
      });
    } catch (_) {}
  }
}
