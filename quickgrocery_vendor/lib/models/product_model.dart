import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_settings.dart';

class ProductModel {
  final String id;
  final String name;
  final String image;
  final Timestamp createdAt;
  final String description;
  final String category;
  final String? subcategory;
  final String unit;
  final String stock;
  final String maxOrder;
  final String minOrder;
  final String price;
  final String slashedPrice;
  final int totalSold;
  final String vendorId;
  final ProductSettings settings;
  final Timestamp lastEdited;
  final String unitPerItem;
  final List favorites;
  final String shopName;
  final List<dynamic> images;
  final List<dynamic> videos;
  final String specialCat;
  final bool isDeleted;
  final bool isAvailable;
  final String? stockStatus;

  ProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.createdAt,
    required this.description,
    required this.category,
    this.subcategory,
    required this.unit,
    required this.stock,
    required this.maxOrder,
    this.minOrder = '1',
    required this.price,
    required this.slashedPrice,
    required this.totalSold,
    required this.vendorId,
    required this.settings,
    required this.lastEdited,
    required this.unitPerItem,
    required this.favorites,
    required this.shopName,
    required this.images,
    required this.videos,
    this.specialCat = '',
    this.isDeleted = false,
    this.isAvailable = true,
    this.stockStatus,
  });

  bool get isOutOfStock =>
      !isAvailable || stockStatus == 'out_of_stock' || stockInt <= 0;

  bool get isActive => settings.isActive;
  bool get isFlashSale => settings.isFlashSale;
  bool get isTodaysBest => settings.isTodaysBest;
  bool get isMostSelling => settings.isMostSelling;

  int get stockInt => int.tryParse(stock) ?? 0;

  /// All gallery URLs (main + extras), deduplicated, main first.
  List<String> get galleryUrls =>
      ProductModel.collectImageUrls(image: image, images: images);

  static List<String>? dataProductImages({Map<String, dynamic>? data}) {
    if (data == null) return null;
    final raw = data['product_images'] ?? data['images'];
    if (raw is! List) return null;
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  static List<String> collectImageUrls({
    required String image,
    required List<dynamic> images,
    List<String>? productImages,
  }) {
    final out = <String>[];
    void add(String url) {
      final u = url.trim();
      if (u.isEmpty || out.contains(u)) return;
      out.add(u);
    }

    add(image);
    for (final item in productImages ?? []) {
      add(item);
    }
    for (final item in images) {
      add(item.toString());
    }
    return out;
  }

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    final gallery = collectImageUrls(
      image: data['image']?.toString() ?? '',
      images: data['images'] is List ? data['images'] as List : const [],
      productImages: dataProductImages(data: data),
    );
    final cover = gallery.isNotEmpty ? gallery.first : '';

    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      image: cover,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : Timestamp.now(),
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'],
      unit: data['unit'] ?? '',
      stock: data['stock']?.toString() ?? '',
      maxOrder: data['maxOrder']?.toString() ?? '',
      minOrder: data['minOrder']?.toString() ?? '1',
      price: data['price']?.toString() ?? '',
      slashedPrice: data['slashedPrice']?.toString() ?? '',
      totalSold: (data['totalSold'] as num?)?.toInt() ?? 0,
      vendorId: data['vendor_id'] ?? '',
      settings: ProductSettings.fromMap(data),
      lastEdited: data['lastEdited'] is Timestamp
          ? data['lastEdited'] as Timestamp
          : Timestamp.now(),
      unitPerItem: data['unitPerItem'] ?? '',
      favorites: data['favorites'] ?? [],
      shopName: data['shop_name'] ?? 'Appmoc',
      images: gallery,
      videos: data['videos'] ?? [],
      specialCat: data['special_cat']?.toString() ?? '',
      isDeleted: data['isDeleted'] == true || data['is_deleted'] == true,
      isAvailable: data['isAvailable'] is bool
          ? data['isAvailable'] as bool
          : (int.tryParse(data['stock']?.toString() ?? '') ?? 0) > 0,
      stockStatus: data['stockStatus']?.toString(),
    );
  }

  static Map<String, dynamic> imageFieldsForFirestore(List<String> urls) {
    final list = urls.where((u) => u.trim().isNotEmpty).toList();
    final cover = list.isNotEmpty ? list.first : '';
    return {
      'image': cover,
      'images': list,
      'product_images': list,
    };
  }

  Map<String, dynamic> toCreateMap() {
    final urls = collectImageUrls(image: image, images: images);
    return {
      'name': name,
      ...imageFieldsForFirestore(urls),
      'createdAt': FieldValue.serverTimestamp(),
      'description': description,
      'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      'unit': unit,
      'stock': _stockInt(),
      'maxOrder': _orderInt(maxOrder),
      'minOrder': _orderInt(minOrder, fallback: 1),
      'isAvailable': settings.isActive && _stockInt() > 0,
      'price': price,
      'slashedPrice': slashedPrice,
      'totalSold': totalSold,
      'vendor_id': vendorId,
      'unitPerItem': unitPerItem,
      'favorites': favorites,
      'shop_name': shopName,
      'videos': videos,
      ...settings.toFirestorePatch(existingSpecialCat: specialCat),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    final urls = collectImageUrls(image: image, images: images);
    return {
      'name': name,
      ...imageFieldsForFirestore(urls),
      'description': description,
      'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      'unit': unit,
      'stock': _stockInt(),
      'maxOrder': _orderInt(maxOrder),
      'minOrder': _orderInt(minOrder, fallback: 1),
      'isAvailable': settings.isActive && _stockInt() > 0,
      'isActive': settings.isActive,
      'is_active': settings.isActive,
      'price': price,
      'slashedPrice': slashedPrice,
      'totalSold': totalSold,
      'vendor_id': vendorId,
      'unitPerItem': unitPerItem,
      'favorites': favorites,
      'shop_name': shopName,
      'videos': videos,
      'lastEdited': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  int _stockInt() => int.tryParse(stock.trim()) ?? 0;

  int _orderInt(String raw, {int fallback = 0}) =>
      int.tryParse(raw.trim()) ?? fallback;

  ProductModel copyWith({
    String? name,
    String? image,
    List<String>? images,
    ProductSettings? settings,
    String? stock,
    String? price,
    String? slashedPrice,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      image: image ?? this.image,
      createdAt: createdAt,
      description: description,
      category: category,
      subcategory: subcategory,
      unit: unit,
      stock: stock ?? this.stock,
      maxOrder: maxOrder,
      price: price ?? this.price,
      slashedPrice: slashedPrice ?? this.slashedPrice,
      totalSold: totalSold,
      vendorId: vendorId,
      settings: settings ?? this.settings,
      lastEdited: lastEdited,
      unitPerItem: unitPerItem,
      favorites: favorites,
      shopName: shopName,
      images: images ?? this.images,
      videos: videos,
      specialCat: specialCat,
      isDeleted: isDeleted,
      isAvailable: isAvailable,
      stockStatus: stockStatus,
    );
  }
}
