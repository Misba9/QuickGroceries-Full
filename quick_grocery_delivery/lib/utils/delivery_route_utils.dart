import 'dart:math';

import 'package:url_launcher/url_launcher.dart';

class DeliveryRouteUtils {
  DeliveryRouteUtils._();

  static const _earthRadiusKm = 6371.0;
  static const _defaultSpeedKmh = 25.0;

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
    return _earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static int estimateMinutes(double km, {double speedKmh = _defaultSpeedKmh}) {
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

  static Future<bool> openNavigation({
    double? lat,
    double? lng,
    String? address,
  }) async {
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
      );
    } else if (address != null && address.trim().isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address.trim())}&travelmode=driving',
      );
    } else {
      return false;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  static double _deg2rad(double deg) => deg * pi / 180;
}
