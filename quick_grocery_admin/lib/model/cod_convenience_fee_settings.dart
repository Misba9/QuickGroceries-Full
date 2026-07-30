import 'package:cloud_firestore/cloud_firestore.dart';

/// COD Convenience Fee config — `app_settings/cod_convenience_fee`.
class CodConvenienceFeeSettings {
  const CodConvenienceFeeSettings({
    required this.codFeeEnabled,
    required this.codFeeAmount,
    required this.minimumOrderAmount,
    required this.maximumOrderAmount,
    required this.freeCodAboveAmount,
    required this.feeDescription,
    this.applicableTo = 'all',
    this.applicableUsers = const [],
    this.applicableCities = const [],
    this.applicableVendors = const [],
    this.applicableCategories = const [],
    this.updatedBy = '',
    this.updatedByName = '',
    this.updatedAt,
  });

  final bool codFeeEnabled;
  final double codFeeAmount;
  final double minimumOrderAmount;
  final double maximumOrderAmount;
  final double freeCodAboveAmount;
  final String feeDescription;
  final String applicableTo;
  final List<String> applicableUsers;
  final List<String> applicableCities;
  final List<String> applicableVendors;
  final List<String> applicableCategories;
  final String updatedBy;
  final String updatedByName;
  final DateTime? updatedAt;

  static const defaults = CodConvenienceFeeSettings(
    codFeeEnabled: false,
    codFeeAmount: 10,
    minimumOrderAmount: 0,
    maximumOrderAmount: 0,
    freeCodAboveAmount: 0,
    feeDescription: 'Convenience Fee for Cash on Delivery',
  );

  factory CodConvenienceFeeSettings.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    return CodConvenienceFeeSettings(
      codFeeEnabled: raw['codFeeEnabled'] == true,
      codFeeAmount: _num(raw['codFeeAmount'], defaults.codFeeAmount),
      minimumOrderAmount: _num(raw['minimumOrderAmount'], 0),
      maximumOrderAmount: _num(raw['maximumOrderAmount'], 0),
      freeCodAboveAmount: _num(raw['freeCodAboveAmount'], 0),
      feeDescription: _str(
        raw['feeDescription'],
        defaults.feeDescription,
      ),
      applicableTo: _str(raw['applicableTo'], 'all'),
      applicableUsers: _list(raw['applicableUsers']),
      applicableCities: _list(raw['applicableCities']),
      applicableVendors: _list(raw['applicableVendors']),
      applicableCategories: _list(raw['applicableCategories']),
      updatedBy: _str(raw['updatedBy']),
      updatedByName: _str(raw['updatedByName']),
      updatedAt: _ts(raw['updatedAt']),
    );
  }

  Map<String, dynamic> toCallablePayload() => {
        'codFeeEnabled': codFeeEnabled,
        'codFeeAmount': codFeeAmount,
        'minimumOrderAmount': minimumOrderAmount,
        'maximumOrderAmount': maximumOrderAmount,
        'freeCodAboveAmount': freeCodAboveAmount,
        'feeDescription': feeDescription.trim(),
        'applicableTo': applicableTo,
        'applicableUsers': applicableUsers,
        'applicableCities': applicableCities,
        'applicableVendors': applicableVendors,
        'applicableCategories': applicableCategories,
      };

  static double _num(dynamic v, [double fb = 0]) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? fb;
  }

  static String _str(dynamic v, [String fb = '']) {
    if (v == null) return fb;
    final s = v.toString().trim();
    return s.isEmpty ? fb : s;
  }

  static List<String> _list(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
