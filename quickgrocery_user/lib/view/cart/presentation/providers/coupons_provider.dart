import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/coupon_service.dart';
import 'cart_notifier.dart';

final couponServiceProvider = Provider<CouponService>((ref) {
  return CouponService(ref.watch(firebaseFirestoreProvider));
});

/// Realtime list of active coupons available to the user.
final couponsStreamProvider =
    StreamProvider.autoDispose<List<CouponEntry>>((ref) {
  return ref.watch(couponServiceProvider).watchActive();
});
