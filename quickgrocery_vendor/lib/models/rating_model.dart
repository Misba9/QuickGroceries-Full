import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String productId;
  final String productName;
  final double rating;
  final String review;
  final String userName;
  final String userId;
  final String orderId;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final bool verifiedPurchase;

  RatingModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.rating,
    required this.review,
    required this.userName,
    required this.userId,
    this.orderId = '',
    required this.createdAt,
    required this.updatedAt,
    this.verifiedPurchase = false,
  });

  factory RatingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RatingModel(
      id: id,
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      review: (data['review_text'] ?? data['review'] ?? '').toString(),
      userName: data['user_name'] ?? data['customer_name'] ?? '',
      userId: data['user_id'] ?? '',
      orderId: data['order_id']?.toString() ?? '',
      createdAt: data['created_at'] ?? Timestamp.now(),
      updatedAt: data['updated_at'] ?? Timestamp.now(),
      verifiedPurchase: data['verified_purchase'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'product_id': productId,
      'product_name': productName,
      'rating': rating,
      'review': review,
      'user_name': userName,
      'user_id': userId,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
