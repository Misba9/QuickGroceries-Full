/// Validates support contact fields before admin save.
class SupportSettingsValidator {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String normalizePhone(String raw) {
    return raw.replaceAll(RegExp(r'[\s\-()]'), '');
  }

  static String? validatePhone(String? value, {required bool required}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return required ? 'Support phone number is required' : null;
    }
    final normalized = normalizePhone(trimmed);
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(normalized)) {
      return 'Enter a valid phone number (10–15 digits, optional + prefix)';
    }
    return null;
  }

  static String? validateEmail(String? value, {required bool required}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return required ? 'Support email is required' : null;
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validateWhatsapp(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final normalized = normalizePhone(trimmed);
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(normalized)) {
      return 'Enter a valid WhatsApp number';
    }
    return null;
  }

  /// Returns null when valid; otherwise first error message.
  static String? validateAll({
    required String phone,
    required String email,
    String? whatsapp,
  }) {
    return validatePhone(phone, required: true) ??
        validateEmail(email, required: true) ??
        validateWhatsapp(whatsapp);
  }
}
