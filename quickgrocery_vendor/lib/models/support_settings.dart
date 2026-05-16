abstract final class _SupportDefaults {
  static const phone = '+919493803361';
  static const email = 'quickgrocery@gmail.com';
  static const whatsapp = '919493803361';
  static const message =
      'Support is available daily from 9:00 AM to 6:30 PM.';
}

/// Remote support contact — `support_settings/main`.
class SupportSettings {
  const SupportSettings({
    this.phone = _SupportDefaults.phone,
    this.email = _SupportDefaults.email,
    this.whatsapp = _SupportDefaults.whatsapp,
    this.message = _SupportDefaults.message,
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
