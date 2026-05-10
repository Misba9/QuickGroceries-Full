class DeliveryZoneModel {
  final String id;
  final String zoneName;
  final String city;
  final List<String> pinCodes;
  final double deliveryCharge;
  final bool isActive;
  final String createdAt;
  final String lastEdited;
  final Map<String, double>?
  coordinates; // For map-based zones (latitude, longitude)

  DeliveryZoneModel({
    required this.id,
    required this.zoneName,
    required this.city,
    required this.pinCodes,
    required this.deliveryCharge,
    required this.isActive,
    required this.createdAt,
    required this.lastEdited,
    this.coordinates,
  });

  factory DeliveryZoneModel.fromJson(Map<String, dynamic> json) =>
      DeliveryZoneModel(
        id: json["id"],
        zoneName: json["zone_name"] ?? json["zoneName"],
        city: json["city"],
        pinCodes: List<String>.from(
          json["pin_codes"] ?? json["pinCodes"] ?? [],
        ),
        deliveryCharge: (json["delivery_charge"] ?? json["deliveryCharge"] ?? 0)
            .toDouble(),
        isActive: json["is_active"] ?? json["isActive"] ?? true,
        createdAt: json["created_at"] ?? json["createdAt"] ?? "",
        lastEdited: json["last_edited"] ?? json["lastEdited"] ?? "",
        coordinates: json["coordinates"] != null
            ? Map<String, double>.from(json["coordinates"])
            : null,
      );

  factory DeliveryZoneModel.fromFirestore(
    Map<String, dynamic> json,
    String id,
  ) {
    return DeliveryZoneModel(
      id: json["id"] ?? id,
      zoneName: json["zone_name"] ?? json["zoneName"] ?? "",
      city: json["city"] ?? "",
      pinCodes: List<String>.from(json["pin_codes"] ?? json["pinCodes"] ?? []),
      deliveryCharge: (json["delivery_charge"] ?? json["deliveryCharge"] ?? 0)
          .toDouble(),
      isActive: json["is_active"] ?? json["isActive"] ?? true,
      createdAt:
          json["created_at"]?.toString() ?? json["createdAt"]?.toString() ?? "",
      lastEdited:
          json["last_edited"]?.toString() ??
          json["lastEdited"]?.toString() ??
          "",
      coordinates: json["coordinates"] != null
          ? Map<String, double>.from(json["coordinates"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "zone_name": zoneName,
    "city": city,
    "pin_codes": pinCodes,
    "delivery_charge": deliveryCharge,
    "is_active": isActive,
    "created_at": createdAt,
    "last_edited": lastEdited,
    if (coordinates != null) "coordinates": coordinates,
  };
}
