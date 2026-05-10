import 'package:cloud_firestore/cloud_firestore.dart';

/// Realtime stream of a delivery rider's profile + live telemetry.
///
/// Reads `delivery_boys/{deliveryBoyId}` — the same doc the existing
/// `TrackingService.getDeliveryBoyById` fetched once. Now it's a stream,
/// so map markers, ETA chips, and rider info animate as the Delivery
/// App pushes updates.
class RealtimeDeliveryService {
  RealtimeDeliveryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'delivery_boys';

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRider(String id) {
    return _firestore.collection(_collection).doc(id).snapshots();
  }
}
