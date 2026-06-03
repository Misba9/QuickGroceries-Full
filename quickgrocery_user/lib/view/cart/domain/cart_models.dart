import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/inventory/inventory_limits.dart';
import 'package:quickgrocery/models/product.dart';

/// A single line in the cart — flat, serializable, and decoupled from
/// [ProductModel] so we can persist a snapshot of price/name/image at the
/// time of adding (so old carts survive product edits).
@immutable
class CartItem {
  final String productId;
  final String name;
  final String image;
  final String unit;
  final String unitPerItem;
  final String packQuantity;
  final String packWeight;
  final String measurementType;
  final String category;
  final String subcategory;
  final String vendorId;
  final double price;
  final double slashedPrice;
  final int stock;
  final int maxOrder;
  final int minOrderQuantity;
  final bool isAvailable;
  final int itemCount;
  final int selectedWeightInGrams;
  final bool isVegetable;

  /// Set when line is part of a combo bundle.
  final String? comboId;
  final String? comboGroupKey;

  const CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.unit,
    required this.unitPerItem,
    this.packQuantity = '',
    this.packWeight = '',
    this.measurementType = '',
    required this.category,
    required this.subcategory,
    required this.vendorId,
    required this.price,
    required this.slashedPrice,
    required this.stock,
    required this.maxOrder,
    this.minOrderQuantity = 1,
    this.isAvailable = true,
    required this.itemCount,
    required this.selectedWeightInGrams,
    required this.isVegetable,
    this.comboId,
    this.comboGroupKey,
  });

  bool get isComboLine => comboGroupKey != null && comboGroupKey!.isNotEmpty;

  bool get isUnavailable => InventoryLimits.isCartLineBlocked(
    stock: stock,
    itemCount: itemCount,
    maxOrder: maxOrder,
    isAvailable: isAvailable,
  );

  int get effectiveMaxQuantity =>
      InventoryLimits.effectiveMaxQuantity(stock: stock, maxOrder: maxOrder);

  factory CartItem.fromProduct(ProductModel p, {int? itemCount}) {
    return CartItem(
      productId: p.id,
      name: p.name,
      image: p.image,
      unit: p.unit,
      unitPerItem: p.unitPerItem,
      packQuantity: p.packQuantity,
      packWeight: p.packWeight,
      measurementType: p.measurementType,
      category: p.category,
      subcategory: p.subcategory,
      vendorId: p.vendorId,
      price: p.price,
      slashedPrice: p.slashedPrice,
      stock: p.stock,
      maxOrder: p.maxOrder,
      minOrderQuantity: p.minOrderQuantity,
      isAvailable: p.isAvailable,
      itemCount: itemCount ?? (p.itemCount <= 0 ? 1 : p.itemCount),
      selectedWeightInGrams: p.selectedWeightInGrams,
      isVegetable: p.isVegetable,
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> data) => CartItem(
    productId: (data['productId'] ?? data['id'] ?? '').toString(),
    name: (data['name'] ?? '').toString(),
    image: (data['image'] ?? '').toString(),
    unit: (data['unit'] ?? '').toString(),
    unitPerItem: (data['unitPerItem'] ?? '').toString(),
    packQuantity: (data['packQuantity'] ?? '').toString(),
    packWeight: (data['packWeight'] ?? '').toString(),
    measurementType: (data['measurementType'] ?? '').toString(),
    category: (data['category'] ?? '').toString(),
    subcategory: (data['subcategory'] ?? '').toString(),
    vendorId: (data['vendorId'] ?? data['vendor_id'] ?? '').toString(),
    price: (data['price'] as num?)?.toDouble() ?? 0,
    slashedPrice: (data['slashedPrice'] as num?)?.toDouble() ?? 0,
    stock: (data['stock'] as num?)?.toInt() ?? 0,
    maxOrder: (data['maxOrder'] as num?)?.toInt() ?? 0,
    minOrderQuantity: (data['minOrder'] as num?)?.toInt() ?? 1,
    isAvailable: data['isAvailable'] as bool? ?? true,
    itemCount: (data['itemCount'] as num?)?.toInt() ?? 1,
    selectedWeightInGrams:
        (data['selectedWeightInGrams'] as num?)?.toInt() ?? 1000,
    isVegetable: data['isVegetable'] as bool? ?? false,
    comboId: data['comboId']?.toString(),
    comboGroupKey: data['comboGroupKey']?.toString(),
  );

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'image': image,
    'unit': unit,
    'unitPerItem': unitPerItem,
    'category': category,
    'subcategory': subcategory,
    'vendorId': vendorId,
    'price': price,
    'slashedPrice': slashedPrice,
    'stock': stock,
    'maxOrder': maxOrder,
    'minOrder': minOrderQuantity,
    'isAvailable': isAvailable,
    'itemCount': itemCount,
    'selectedWeightInGrams': selectedWeightInGrams,
    'isVegetable': isVegetable,
    if (comboId != null) 'comboId': comboId,
    if (comboGroupKey != null) 'comboGroupKey': comboGroupKey,
  };

  /// Catalog discount: [slashedPrice] is the selling price, [price] is MRP.
  bool get hasCatalogDiscount =>
      slashedPrice > 0 && slashedPrice < price;

  /// Combo lines store allocated price in [price] and MRP in [slashedPrice].
  bool get hasComboMrpReference =>
      !hasCatalogDiscount && slashedPrice > price + 0.5;

  /// Per-unit amount the customer pays (after weight variant).
  double get unitEffectivePrice {
    final base = hasCatalogDiscount ? slashedPrice : price;
    if (isVegetable) {
      return (base * selectedWeightInGrams) / 1000.0;
    }
    return base;
  }

  /// Per-unit MRP / reference price for savings display.
  double get unitEffectiveSlashedPrice {
    if (isVegetable) {
      final mrpBase = hasComboMrpReference ? slashedPrice : price;
      return (mrpBase * selectedWeightInGrams) / 1000.0;
    }
    if (hasCatalogDiscount || hasComboMrpReference) {
      return hasComboMrpReference ? slashedPrice : price;
    }
    return unitEffectivePrice;
  }

  /// Total line price before global discounts/fees.
  double get lineTotal => unitEffectivePrice * itemCount;

  /// Sum of MRPs (used to compute "you save" badge).
  double get lineSlashedTotal => unitEffectiveSlashedPrice * itemCount;

  CartItem copyWith({
    int? itemCount,
    int? selectedWeightInGrams,
    int? stock,
    int? maxOrder,
    int? minOrderQuantity,
    bool? isAvailable,
    double? price,
    double? slashedPrice,
    String? comboId,
    String? comboGroupKey,
  }) => CartItem(
    productId: productId,
    name: name,
    image: image,
    unit: unit,
    unitPerItem: unitPerItem,
    category: category,
    subcategory: subcategory,
    vendorId: vendorId,
    price: price ?? this.price,
    slashedPrice: slashedPrice ?? this.slashedPrice,
    stock: stock ?? this.stock,
    maxOrder: maxOrder ?? this.maxOrder,
    minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
    isAvailable: isAvailable ?? this.isAvailable,
    itemCount: itemCount ?? this.itemCount,
    selectedWeightInGrams: selectedWeightInGrams ?? this.selectedWeightInGrams,
    isVegetable: isVegetable,
    comboId: comboId ?? this.comboId,
    comboGroupKey: comboGroupKey ?? this.comboGroupKey,
  );

  /// Builds a (lossy but safe) [ProductModel] from this cart line so that
  /// existing screens keyed off `CategoryService.selectedProduct` keep
  /// rendering correctly when we hydrate from Firestore.
  ProductModel toLegacyProduct() => ProductModel(
    id: productId,
    name: name,
    image: image,
    description: '',
    category: category,
    subcategory: subcategory,
    unit: unit,
    stock: stock,
    maxOrder: maxOrder,
    price: price,
    slashedPrice: slashedPrice,
    vendorId: vendorId,
    unitPerItem: unitPerItem,
    itemCount: itemCount,
    isMostSold: false,
    productIndex: 0,
    specialCat: '',
    addonIds: const [],
    images: const [],
    videos: const [],
    selectedWeightInGrams: selectedWeightInGrams,
  );
}

