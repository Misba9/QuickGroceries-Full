import 'package:cloud_firestore/cloud_firestore.dart';

/// Realtime view of the `orders` collection for the signed-in customer.
///
/// Order status is written by:
/// * **User App**     — `isCancelled` (when customer cancels)
/// * **Admin Panel**  — `order_status`, `confrimTime`, `deliveryBoyId`
/// * **Vendor App**   — `pickedTime`, `driverShop`
/// * **Delivery App** — `onTheWayTime`, `deliveredTime`, `lat`, `lng`,
///                     `current_location`
///
/// Anyone of those writes triggers a snapshot tick here, so the User App
/// reflects the change without a manual refresh.
class RealtimeOrderService {
  RealtimeOrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'orders';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserOrders(String uid) {
    // Server-side filter on `uuid` so we don't pull the whole collection.
    // We *don't* `orderBy('created_date')` here because that field is
    // sometimes a string-ISO and sometimes a Timestamp; the repository
    // sorts after parsing for consistency.
    return _ref.where('uuid', isEqualTo: uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOrder(String id) {
    return _ref.doc(id).snapshots();
  }
}
