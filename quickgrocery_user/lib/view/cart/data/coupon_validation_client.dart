import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quickgrocery/core/firebase/callable_payload.dart';

import '../domain/cart_models.dart';

class CouponValidationClient {
  CouponValidationClient({FirebaseFunctions? functions})
    : _fn =
          functions ??
          FirebaseFunctions.instanceFor(
            app: Firebase.app(),
            region: 'us-central1',
          );

  final FirebaseFunctions _fn;

  Future<CouponValidationResult> validate({
    required String code,
    required double subtotal,
    required List<CartItem> items,
    String? phone,
    String? deviceId,
  }) async {
    try {
      final payload = sanitizeCallableData({
        'code': code.trim(),
        'subtotal': subtotal,
        'phone': phone ?? '',
        'deviceId': deviceId ?? '',
        'vendorIds': items
            .map((i) => i.vendorId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList(),
        'productIds': items.map((i) => i.productId).toList(),
        'categoryIds': items
            .map((i) => i.category)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList(),
      });
      debugCallableData('validateCouponCallable', payload);

      final res = await _fn
          .httpsCallable('validateCouponCallable')
          .call(payload);

      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['valid'] == true) {
        return CouponValidationResult.success(
          applied: AppliedCoupon(
            id: data['couponId']?.toString() ?? '',
            code: data['code']?.toString() ?? code,
            discountPercent: (data['discountPercent'] as num?)?.toInt() ?? 0,
            flatAmount: (data['flatAmount'] as num?)?.toDouble() ?? 0,
            maxDiscountAmount:
                (data['maxDiscountAmount'] as num?)?.toDouble() ?? 0,
            freeDelivery: data['freeDelivery'] == true,
            couponType: data['couponType']?.toString() ?? '',
            firstOrderOnly: data['firstOrderOnly'] == true,
            savingsPreview: (data['savingsPreview'] as num?)?.toDouble() ?? 0,
          ),
          message: data['message']?.toString() ?? 'Coupon applied successfully',
        );
      }

      return CouponValidationResult.failure(
        message: data['message']?.toString() ?? 'Coupon not valid',
        errorCode: data['errorCode']?.toString() ?? '',
      );
    } on FirebaseFunctionsException catch (e) {
      return CouponValidationResult.failure(
        message: e.message ?? 'Could not validate coupon',
        errorCode: e.code,
      );
    }
  }

  Future<void> redeem({
    required String code,
    required String orderId,
    required double subtotal,
    required double discountApplied,
    required List<CartItem> items,
    String? phone,
    String? deviceId,
  }) async {
    final payload = sanitizeCallableData({
      'code': code,
      'orderId': orderId,
      'subtotal': subtotal,
      'discountApplied': discountApplied,
      'phone': phone ?? '',
      'deviceId': deviceId ?? '',
      'vendorIds': items
          .map((i) => i.vendorId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(),
      'productIds': items.map((i) => i.productId).toList(),
      'categoryIds': items
          .map((i) => i.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList(),
    });
    debugCallableData('redeemCouponCallable', payload);
    await _fn.httpsCallable('redeemCouponCallable').call(payload);
  }
}

class CouponValidationResult {
  const CouponValidationResult._({
    required this.isValid,
    this.applied,
    this.message = '',
    this.errorCode = '',
  });

  final bool isValid;
  final AppliedCoupon? applied;
  final String message;
  final String errorCode;

  factory CouponValidationResult.success({
    required AppliedCoupon applied,
    required String message,
  }) => CouponValidationResult._(
    isValid: true,
    applied: applied,
    message: message,
  );

  factory CouponValidationResult.failure({
    required String message,
    required String errorCode,
  }) => CouponValidationResult._(
    isValid: false,
    message: message,
    errorCode: errorCode,
  );
}
