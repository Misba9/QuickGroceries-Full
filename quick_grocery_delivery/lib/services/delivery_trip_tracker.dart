import 'package:quick_grocery_delivery/utils/delivery_route_utils.dart';

/// Accumulates GPS distance during the customer delivery leg (`out_for_delivery`).
class DeliveryTripTracker {
  DeliveryTripTracker._();

  static final DeliveryTripTracker instance = DeliveryTripTracker._();

  String? _orderId;
  DateTime? _startedAt;
  double _distanceKm = 0;
  double? _lastLat;
  double? _lastLng;

  String? get orderId => _orderId;
  bool get isTracking => _orderId != null;

  void start(String orderId) {
    _orderId = orderId;
    _startedAt = DateTime.now();
    _distanceKm = 0;
    _lastLat = null;
    _lastLng = null;
  }

  void onPosition(double lat, double lng) {
    if (_orderId == null) return;
    if (_lastLat != null && _lastLng != null) {
      final delta = DeliveryRouteUtils.haversineKm(
        _lastLat!,
        _lastLng!,
        lat,
        lng,
      );
      if (delta > 0.01 && delta < 2) {
        _distanceKm += delta;
      }
    }
    _lastLat = lat;
    _lastLng = lng;
  }

  ({double distanceKm, int durationSec}) metrics() {
    final started = _startedAt;
    final durationSec =
        started == null ? 0 : DateTime.now().difference(started).inSeconds;
    return (distanceKm: _distanceKm, durationSec: durationSec);
  }

  void stop() {
    _orderId = null;
    _startedAt = null;
    _distanceKm = 0;
    _lastLat = null;
    _lastLng = null;
  }
}
