import 'dart:math';

/// Straight-line distance and ETA helpers (road routing may differ).
class RouteMath {
  RouteMath._();

  static const earthRadiusKm = 6371.0;
  static const defaultSpeedKmh = 25.0;

  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static int estimateMinutes(double km, {double speedKmh = defaultSpeedKmh}) {
    if (km <= 0) return 0;
    return max(5, ((km / speedKmh) * 60).round() + 5);
  }

  static String formatDistance(double? km) {
    if (km == null || km <= 0) return '—';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static String formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '—';
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static double _deg2rad(double deg) => deg * pi / 180;
}
