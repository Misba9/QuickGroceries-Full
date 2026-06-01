class OrderModel {
  String id;
  List<ProductItem> products;
  String createdDate;
  String customerName;
  String phone;
  String address;
  bool isPaid;
  String orderStatus;
  String modernStatus;
  String deliveryBoyId;
  bool isDelivered;
  bool isCancelled;
  String deliveryType;
  bool isRated;
  double rating;
  String confimedTime;
  String driverGoShopTime;
  String orderPickedTime;
  String onTheWayTime;
  String orderDeliveredTime;
  int deliveryCharge;
  String uuid;
  double? latitude;
  double? longitude;
  String vendorId;
  String vendorName;
  String vendorPhone;
  String pickupAddress;
  double? pickupLat;
  double? pickupLng;
  double? routeDistanceKm;
  int? expectedDeliveryMinutes;
  int? deliveryDurationSec;
  double? distanceTravelledKm;
  final Map<String, dynamic>? deliverySlotRaw;
  final Map<String, dynamic>? deliveryInstructionsRaw;
  final Map<String, dynamic>? bill;

  OrderModel({
    required this.id,
    required this.products,
    required this.createdDate,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.isPaid,
    required this.orderStatus,
    this.modernStatus = '',
    required this.deliveryBoyId,
    required this.isDelivered,
    required this.isCancelled,
    required this.deliveryType,
    required this.isRated,
    required this.rating,
    required this.confimedTime,
    required this.driverGoShopTime,
    required this.orderPickedTime,
    required this.onTheWayTime,
    required this.orderDeliveredTime,
    required this.deliveryCharge,
    required this.uuid,
    this.latitude,
    this.longitude,
    this.vendorId = '',
    this.vendorName = '',
    this.vendorPhone = '',
    this.pickupAddress = '',
    this.pickupLat,
    this.pickupLng,
    this.routeDistanceKm,
    this.expectedDeliveryMinutes,
    this.deliveryDurationSec,
    this.distanceTravelledKm,
    this.deliverySlotRaw,
    this.deliveryInstructionsRaw,
    this.bill,
  });

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    List<ProductItem> parsedProducts = [];
    if (data['products'] != null) {
      parsedProducts = List<Map<String, dynamic>>.from(
        data['products'],
      ).map((e) => ProductItem.fromMap(e)).toList();
    }

    return OrderModel(
      id: id,
      products: parsedProducts,
      createdDate: data['created_date'] ?? '',
      customerName: data['customer_name'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      isPaid: data['isPaid'] ?? false,
      orderStatus: data['order_status'] ?? '',
      modernStatus: data['status']?.toString() ?? '',
      deliveryBoyId: data['deliveryBoyId'] ?? data['delivery_boy_id'] ?? '',
      isDelivered: data['isDelivered'] ?? false,
      isCancelled: data['isCancelled'] ?? false,
      deliveryType: data['delivery_type'] ?? '',
      isRated: data['is_rated'] ?? false,
      rating: (data['star'] ?? 0).toDouble(),
      confimedTime: data['confrimTime'] ?? '',
      driverGoShopTime: data['driverShop'] ?? '',
      orderPickedTime: data['pickedTime'] ?? '',
      onTheWayTime: data['onTheWayTime'] ?? '',
      orderDeliveredTime: data['deliveredTime'] ?? '',
      deliveryCharge: (data['delivery_charge'] ?? data['deliveryCharge'] ?? 0) is int
          ? (data['delivery_charge'] ?? data['deliveryCharge'] ?? 0) as int
          : ((data['delivery_charge'] ?? data['deliveryCharge'] ?? 0) as num).toInt(),
      uuid: data['uuid'] ?? '',
      latitude: data['lat'] != null ? (data['lat'] as num).toDouble() : null,
      longitude: data['lng'] != null ? (data['lng'] as num).toDouble() : null,
      vendorId: (data['vendorId'] ?? data['vendor_id'] ?? '').toString(),
      vendorName: (data['vendorName'] ?? data['vendor_name'] ?? '').toString(),
      vendorPhone: (data['vendorPhone'] ?? data['vendor_phone'] ?? '').toString(),
      pickupAddress:
          (data['pickupAddress'] ?? data['pickup_address'] ?? '').toString(),
      pickupLat: _optionalDouble(data['pickupLat'] ?? data['pickup_lat']),
      pickupLng: _optionalDouble(data['pickupLng'] ?? data['pickup_lng']),
      routeDistanceKm:
          _optionalDouble(data['routeDistanceKm'] ?? data['route_distance_km']),
      expectedDeliveryMinutes: _optionalInt(
        data['expectedDeliveryMinutes'] ?? data['expected_delivery_minutes'],
      ),
      deliveryDurationSec: _optionalInt(
        data['deliveryDurationSec'] ?? data['delivery_duration_seconds'],
      ),
      distanceTravelledKm: _optionalDouble(
        data['distanceTravelledKm'] ?? data['distance_travelled_km'],
      ),
      deliverySlotRaw: _asMap(data['deliverySlot'] ?? data['delivery_slot']),
      deliveryInstructionsRaw: _instructionsMap(
        data['deliveryInstructions'] ?? data['delivery_instructions'],
      ),
      bill: _asMap(data['bill']),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static double? _optionalDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  static int? _optionalInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw.toString());
  }

  String get primaryVendorId {
    if (vendorId.isNotEmpty) return vendorId;
    for (final p in products) {
      if (p.vendorId.isNotEmpty) return p.vendorId;
    }
    return '';
  }

  bool get hasPickupCoords => pickupLat != null && pickupLng != null;

  bool get hasDeliveryCoords => latitude != null && longitude != null;

  OrderModel copyWith({
    String? modernStatus,
    String? orderStatus,
    String? vendorName,
    String? vendorPhone,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    double? routeDistanceKm,
    int? expectedDeliveryMinutes,
  }) {
    return OrderModel(
      id: id,
      products: products,
      createdDate: createdDate,
      customerName: customerName,
      phone: phone,
      address: address,
      isPaid: isPaid,
      orderStatus: orderStatus ?? this.orderStatus,
      modernStatus: modernStatus ?? this.modernStatus,
      deliveryBoyId: deliveryBoyId,
      isDelivered: isDelivered,
      isCancelled: isCancelled,
      deliveryType: deliveryType,
      isRated: isRated,
      rating: rating,
      confimedTime: confimedTime,
      driverGoShopTime: driverGoShopTime,
      orderPickedTime: orderPickedTime,
      onTheWayTime: onTheWayTime,
      orderDeliveredTime: orderDeliveredTime,
      deliveryCharge: deliveryCharge,
      uuid: uuid,
      latitude: latitude,
      longitude: longitude,
      vendorId: vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      routeDistanceKm: routeDistanceKm ?? this.routeDistanceKm,
      expectedDeliveryMinutes:
          expectedDeliveryMinutes ?? this.expectedDeliveryMinutes,
      deliverySlotRaw: deliverySlotRaw,
      deliveryInstructionsRaw: deliveryInstructionsRaw,
      bill: bill,
    );
  }

  static Map<String, dynamic>? _instructionsMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      return {'instructionText': raw.trim()};
    }
    return null;
  }

  String get deliverySlotLabel {
    final slot = deliverySlotRaw;
    if (slot == null) return '';
    final name = (slot['slotName'] ?? slot['label'] ?? '').toString();
    final express = slot['isExpress'] == true ||
        slot['slotType']?.toString().toLowerCase() == 'express';
    if (express) {
      final cleaned =
          name.replaceAll(RegExp(r'^Express\s*[·•\-]\s*', caseSensitive: false), '');
      return 'Express • $cleaned';
    }
    return name;
  }

  List<String> get deliveryInstructionLines {
    final m = deliveryInstructionsRaw;
    if (m == null) return const [];
    final lines = <String>[];
    final gate = (m['gateCode'] ?? m['gate_code'] ?? '').toString();
    final landmark = (m['landmark'] ?? '').toString();
    final notes = (m['notes'] ?? '').toString();
    final text = (m['instructionText'] ?? m['text'] ?? '').toString();
    if (gate.isNotEmpty) lines.add('Gate code: $gate');
    if (landmark.isNotEmpty) lines.add('Landmark: $landmark');
    if (m['leaveAtDoor'] == true || m['leave_at_door'] == true) {
      lines.add('Leave at door: Yes');
    }
    if (notes.isNotEmpty) lines.add('Notes: $notes');
    if (lines.isEmpty && text.isNotEmpty) lines.add(text);
    return lines;
  }

  Map<String, dynamic> toMap() {
    return {
      'products': products.map((e) => e.toMap()).toList(),
      'created_date': createdDate,
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'isPaid': isPaid,
      'order_status': orderStatus,
      'deliveryBoyId': deliveryBoyId,
      'isDelivered': isDelivered,
      'isCancelled': isCancelled,
      'delivery_type': deliveryType,
      'is_rated': isRated,
      'star': rating,
      'uuid': uuid,
      'confrimTime': confimedTime,
      'driverShop': driverGoShopTime,
      'pickedTime': orderPickedTime,
      'onTheWayTime': onTheWayTime,
      'deliveredTime': orderDeliveredTime,
      'delivery_charge': deliveryCharge,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class ProductItem {
  String name;
  String image;
  String description;
  String category;
  String unit;
  double price;
  double slashedPrice;
  int itemCount;
  String vendorId;

  ProductItem({
    required this.name,
    required this.image,
    required this.description,
    required this.category,
    required this.unit,
    required this.price,
    required this.slashedPrice,
    required this.itemCount,
    required this.vendorId,
  });

  factory ProductItem.fromMap(Map<String, dynamic> data) {
    return ProductItem(
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      unit: data['unit'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      slashedPrice: (data['slashedPrice'] ?? 0).toDouble(),
      itemCount: data['itemCount'] ?? 0,
      vendorId: data['vendor_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'description': description,
      'category': category,
      'unit': unit,
      'price': price,
      'slashedPrice': slashedPrice,
      'itemCount': itemCount,
      'vendor_id': vendorId,
    };
  }
}
