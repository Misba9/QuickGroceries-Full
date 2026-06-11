import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_payment.dart';

class OrderModel {
  String id;
  List<ProductItem> products;
  String createdDate;
  DateTime? createdAt;
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
  String storeName;
  String vendorPhone;
  String pickupAddress;
  DateTime? acceptedAt;
  DateTime? pickedUpAt;
  DateTime? outForDeliveryAt;
  DateTime? deliveredAt;
  double? pickupLat;
  double? pickupLng;
  double? routeDistanceKm;
  int? expectedDeliveryMinutes;
  int? deliveryDurationSec;
  double? distanceTravelledKm;
  final Map<String, dynamic>? deliverySlotRaw;
  final Map<String, dynamic>? deliveryInstructionsRaw;
  final Map<String, dynamic>? bill;
  final Map<String, dynamic>? couponRaw;
  final double tipAmount;
  final String tipStatus;
  final String paymentMethod;
  final String paymentStatus;
  final String razorpayPaymentId;
  final String transactionId;
  final double paidAmount;
  final DateTime? paidAt;
  final String collectionMethod;
  final String fullAddress;
  final OrderPaymentInfo payment;

  OrderModel({
    required this.id,
    required this.products,
    required this.createdDate,
    this.createdAt,
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
    this.storeName = '',
    this.vendorPhone = '',
    this.pickupAddress = '',
    this.acceptedAt,
    this.pickedUpAt,
    this.outForDeliveryAt,
    this.deliveredAt,
    this.pickupLat,
    this.pickupLng,
    this.routeDistanceKm,
    this.expectedDeliveryMinutes,
    this.deliveryDurationSec,
    this.distanceTravelledKm,
    this.deliverySlotRaw,
    this.deliveryInstructionsRaw,
    this.bill,
    this.couponRaw,
    this.tipAmount = 0,
    this.tipStatus = '',
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    this.razorpayPaymentId = '',
    this.transactionId = '',
    this.paidAmount = 0,
    this.paidAt,
    this.collectionMethod = '',
    this.fullAddress = '',
    OrderPaymentInfo? payment,
  }) : payment = payment ??
            OrderPaymentInfo(
              paymentMethod: paymentMethod,
              paymentStatus: paymentStatus,
              isPaidLegacy: isPaid,
              razorpayPaymentId: razorpayPaymentId,
              transactionId: transactionId,
              paidAmount: paidAmount,
              paidAt: paidAt,
              collectionMethod: collectionMethod,
              bill: bill,
              productsSubtotal: 0,
              deliveryCharge: deliveryCharge,
            );

