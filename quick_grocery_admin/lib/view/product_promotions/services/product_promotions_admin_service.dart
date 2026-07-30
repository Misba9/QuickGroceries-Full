import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/view/product_promotions/models/product_promotion_model.dart';

/// Admin service for product promotions — callables + live Firestore streams.
class ProductPromotionsAdminService {
  ProductPromotionsAdminService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _fn = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  Stream<List<ProductPromotionModel>> watchPromotions({String? productId}) {
    Query<Map<String, dynamic>> q = _db.collection('product_promotions');
    if (productId != null && productId.isNotEmpty) {
      q = q.where('productId', isEqualTo: productId);
    }
    return q.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => ProductPromotionModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.priority.compareTo(a.priority));
      return list;
    });
  }

  Stream<List<ProductModel>> watchProducts() {
    return _db.collection('products').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => ProductModel.fromFirestore(d.data(), d.id))
          .where((p) => !p.isDeleted)
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final result = await _fn.httpsCallable(name).call(payload);
    final data = result.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'ok': true, 'data': data};
  }

  Future<void> patchProductPromotions({
    required String productId,
    required Map<String, bool> flags,
    double? salePrice,
    double? discountPercent,
    DateTime? flashSaleStart,
    DateTime? flashSaleEnd,
    DateTime? offerExpiry,
    int? stockLimit,
    int? maxPurchase,
    bool? visible,
    bool? pinToTop,
    String? bannerLabel,
    String? badge,
    bool locked = true,
    String reason = '',
  }) async {
    await _call('patchProductPromotionsCallable', {
      'productId': productId,
      'flags': flags,
      if (salePrice != null) 'salePrice': salePrice,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (flashSaleStart != null)
        'flashSaleStart': flashSaleStart.toUtc().toIso8601String(),
      if (flashSaleEnd != null)
        'flashSaleEnd': flashSaleEnd.toUtc().toIso8601String(),
      if (offerExpiry != null)
        'offerExpiry': offerExpiry.toUtc().toIso8601String(),
      if (stockLimit != null) 'stockLimit': stockLimit,
      if (maxPurchase != null) 'maxPurchase': maxPurchase,
      if (visible != null) 'visible': visible,
      if (pinToTop != null) 'pinToTop': pinToTop,
      if (bannerLabel != null) 'bannerLabel': bannerLabel,
      if (badge != null) 'badge': badge,
      'locked': locked,
      'reason': reason,
    });
  }

  Future<void> deletePromotion(String id, {String reason = 'deleted'}) async {
    await _call('adminDeletePromotionCallable', {
      'id': id,
      'reason': reason,
    });
  }

  Future<List<ProductPromotionModel>> listViaApi({String? productId}) async {
    final res = await _call('adminListPromotionsCallable', {
      if (productId != null) 'productId': productId,
      'includeExpired': true,
    });
    final raw = res['promotions'];
    if (raw is! List) return [];
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return ProductPromotionModel.fromMap(m, m['id']?.toString() ?? '');
    }).toList();
  }

  Future<List<Map<String, dynamic>>> listPromotionRequests({
    String status = 'pending',
  }) async {
    final res = await _call('adminListPromotionRequestsCallable', {
      'status': status,
    });
    final raw = res['requests'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> resolvePromotionRequest({
    required String requestId,
    required String action,
    String reviewNote = '',
  }) async {
    await _call('adminResolvePromotionRequestCallable', {
      'id': requestId,
      'action': action,
      if (reviewNote.isNotEmpty) 'reviewNote': reviewNote,
    });
  }
}
