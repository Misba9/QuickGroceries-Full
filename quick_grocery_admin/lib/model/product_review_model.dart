import 'package:cloud_firestore/cloud_firestore.dart';

class ProductReviewModel {
  ProductReviewModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.vendorId,
    required this.rating,
    required this.review,
    required this.userName,
    required this.userId,
    required this.status,
    required this.verifiedPurchase,
    required this.adminApproved,
    required this.hidden,
    required this.isFeatured,
    required this.helpfulCount,
    required this.reportedCount,
    required this.reviewImages,
    required this.createdAt,
    this.vendorReply = '',
  });

  final String id;
  final String productId;
  final String productName;
  final String vendorId;
  final double rating;
  final String review;
  final String userName;
  final String userId;
  final String status;
  final bool verifiedPurchase;
  final bool adminApproved;
  final bool hidden;
  final bool isFeatured;
  final int helpfulCount;
  final int reportedCount;
  final List<String> reviewImages;
  final DateTime? createdAt;
  final String vendorReply;

  factory ProductReviewModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    DateTime? created;
    final c = m['created_at'];
    if (c is Timestamp) created = c.toDate();
    final reply = m['vendor_reply'];
    String replyText = '';
    if (reply is Map) replyText = (reply['text'] ?? '').toString();

    return ProductReviewModel(
      id: doc.id,
      productId: (m['product_id'] ?? '').toString(),
      productName: (m['product_name'] ?? '').toString(),
      vendorId: (m['vendor_id'] ?? '').toString(),
      rating: (m['rating'] as num?)?.toDouble() ?? 0,
      review: (m['review_text'] ?? m['review'] ?? '').toString(),
      userName: (m['user_name'] ?? '').toString(),
      userId: (m['user_id'] ?? '').toString(),
      status: (m['status'] ?? 'approved').toString(),
      verifiedPurchase: m['verified_purchase'] == true,
      adminApproved: m['admin_approved'] != false,
      hidden: m['hidden'] == true,
      isFeatured: m['is_featured'] == true,
      helpfulCount: (m['helpful_count'] as num?)?.toInt() ?? 0,
      reportedCount: (m['reported_count'] as num?)?.toInt() ?? 0,
      reviewImages: List<String>.from(m['review_images'] ?? const []),
      createdAt: created,
      vendorReply: replyText,
    );
  }
}
