import 'package:quickgrocery/view/support/models/support_settings_defaults.dart';

/// Remote support contact — `support_settings/main`.
class SupportSettingsConfig {
  const SupportSettingsConfig({
    this.phone = SupportSettingsDefaults.phone,
    this.email = SupportSettingsDefaults.email,
    this.whatsapp = SupportSettingsDefaults.whatsapp,
    this.message = SupportSettingsDefaults.message,
  });

  static const defaults = SupportSettingsConfig();

  final String phone;
  final String email;
  final String whatsapp;
  final String message;

  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasEmail => email.trim().isNotEmpty;
  bool get hasWhatsapp => whatsapp.trim().isNotEmpty;
  bool get hasMessage => message.trim().isNotEmpty;

  String get whatsappLaunch => hasWhatsapp ? whatsapp : phone;

  factory SupportSettingsConfig.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    return SupportSettingsConfig(
      phone: _str(raw['phone'], defaults.phone),
      email: _str(raw['email'], defaults.email),
      whatsapp: _str(raw['whatsapp'], defaults.whatsapp),
      message: _str(raw['message'], defaults.message),
    );
  }

  static String _str(Object? value, String fallback) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return fallback;
    return s;
  }
}
