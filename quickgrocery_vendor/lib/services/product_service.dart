import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/product_settings.dart';
import 'product_settings_service.dart';

class ProductService {
  ProductService({
    FirebaseFirestore? firestore,
    ProductSettingsService? settingsService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _settingsService = settingsService ?? ProductSettingsService();

  final FirebaseFirestore _firestore;
  final ProductSettingsService _settingsService;
  final String _collectionName = 'products';

  Stream<List<ProductModel>> getVendorProducts(String vendorId) {
    return _firestore
        .collection(_collectionName)
        .where('vendor_id', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<ProductModel?> watchProduct(String productId) {
    return _firestore
        .collection(_collectionName)
        .doc(productId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return ProductModel.fromFirestore(snap.data()!, snap.id);
    });
  }

  Future<ProductModel?> getProductById(String productId) async {
    final doc = await _firestore.collection(_collectionName).doc(productId).get();
    if (doc.exists) {
      return ProductModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  Future<String> addProduct(ProductModel product) async {
    final docRef =
        await _firestore.collection(_collectionName).add(product.toCreateMap());
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  Future<void> updateProduct(ProductModel product) async {
    await _firestore
        .collection(_collectionName)
        .doc(product.id)
        .update(product.toUpdateMap());
    await _settingsService.patchSettings(
      productId: product.id,
      settings: product.settings,
      existingSpecialCat: product.specialCat,
    );
  }

  Future<void> patchSettings({
    required String productId,
    required ProductSettings settings,
    String? specialCat,
  }) async {
    await _settingsService.patchSettings(
      productId: productId,
      settings: settings,
      existingSpecialCat: specialCat,
    );
  }

  ProductSettingsService get settingsService => _settingsService;

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection(_collectionName).doc(productId).delete();
  }

  Future<void> patchImages(String productId, List<String> urls) async {
    await _firestore.collection(_collectionName).doc(productId).update({
      ...ProductModel.imageFieldsForFirestore(urls),
      'lastEdited': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleProductStatus(String productId, bool isActive) async {
    final settings = await _settingsService.fetchSettings(productId);
    await _settingsService.patchSettings(
      productId: productId,
      settings: settings.copyWith(isActive: isActive),
    );
  }
}