/// Currently-applied coupon. Discount is a flat percentage (matches existing
/// `coupons` schema where `discount` is an integer percentage).
@immutable
class AppliedCoupon {
  final String id;
  final String code;
  final int discountPercent;
  final double flatAmount;
  final double maxDiscountAmount;
  final bool freeDelivery;
  final String couponType;
  final bool firstOrderOnly;
  final double savingsPreview;

  const AppliedCoupon({
    required this.id,
    required this.code,
    required this.discountPercent,
    this.flatAmount = 0,
    this.maxDiscountAmount = 0,
    this.freeDelivery = false,
    this.couponType = '',
    this.firstOrderOnly = false,
    this.savingsPreview = 0,
  });

  bool get isFirstOrderOffer => firstOrderOnly || couponType == 'first_order';

  Map<String, dynamic> toMap() => {
    'id': id,
    'code': code,
    'discount': discountPercent,
    'flat_amount': flatAmount,
    'free_delivery': freeDelivery,
    'coupon_type': couponType,
  };

  factory AppliedCoupon.fromMap(Map<String, dynamic> m) => AppliedCoupon(
    id: (m['id'] ?? '').toString(),
    code: (m['code'] ?? '').toString(),
    discountPercent: (m['discount'] as num?)?.toInt() ?? 0,
    flatAmount: (m['flat_amount'] as num?)?.toDouble() ?? 0,
    maxDiscountAmount: (m['max_discount'] as num?)?.toDouble() ?? 0,
    freeDelivery: m['free_delivery'] as bool? ?? false,
    couponType: (m['coupon_type'] ?? '').toString(),
    firstOrderOnly: m['first_order_only'] as bool? ?? false,
  );
}

