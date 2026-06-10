import 'dart:convert';

import 'package:http/http.dart' as http;

import 'geo_coordinates.dart';

/// Free geocoding via OpenStreetMap Nominatim (rate-limited; cache results).
class GeocodeService {
  GeocodeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, GpsPoint> _cache = {};

  Future<GpsPoint?> geocodeAddress(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final cached = _cache[normalized];
    if (cached != null) return cached;

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query.trim(),
        'format': 'json',
        'limit': '1',
      },
    );

    final response = await _client.get(
      uri,
      headers: const {'User-Agent': 'QuickGroceries/1.0'},
    );
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body);
    if (body is! List || body.isEmpty) return null;
    final first = body.first;
    if (first is! Map) return null;

    final coords = GpsPoint.tryParse(first['lat'], first['lon']);
    if (coords != null) {
      _cache[normalized] = coords;
    }
    return coords;
  }

  void dispose() => _client.close();
}
