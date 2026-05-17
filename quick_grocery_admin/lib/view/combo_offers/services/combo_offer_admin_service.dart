import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_grocery_admin/model/combo_offer_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';

/// Admin CRUD for `combo_offers/`.
class ComboOfferAdminService {
  final _db = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  static const _col = 'combo_offers';

  Uint8List? _imageBytes;
  Uint8List? get imageBytes => _imageBytes;

  Future<void> pickImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery);
    if (f != null) _imageBytes = await f.readAsBytes();
  }

  void clearImage() => _imageBytes = null;

  Stream<List<ComboOfferModel>> watchCombos() {
    return _db.collection(_col).snapshots().map((s) {
      final list = s.docs
          .map((d) => ComboOfferModel.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.priority.compareTo(a.priority));
      return list;
    });
  }

  Future<List<ProductModel>> fetchProducts() async {
    final snap = await _db.collection('products').get();
    return snap.docs
        .map((d) => ProductModel.fromFirestore(d.data(), d.id))
        .toList();
  }

  Future<List<VendorModel>> fetchVendors() async {
    final snap = await _db.collection('vendors').get();
    return snap.docs
        .map((d) => VendorModel.fromFirestore(d.data(), d.id))
        .toList();
  }

  Future<String> _uploadImage(Uint8List bytes) async {
    final ref = FirebaseStorage.instance.ref().child(
      'combo_offers/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  Future<void> saveCombo({
    String? editingId,
    required String title,
    required String subtitle,
    required List<ProductModel> selectedProducts,
    required double comboPrice,
    required String vendorId,
    required String vendorName,
    required int stock,
    required bool isActive,
    required bool isFlashSale,
    required bool isTrending,
    required int priority,
    DateTime? startsAt,
    DateTime? endsAt,
    String? existingImageUrl,
  }) async {
    if (selectedProducts.isEmpty) {
      throw Exception('Select at least one product');
    }

    var imageUrl = existingImageUrl ?? '';
    if (_imageBytes != null) {
      imageUrl = await _uploadImage(_imageBytes!);
    }

    final original = selectedProducts.fold<double>(
      0,
      (s, p) => s + (double.tryParse(p.price) ?? 0),
    );
    final pct = original > 0
        ? (((original - comboPrice) / original) * 100).round()
        : 0;

    final lines = selectedProducts
        .map(
          (p) => ComboProductLine(
            productId: p.id,
            name: p.name,
            image: p.image,
            unitPrice: double.tryParse(p.price) ?? 0,
          ).toMap(),
        )
        .toList();

    final payload = <String, dynamic>{
      'title': title,
      'subtitle': subtitle,
      'image': imageUrl,
      'productIds': selectedProducts.map((p) => p.id).toList(),
      'products': lines,
      'originalTotalPrice': original,
      'comboPrice': comboPrice,
      'discountPercent': pct,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'stock': stock,
      'isActive': isActive,
      'isFlashSale': isFlashSale,
      'isTrending': isTrending,
      'priority': priority,
      'createdBy': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (startsAt != null) {
      payload['startsAt'] = Timestamp.fromDate(startsAt);
    }
    if (endsAt != null) {
      payload['endsAt'] = Timestamp.fromDate(endsAt);
    }

    if (editingId != null && editingId.isNotEmpty) {
      await _db.collection(_col).doc(editingId).update(payload);
    } else {
      final ref = await _db.collection(_col).add({
        ...payload,
        'viewCount': 0,
        'orderCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await ref.update({'id': ref.id});
    }
    _imageBytes = null;
  }

  Future<void> deleteCombo(String id) => _db.collection(_col).doc(id).delete();

  Future<void> toggleActive(String id, bool active) =>
      _db.collection(_col).doc(id).update({'isActive': active});
}