/// Pricing config sourced from Firestore + remote knobs.
@immutable
class PricingConfig {
  final int platformFee;
  final int handlingCharge;
  final int defaultDeliveryCharge;
  final int standardDeliveryCharge;
  final int minOrderValue;
  final int freeDeliveryThreshold;
  final bool isFreeDeliveryEnabled;
  final bool isDeliveryChargesEnabled;
  final double taxPercent;
  final double surgeMultiplier;
  final bool surgeActive;
  final String? surgeReason;

  /// Latest [settings/main] (or merged admin) `updatedAt` for UI / debugging.
  final DateTime? settingsUpdatedAt;

  const PricingConfig({
    this.platformFee = 0,
    this.handlingCharge = 0,
    this.defaultDeliveryCharge = 0,
    this.standardDeliveryCharge = 0,
    this.minOrderValue = 100,
    this.freeDeliveryThreshold = 99,
    this.isFreeDeliveryEnabled = true,
    this.isDeliveryChargesEnabled = true,
    this.taxPercent = 0,
    this.surgeMultiplier = 1.0,
    this.surgeActive = false,
    this.surgeReason,
    this.settingsUpdatedAt,
  });

  static const PricingConfig empty = PricingConfig();

  PricingConfig copyWith({
    int? platformFee,
    int? handlingCharge,
    int? defaultDeliveryCharge,
    int? standardDeliveryCharge,
    int? minOrderValue,
    int? freeDeliveryThreshold,
    bool? isFreeDeliveryEnabled,
    bool? isDeliveryChargesEnabled,
    double? taxPercent,
    double? surgeMultiplier,
    bool? surgeActive,
    String? surgeReason,
    DateTime? settingsUpdatedAt,
  }) => PricingConfig(
    platformFee: platformFee ?? this.platformFee,
    handlingCharge: handlingCharge ?? this.handlingCharge,
    defaultDeliveryCharge: defaultDeliveryCharge ?? this.defaultDeliveryCharge,
    standardDeliveryCharge:
        standardDeliveryCharge ?? this.standardDeliveryCharge,
    minOrderValue: minOrderValue ?? this.minOrderValue,
    freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
    isFreeDeliveryEnabled: isFreeDeliveryEnabled ?? this.isFreeDeliveryEnabled,
    isDeliveryChargesEnabled:
        isDeliveryChargesEnabled ?? this.isDeliveryChargesEnabled,
    taxPercent: taxPercent ?? this.taxPercent,
    surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
    surgeActive: surgeActive ?? this.surgeActive,
    surgeReason: surgeReason ?? this.surgeReason,
    settingsUpdatedAt: settingsUpdatedAt ?? this.settingsUpdatedAt,
  );
}

