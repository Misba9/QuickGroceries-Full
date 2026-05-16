import 'package:cloud_firestore/cloud_firestore.dart';

/// ProductModel — extended schema for the dynamic homepage.
///
/// All legacy fields and behavior (`itemCount`, `effectivePrice`,
/// `isVegetable`, `slashedPrice`, etc.) remain unchanged so the cart,
/// search, wishlist, category and product-view screens keep working.
///
/// New homepage-driven fields:
/// - [discountPrice]  — alias of [slashedPrice] (kept for new schema clarity).
/// - [rating]         — average rating, 0..5.
/// - [totalReviews]   — review count.
/// - [isTrending]     — drives the "Trending Now" home rail.
/// - [isFeatured]     — drives the "Featured" home rail.
/// - [isAvailable]    — soft availability flag (independent of [stock]).
/// - [createdAt]      — server creation timestamp for "New Arrivals" sorting.
class ProductModel {
  String id;
  String name;
  String image;
  String description;
  String category;
  String subcategory;
  String unit;
  int stock;
  int maxOrder;
  double price;
  double slashedPrice;
  String vendorId;
  String unitPerItem;
  /// Optional pack quantity from admin (`quantity`, `qty`, …).
  String packQuantity;
  /// Optional weight / size from admin (`weight`, …).
  String packWeight;
  /// Optional measurement hint (`measurement_type`, …).
  String measurementType;
  int itemCount;
  bool isMostSold;
  int productIndex;
  String specialCat;
  List<String> addonIds;
  List<dynamic> images;
  List<dynamic> videos;
  int selectedWeightInGrams;

