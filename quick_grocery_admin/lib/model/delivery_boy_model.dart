class DeliveryPersonModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String createdDate;
  final String email;
  final String password;
  final String address;
  final String image;
  final String licenceNumber;
  bool isActive;
  final bool isOnline;
  final double lat;
  final double lng;
  final int activeOrders;
  final String activeOrderId;

  DeliveryPersonModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.createdDate,
    required this.email,
    required this.password,
    required this.address,
    required this.image,
    required this.licenceNumber,
    required this.isActive,
    this.isOnline = false,
    this.lat = 0,
    this.lng = 0,
    this.activeOrders = 0,
    this.activeOrderId = '',
  });

  String get displayName => '$firstName $lastName'.trim().isEmpty
      ? 'Rider'
      : '$firstName $lastName'.trim();

  bool get hasLiveLocation => lat != 0 || lng != 0;

  factory DeliveryPersonModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return DeliveryPersonModel(
      id: id,
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      phone: data['phone'] ?? '',
      createdDate: data['createdDate'] ?? DateTime.now().toString(),
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      address: data['address'] ?? '',
      image: data['image'] ?? '',
      licenceNumber: data['licence_number'] ?? '',
      isActive: data['is_active'] ?? data['isActive'] != false,
      isOnline: data['isOnline'] == true || data['online_status'] == true,
      lat: (data['lat'] as num?)?.toDouble() ??
          (data['latitude'] as num?)?.toDouble() ??
          0,
      lng: (data['lng'] as num?)?.toDouble() ??
          (data['longitude'] as num?)?.toDouble() ??
          0,
      activeOrders: (data['activeOrders'] as num?)?.toInt() ??
          (data['active_orders'] as num?)?.toInt() ??
          0,
      activeOrderId: (data['activeOrderId'] ?? data['active_order_id'] ?? '')
          .toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "first_name": firstName,
      "last_name": lastName,
      "phone": phone,
      "createdDate": createdDate,
      "email": email,
      "password": password,
      "address": address,
      "image": image,
      "licence_number": licenceNumber,
      "is_active": isActive,
    };
  }
}
