import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'order_models.dart';

/// Pure ETA calculator. No widgets, no Firebase — easy to unit-test.
///
/// Logic:
///  - Cancelled / delivered orders have no ETA.
///  - Without a rider position we use a flat estimate per status.
///  - With a rider position we estimate Haversine distance ÷ avg city speed.
class EtaCalculator {
  const EtaCalculator({this.cityKmh = 22, this.warmupSeconds = 60});

  final double cityKmh;
  final int warmupSeconds;

  Duration estimate(LiveOrder order, RiderLocation? rider) {
    if (order.isCancelled) return Duration.zero;
    if (order.isDelivered) return Duration.zero;

    switch (order.status) {
      case OrderStatus.pending:
        return const Duration(minutes: 18);
      case OrderStatus.vendorAccepted:
      case OrderStatus.accepted:
        return const Duration(minutes: 15);
      case OrderStatus.packing:
        return const Duration(minutes: 12);
      case OrderStatus.readyForPickup:
        return const Duration(minutes: 10);
      case OrderStatus.riderAssigned:
        return const Duration(minutes: 10);
      case OrderStatus.riderAccepted:
      case OrderStatus.reachedStore:
      case OrderStatus.headingToStore:
        return const Duration(minutes: 9);
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        if (rider?.position == null) {
          return Duration(
            minutes: order.status == OrderStatus.pickedUp ? 7 : 8,
          );
        }
        final km = _haversineKm(rider!.position!, order.dropLatLng);
        final hours = km / cityKmh;
        final secs = (hours * 3600).round() + warmupSeconds;
        return Duration(seconds: secs.clamp(60, 60 * 30));
      case OrderStatus.vendorRejected:
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return Duration.zero;
    }
  }

  static double _haversineKm(LatLng a, LatLng b) {
    const earth = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLng = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * earth * asin(sqrt(h));
  }

  static double _deg2rad(double d) => d * pi / 180.0;
}
