import 'package:cloud_firestore/cloud_firestore.dart';

/// Product line inside a combo (`combo_offers` collection).
class ComboProductLine {
  const ComboProductLine({
    required this.productId,
    required this.name,
    required this.image,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String name;
  final String image;
  final int quantity;
  final double unitPrice;

  factory ComboProductLine.fromMap(Map<String, dynamic> m) => ComboProductLine(
        productId: (m['productId'] ?? m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        image: (m['image'] ?? '').toString(),
        quantity: _int(m['quantity'], 1),
        unitPrice: _dbl(m['unitPrice'] ?? m['price']),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'image': image,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  static int _int(dynamic v, [int fb = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fb;
  }

  static double _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}

/// Combo bundle offer — admin or vendor created.
class ComboOfferModel {
  const ComboOfferModel({
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
    this.stock = 0,
    this.isActive = true,
    this.isFlashSale = false,
    this.isTrending = false,
    this.startsAt,
    this.endsAt,
    this.priority = 10,
    this.viewCount = 0,
    this.orderCount = 0,
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
  final int viewCount;
  final int orderCount;
  final String createdBy;

  factory ComboOfferModel.fromFirestore(Map<String, dynamic> data, String id) {
    final linesRaw = data['products'] ?? data['productItems'];
    final lines = <ComboProductLine>[];
    if (linesRaw is List) {
      for (final e in linesRaw) {
        if (e is Map) {
          lines.add(ComboProductLine.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }
    final idsRaw = data['productIds'];
    final ids = idsRaw is List
        ? idsRaw.map((e) => e.toString()).toList()
        : lines.map((p) => p.productId).toList();

    final original = _dbl(data['originalTotalPrice'] ?? data['originalPrice']);
    final combo = _dbl(data['comboPrice'] ?? data['discountedPrice']);
    var pct = _int(data['discountPercent'] ?? data['offerPercent']);
    if (pct <= 0 && original > 0 && combo > 0) {
      pct = (((original - combo) / original) * 100).round();
    }

    return ComboOfferModel(
      id: (data['id'] ?? id).toString(),
      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      image: (data['image'] ?? data['bannerImage'] ?? '').toString(),
      productIds: ids,
      products: lines,
      originalTotalPrice: original,
      comboPrice: combo,
      discountPercent: pct,
      vendorId: (data['vendorId'] ?? '').toString(),
      vendorName: (data['vendorName'] ?? data['shopName'] ?? '').toString(),
      stock: _int(data['stock'] ?? data['stockAvailable']),
      isActive: data['isActive'] as bool? ?? true,
      isFlashSale: data['isFlashSale'] as bool? ?? false,
      isTrending: data['isTrending'] as bool? ?? false,
      startsAt: _date(data['startsAt'] ?? data['startDate']),
      endsAt: _date(data['endsAt'] ?? data['endDate']),
      priority: _int(data['priority'], 10),
      viewCount: _int(data['viewCount']),
      orderCount: _int(data['orderCount']),
      createdBy: (data['createdBy'] ?? 'admin').toString(),
    );
  }

  bool get isScheduleOk {
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  bool get isAvailableNow => isActive && isScheduleOk && stock > 0;

  bool get hasLimitedStock => stock > 0 && stock <= 20;

  Duration? get timeRemaining {
    if (endsAt == null) return null;
    final d = endsAt!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  double get savingsAmount =>
      (originalTotalPrice - comboPrice).clamp(0, double.infinity);

  static double _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int _int(dynamic v, [int fb = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fb;
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
