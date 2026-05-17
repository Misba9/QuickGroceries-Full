import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';

class ComboOfferService {
  final _db = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  Uint8List? get imageBytes => _imageBytes;

  Future<void> pickImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery);
    if (f != null) _imageBytes = await f.readAsBytes();
  }

  Stream<List<Map<String, dynamic>>> watchVendorCombos(String vendorId) {
    return _db
        .collection('combo_offers')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<List<ProductModel>> vendorProducts(String vendorId) async {
    final snap = await _db
        .collection('products')
        .where('vendor_id', isEqualTo: vendorId)
        .get();
    return snap.docs
        .map((d) => ProductModel.fromFirestore(d.data(), d.id))
        .toList();
  }

  Future<void> save({
    required String vendorId,
    required String vendorName,
    String? editingId,
    required String title,
    required String subtitle,
    required List<ProductModel> products,
    required double comboPrice,
    required int stock,
    required bool isActive,
    String? existingImage,
  }) async {
    if (products.isEmpty) throw Exception('Select products');

    var image = existingImage ?? '';
    if (_imageBytes != null) {
      final ref = FirebaseStorage.instance.ref().child(
        'combo_offers/vendor_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putData(_imageBytes!);
      image = await ref.getDownloadURL();
    }

    final original = products.fold<double>(
      0,
      (s, p) => s + (double.tryParse(p.price) ?? 0),
    );
    final pct = original > 0
        ? (((original - comboPrice) / original) * 100).round()
        : 0;

    final payload = {
      'title': title,
      'subtitle': subtitle,
      'image': image,
      'productIds': products.map((p) => p.id).toList(),
      'products': products
          .map(
            (p) => {
              'productId': p.id,
              'name': p.name,
              'image': p.image,
              'quantity': 1,
              'unitPrice': double.tryParse(p.price) ?? 0,
            },
          )
          .toList(),
      'originalTotalPrice': original,
      'comboPrice': comboPrice,
      'discountPercent': pct,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'stock': stock,
      'isActive': isActive,
      'isTrending': false,
      'isFlashSale': false,
      'priority': 10,
      'createdBy': 'vendor',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (editingId != null) {
      await _db.collection('combo_offers').doc(editingId).update(payload);
    } else {
      final ref = await _db.collection('combo_offers').add({
        ...payload,
        'viewCount': 0,
        'orderCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await ref.update({'id': ref.id});
    }
    _imageBytes = null;
  }

  Future<void> toggle(String id, bool active) =>
      _db.collection('combo_offers').doc(id).update({'isActive': active});

  Future<void> delete(String id) =>
      _db.collection('combo_offers').doc(id).delete();
}
