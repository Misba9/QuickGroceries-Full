import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String image;
  final Timestamp createdAt;
  final String description;
  final String category;
  final String? subcategory; // Optional subcategory
  final String unit;
  final String stock;
  final String maxOrder;
  final String price;
  final String slashedPrice;
  final int totalSold;
  final String vendorId;
  final bool isFlashSale;
  final bool isActive;
  final Timestamp lastEdited;
  final String unitPerItem;
  final List favorites;
  final String shopName;
  final bool isTodaysBest;
  final bool isMostSelling;
  final List<dynamic> images; // list of image URLs
  final List<dynamic> videos; // list of video URLs

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
    required this.price,
    required this.slashedPrice,
    required this.totalSold,
    required this.vendorId,
    required this.isFlashSale,
    required this.isActive,
    required this.lastEdited,
    required this.unitPerItem,
    required this.favorites,
    required this.shopName,
    required this.isMostSelling,
    required this.isTodaysBest,
    required this.images,
    required this.videos,
  });

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'],
      unit: data['unit'] ?? '',
      stock: data['stock'] ?? '',
      maxOrder: data['maxOrder'] ?? '',
      price: data['price'] ?? '',
      slashedPrice: data['slashedPrice'] ?? '',
      totalSold: data['totalSold'] ?? 0,
      vendorId: data['vendor_id'] ?? '',
      isFlashSale: data['is_flash_sale'] ?? false,
      isActive: data['is_active'] ?? true,
      lastEdited: data['lastEdited'] ?? Timestamp.now(),
      unitPerItem: data['unitPerItem'] ?? '',
      favorites: data['favorites'] ?? [],
      shopName: data['shop_name'] ?? 'Appmoc',
      isMostSelling: data['is_most_selling'] ?? false,
      isTodaysBest: data['is_todays_best'] ?? false,
      images: data['images'] ?? [],
      videos: data['videos'] ?? [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "name": name,
      "image": image,
      "createdAt": FieldValue.serverTimestamp(),
      "description": description,
      "category": category,
      if (subcategory != null) "subcategory": subcategory,
      "unit": unit,
      "stock": stock,
      "maxOrder": maxOrder,
      "price": price,
      "slashedPrice": slashedPrice,
      "totalSold": totalSold,
      "vendor_id": vendorId,
      "is_flash_sale": isFlashSale,
      "is_active": isActive,
      "lastEdited": FieldValue.serverTimestamp(),
      "unitPerItem": unitPerItem,
      "favorites": favorites,
      "shop_name": shopName,
      "is_most_selling": isMostSelling,
      "is_todays_best": isTodaysBest,
      "images": images,
      "videos": videos,
    };
  }
}