/// Output of the pricing calculator — every monetary line a UI may need.
@immutable
class BillBreakdown {
  final double subtotal;
  final double slashedSubtotal; // sum of MRP for "you save"
  final double itemSavings; // slashedSubtotal - subtotal
  final double couponDiscount;
  final double deliveryFee;
  final double surgeFee;
  final double handlingCharge;
  final double platformFee;
  final double tax;
  final double deliveryPartnerTip;
  final double total;
  final bool isFreeDelivery;
  final bool meetsMinimumOrder;
  final double minimumOrderValue;

  const BillBreakdown({
    required this.subtotal,
    required this.slashedSubtotal,
    required this.itemSavings,
    required this.couponDiscount,
    required this.deliveryFee,
    required this.surgeFee,
    required this.handlingCharge,
    required this.platformFee,
    required this.tax,
    this.deliveryPartnerTip = 0,
    required this.total,
    required this.isFreeDelivery,
    required this.meetsMinimumOrder,
    required this.minimumOrderValue,
  });

  BillBreakdown withDeliveryTip(double tip) {
    final t = tip < 0 ? 0.0 : tip;
    final delta = t - deliveryPartnerTip;
    return BillBreakdown(
      subtotal: subtotal,
      slashedSubtotal: slashedSubtotal,
      itemSavings: itemSavings,
      couponDiscount: couponDiscount,
      deliveryFee: deliveryFee,
      surgeFee: surgeFee,
      handlingCharge: handlingCharge,
      platformFee: platformFee,
      tax: tax,
      deliveryPartnerTip: t,
      total: double.parse((total + delta).toStringAsFixed(2)),
      isFreeDelivery: isFreeDelivery,
      meetsMinimumOrder: meetsMinimumOrder,
      minimumOrderValue: minimumOrderValue,
    );
  }

  static const BillBreakdown empty = BillBreakdown(
    subtotal: 0,
    slashedSubtotal: 0,
    itemSavings: 0,
    couponDiscount: 0,
    deliveryFee: 0,
    surgeFee: 0,
    handlingCharge: 0,
    platformFee: 0,
    tax: 0,
    deliveryPartnerTip: 0,
    total: 0,
    isFreeDelivery: false,
    meetsMinimumOrder: false,
    minimumOrderValue: 0,
  );

  Map<String, dynamic> toMap() => {
    'subtotal': subtotal,
    'slashedSubtotal': slashedSubtotal,
    'itemSavings': itemSavings,
    'couponDiscount': couponDiscount,
    'discount': couponDiscount,
    'deliveryFee': deliveryFee,
    'surgeFee': surgeFee,
    'handlingCharge': handlingCharge,
    'platformFee': platformFee,
    'tax': tax,
    if (deliveryPartnerTip > 0) 'deliveryPartnerTip': deliveryPartnerTip,
    'total': total,
    'grandTotal': total,
    'isFreeDelivery': isFreeDelivery,
  };

  /// Total user-visible savings (item savings + coupon).
  double get totalSavings => itemSavings + couponDiscount;
}

/// Structured delivery instructions saved on every order.
@immutable
class DeliveryInstructions {
  final String instructionText;
  final bool leaveAtDoor;
  final String gateCode;
  final String landmark;
  final String notes;

  const DeliveryInstructions({
    this.instructionText = '',
    this.leaveAtDoor = false,
    this.gateCode = '',
    this.landmark = '',
    this.notes = '',
  });

  bool get isEmpty =>
      instructionText.isEmpty &&
      !leaveAtDoor &&
      gateCode.isEmpty &&
      landmark.isEmpty &&
      notes.isEmpty;

  String get legacyText {
    if (instructionText.isNotEmpty) return instructionText;
    final parts = <String>[];
    if (gateCode.isNotEmpty) parts.add('Gate code: $gateCode');
    if (landmark.isNotEmpty) parts.add('Landmark: $landmark');
    if (leaveAtDoor) parts.add('Leave at door');
    if (notes.isNotEmpty) parts.add(notes);
    return parts.join(' · ');
  }

