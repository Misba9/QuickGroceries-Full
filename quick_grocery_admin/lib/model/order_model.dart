import 'package:quick_grocery_admin/view/orders/utils/order_applied_coupon.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_bill_totals.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_delivery_meta.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_product_parse.dart';

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
  String currentLocation;
  final double lat;
  final double lng;
  final OrderDeliverySlot? deliverySlot;
  final OrderDeliveryInstructions? deliveryInstructions;
  final Map<String, dynamic> billRaw;
  final OrderAppliedCoupon? appliedCoupon;

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
    required this.currentLocation,
    required this.lat,
    required this.lng,
    this.deliverySlot,
    this.deliveryInstructions,
    this.billRaw = const {},
    this.appliedCoupon,
  });

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    final parsedProducts = OrderProductParse.linesFromOrder(data);

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
      deliveryBoyId: (data['deliveryBoyId'] ?? data['delivery_boy_id'] ?? '')
          .toString(),
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
      currentLocation: data['current_location'] ?? '',
      lat: data['lat'] != null ? double.parse(data['lat'].toString()) : 0.0,
      lng: data['lng'] != null ? double.parse(data['lng'].toString()) : 0.0,
      deliverySlot: OrderDeliverySlot.fromFirestore(data),
      deliveryInstructions: OrderDeliveryInstructions.fromFirestore(data),
      billRaw: data['bill'] is Map
          ? Map<String, dynamic>.from(data['bill'] as Map)
          : const {},
      appliedCoupon: OrderAppliedCoupon.fromMap(
        data['coupon'] is Map
            ? Map<String, dynamic>.from(data['coupon'] as Map)
            : null,
      ),
    );
  }

  OrderBillTotals get billTotals => OrderBillTotals.resolve(this);

  String? get couponCode => appliedCoupon?.code;

  bool get hasCoupon =>
      (appliedCoupon != null && appliedCoupon!.code.isNotEmpty) ||
      billTotals.couponDiscount > 0;

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

  /// Grand total from saved `bill` (single source of truth).
  double getTotalAmount() => billTotals.grandTotal;

  String get deliverySlotLabel => formatDeliverySlotLabel(deliverySlot);

  /// Item subtotal from saved `bill`, or sum of line totals for legacy orders.
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
    };
  }
}
