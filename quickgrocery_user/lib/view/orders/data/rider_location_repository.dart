import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/order_models.dart';

/// Streams realtime rider info + position from `delivery_boys/{id}`.
///
/// Two shapes are supported (in priority order) so this works with both
/// the legacy schema and any future "live location subdoc" schema:
///
///  1. Modern (preferred):
///     `delivery_boys/{id}/live/current` document with
///       { lat, lng, heading, lastUpdated, ... }
///     plus the parent doc for static profile (name/phone/image).
///
///  2. Legacy / simple:
///     `delivery_boys/{id}` document with `lat` + `lng` directly on it.
///
/// We try (1) first; if that doc never appears, we fall back to (2).
class RiderLocationRepository {
  RiderLocationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<RiderLocation?> watch(String deliveryBoyId) {
    if (deliveryBoyId.isEmpty) {
      return Stream<RiderLocation?>.value(null);
    }

    final boyDoc = _firestore.collection('delivery_boys').doc(deliveryBoyId);
    final liveDoc = boyDoc.collection('live').doc('current');

    return boyDoc.snapshots().asyncMap((profileSnap) async {
      if (!profileSnap.exists) return null;
      final profile = profileSnap.data() ?? const <String, dynamic>{};

      try {
        final liveSnap = await liveDoc.get();
        if (liveSnap.exists) {
          final liveData = liveSnap.data() ?? const {};
          final merged = <String, dynamic>{
            ...profile,
            ...liveData,
          };
          return RiderLocation.fromMap(merged, deliveryBoyId);
        }
      } catch (_) {
        // ignore — fall back to profile fields
      }
      return RiderLocation.fromMap(profile, deliveryBoyId);
    });
  }
}
