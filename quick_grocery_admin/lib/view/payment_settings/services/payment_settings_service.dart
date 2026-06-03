import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:quick_grocery_admin/model/payment_settings_model.dart';

/// Admin editor for `app_settings/payment`.
class PaymentSettingsService extends ChangeNotifier {
  PaymentSettingsService() {
    _listen();
  }

  static const docPath = 'app_settings/payment';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PaymentSettingsModel settings = PaymentSettingsModel.defaults;
  bool loading = true;
  bool saving = false;
  String? error;

  final merchantNameController = TextEditingController();
  final merchantUpiController = TextEditingController();
  final merchantMobileController = TextEditingController();

  bool enableUpi = true;
  bool enableCod = true;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.doc(docPath);

  void _listen() {
    _doc.snapshots().listen(
      (snap) {
        loading = false;
        error = null;
        settings = PaymentSettingsModel.fromMap(snap.data());
        enableUpi = settings.enableUpiCollection;
        enableCod = settings.enableCodCollection;
        merchantNameController.text = settings.merchantName;
        merchantUpiController.text = settings.merchantUpiId;
        merchantMobileController.text = settings.merchantMobileNumber;
        notifyListeners();
      },
      onError: (Object e) {
        loading = false;
        error = e.toString();
        notifyListeners();
      },
    );
  }

  void setEnableUpi(bool v) {
    enableUpi = v;
    notifyListeners();
  }

  void setEnableCod(bool v) {
    enableCod = v;
    notifyListeners();
  }

  Future<void> ensureDocument() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      await _doc.set(PaymentSettingsModel.defaults.toWriteMap());
    }
  }

  Future<bool> save() async {
    final upi = merchantUpiController.text.trim();
    if (enableUpi && upi.isEmpty) {
      error = 'Merchant UPI ID is required when UPI collection is enabled.';
      notifyListeners();
      return false;
    }
    if (enableUpi && !upi.contains('@')) {
      error = 'Enter a valid UPI ID (e.g. quickgroceries@paytm).';
      notifyListeners();
      return false;
    }

    saving = true;
    error = null;
    notifyListeners();
    try {
      final next = PaymentSettingsModel(
        merchantName: merchantNameController.text.trim().isEmpty
            ? PaymentSettingsModel.defaults.merchantName
            : merchantNameController.text.trim(),
        merchantUpiId: upi,
        merchantMobileNumber: merchantMobileController.text.trim(),
        enableUpiCollection: enableUpi,
        enableCodCollection: enableCod,
      );
      await _doc.set(next.toWriteMap(), SetOptions(merge: true));
      saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      saving = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    merchantNameController.dispose();
    merchantUpiController.dispose();
    merchantMobileController.dispose();
    super.dispose();
  }
}
