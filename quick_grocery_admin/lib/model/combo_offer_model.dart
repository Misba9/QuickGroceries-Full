import 'package:cloud_firestore/cloud_firestore.dart';

class ComboProductLine {
  const ComboProductLine({
    required this.productId,
    required this.name,
    required this.image,
    this.quantity = 1,
    required this.unitPrice,
  });

  final String productId;
  final String name;
  final String image;
  final int quantity;
  final double unitPrice;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'image': image,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory ComboProductLine.fromMap(Map<String, dynamic> m) => ComboProductLine(
        productId: (m['productId'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        image: (m['image'] ?? '').toString(),
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
      );
}

class ComboOfferModel {
  ComboOfferModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.image = '',
    required this.productIds,
    required this.products,
    required this.originalTotalPrice,
    required this.comboPrice,
    required this.discountPercent,
    this.vendorId = '',
    this.vendorName = '',
    this.stock = 50,
    this.isActive = true,
    this.isFlashSale = false,
    this.isTrending = false,
    this.startsAt,
    this.endsAt,
    this.priority = 10,
    this.createdBy = 'admin',
  });

  final String id;
  final String title;
  final String subtitle;
  final String image;
  final List<String> productIds;
  final List<ComboProductLine> products;
  final double originalTotalPrice;
  final double comboPrice;
  final int discountPercent;
  final String vendorId;
  final String vendorName;
  final int stock;
  final bool isActive;
  final bool isFlashSale;
  final bool isTrending;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int priority;
  final String createdBy;

  factory ComboOfferModel.fromFirestore(Map<String, dynamic> data, String id) {
    final lines = <ComboProductLine>[];
    final raw = data['products'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          lines.add(ComboProductLine.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }
    final ids = (data['productIds'] as List?)?.map((e) => e.toString()).toList() ??
        lines.map((p) => p.productId).toList();
    final original = (data['originalTotalPrice'] as num?)?.toDouble() ?? 0;
    final combo = (data['comboPrice'] as num?)?.toDouble() ?? 0;
    var pct = (data['discountPercent'] as num?)?.toInt() ?? 0;
    if (pct <= 0 && original > 0) {
      pct = (((original - combo) / original) * 100).round();
    }
    return ComboOfferModel(
      id: id,
      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      image: (data['image'] ?? '').toString(),
      productIds: ids,
      products: lines,
      originalTotalPrice: original,
      comboPrice: combo,
      discountPercent: pct,
      vendorId: (data['vendorId'] ?? '').toString(),
      vendorName: (data['vendorName'] ?? '').toString(),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      isFlashSale: data['isFlashSale'] as bool? ?? false,
      isTrending: data['isTrending'] as bool? ?? false,
      startsAt: _date(data['startsAt']),
      endsAt: _date(data['endsAt']),
      priority: (data['priority'] as num?)?.toInt() ?? 10,
      createdBy: (data['createdBy'] ?? 'admin').toString(),
    );
  }

  static DateTime? _date(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v?.toString() ?? '');
  }
}
