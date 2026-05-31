class OrderModel {
  String id;
  List<ProductItem> products;
  String createdDate;
  String customerName;
  String phone;
  String address;
  bool isPaid;
  String orderStatus;
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
  final Map<String, dynamic>? deliverySlotRaw;
  final Map<String, dynamic>? deliveryInstructionsRaw;

  OrderModel({
    required this.id,
    required this.products,
    required this.createdDate,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.isPaid,
    required this.orderStatus,
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
    this.deliverySlotRaw,
    this.deliveryInstructionsRaw,
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
      deliveryBoyId: data['deliveryBoyId'] ?? '',
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
      deliveryCharge: data['delivery_charge'] ?? 0,
      uuid: data['uuid'] ?? '',
      latitude: data['lat'] != null ? (data['lat'] as num).toDouble() : null,
      longitude: data['lng'] != null ? (data['lng'] as num).toDouble() : null,
      deliverySlotRaw: _asMap(data['deliverySlot'] ?? data['delivery_slot']),
      deliveryInstructionsRaw: _instructionsMap(
        data['deliveryInstructions'] ?? data['delivery_instructions'],
      ),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
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
