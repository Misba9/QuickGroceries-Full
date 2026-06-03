import 'package:cloud_firestore/cloud_firestore.dart';

/// Rider payment collection config from `app_settings/payment`.
class PaymentCollectionSettings {
  const PaymentCollectionSettings({
    required this.merchantName,
    required this.merchantUpiId,
    required this.merchantMobileNumber,
    required this.enableUpiCollection,
    required this.enableCodCollection,
  });

  final String merchantName;
  final String merchantUpiId;
  final String merchantMobileNumber;
  final bool enableUpiCollection;
  final bool enableCodCollection;

  static const empty = PaymentCollectionSettings(
    merchantName: 'Quick Groceries',
    merchantUpiId: '',
    merchantMobileNumber: '',
    enableUpiCollection: true,
    enableCodCollection: true,
  );

  static const _docPath = 'app_settings/payment';
  static const _legacyPath = 'app_settings/delivery_collection';

  bool get canShowUpiQr =>
      enableUpiCollection && merchantUpiId.trim().isNotEmpty;

  /// Dynamic UPI deep link for QR.
  String buildUpiPayload({
    required double amount,
    required String orderId,
  }) {
    final vpa = merchantUpiId.trim();
    if (vpa.isEmpty) return '';
    final pn = Uri.encodeComponent(
      merchantName.trim().isEmpty ? 'Quick Groceries' : merchantName.trim(),
    );
    final am = amount.toStringAsFixed(2);
    final tn = Uri.encodeComponent(orderId);
    return 'upi://pay?pa=$vpa&pn=$pn&am=$am&cu=INR&tn=$tn';
  }

  static Stream<PaymentCollectionSettings> stream({
    FirebaseFirestore? firestore,
  }) {
    final db = firestore ?? FirebaseFirestore.instance;
    return db.doc(_docPath).snapshots().asyncMap((snap) async {
      var settings = _fromMap(snap.data());
      if (!settings.canShowUpiQr) {
        final legacy = await db.doc(_legacyPath).get();
        final legacyUpi = (legacy.data()?['merchantUpiId'] ??
                legacy.data()?['merchant_upi_id'] ??
                '')
            .toString()
            .trim();
        if (legacyUpi.isNotEmpty) {
          settings = PaymentCollectionSettings(
            merchantName: settings.merchantName,
            merchantUpiId: legacyUpi,
            merchantMobileNumber: settings.merchantMobileNumber,
            enableUpiCollection: settings.enableUpiCollection,
            enableCodCollection: settings.enableCodCollection,
          );
        }
      }
      return settings;
    });
  }

  static PaymentCollectionSettings _fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return empty;
    return PaymentCollectionSettings(
      merchantName: _str(
        raw['merchantName'] ?? raw['merchant_name'],
        empty.merchantName,
      ),
      merchantUpiId: _str(raw['merchantUpiId'] ?? raw['merchant_upi_id']),
      merchantMobileNumber:
          _str(raw['merchantMobileNumber'] ?? raw['merchant_mobile_number']),
      enableUpiCollection: raw['enableUpiCollection'] != false &&
          raw['enable_upi_collection'] != false,
      enableCodCollection: raw['enableCodCollection'] != false &&
          raw['enable_cod_collection'] != false,
    );
  }

  static String _str(dynamic v, [String fb = '']) {
    if (v == null) return fb;
    final s = v.toString().trim();
    return s.isEmpty ? fb : s;
  }
}
