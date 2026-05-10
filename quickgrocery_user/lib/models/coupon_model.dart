class CouponModel {
  final String code;
  final int discount;

  CouponModel({required this.code, required this.discount});

  factory CouponModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CouponModel(
      code: data['code'],
      discount: data['discount'],
    );
  }
}
