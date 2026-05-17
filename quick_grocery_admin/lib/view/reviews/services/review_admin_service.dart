import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_admin/model/product_review_model.dart';

enum ReviewAdminFilter {
  all,
  pending,
  lowRating,
  highRating,
  reported,
}

class ReviewAdminService {
  ReviewAdminService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<ProductReviewModel>> watchReviews() {
    return _db.collection('ratings').snapshots().map((snap) {
      final list = snap.docs.map(ProductReviewModel.fromDoc).toList();
      list.sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  List<ProductReviewModel> filter(
    List<ProductReviewModel> list, {
    required ReviewAdminFilter f,
    String search = '',
    String? vendorId,
    String? productId,
  }) {
    var out = list;
    if (vendorId != null && vendorId.isNotEmpty) {
      out = out.where((r) => r.vendorId == vendorId).toList();
    }
    if (productId != null && productId.isNotEmpty) {
      out = out.where((r) => r.productId == productId).toList();
    }
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out
          .where(
            (r) =>
                r.productName.toLowerCase().contains(q) ||
                r.userName.toLowerCase().contains(q) ||
                r.review.toLowerCase().contains(q),
          )
          .toList();
    }
    switch (f) {
      case ReviewAdminFilter.pending:
        out = out.where((r) => r.status == 'pending').toList();
        break;
      case ReviewAdminFilter.lowRating:
        out = out.where((r) => r.rating <= 2).toList();
        break;
      case ReviewAdminFilter.highRating:
        out = out.where((r) => r.rating >= 4).toList();
        break;
      case ReviewAdminFilter.reported:
        out = out.where((r) => r.reportedCount > 0).toList();
        break;
      case ReviewAdminFilter.all:
        break;
    }
    return out;
  }

  Future<void> updateProductQuality({
    required String productId,
    int? qualityOverride,
    bool? featuredQuality,
    bool? premiumBadge,
    bool? freshTag,
    bool? trendingTag,
  }) async {
    final data = <String, dynamic>{};
    if (qualityOverride != null) data['quality_score_override'] = qualityOverride;
    if (featuredQuality != null) data['featured_quality_badge'] = featuredQuality;
    if (premiumBadge != null) data['premium_badge'] = premiumBadge;
    if (freshTag != null) data['fresh_product_tag'] = freshTag;
    if (trendingTag != null) data['isTrending'] = trendingTag;
    await _db.collection('products').doc(productId).set(data, SetOptions(merge: true));
  }

  Map<String, dynamic> analytics(List<ProductReviewModel> reviews) {
    if (reviews.isEmpty) {
      return {
        'avgRating': 0.0,
        'total': 0,
        'pending': 0,
        'reported': 0,
        'satisfaction': 0.0,
      };
    }
    final approved = reviews.where((r) => r.status == 'approved' && !r.hidden);
    final sum = approved.fold<double>(0, (a, r) => a + r.rating);
    final count = approved.length;
    final avg = count > 0 ? sum / count : 0.0;
    return {
      'avgRating': avg,
      'total': reviews.length,
      'pending': reviews.where((r) => r.status == 'pending').length,
      'reported': reviews.where((r) => r.reportedCount > 0).length,
      'satisfaction': count > 0 ? (avg / 5) * 100 : 0.0,
    };
  }

  List<ProductRatingStat> productStats(List<ProductReviewModel> reviews) {
    final map = <String, _Agg>{};
    for (final r in reviews) {
      if (r.status != 'approved' || r.hidden) continue;
      final key = r.productId.isNotEmpty ? r.productId : r.productName;
      map.putIfAbsent(key, () => _Agg(r.productName));
      map[key]!.add(r.rating);
    }
    return map.entries
        .map(
          (e) => ProductRatingStat(
            productId: e.key,
            productName: e.value.name,
            average: e.value.avg,
            count: e.value.count,
          ),
        )
        .toList();
  }

  List<VendorRatingStat> vendorStats(List<ProductReviewModel> reviews) {
    final map = <String, _Agg>{};
    for (final r in reviews) {
      if (r.status != 'approved' || r.hidden || r.vendorId.isEmpty) continue;
      map.putIfAbsent(r.vendorId, () => _Agg(r.vendorId));
      map[r.vendorId]!.add(r.rating);
    }
    return map.entries
        .map(
          (e) => VendorRatingStat(
            vendorId: e.key,
            average: e.value.avg,
            count: e.value.count,
          ),
        )
        .toList();
  }
}

class ProductRatingStat {
  const ProductRatingStat({
    required this.productId,
    required this.productName,
    required this.average,
    required this.count,
  });

  final String productId;
  final String productName;
  final double average;
  final int count;
}

class VendorRatingStat {
  const VendorRatingStat({
    required this.vendorId,
    required this.average,
    required this.count,
  });

  final String vendorId;
  final double average;
  final int count;
}

class _Agg {
  _Agg(this.name);
  final String name;
  double _sum = 0;
  int count = 0;

  void add(double rating) {
    _sum += rating;
    count++;
  }

  double get avg => count > 0 ? _sum / count : 0;
}
