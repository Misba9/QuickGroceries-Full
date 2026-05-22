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

  bool get isComboLine =>
      comboGroupKey != null && comboGroupKey!.isNotEmpty;

  bool get isUnavailable => InventoryLimits.isCartLineBlocked(
        stock: stock,
        itemCount: itemCount,
        maxOrder: maxOrder,
        isAvailable: isAvailable,
      );

  int get effectiveMaxQuantity => InventoryLimits.effectiveMaxQuantity(
        stock: stock,
        maxOrder: maxOrder,
      );

  factory CartItem.fromProduct(ProductModel p, {int? itemCount}) {
    return CartItem(
      productId: p.id,
      name: p.name,
      image: p.image,
      unit: p.unit,
      unitPerItem: p.unitPerItem,
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

  /// Per-item price after weight-variant adjustment.
  double get unitEffectivePrice {
    if (isVegetable) {
      return (price * selectedWeightInGrams) / 1000.0;
    }
    return price;
  }

  /// Per-item slashed/MRP price after weight-variant adjustment.
  double get unitEffectiveSlashedPrice {
    if (isVegetable) {
      return (slashedPrice * selectedWeightInGrams) / 1000.0;
    }
    return slashedPrice;
  }

  /// Total line price before global discounts/fees.
  double get lineTotal => unitEffectivePrice * itemCount;

  /// Sum of MRPs (used to compute "you save" badge).
  double get lineSlashedTotal {
    final ref =
        unitEffectiveSlashedPrice > 0 ? unitEffectiveSlashedPrice : unitEffectivePrice;
    return ref * itemCount;
  }

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
  }) =>
      CartItem(
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
        selectedWeightInGrams:
            selectedWeightInGrams ?? this.selectedWeightInGrams,
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

  bool get isFirstOrderOffer =>
      firstOrderOnly || couponType == 'first_order';

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
  }) =>
      PricingConfig(
        platformFee: platformFee ?? this.platformFee,
        handlingCharge: handlingCharge ?? this.handlingCharge,
        defaultDeliveryCharge:
            defaultDeliveryCharge ?? this.defaultDeliveryCharge,
        standardDeliveryCharge:
            standardDeliveryCharge ?? this.standardDeliveryCharge,
        minOrderValue: minOrderValue ?? this.minOrderValue,
        freeDeliveryThreshold:
            freeDeliveryThreshold ?? this.freeDeliveryThreshold,
        isFreeDeliveryEnabled:
            isFreeDeliveryEnabled ?? this.isFreeDeliveryEnabled,
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
    required this.total,
    required this.isFreeDelivery,
    required this.meetsMinimumOrder,
    required this.minimumOrderValue,
  });

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
        'deliveryFee': deliveryFee,
        'surgeFee': surgeFee,
        'handlingCharge': handlingCharge,
        'platformFee': platformFee,
        'tax': tax,
        'total': total,
        'isFreeDelivery': isFreeDelivery,
      };

  /// Total user-visible savings (item savings + coupon).
  double get totalSavings => itemSavings + couponDiscount;
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        'isExpress': isExpress,
      };

  factory DeliverySlot.fromMap(Map<String, dynamic> m) => DeliverySlot(
        id: (m['id'] ?? '').toString(),
        label: (m['label'] ?? '').toString(),
        start: _readTime(m['start']),
        end: _readTime(m['end']),
        isExpress: m['isExpress'] as bool? ?? false,
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

/// Canonical order lifecycle for the new schema.
enum OrderStatus {
  pending('pending'),
  accepted('accepted'),
  packing('packing'),
  outForDelivery('out_for_delivery'),
  delivered('delivered'),
  cancelled('cancelled');

  const OrderStatus(this.id);
  final String id;

  static OrderStatus fromId(String id) => OrderStatus.values.firstWhere(
        (e) => e.id == id,
        orElse: () => OrderStatus.pending,
      );

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.packing:
        return 'Packing';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
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
  final String instructions;
  final PaymentMethod paymentMethod;
  final bool isPlacingOrder;
  final String? errorMessage;

  const CheckoutState({
    required this.selectedAddressIndex,
    required this.slot,
    required this.instructions,
    required this.paymentMethod,
    required this.isPlacingOrder,
    required this.errorMessage,
  });

  static const CheckoutState initial = CheckoutState(
    selectedAddressIndex: 0,
    slot: null,
    instructions: '',
    paymentMethod: PaymentMethod.cod,
    isPlacingOrder: false,
    errorMessage: null,
  );

  CheckoutState copyWith({
    int? selectedAddressIndex,
    DeliverySlot? slot,
    String? instructions,
    PaymentMethod? paymentMethod,
    bool? isPlacingOrder,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CheckoutState(
      selectedAddressIndex: selectedAddressIndex ?? this.selectedAddressIndex,
      slot: slot ?? this.slot,
      instructions: instructions ?? this.instructions,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
