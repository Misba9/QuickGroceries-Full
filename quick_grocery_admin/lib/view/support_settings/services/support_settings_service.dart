import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:quick_grocery_admin/model/support_settings_model.dart';
import 'package:quick_grocery_admin/utils/support_settings_validator.dart';

/// Realtime admin editor for `support_settings/main`.
class SupportSettingsService extends ChangeNotifier {
  SupportSettingsService() {
    _listen();
  }

  static const collection = 'support_settings';
  static const documentId = 'main';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SupportSettingsModel settings = SupportSettingsModel.defaults;
  bool loading = true;
  bool saving = false;
  String? error;
  String? validationError;

  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final whatsappController = TextEditingController();
  final messageController = TextEditingController();

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection(collection).doc(documentId);

  void _listen() {
    _doc.snapshots().listen(
      (snap) {
        loading = false;
        error = null;
        settings = SupportSettingsModel.fromMap(snap.data());
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
    phoneController.text = settings.phone;
    emailController.text = settings.email;
    whatsappController.text = settings.whatsapp;
    messageController.text = settings.message;
  }

  Future<void> ensureDocument() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      await _doc.set(SupportSettingsModel.defaults.toWriteMap());
    }
  }

  Future<bool> save() async {
    validationError = SupportSettingsValidator.validateAll(
      phone: phoneController.text,
      email: emailController.text,
      whatsapp: whatsappController.text,
    );
    if (validationError != null) {
      notifyListeners();
      return false;
    }

    saving = true;
    error = null;
    notifyListeners();
    try {
      final next = SupportSettingsModel(
        phone: SupportSettingsValidator.normalizePhone(phoneController.text),
        email: emailController.text.trim(),
        whatsapp: whatsappController.text.trim().isEmpty
            ? ''
            : SupportSettingsValidator.normalizePhone(whatsappController.text),
        message: messageController.text.trim(),
      );
      await _doc.set(next.toWriteMap(), SetOptions(merge: true));
      settings = next;
      validationError = null;
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
    phoneController.dispose();
    emailController.dispose();
    whatsappController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
