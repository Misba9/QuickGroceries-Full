class AddressModel {
  final String id;
  final String name;
  final String mobile;
  final String address;
  final String area;
  final String type;
  final String createdAt;
  final String lastEdited;
  final String userId;
  final double? latitude;
  final double? longitude;
  final String houseNumber;
  final String buildingName;
  final String street;
  final String landmark;
  final String city;
  final String state;
  final String country;
  final String postalCode;

  AddressModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.area,
    required this.type,
    required this.createdAt,
    required this.lastEdited,
    required this.userId,
    this.latitude,
    this.longitude,
    this.houseNumber = '',
    this.buildingName = '',
    this.street = '',
    this.landmark = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.postalCode = '',
  });

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude != 0 &&
      longitude != 0;

  /// Checkout / address-book title — type only when no contact name saved.
  String get displayTitle {
    final n = name.trim();
    if (n.isNotEmpty) return '$type · $n';
    return type;
  }

  /// Mobile on the address, or [fallbackE164] (e.g. Firebase Auth phone).
  String resolvedMobile(String fallbackE164) {
    final m = mobile.trim();
    if (m.isNotEmpty) return m;
    return AddressModel.localMobileDigits(fallbackE164);
  }

  /// Last 10 digits for form display / validation.
  static String localMobileDigits(String? e164OrRaw) {
    final digits = (e164OrRaw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return '';
  }

  /// True when name, house/building, area, and a 10-digit mobile are present.
  bool isCompleteForDelivery(String? authPhoneE164) {
    if (name.trim().isEmpty) return false;
    if (address.trim().isEmpty) return false;
    if (area.trim().isEmpty) return false;
    final digits =
        resolvedMobile(authPhoneE164 ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  String get formattedAddress {
    final parts = <String>[
      if (houseNumber.isNotEmpty) houseNumber,
      if (buildingName.isNotEmpty) buildingName,
      if (street.isNotEmpty) street,
      if (area.isNotEmpty) area,
      if (landmark.isNotEmpty) 'Near $landmark',
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (postalCode.isNotEmpty) postalCode,
      if (country.isNotEmpty) country,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return address;
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        mobile: json['mobile']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        area: json['area']?.toString() ?? '',
        type: json['type']?.toString() ?? 'HOME',
        createdAt: json['createdAt']?.toString() ?? '',
        lastEdited: json['lastEdited']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        latitude: _optionalDouble(json['lat'] ?? json['latitude']),
        longitude: _optionalDouble(json['lng'] ?? json['longitude']),
        houseNumber: json['houseNumber']?.toString() ?? '',
        buildingName: json['buildingName']?.toString() ?? '',
        street: json['street']?.toString() ?? '',
        landmark: json['landmark']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        country: json['country']?.toString() ?? '',
        postalCode: json['postalCode']?.toString() ?? '',
      );

  factory AddressModel.fromFirestore(Map<String, dynamic> json, String id) {
    return AddressModel(
      id: (json['id'] ?? id).toString(),
      name: (json['name'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      area: (json['area'] ?? '').toString(),
      type: (json['type'] ?? 'HOME').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      lastEdited: (json['lastEdited'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      latitude: _optionalDouble(json['lat'] ?? json['latitude']),
      longitude: _optionalDouble(json['lng'] ?? json['longitude']),
      houseNumber: (json['houseNumber'] ?? '').toString(),
      buildingName: (json['buildingName'] ?? '').toString(),
      street: (json['street'] ?? '').toString(),
      landmark: (json['landmark'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      postalCode: (json['postalCode'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toFirestorePayload() => {
        'name': name,
        'mobile': mobile,
        'address': address,
        'area': area,
        'type': type,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (houseNumber.isNotEmpty) 'houseNumber': houseNumber,
        if (buildingName.isNotEmpty) 'buildingName': buildingName,
        if (street.isNotEmpty) 'street': street,
        if (landmark.isNotEmpty) 'landmark': landmark,
        if (city.isNotEmpty) 'city': city,
        if (state.isNotEmpty) 'state': state,
        if (country.isNotEmpty) 'country': country,
        if (postalCode.isNotEmpty) 'postalCode': postalCode,
      };

  Map<String, dynamic> toSnapshotMap() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'address': address,
        'area': area,
        'type': type,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (houseNumber.isNotEmpty) 'houseNumber': houseNumber,
        if (buildingName.isNotEmpty) 'buildingName': buildingName,
        if (street.isNotEmpty) 'street': street,
        if (landmark.isNotEmpty) 'landmark': landmark,
        if (city.isNotEmpty) 'city': city,
        if (state.isNotEmpty) 'state': state,
        if (country.isNotEmpty) 'country': country,
        if (postalCode.isNotEmpty) 'postalCode': postalCode,
      };

  AddressModel copyWith({
    double? latitude,
    double? longitude,
  }) =>
      AddressModel(
        id: id,
        name: name,
        mobile: mobile,
        address: address,
        area: area,
        type: type,
        createdAt: createdAt,
        lastEdited: lastEdited,
        userId: userId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        houseNumber: houseNumber,
        buildingName: buildingName,
        street: street,
        landmark: landmark,
        city: city,
        state: state,
        country: country,
        postalCode: postalCode,
      );

  static double? _optionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
