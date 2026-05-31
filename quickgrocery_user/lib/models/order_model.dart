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
  });

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    List<ProductItem> parsedProducts = [];
    final raw = data['products'] ?? data['items'];
    if (raw is List) {
      parsedProducts = raw
          .whereType<Map>()
          .map((e) => ProductItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
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
      currentLocation: data['current_location'] ?? '',
      lat: data['lat'] != null ? double.parse(data['lat'].toString()) : 0.0,
      lng: data['lng'] != null ? double.parse(data['lng'].toString()) : 0.0,
    );
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
}

class ProductItem {
  String productId;
  String name;
  String image;
  String description;
  String category;
  String unit;
  double price;
  double slashedPrice;
  int itemCount;
  String vendorId;
  final String variantName;
  final num? weightAmount;
  final String packUnit;
  final double? totalPrice;

  ProductItem({
    this.productId = '',
    required this.name,
    required this.image,
    required this.description,
    required this.category,
    required this.unit,
    required this.price,
    required this.slashedPrice,
    required this.itemCount,
    required this.vendorId,
    this.variantName = '',
    this.weightAmount,
    this.packUnit = '',
    this.totalPrice,
  });

  double get lineTotal {
    if (totalPrice != null && totalPrice! > 0) return totalPrice!;
    if (price > 0 && itemCount > 0) return price * itemCount;
    return 0;
  }

  factory ProductItem.fromMap(Map<String, dynamic> data) {
    final qty = (data['quantity'] as num?)?.toInt() ??
        (data['itemCount'] as num?)?.toInt() ??
        0;
    var unitPrice = (data['unitPrice'] as num?)?.toDouble() ??
        (data['price'] as num?)?.toDouble() ??
        0.0;
    var lineTotal = (data['totalPrice'] as num?)?.toDouble();
    if (unitPrice <= 0 && lineTotal != null && lineTotal > 0 && qty > 0) {
      unitPrice = lineTotal / qty;
    }
    final effectiveQty = qty > 0 ? qty : 1;
    if (unitPrice > 0) {
      lineTotal = unitPrice * effectiveQty;
    }

    final weight = _num(data['weight']);
    final unitField = (data['unit'] ?? '').toString();
    final variant = (data['variantName'] ?? data['variant'] ?? '').toString();

    return ProductItem(
      productId: (data['productId'] ?? data['product_id'] ?? '').toString(),
      name: (data['productName'] ?? data['name'] ?? '').toString(),
      image: (data['image'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      unit: (data['unitType'] ?? '').toString(),
      price: unitPrice,
      slashedPrice: (data['slashedPrice'] as num?)?.toDouble() ?? 0,
      itemCount: qty > 0 ? qty : 1,
      vendorId: (data['vendor_id'] ?? data['vendorId'] ?? '').toString(),
      variantName: variant,
      weightAmount: weight,
      packUnit: weight != null ? unitField : '',
      totalPrice: lineTotal,
    );
  }

  static num? _num(dynamic v) {
    if (v is num) return v;
    if (v is String && v.trim().isNotEmpty) return num.tryParse(v.trim());
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      if (productId.isNotEmpty) 'productId': productId,
      'name': name,
      'productName': name,
      'image': image,
      'description': description,
      'category': category,
      'quantity': itemCount,
      'itemCount': itemCount,
      if (weightAmount != null) 'weight': weightAmount,
      if (packUnit.isNotEmpty) 'unit': packUnit,
      if (unit.isNotEmpty) 'unitType': unit,
      if (variantName.isNotEmpty) 'variantName': variantName,
      'price': price,
      'unitPrice': price,
      'totalPrice': lineTotal,
      'slashedPrice': slashedPrice,
      'vendor_id': vendorId,
      'vendorId': vendorId,
    };
  }
}
