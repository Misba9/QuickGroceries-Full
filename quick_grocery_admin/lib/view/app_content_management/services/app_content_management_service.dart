import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:quick_grocery_admin/model/app_content_models.dart';

/// Realtime admin editor for `app_content/main`.
class AppContentManagementService extends ChangeNotifier {
  AppContentManagementService() {
    _listen();
  }

  static const collection = 'app_content';
  static const documentId = 'main';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppContentModel content = AppContentModel.defaults;
  bool loading = true;
  bool saving = false;
  String? error;

  final trendingHeadingController = TextEditingController();
  final shopCategoryHeadingController = TextEditingController();
  final flashDealHeadingController = TextEditingController();
  final deliveryTimeTextController = TextEditingController();

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection(collection).doc(documentId);

  void _listen() {
    _doc.snapshots().listen(
      (snap) {
        loading = false;
        error = null;
        content = AppContentModel.fromMap(snap.data());
        _syncControllers();
        notifyListeners();
      },
      onError: (Object e) {
        loading = false;
        error = e.toString();
        notifyListeners();
      },
    );
  }

  void _syncControllers() {
    trendingHeadingController.text = content.trendingHeading;
    shopCategoryHeadingController.text = content.shopCategoryHeading;
    flashDealHeadingController.text = content.flashDealHeading;
    deliveryTimeTextController.text = content.deliveryTimeText;
  }

  void setShowTrendingCategories(bool value) {
    content = content.copyWith(showTrendingCategories: value);
    notifyListeners();
  }

  void setShowShopCategory(bool value) {
    content = content.copyWith(showShopCategory: value);
    notifyListeners();
  }

  void setShowFlashDeals(bool value) {
    content = content.copyWith(showFlashDeals: value);
    notifyListeners();
  }

  Future<void> ensureDocument() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      await _doc.set(AppContentModel.defaults.toWriteMap());
    }
  }

  Future<bool> save() async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      final next = content.copyWith(
        trendingHeading: trendingHeadingController.text,
        shopCategoryHeading: shopCategoryHeadingController.text,
        flashDealHeading: flashDealHeadingController.text,
        deliveryTimeText: deliveryTimeTextController.text,
      );
      await _doc.set(next.toWriteMap(), SetOptions(merge: true));
      content = next;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    trendingHeadingController.dispose();
    shopCategoryHeadingController.dispose();
    flashDealHeadingController.dispose();
    deliveryTimeTextController.dispose();
    super.dispose();
  }
}
