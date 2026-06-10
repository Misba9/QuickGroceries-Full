import 'dart:convert';

import 'package:http/http.dart' as http;

import 'geo_coordinates.dart';
import 'route_math.dart';

/// Fetches a driving route polyline from the public OSRM router.
class OsrmRouteService {
  OsrmRouteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, OsrmRouteResult> _cache = {};

  Future<OsrmRouteResult?> route({
    required GpsPoint from,
    required GpsPoint to,
  }) async {
    final key =
        '${from.latitude},${from.longitude}|${to.latitude},${to.longitude}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final path =
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$path'
      '?overview=full&geometries=geojson&steps=false',
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['code'] != 'Ok') return null;
    final routes = body['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) return null;

    final points = <GpsPoint>[];
    for (final point in coordinates) {
      if (point is List && point.length >= 2) {
        final coords = GpsPoint.tryParse(point[1], point[0]);
        if (coords != null) points.add(coords);
      }
    }
    if (points.isEmpty) return null;

    final distanceKm = ((route['distance'] as num?)?.toDouble() ?? 0) / 1000;
    final durationSec = (route['duration'] as num?)?.toDouble() ?? 0;
    final etaMinutes = durationSec > 0
        ? (durationSec / 60).round()
        : RouteMath.estimateMinutes(distanceKm);

    final result = OsrmRouteResult(
      points: points,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
    );
    _cache[key] = result;
    return result;
  }

  void dispose() => _client.close();
}

class OsrmRouteResult {
  const OsrmRouteResult({
    required this.points,
    required this.distanceKm,
    required this.etaMinutes,
  });

  final List<GpsPoint> points;
  final double distanceKm;
  final int etaMinutes;
}
