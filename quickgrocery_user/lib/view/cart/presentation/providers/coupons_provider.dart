import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/coupon_service.dart';
import '../../data/coupon_validation_client.dart';
import 'cart_notifier.dart';

final couponServiceProvider = Provider<CouponService>((ref) {
  return CouponService(ref.watch(firebaseFirestoreProvider));
});

final couponValidationClientProvider = Provider<CouponValidationClient>((ref) {
  return CouponValidationClient();
});

/// Realtime list of active coupons available to the user.
final couponsStreamProvider =
    StreamProvider.autoDispose<List<CouponEntry>>((ref) {
  return ref.watch(couponServiceProvider).watchActive();
});
