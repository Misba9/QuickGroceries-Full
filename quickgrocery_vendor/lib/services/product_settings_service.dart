import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_settings.dart';

class ProductSettingsPatchResult {
  const ProductSettingsPatchResult({required this.settings});
  final ProductSettings settings;
}

class ProductSettingsService {
  ProductSettingsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<ProductSettings> watchSettings(String productId) {
    return _db.collection('products').doc(productId).snapshots().map((snap) {
      return ProductSettings.fromMap(snap.data() ?? {});
    });
  }

  Future<ProductSettings> fetchSettings(String productId) async {
    final snap = await _db.collection('products').doc(productId).get();
    return ProductSettings.fromMap(snap.data() ?? {});
  }

  /// Applies smart automation rules when auto-* flags are enabled.
  ProductSettings applyAutomation({
    required ProductSettings current,
    required int stock,
    required int totalSold,
    required DateTime? createdAt,
  }) {
    var s = current;
    if (s.autoMostSelling) {
      s = s.copyWith(isMostSelling: totalSold >= 5);
    }
    if (s.autoTrending) {
      s = s.copyWith(isTrending: totalSold >= 3 || stock > 0 && totalSold >= 1);
    }
    if (s.autoLimitedStock) {
      s = s.copyWith(isLimitedStock: stock > 0 && stock <= 5);
    }
    if (s.autoNewArrival && createdAt != null) {
      final days = DateTime.now().difference(createdAt).inDays;
      s = s.copyWith(isNewArrival: days <= 14);
    }
    return s;
  }

  Future<ProductSettingsPatchResult> patchSettings({
    required String productId,
    required ProductSettings settings,
    String? existingSpecialCat,
  }) async {
    final doc = await _db.collection('products').doc(productId).get();
    final data = doc.data() ?? {};
    final patch = settings.toFirestorePatch(
      existingSpecialCat: existingSpecialCat ?? data['special_cat']?.toString(),
    );
    await _db.collection('products').doc(productId).update(patch);
    return ProductSettingsPatchResult(settings: settings);
  }
}
