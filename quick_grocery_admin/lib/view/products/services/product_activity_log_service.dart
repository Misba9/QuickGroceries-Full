import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Audit trail for admin product lifecycle actions.
abstract final class ProductActivityLogService {
  static const collection = 'product_activity_logs';

  static const actionMarkedOutOfStock = 'product_marked_out_of_stock';
  static const actionRestoredInStock = 'product_restored_in_stock';
  static const actionDeleted = 'product_deleted';

  static Future<void> log({
    required String actionType,
    required String productId,
    String? productName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim();
    final email = user?.email?.trim();
    final actorName = (name != null && name.isNotEmpty)
        ? name
        : (email != null && email.isNotEmpty ? email : 'Admin');

    await FirebaseFirestore.instance.collection(collection).add({
      'actionType': actionType,
      'action': _displayAction(actionType),
      'productId': productId,
      'productName': productName ?? '',
      'actorType': 'admin',
      'actorName': actorName,
      'actorUid': user?.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static String _displayAction(String type) {
    switch (type) {
      case actionMarkedOutOfStock:
        return 'Product Marked Out of Stock';
      case actionRestoredInStock:
        return 'Product Restored In Stock';
      case actionDeleted:
        return 'Product Deleted';
      default:
        return type;
    }
  }
}
