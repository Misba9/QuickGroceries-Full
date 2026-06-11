import 'package:url_launcher/url_launcher.dart';

import 'geo_coordinates.dart';

/// Opens turn-by-turn navigation in the device's maps app using GPS coordinates.
class ExternalNavigation {
  ExternalNavigation._();

  static Future<bool> open({
    double? lat,
    double? lng,
    String? address,
    bool coordinatesOnly = true,
    double? originLat,
    double? originLng,
  }) async {
    final destination = GpsPoint.tryParse(lat, lng);
    final origin = GpsPoint.tryParse(originLat, originLng);

    Uri uri;
    if (destination != null) {
      final dest = '${destination.latitude},${destination.longitude}';
      if (origin != null) {
        final start = '${origin.latitude},${origin.longitude}';
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1'
          '&origin=$start&destination=$dest&travelmode=driving',
        );
      } else {
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1'
          '&destination=$dest&travelmode=driving',
        );
      }
    } else if (!coordinatesOnly &&
        address != null &&
        address.trim().isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${Uri.encodeComponent(address.trim())}&travelmode=driving',
      );
    } else {
      return false;
    }

    final candidates = <Uri>[uri];
    if (destination != null) {
      final dest = '${destination.latitude},${destination.longitude}';
      candidates.add(Uri.parse('geo:$dest?q=$dest'));
      candidates.add(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$dest'),
      );
    } else if (address != null && address.trim().isNotEmpty) {
      final encoded = Uri.encodeComponent(address.trim());
      candidates.add(Uri.parse('geo:0,0?q=$encoded'));
      candidates.add(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded'),
      );
    }

    for (final candidate in candidates) {
      try {
        final launched = await launchUrl(
          candidate,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (_) {
        /* try next scheme */
      }
    }
    return false;
  }
}
