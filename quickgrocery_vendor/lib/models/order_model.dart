import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/order_bill_totals.dart';
import '../utils/order_product_parse.dart';

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
  String currentLocation;
  final double lat;
  final double lng;
  final String modernStatus;
  final DateTime? createdAt;
  final Map<String, dynamic>? deliverySlotRaw;
  final Map<String, dynamic>? deliveryInstructionsRaw;
  final Map<String, dynamic> billRaw;

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
    required this.currentLocation,
    required this.lat,
    required this.lng,
    this.modernStatus = '',
    this.createdAt,
    this.deliverySlotRaw,
    this.deliveryInstructionsRaw,
    this.billRaw = const {},
  });

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    final parsedProducts = OrderProductParse.linesFromOrder(data);

    DateTime? createdAt;
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    }

    final deliveryRaw = data['delivery_charge'] ?? data['deliveryCharge'] ?? 0;
    final deliveryCharge = deliveryRaw is int
        ? deliveryRaw
        : int.tryParse(deliveryRaw.toString()) ?? 0;

    return OrderModel(
      id: id,
      products: parsedProducts,
      createdDate: data['created_date']?.toString() ??
          (createdAt?.toIso8601String() ?? ''),
      customerName: data['customer_name'] ?? data['customerName'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      isPaid: data['isPaid'] == true ||
          (data['paymentStatus']?.toString().toLowerCase() == 'paid'),
      orderStatus: data['order_status'] ?? data['orderStatus'] ?? '',
      deliveryBoyId: data['deliveryBoyId'] ?? '',
      isDelivered: data['isDelivered'] == true ||
          (data['status']?.toString().toLowerCase() == 'delivered'),
      isCancelled: data['isCancelled'] == true ||
          (data['status']?.toString().toLowerCase() == 'cancelled'),
      deliveryType: data['delivery_type'] ?? '',
      isRated: data['is_rated'] == true,
      rating: (data['star'] ?? 0).toDouble(),
      confimedTime: data['confrimTime'] ?? '',
      driverGoShopTime: data['driverShop'] ?? '',
      orderPickedTime: data['pickedTime'] ?? '',
      onTheWayTime: data['onTheWayTime'] ?? '',
      orderDeliveredTime: data['deliveredTime'] ?? '',
      deliveryCharge: deliveryCharge,
      uuid: data['uuid'] ?? '',
      currentLocation: data['current_location'] ?? '',
      lat: data['lat'] != null ? double.parse(data['lat'].toString()) : 0.0,
      lng: data['lng'] != null ? double.parse(data['lng'].toString()) : 0.0,
      modernStatus: data['status']?.toString() ?? '',
      createdAt: createdAt,
      deliverySlotRaw: _asMap(data['deliverySlot'] ?? data['delivery_slot']),
      deliveryInstructionsRaw: _instructionsMap(
        data['deliveryInstructions'] ?? data['delivery_instructions'],
      ),
      billRaw: data['bill'] is Map
          ? Map<String, dynamic>.from(data['bill'] as Map)
          : const {},
    );
  }

  OrderBillTotals get billTotals => OrderBillTotals.resolve(this);

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
      'current_location': currentLocation,
      'lat': lat,
      'lng': lng,
    };
  }

  double getTotalAmount() => billTotals.grandTotal;

  double getSubtotal() => billTotals.subtotal;
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
  final String unitPerItem;
  final String packQuantity;
  final String packWeight;
  final String measurementType;
  final String variantName;
  final num? weightAmount;
  final String packUnit;
  final double? totalPrice;
  final int? selectedWeightInGrams;

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
    this.unitPerItem = '',
    this.packQuantity = '',
    this.packWeight = '',
    this.measurementType = '',
    this.variantName = '',
    this.weightAmount,
    this.packUnit = '',
    this.totalPrice,
    this.selectedWeightInGrams,
  });

  double get lineTotal {
    if (totalPrice != null && totalPrice! > 0) return totalPrice!;
    if (price > 0 && itemCount > 0) return price * itemCount;
    return 0;
  }

  factory ProductItem.fromMap(Map<String, dynamic> data) =>
      OrderProductParse.fromMap(data);

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
      'vendorId': vendorId,
    };
  }
}
