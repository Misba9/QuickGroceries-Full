/// Lightweight latitude/longitude pair with validation helpers.
class GpsPoint {
  const GpsPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  static bool isValidCoord(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat == 0 && lng == 0) return false;
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    return true;
  }

  bool get isValid => GpsPoint.isValidCoord(latitude, longitude);

  static GpsPoint? tryParse(dynamic lat, dynamic lng) {
    final parsedLat = _asDouble(lat);
    final parsedLng = _asDouble(lng);
    if (!isValidCoord(parsedLat, parsedLng)) return null;
    return GpsPoint(parsedLat!, parsedLng!);
  }

  static GpsPoint? fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return null;
    return tryParse(
      map['lat'] ?? map['latitude'],
      map['lng'] ?? map['longitude'],
    );
  }

  Map<String, dynamic> toMap() => {
        'lat': latitude,
        'lng': longitude,
        'latitude': latitude,
        'longitude': longitude,
      };

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
