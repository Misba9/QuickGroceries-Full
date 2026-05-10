import 'package:cloud_firestore/cloud_firestore.dart';

/// Live rider telemetry shared between the Delivery App (writer) and the
/// User App (reader). Written under `delivery_boys/{deliveryBoyId}` so it
/// piggybacks on the existing rider profile doc — no new collection
/// required for first ship.
///
/// **Schema (writer responsibility — Delivery App):**
/// ```json
/// {
///   "name": "Asha",
///   "phone": "+91…",
///   "image": "…",
///   "lat": 12.97,
///   "lng": 77.59,
///   "heading": 92.3,        // degrees, 0=N, 90=E
///   "speed": 24.5,          // km/h
///   "isOnline": true,
///   "updatedAt": Timestamp
/// }
/// ```
class RiderLiveLocation {
  const RiderLiveLocation({
    required this.id,
    required this.name,
    required this.phone,
    required this.image,
    required this.lat,
    required this.lng,
    required this.heading,
    required this.speed,
    required this.isOnline,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String image;
  final double lat;
  final double lng;
  final double heading;
  final double speed;
  final bool isOnline;
  final DateTime? updatedAt;

  /// True once we have a valid GPS fix.
  bool get hasFix => lat != 0 || lng != 0;

  factory RiderLiveLocation.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return RiderLiveLocation(
      id: id,
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      image: data['image']?.toString() ?? '',
      lat: _asDouble(data['lat']),
      lng: _asDouble(data['lng']),
      heading: _asDouble(data['heading']),
      speed: _asDouble(data['speed']),
      isOnline: data['isOnline'] as bool? ?? true,
      updatedAt: _asDateTime(data['updatedAt']),
    );
  }

  RiderLiveLocation copyWith({
    String? id,
    String? name,
    String? phone,
    String? image,
    double? lat,
    double? lng,
    double? heading,
    double? speed,
    bool? isOnline,
    DateTime? updatedAt,
  }) {
    return RiderLiveLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      isOnline: isOnline ?? this.isOnline,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

double _asDouble(dynamic v, {double fallback = 0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

DateTime? _asDateTime(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return DateTime.tryParse(v.toString());
}
