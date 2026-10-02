import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:quick_grocery_admin/model/cod_convenience_fee_settings.dart';

/// Admin editor for COD Convenience Fee (`app_settings/cod_convenience_fee`).
///
/// Reads via Firestore stream (realtime). Saves via
/// [updatePaymentSettingsCallable] so the backend writes the audit log and
/// mirrors knobs onto `settings/main` for instant checkout updates.
class CodConvenienceFeeAdminService extends ChangeNotifier {
  CodConvenienceFeeAdminService() {
    _listen();
  }

  static const docPath = 'app_settings/cod_convenience_fee';
  static const saveCallable = 'updatePaymentSettingsCallable';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _fn =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  CodConvenienceFeeSettings settings = CodConvenienceFeeSettings.defaults;
  bool loading = true;
  bool saving = false;
  String? error;

  bool enabled = false;
  final amountController = TextEditingController(text: '10');
  final minOrderController = TextEditingController(text: '0');
  final maxOrderController = TextEditingController(text: '0');
  final freeAboveController = TextEditingController(text: '0');
  final descriptionController = TextEditingController(
    text: CodConvenienceFeeSettings.defaults.feeDescription,
  );

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.doc(docPath);

  void _listen() {
    _doc.snapshots().listen(
      (snap) {
        loading = false;
        error = null;
        settings = CodConvenienceFeeSettings.fromMap(snap.data());
        _syncControllers(settings);
        notifyListeners();
      },
      onError: (Object e) {
        loading = false;
        error = e.toString();
        notifyListeners();
      },
    );
  }

  void _syncControllers(CodConvenienceFeeSettings s) {
    enabled = s.codFeeEnabled;
    amountController.text = _fmt(s.codFeeAmount);
    minOrderController.text = _fmt(s.minimumOrderAmount);
    maxOrderController.text = _fmt(s.maximumOrderAmount);
    freeAboveController.text = _fmt(s.freeCodAboveAmount);
    descriptionController.text = s.feeDescription;
  }

  void setEnabled(bool v) {
    enabled = v;
    notifyListeners();
  }

  Future<void> ensureDocument() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      await _doc.set({
        ...CodConvenienceFeeSettings.defaults.toCallablePayload(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> save() async {
    final amount = double.tryParse(amountController.text.trim());
    final minOrder = double.tryParse(minOrderController.text.trim()) ?? 0;
    final maxOrder = double.tryParse(maxOrderController.text.trim()) ?? 0;
    final freeAbove = double.tryParse(freeAboveController.text.trim()) ?? 0;
    final description = descriptionController.text.trim();

    if (enabled && (amount == null || amount < 0)) {
      error = 'Enter a valid COD fee amount (₹).';
      notifyListeners();
      return false;
    }
    if (maxOrder > 0 && minOrder > 0 && maxOrder < minOrder) {
      error = 'Maximum order amount must be ≥ minimum order amount.';
      notifyListeners();
      return false;
    }
    if (description.isEmpty) {
      error = 'Customer-facing description is required.';
      notifyListeners();
      return false;
    }

    saving = true;
    error = null;
    notifyListeners();
    try {
      final next = CodConvenienceFeeSettings(
        codFeeEnabled: enabled,
        codFeeAmount: amount ?? 0,
        minimumOrderAmount: minOrder < 0 ? 0 : minOrder,
        maximumOrderAmount: maxOrder < 0 ? 0 : maxOrder,
        freeCodAboveAmount: freeAbove < 0 ? 0 : freeAbove,
        feeDescription: description,
        applicableTo: 'all',
      );
      await _fn.httpsCallable(saveCallable).call({
        'codConvenienceFee': next.toCallablePayload(),
      });
      saving = false;
      notifyListeners();
      return true;
    } on FirebaseFunctionsException catch (e) {
      saving = false;
      error = e.message ?? e.code;
      notifyListeners();
      return false;
    } catch (e) {
      saving = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  @override
  void dispose() {
    amountController.dispose();
    minOrderController.dispose();
    maxOrderController.dispose();
    freeAboveController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