  static DateTime? _parseCreatedAt(Map<String, dynamic> data) {
    final raw = data['createdAt'] ?? data['created_at'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    final legacy = data['created_date']?.toString().trim();
    if (legacy != null && legacy.isNotEmpty) {
      return DateTime.tryParse(legacy);
    }
    return null;
  }

  /// Best available creation time for list ordering (newest-first).
  DateTime get sortCreatedAt {
    if (createdAt != null) return createdAt!;
    final parsed = DateTime.tryParse(createdDate.trim());
    if (parsed != null) return parsed;
    final idMs = int.tryParse(id);
    if (idMs != null && idMs > 0) {
      return DateTime.fromMillisecondsSinceEpoch(idMs);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static int compareNewestFirst(OrderModel a, OrderModel b) =>
      b.sortCreatedAt.compareTo(a.sortCreatedAt);

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    List<ProductItem> parsedProducts = [];
    if (data['products'] != null) {
      parsedProducts = List<Map<String, dynamic>>.from(
        data['products'],
      ).map((e) => ProductItem.fromMap(e)).toList();
    }

    final deliveryCharge = (data['delivery_charge'] ?? data['deliveryCharge'] ?? 0) is int
        ? (data['delivery_charge'] ?? data['deliveryCharge'] ?? 0) as int
        : ((data['delivery_charge'] ?? data['deliveryCharge'] ?? 0) as num).toInt();
    final productsSubtotal = parsedProducts.fold<double>(
      0,
      (s, p) => s + p.lineTotal,
    );
    final billMap = _asMap(data['bill']);
    final paymentInfo = OrderPaymentInfo.fromOrderData(
      data,
      productsSubtotal: productsSubtotal,
      deliveryCharge: deliveryCharge,
      bill: billMap,
    );

    return OrderModel(
      id: id,
      products: parsedProducts,
      createdDate: data['created_date'] ?? '',
      createdAt: _parseCreatedAt(data),
      customerName: (data['customer_name'] ?? data['customerName'] ?? '')
          .toString(),
      phone: _customerPhoneFromData(data),
      address: (data['address'] ?? data['deliveryAddress'] ?? '').toString(),
      fullAddress: _fullAddress(data),
      isPaid: data['isPaid'] ?? paymentInfo.isPaymentCollected,
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
      deliveryCharge: deliveryCharge,
      uuid: data['uuid'] ?? '',
      latitude: _customerLat(data),
      longitude: _customerLng(data),
      paymentMethod: paymentInfo.paymentMethod,
      paymentStatus: paymentInfo.paymentStatus,
      razorpayPaymentId: paymentInfo.razorpayPaymentId,
      transactionId: paymentInfo.transactionId,
      paidAmount: paymentInfo.paidAmount,
      paidAt: paymentInfo.paidAt,
      collectionMethod: paymentInfo.collectionMethod,
      payment: paymentInfo,
      vendorId: (data['vendorId'] ?? data['vendor_id'] ?? '').toString(),
      vendorName: (data['vendorName'] ?? data['vendor_name'] ?? '').toString(),
      storeName: (data['storeName'] ??
              data['store_name'] ??
              data['shopName'] ??
              data['shop_name'] ??
              '')
          .toString(),
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
      bill: billMap,
      couponRaw: _asMap(data['coupon']),
      tipAmount: _tipFromData(data),
      tipStatus: (data['tipStatus'] ?? '').toString(),
      acceptedAt: _parseDateTime(
        data['acceptedAt'] ?? data['riderAcceptedAt'] ?? data['confrimTime'],
      ),
      pickedUpAt: _parseDateTime(data['pickedUpAt'] ?? data['pickedTime']),
      outForDeliveryAt: _parseDateTime(
        data['outForDeliveryAt'] ?? data['onTheWayTime'],
      ),
      deliveredAt: _parseDateTime(
        data['deliveredAt'] ?? data['deliveredTime'],
      ),
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim());
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static String _customerPhoneFromData(Map<String, dynamic> data) {
    final addressSnapshot = data['address_snapshot'];
    final snapshot = addressSnapshot is Map
        ? Map<String, dynamic>.from(addressSnapshot)
        : null;

    for (final v in [
      data['phone'],
      data['customerPhone'],
      data['customer_phone'],
      data['phoneNumber'],
      data['phone_number'],
      data['mobile'],
      data['customerMobile'],
      snapshot?['mobile'],
      snapshot?['phone'],
      snapshot?['phoneNumber'],
      snapshot?['phone_number'],
    ]) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  static String _fullAddress(Map<String, dynamic> data) {
    final direct = (data['fullAddress'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final snap = data['address_snapshot'];
    if (snap is Map) {
      final m = Map<String, dynamic>.from(snap);
      final line = '${m['address'] ?? ''} ${m['area'] ?? ''}'.trim();
      if (line.isNotEmpty) return line;
    }
    return (data['address'] ?? data['deliveryAddress'] ?? '').toString().trim();
  }

  static double? _customerLat(Map<String, dynamic> data) {
    if (data['lat'] != null) return (data['lat'] as num).toDouble();
    if (data['latitude'] != null) return (data['latitude'] as num).toDouble();
    final snap = data['address_snapshot'];
    if (snap is Map) {
      final lat = snap['lat'] ?? snap['latitude'];
      if (lat is num) return lat.toDouble();
    }
    return null;
  }

  static double? _customerLng(Map<String, dynamic> data) {
    if (data['lng'] != null) return (data['lng'] as num).toDouble();
    if (data['longitude'] != null) return (data['longitude'] as num).toDouble();
    final snap = data['address_snapshot'];
    if (snap is Map) {
      final lng = snap['lng'] ?? snap['longitude'];
      if (lng is num) return lng.toDouble();
    }
    return null;
  }

  bool get hasCustomerCoordinates =>
      latitude != null && longitude != null && latitude != 0 && longitude != 0;

  bool get hasVendorCoordinates =>
      pickupLat != null && pickupLng != null && pickupLat != 0 && pickupLng != 0;

  static double _tipFromData(Map<String, dynamic> data) {
    final direct = data['tipAmount'];
    if (direct is num && direct > 0) return direct.toDouble();
    final bill = data['bill'];
    if (bill is Map) {
      final t = bill['deliveryPartnerTip'] ?? bill['tipAmount'];
      if (t is num && t > 0) return t.toDouble();
    }
    return 0;
  }

  double get deliveryFeeEarning {
    if (deliveryCharge > 0) return deliveryCharge.toDouble();
    final fee = bill?['deliveryFee'];
    if (fee is num) return fee.toDouble();
    return 0;
  }

  double get tipEarning => tipAmount > 0
      ? tipAmount
      : (bill?['deliveryPartnerTip'] is num
          ? (bill!['deliveryPartnerTip'] as num).toDouble()
          : 0);

  double get totalRiderEarning => deliveryFeeEarning + tipEarning;

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
    String? storeName,
    String? vendorPhone,
    String? pickupAddress,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? outForDeliveryAt,
    DateTime? deliveredAt,
    double? pickupLat,
    double? pickupLng,
    double? routeDistanceKm,
    int? expectedDeliveryMinutes,
  }) {
    return OrderModel(
      id: id,
      products: products,
      createdDate: createdDate,
      createdAt: createdAt,
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
      storeName: storeName ?? this.storeName,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      outForDeliveryAt: outForDeliveryAt ?? this.outForDeliveryAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      routeDistanceKm: routeDistanceKm ?? this.routeDistanceKm,
      expectedDeliveryMinutes:
          expectedDeliveryMinutes ?? this.expectedDeliveryMinutes,
      deliverySlotRaw: deliverySlotRaw,
      deliveryInstructionsRaw: deliveryInstructionsRaw,
      bill: bill,
      couponRaw: couponRaw,
      tipAmount: tipAmount,
      tipStatus: tipStatus,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      razorpayPaymentId: razorpayPaymentId,
      transactionId: transactionId,
      paidAmount: paidAmount,
      paidAt: paidAt,
      collectionMethod: collectionMethod,
      fullAddress: fullAddress,
      payment: payment,
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

  final double? _lineTotalStored;

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
    double? lineTotalStored,
  }) : _lineTotalStored = lineTotalStored;

  double get unitPricePaid => price;

  double get unitMrp => slashedPrice > price + 0.01 ? slashedPrice : price;

  bool get hasPurchasedDiscount => unitMrp > unitPricePaid + 0.01;

  double get lineTotal {
    final t = _lineTotalStored;
    if (t != null && t > 0) return t;
    if (price > 0 && itemCount > 0) return price * itemCount;
    return 0;
  }

  factory ProductItem.fromMap(Map<String, dynamic> data) {
    final qty = (data['quantity'] as num?)?.toInt() ??
        (data['itemCount'] as num?)?.toInt() ??
        0;
    final effectiveQty = qty > 0 ? qty : 1;
    final resolved = _resolveOrderLinePrices(data, effectiveQty);

    return ProductItem(
      name: (data['productName'] ?? data['name'] ?? '').toString(),
      image: data['image'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      unit: (data['unitType'] ?? data['unit'] ?? '').toString(),
      price: resolved.selling,
      slashedPrice: resolved.original,
      itemCount: effectiveQty,
      vendorId: (data['vendor_id'] ?? data['vendorId'] ?? '').toString(),
      lineTotalStored: resolved.lineTotal,
    );
  }

  static _OrderLinePrices _resolveOrderLinePrices(
    Map<String, dynamic> data,
    int qty,
  ) {
    double d(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String && v.trim().isNotEmpty) {
        return double.tryParse(v.trim()) ?? 0;
      }
      return 0;
    }

    final lineTotalExplicit = d(data['lineTotal'] ?? data['totalPrice']);
    final pricePaid = d(
      data['pricePaid'] ??
          data['sellingPrice'] ??
          data['discountedPrice'] ??
          data['unitPrice'],
    );

    if (pricePaid > 0) {
      var mrp = d(data['mrp'] ?? data['originalPrice']);
      if (mrp <= pricePaid) {
        mrp = d(data['slashedPrice']);
        if (mrp <= pricePaid) mrp = pricePaid;
      }
      return _OrderLinePrices(
        selling: pricePaid,
        original: mrp,
        lineTotal: lineTotalExplicit > 0
            ? lineTotalExplicit
            : pricePaid * qty,
      );
    }

    var unitPrice = d(data['price']);
    final slashed = d(data['slashedPrice']);
    var lineTotal = lineTotalExplicit;
    if (unitPrice <= 0 && lineTotal > 0) unitPrice = lineTotal / qty;
    if (slashed > 0 && slashed < unitPrice) {
      return _OrderLinePrices(
        selling: slashed,
        original: unitPrice,
        lineTotal: lineTotal > 0 ? lineTotal : slashed * qty,
      );
    }
    return _OrderLinePrices(
      selling: unitPrice,
      original: slashed > unitPrice ? slashed : unitPrice,
      lineTotal: lineTotal > 0 ? lineTotal : unitPrice * qty,
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

class _OrderLinePrices {
  const _OrderLinePrices({
    required this.selling,
    required this.original,
    required this.lineTotal,
  });

  final double selling;
  final double original;
  final double lineTotal;
}
