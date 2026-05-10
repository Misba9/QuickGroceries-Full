class DeliveryZoneModel {
  final String id;
  final String zoneName;
  final String city;
  final List<String> pinCodes;
  final double deliveryCharge;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastEdited;
  final Map<String, double>?
  coordinates; // {latitude: double, longitude: double}

  DeliveryZoneModel({
    required this.id,
    required this.zoneName,
    required this.city,
    required this.pinCodes,
    required this.deliveryCharge,
    required this.isActive,
    this.createdAt,
    this.lastEdited,
    this.coordinates,
  });

  factory DeliveryZoneModel.fromFirestore(
    Map<String, dynamic> json,
    String id,
  ) {
    return DeliveryZoneModel(
      id: json['id'] ?? id,
      zoneName: json['zone_name'] ?? '',
      city: json['city'] ?? '',
      pinCodes: List<String>.from(json['pin_codes'] ?? []),
      deliveryCharge: (json['delivery_charge'] ?? 0.0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? (json['created_at'] as dynamic).toDate()
          : null,
      lastEdited: json['last_edited'] != null
          ? (json['last_edited'] as dynamic).toDate()
          : null,
      coordinates: json['coordinates'] != null
          ? Map<String, double>.from(json['coordinates'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_name': zoneName,
      'city': city,
      'pin_codes': pinCodes,
      'delivery_charge': deliveryCharge,
      'is_active': isActive,
      'created_at': createdAt,
      'last_edited': lastEdited,
      'coordinates': coordinates,
    };
  }
}
