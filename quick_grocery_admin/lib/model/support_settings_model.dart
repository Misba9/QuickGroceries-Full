import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quick_grocery_admin/model/support_settings_defaults.dart';

/// Firestore `support_settings/main` — shared across all customer apps.
class SupportSettingsModel {
  const SupportSettingsModel({
    this.phone = SupportSettingsDefaults.phone,
    this.email = SupportSettingsDefaults.email,
    this.whatsapp = SupportSettingsDefaults.whatsapp,
    this.message = SupportSettingsDefaults.message,
    this.updatedAt,
  });

  static const defaults = SupportSettingsModel();

  final String phone;
  final String email;
  final String whatsapp;
  final String message;
  final DateTime? updatedAt;

  factory SupportSettingsModel.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    DateTime? updated;
    final ts = raw['updated_at'];
    if (ts is Timestamp) updated = ts.toDate();

    return SupportSettingsModel(
      phone: _str(raw['phone'], defaults.phone),
      email: _str(raw['email'], defaults.email),
      whatsapp: _str(raw['whatsapp'], defaults.whatsapp),
      message: _str(raw['message'], defaults.message),
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'phone': phone.trim(),
        'email': email.trim(),
        'whatsapp': whatsapp.trim(),
        'message': message.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      };

  static String _str(Object? value, String fallback) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return fallback;
    return s;
  }
}