  List<String> displayLines() {
    final lines = <String>[];
    if (gateCode.isNotEmpty) lines.add('Gate code: $gateCode');
    if (landmark.isNotEmpty) lines.add('Landmark: $landmark');
    if (leaveAtDoor) lines.add('Leave at door: Yes');
    if (notes.isNotEmpty) lines.add('Notes: $notes');
    if (lines.isEmpty && instructionText.isNotEmpty) {
      lines.add(instructionText);
    }
    return lines;
  }

  Map<String, dynamic> toMap() => {
        'instructionText':
            instructionText.isNotEmpty ? instructionText : legacyText,
        'leaveAtDoor': leaveAtDoor,
        'gateCode': gateCode,
        'landmark': landmark,
        'notes': notes,
      };

  factory DeliveryInstructions.fromMap(dynamic raw) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return DeliveryInstructions(
        instructionText: (m['instructionText'] ?? m['text'] ?? '').toString(),
        leaveAtDoor: m['leaveAtDoor'] == true || m['leave_at_door'] == true,
        gateCode: (m['gateCode'] ?? m['gate_code'] ?? '').toString(),
        landmark: (m['landmark'] ?? '').toString(),
        notes: (m['notes'] ?? '').toString(),
      );
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return DeliveryInstructions(instructionText: raw.trim());
    }
    return const DeliveryInstructions();
  }

  DeliveryInstructions copyWith({
    String? instructionText,
    bool? leaveAtDoor,
    String? gateCode,
    String? landmark,
    String? notes,
  }) =>
      DeliveryInstructions(
        instructionText: instructionText ?? this.instructionText,
        leaveAtDoor: leaveAtDoor ?? this.leaveAtDoor,
        gateCode: gateCode ?? this.gateCode,
        landmark: landmark ?? this.landmark,
        notes: notes ?? this.notes,
      );
}

/// Express / scheduled delivery slot.
@immutable
class DeliverySlot {
  final String id;
  final String label;
  final DateTime start;
  final DateTime end;
  final bool isExpress;

  const DeliverySlot({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    required this.isExpress,
  });

  String get slotType => isExpress ? 'Express' : 'Scheduled';

  Map<String, dynamic> toMap() => {
        'slotId': id,
        'slotName': label,
        'startTime': start.toUtc().toIso8601String(),
        'endTime': end.toUtc().toIso8601String(),
        'slotType': slotType,
        'id': id,
        'label': label,
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'isExpress': isExpress,
      };

  factory DeliverySlot.fromMap(Map<String, dynamic> m) => DeliverySlot(
    id: (m['slotId'] ?? m['id'] ?? '').toString(),
    label: (m['slotName'] ?? m['label'] ?? '').toString(),
    start: _readTime(m['startTime'] ?? m['start']),
    end: _readTime(m['endTime'] ?? m['end']),
    isExpress: m['isExpress'] as bool? ??
        (m['slotType']?.toString().toLowerCase() == 'express'),
  );

  static DateTime _readTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}

/// Payment options exposed to the user.
enum PaymentMethod {
  cod('cod', 'Cash on Delivery'),
  upi('upi', 'UPI'),
  card('card', 'Card'),
  wallet('wallet', 'Wallet');

  const PaymentMethod(this.id, this.displayName);

  final String id;
  final String displayName;

  bool get isOnline => this != PaymentMethod.cod;

  static PaymentMethod fromId(String id) {
    return PaymentMethod.values.firstWhere(
      (e) => e.id == id,
      orElse: () => PaymentMethod.cod,
    );
  }
}

/// Simplified order lifecycle (4 customer-visible steps).
enum OrderStatus {
  orderPlaced('order_placed'),
  deliveryAssigned('delivery_assigned'),
  outForDelivery('out_for_delivery'),
  delivered('delivered'),
  cancelled('cancelled'),
  vendorRejected('cancelled_by_vendor');

  const OrderStatus(this.id);
  final String id;

