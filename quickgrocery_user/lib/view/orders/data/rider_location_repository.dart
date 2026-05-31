import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/order_models.dart';

/// Streams realtime rider info + position from `delivery_boys/{id}`.
///
/// Profile fields (name, phone, image, vehicle) come from the parent doc.
/// Live coordinates prefer `delivery_boys/{id}/live/current` snapshots so
/// position updates propagate without polling.
class RiderLocationRepository {
  RiderLocationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<RiderLocation?> watch(String deliveryBoyId) {
    if (deliveryBoyId.isEmpty) {
      return Stream<RiderLocation?>.value(null);
    }

    final boyDoc = _firestore.collection('delivery_boys').doc(deliveryBoyId);
    final liveDoc = boyDoc.collection('live').doc('current');

    return boyDoc.snapshots().asyncExpand((profileSnap) {
      if (!profileSnap.exists) {
        return Stream<RiderLocation?>.value(null);
      }
      final profile = profileSnap.data() ?? const <String, dynamic>{};

      return liveDoc.snapshots().map((liveSnap) {
        final merged = <String, dynamic>{
          ...profile,
          if (liveSnap.exists) ...(liveSnap.data() ?? const {}),
        };
        return RiderLocation.fromMap(merged, deliveryBoyId);
      });
    });
  }
}
