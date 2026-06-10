import 'package:quickgrocery/view/support/models/support_settings_defaults.dart';

/// Live support contact from Firestore `support_settings/main`.
class SupportSettings {
  const SupportSettings({
    this.phone = SupportSettingsDefaults.phone,
    this.email = SupportSettingsDefaults.email,
    this.whatsapp = SupportSettingsDefaults.whatsapp,
    this.message = SupportSettingsDefaults.message,
  });

  static const defaults = SupportSettings();

  final String phone;
  final String email;
  final String whatsapp;
  final String message;

  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasEmail => email.trim().isNotEmpty;
  bool get hasWhatsapp => whatsapp.trim().isNotEmpty;
  bool get hasMessage => message.trim().isNotEmpty;
  String get whatsappLaunch => hasWhatsapp ? whatsapp : phone;

  factory SupportSettings.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    return SupportSettings(
      phone: _str(raw['phone'], SupportSettingsDefaults.phone),
      email: _str(raw['email'], SupportSettingsDefaults.email),
      whatsapp: _str(raw['whatsapp'], SupportSettingsDefaults.whatsapp),
      message: _str(raw['message'], SupportSettingsDefaults.message),
    );
  }

  static String _str(Object? value, String fallback) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return fallback;
    return s;
  }
}
