import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryRatings {
  const CategoryRatings({
    required this.productQuality,
    required this.freshness,
    required this.packaging,
    required this.deliveryExperience,
    required this.valueForMoney,
  });

  final double productQuality;
  final double freshness;
  final double packaging;
  final double deliveryExperience;
  final double valueForMoney;

  factory CategoryRatings.fromMap(Map<String, dynamic>? m) {
    if (m == null) {
      return const CategoryRatings(
        productQuality: 5,
        freshness: 5,
        packaging: 5,
        deliveryExperience: 5,
        valueForMoney: 5,
      );
    }
    double r(dynamic v) {
      final n = (v as num?)?.toDouble() ?? 5;
      return n.clamp(1.0, 5.0);
    }
    return CategoryRatings(
      productQuality: r(m['product_quality']),
      freshness: r(m['freshness']),
      packaging: r(m['packaging']),
      deliveryExperience: r(m['delivery_experience']),
      valueForMoney: r(m['value_for_money']),
    );
  }

  Map<String, dynamic> toMap() => {
        'product_quality': productQuality,
        'freshness': freshness,
        'packaging': packaging,
        'delivery_experience': deliveryExperience,
        'value_for_money': valueForMoney,
      };
}

class VendorReply {
  const VendorReply({required this.text, this.repliedAt});

  final String text;
  final DateTime? repliedAt;

  factory VendorReply.fromMap(dynamic raw) {
    if (raw is! Map) return const VendorReply(text: '');
    final m = Map<String, dynamic>.from(raw);
    DateTime? at;
    final ts = m['repliedAt'];
    if (ts is Timestamp) at = ts.toDate();
    return VendorReply(text: (m['text'] ?? '').toString(), repliedAt: at);
  }
}

class RatingModel {
  final String id;
  final String productId;
  final String productName;
  final String vendorId;
  final String orderId;
  final double rating;
  final String review;
  final String userName;
  final String userId;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final List<String> reviewImages;
  final String reviewVideo;
  final bool verifiedPurchase;
  final bool adminApproved;
  final String status;
  final bool hidden;
  final bool isFeatured;
  final int helpfulCount;
  final int reportedCount;
  final CategoryRatings categoryRatings;
  final VendorReply vendorReply;

  RatingModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.vendorId = '',
    this.orderId = '',
    required this.rating,
    required this.review,
    required this.userName,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.reviewImages = const [],
    this.reviewVideo = '',
    this.verifiedPurchase = false,
    this.adminApproved = true,
    this.status = 'approved',
    this.hidden = false,
    this.isFeatured = false,
    this.helpfulCount = 0,
    this.reportedCount = 0,
    this.categoryRatings = const CategoryRatings(
      productQuality: 5,
      freshness: 5,
      packaging: 5,
      deliveryExperience: 5,
      valueForMoney: 5,
    ),
    this.vendorReply = const VendorReply(text: ''),
  });

  bool get isPublicVisible {
    if (hidden || status == 'hidden' || status == 'rejected') return false;
    if (adminApproved == false) return false;
    if (status == 'pending' || status == 'rejected') return false;
    return true;
  }

  bool get canEdit {
    final age = DateTime.now().difference(createdAt.toDate());
    return userId.isNotEmpty && age.inHours < 24;
  }

  factory RatingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RatingModel(
      id: id,
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      vendorId: (data['vendor_id'] ?? '').toString(),
      orderId: (data['order_id'] ?? '').toString(),
      rating: (data['rating'] ?? data['overall_rating'] ?? 0.0).toDouble(),
      review: (data['review_text'] ?? data['review'] ?? '').toString(),
      userName: data['user_name'] ?? '',
      userId: data['user_id'] ?? '',
      createdAt: data['created_at'] is Timestamp
          ? data['created_at'] as Timestamp
          : Timestamp.now(),
      updatedAt: data['updated_at'] is Timestamp
          ? data['updated_at'] as Timestamp
          : Timestamp.now(),
      reviewImages: List<String>.from(data['review_images'] ?? const []),
      reviewVideo: (data['review_video'] ?? '').toString(),
      verifiedPurchase: data['verified_purchase'] == true,
      adminApproved: data['admin_approved'] != false,
      status: (data['status'] ?? 'approved').toString(),
      hidden: data['hidden'] == true,
      isFeatured: data['is_featured'] == true,
      helpfulCount: (data['helpful_count'] as num?)?.toInt() ?? 0,
      reportedCount: (data['reported_count'] as num?)?.toInt() ?? 0,
      categoryRatings: CategoryRatings.fromMap(
        data['category_ratings'] as Map<String, dynamic>?,
      ),
      vendorReply: VendorReply.fromMap(data['vendor_reply']),
    );
  }
}