  // ── New, dynamic-homepage fields ─────────────────────────────────────────
  double rating;
  int totalReviews;
  bool isTrending;
  bool isFeatured;
  bool isAvailable;
  DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.unit,
    required this.stock,
    required this.maxOrder,
    required this.price,
    required this.slashedPrice,
    required this.vendorId,
    required this.unitPerItem,
    this.packQuantity = '',
    this.packWeight = '',
    this.measurementType = '',
    required this.itemCount,
    required this.isMostSold,
    required this.productIndex,
    required this.specialCat,
    required this.addonIds,
    required this.images,
    required this.videos,
    this.selectedWeightInGrams = 1000,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isTrending = false,
    this.isFeatured = false,
    this.isAvailable = true,
    this.createdAt,
  });

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      name: data['name']?.toString() ?? '',
      image: data['image']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      subcategory: data['subcategory']?.toString() ?? '',
      unit: data['unit']?.toString() ?? '',
      stock: _asInt(data['stock']),
      maxOrder: _asInt(data['maxOrder']),
      price: _asDouble(data['price']),
      // 'discountPrice' is the new schema name; fall back to legacy
      // 'slashedPrice' so old documents keep working.
      slashedPrice: _asDouble(data['discountPrice'] ?? data['slashedPrice']),
      vendorId: data['vendor_id']?.toString() ?? '',
      unitPerItem: data['unitPerItem']?.toString() ?? '',
      packQuantity: _firstNonEmptyString(data, const [
        'quantity',
        'packQuantity',
        'qty',
      ]),
      packWeight: _firstNonEmptyString(data, const [
        'weight',
        'packWeight',
        'gram_weight',
      ]),
      measurementType: _firstNonEmptyString(data, const [
        'measurement_type',
        'measurementType',
      ]),
      itemCount: _asInt(data['itemCount']),
      isMostSold: _asBool(data['most_sold'], fallback: false),
      productIndex: _asInt(data['product_index']),
      specialCat: data['special_cat']?.toString() ?? '',
      addonIds: _asStringList(data['addonIds']),
      images: _asDynamicList(data['images']),
      videos: _asDynamicList(data['videos']),
      selectedWeightInGrams: _asInt(
        data['selectedWeightInGrams'],
        fallback: 1000,
      ),
      rating: _asDouble(data['rating']),
      totalReviews: _asInt(data['totalReviews']),
      isTrending: _asBool(data['isTrending'], fallback: false),
      isFeatured: _asBool(data['isFeatured'], fallback: false),
      // Prefer explicit flags when present; tolerate string/int representations.
      isAvailable: _resolveIsAvailable(data),
      createdAt: _asDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'description': description,
    'category': category,
    'subcategory': subcategory,
    'unit': unit,
    'stock': stock,
    'maxOrder': maxOrder,
    'price': price,
    'discountPrice': slashedPrice,
    'slashedPrice': slashedPrice,
    'vendor_id': vendorId,
    'unitPerItem': unitPerItem,
    if (packQuantity.isNotEmpty) 'quantity': packQuantity,
    if (packWeight.isNotEmpty) 'weight': packWeight,
    if (measurementType.isNotEmpty) 'measurement_type': measurementType,
    'itemCount': itemCount,
    'most_sold': isMostSold,
    'product_index': productIndex,
    'special_cat': specialCat,
    'addonIds': addonIds,
    'images': images,
    'videos': videos,
    'selectedWeightInGrams': selectedWeightInGrams,
    'rating': rating,
    'totalReviews': totalReviews,
    'isTrending': isTrending,
    'isFeatured': isFeatured,
    'isAvailable': isAvailable,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
  };

  ProductModel copyWith({
    String? id,
    String? name,
    String? image,
    String? description,
    String? category,
    String? subcategory,
    String? unit,
    int? stock,
    int? maxOrder,
    double? price,
    double? slashedPrice,
    String? vendorId,
    String? unitPerItem,
    String? packQuantity,
    String? packWeight,
    String? measurementType,
    int? itemCount,
    bool? isMostSold,
    int? productIndex,
    String? specialCat,
    List<String>? addonIds,
    List<dynamic>? images,
    List<dynamic>? videos,
    int? selectedWeightInGrams,
    double? rating,
    int? totalReviews,
    bool? isTrending,
    bool? isFeatured,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      maxOrder: maxOrder ?? this.maxOrder,
      price: price ?? this.price,
      slashedPrice: slashedPrice ?? this.slashedPrice,
      vendorId: vendorId ?? this.vendorId,
      unitPerItem: unitPerItem ?? this.unitPerItem,
      packQuantity: packQuantity ?? this.packQuantity,
      packWeight: packWeight ?? this.packWeight,
      measurementType: measurementType ?? this.measurementType,
      itemCount: itemCount ?? this.itemCount,
      isMostSold: isMostSold ?? this.isMostSold,
      productIndex: productIndex ?? this.productIndex,
      specialCat: specialCat ?? this.specialCat,
      addonIds: addonIds ?? this.addonIds,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      selectedWeightInGrams:
          selectedWeightInGrams ?? this.selectedWeightInGrams,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isTrending: isTrending ?? this.isTrending,
      isFeatured: isFeatured ?? this.isFeatured,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// New-schema alias of [slashedPrice] kept readable in homepage UI code.
  double get discountPrice => slashedPrice;

  /// True when [discountPrice] is set and undercuts [price].
  bool get hasDiscount => slashedPrice > 0 && slashedPrice < price;

  /// Discount percentage rounded to a whole number, 0 when none.
  int get discountPercent {
    if (!hasDiscount || price <= 0) return 0;
    return (((price - slashedPrice) / price) * 100).round();
  }

  bool get isVegetable {
    final catLower = category.toLowerCase();
    final subCatLower = subcategory.toLowerCase();
    return catLower.contains('vegetable') ||
        catLower.contains('vegetables') ||
        subCatLower.contains('vegetable') ||
        subCatLower.contains('vegetables');
  }

  double get effectivePrice {
    if (isVegetable) {
      return (price * selectedWeightInGrams) / 1000.0;
    }
    return price;
  }

  double get effectiveSlashedPrice {
    if (isVegetable) {
      return (slashedPrice * selectedWeightInGrams) / 1000.0;
    }
    return slashedPrice;
  }
}

String _firstNonEmptyString(Map<String, dynamic> data, List<String> keys) {
  for (final k in keys) {
    if (!data.containsKey(k)) continue;
    final v = data[k];
    if (v == null) continue;
    final t = v.toString().trim();
    if (t.isNotEmpty) return t;
  }
  return '';
}

bool _resolveIsAvailable(Map<String, dynamic> data) {
  if (data.containsKey('isAvailable')) {
    return _asBool(data['isAvailable'], fallback: true);
  }
  if (data.containsKey('is_active')) {
    return _asBool(data['is_active'], fallback: true);
  }
  if (data.containsKey('active')) {
    return _asBool(data['active'], fallback: true);
  }
  return true;
}

bool _asBool(dynamic value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value.toString().trim().toLowerCase();
  if (s.isEmpty) return fallback;
  if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
  if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
  return fallback;
}

List<dynamic> _asDynamicList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value.map((e) => e is String ? e : e.toString()).toList();
  }
  return const [];
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  final str = value.toString();
  if (str.isEmpty) return fallback;
  return double.tryParse(str) ?? fallback;
}

List<String> _asStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) return value.map((e) => e.toString()).toList();
  return const [];
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString());
}