  static String normalizeId(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return orderPlaced.id;
    switch (s) {
      case 'order_placed':
      case 'delivery_assigned':
      case 'out_for_delivery':
      case 'delivered':
      case 'cancelled':
      case 'cancelled_by_customer':
      case 'cancelled_by_vendor':
      case 'cancelled_by_rider':
      case 'vendor_rejected':
        return s == 'vendor_rejected' ? vendorRejected.id : s;
      case 'pending':
      case 'vendor_accepted':
      case 'accepted':
      case 'packing':
      case 'ready_for_pickup':
        return orderPlaced.id;
      case 'rider_assigned':
      case 'rider_accepted':
        return deliveryAssigned.id;
      case 'picked_up':
      case 'reached_store':
      case 'heading_to_store':
        return outForDelivery.id;
      default:
        return orderPlaced.id;
    }
  }

  static OrderStatus fromId(String id) {
    final normalized = normalizeId(id);
    return OrderStatus.values.firstWhere(
      (e) => e.id == normalized,
      orElse: () => OrderStatus.orderPlaced,
    );
  }

  String get displayName {
    switch (this) {
      case OrderStatus.orderPlaced:
        return 'Order placed';
      case OrderStatus.deliveryAssigned:
        return 'Delivery partner assigned';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
      case OrderStatus.vendorRejected:
        return 'Cancelled';
    }
  }

  bool get isTerminal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.vendorRejected;

  bool get isInTransit => this == OrderStatus.outForDelivery;

  bool get isLiveTracking => this == OrderStatus.outForDelivery;
}

/// In-memory cart state surfaced to the UI.
@immutable
class CartState {
  final List<CartItem> items;
  final AppliedCoupon? coupon;
  final PricingConfig pricing;
  final BillBreakdown bill;
  final bool isHydrating;
  final bool isSyncing;
  final String? errorMessage;

  const CartState({
    required this.items,
    required this.coupon,
    required this.pricing,
    required this.bill,
    required this.isHydrating,
    required this.isSyncing,
    required this.errorMessage,
  });

  static const CartState empty = CartState(
    items: <CartItem>[],
    coupon: null,
    pricing: PricingConfig.empty,
    bill: BillBreakdown.empty,
    isHydrating: false,
    isSyncing: false,
    errorMessage: null,
  );

  bool get isEmpty => items.isEmpty;
  int get totalUnits => items.fold(0, (a, b) => a + b.itemCount);

  CartState copyWith({
    List<CartItem>? items,
    AppliedCoupon? coupon,
    bool clearCoupon = false,
    PricingConfig? pricing,
    BillBreakdown? bill,
    bool? isHydrating,
    bool? isSyncing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      coupon: clearCoupon ? null : (coupon ?? this.coupon),
      pricing: pricing ?? this.pricing,
      bill: bill ?? this.bill,
      isHydrating: isHydrating ?? this.isHydrating,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Local-only state owned by the checkout screen.
@immutable
class CheckoutState {
  final int selectedAddressIndex;
  final DeliverySlot? slot;
  final DeliveryInstructions instructions;
  final PaymentMethod paymentMethod;
  final double deliveryTipAmount;
  final bool isPlacingOrder;
  final String? errorMessage;

  const CheckoutState({
    required this.selectedAddressIndex,
    required this.slot,
    required this.instructions,
    required this.paymentMethod,
    required this.deliveryTipAmount,
    required this.isPlacingOrder,
    required this.errorMessage,
  });

  static const CheckoutState initial = CheckoutState(
    selectedAddressIndex: 0,
    slot: null,
    instructions: DeliveryInstructions(),
    paymentMethod: PaymentMethod.cod,
    deliveryTipAmount: 0,
    isPlacingOrder: false,
    errorMessage: null,
  );

  CheckoutState copyWith({
    int? selectedAddressIndex,
    DeliverySlot? slot,
    DeliveryInstructions? instructions,
    PaymentMethod? paymentMethod,
    double? deliveryTipAmount,
    bool? isPlacingOrder,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CheckoutState(
      selectedAddressIndex: selectedAddressIndex ?? this.selectedAddressIndex,
      slot: slot ?? this.slot,
      instructions: instructions ?? this.instructions,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryTipAmount: deliveryTipAmount ?? this.deliveryTipAmount,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
