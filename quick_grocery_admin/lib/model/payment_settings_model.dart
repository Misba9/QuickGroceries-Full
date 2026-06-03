import 'package:cloud_firestore/cloud_firestore.dart';

/// Rider COD/UPI collection config — `app_settings/payment`.
class PaymentSettingsModel {
  const PaymentSettingsModel({
    required this.merchantName,
    required this.merchantUpiId,
    required this.merchantMobileNumber,
    required this.enableUpiCollection,
    required this.enableCodCollection,
    this.updatedAt,
  });

  final String merchantName;
  final String merchantUpiId;
  final String merchantMobileNumber;
  final bool enableUpiCollection;
  final bool enableCodCollection;
  final DateTime? updatedAt;

  static const defaults = PaymentSettingsModel(
    merchantName: 'Quick Groceries',
    merchantUpiId: '',
    merchantMobileNumber: '',
    enableUpiCollection: true,
    enableCodCollection: true,
  );

  factory PaymentSettingsModel.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    return PaymentSettingsModel(
      merchantName: _str(raw['merchantName'] ?? raw['merchant_name'], defaults.merchantName),
      merchantUpiId: _str(raw['merchantUpiId'] ?? raw['merchant_upi_id']),
      merchantMobileNumber:
          _str(raw['merchantMobileNumber'] ?? raw['merchant_mobile_number']),
      enableUpiCollection: raw['enableUpiCollection'] != false &&
          raw['enable_upi_collection'] != false,
      enableCodCollection: raw['enableCodCollection'] != false &&
          raw['enable_cod_collection'] != false,
      updatedAt: _ts(raw['updatedAt'] ?? raw['updated_at']),
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'merchantName': merchantName.trim(),
        'merchantUpiId': merchantUpiId.trim(),
        'merchantMobileNumber': merchantMobileNumber.trim(),
        'enableUpiCollection': enableUpiCollection,
        'enableCodCollection': enableCodCollection,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  bool get hasValidUpi =>
      enableUpiCollection && merchantUpiId.trim().isNotEmpty;

  static String _str(dynamic v, [String fb = '']) {
    if (v == null) return fb;
    final s = v.toString().trim();
    return s.isEmpty ? fb : s;
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
