import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/order_models.dart';

/// Streams realtime rider info + position from `delivery_boys/{id}`.
///
/// Profile fields (name, phone, image, vehicle) come from the parent doc.
/// Live coordinates prefer `delivery_boys/{id}/live/current` snapshots so
/// position updates propagate without polling (driver publishes every 5s).
class RiderLocationRepository {
  RiderLocationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<RiderLocation?> watch(String deliveryBoyId, {String? orderId}) {
    if (deliveryBoyId.isEmpty) {
      return Stream<RiderLocation?>.value(null);
    }

    final boyDoc = _firestore.collection('delivery_boys').doc(deliveryBoyId);
    final liveDoc = boyDoc.collection('live').doc('current');
    final orderLiveDoc = orderId != null && orderId.isNotEmpty
        ? _firestore.collection('orders').doc(orderId).collection('live').doc('rider')
        : null;

    return boyDoc.snapshots().asyncExpand((profileSnap) {
      if (!profileSnap.exists) {
        return Stream<RiderLocation?>.value(null);
      }
      final profile = profileSnap.data() ?? const <String, dynamic>{};

      if (orderLiveDoc == null) {
        return liveDoc.snapshots().map((liveSnap) {
          return _mergeRiderLocation(profile, liveSnap.data(), deliveryBoyId);
        });
      }

      return _mergeLiveStreams(
        profile: profile,
        riderId: deliveryBoyId,
        liveDoc: liveDoc,
        orderLiveDoc: orderLiveDoc,
      );
    });
  }

  Stream<RiderLocation?> _mergeLiveStreams({
    required Map<String, dynamic> profile,
    required String riderId,
    required DocumentReference<Map<String, dynamic>> liveDoc,
    required DocumentReference<Map<String, dynamic>> orderLiveDoc,
  }) {
    late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> riderSub;
    late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> orderSub;
    Map<String, dynamic>? riderLive;
    Map<String, dynamic>? orderLive;

    late StreamController<RiderLocation?> controller;

    void emit() {
      final coords = orderLive ?? riderLive;
      controller.add(_mergeRiderLocation(profile, coords, riderId));
    }

    controller = StreamController<RiderLocation?>(
      onListen: () {
        riderSub = liveDoc.snapshots().listen((snap) {
          riderLive = snap.data();
          emit();
        });
        orderSub = orderLiveDoc.snapshots().listen((snap) {
          orderLive = snap.exists ? snap.data() : null;
          emit();
        });
      },
      onCancel: () async {
        await riderSub.cancel();
        await orderSub.cancel();
      },
    );

    return controller.stream;
  }

  RiderLocation? _mergeRiderLocation(
    Map<String, dynamic> profile,
    Map<String, dynamic>? live,
    String riderId,
  ) {
    final merged = <String, dynamic>{
      ...profile,
      if (live != null) ...live,
    };
    return RiderLocation.fromMap(merged, riderId);
  }
}
