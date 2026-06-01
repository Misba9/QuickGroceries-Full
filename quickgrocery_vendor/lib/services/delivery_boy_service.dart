import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/delivery_boy_model.dart';

/// Rider row for assign-driver UI (profile + live workload).
class RiderOption {
  const RiderOption({
    required this.rider,
    required this.activeOrders,
    required this.isOnline,
  });

  final DeliveryPersonModel rider;
  final int activeOrders;
  final bool isOnline;

  String get displayName =>
      '${rider.firstName} ${rider.lastName}'.trim().isEmpty
          ? 'Rider'
          : '${rider.firstName} ${rider.lastName}'.trim();

  String get statusLabel {
    if (!rider.isActive) return 'Inactive';
    return isOnline ? 'Online' : 'Offline';
  }
}

/// Live delivery partners from Firestore `delivery_boys`.
class DeliveryBoyService {
  DeliveryBoyService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<DeliveryPersonModel>> watchDeliveryBoys() {
    return _db.collection('delivery_boys').snapshots().map((snap) {
      return snap.docs
          .map((d) => DeliveryPersonModel.fromFirestore(d.data(), d.id))
          .toList()
        ..sort((a, b) => a.firstName.compareTo(b.firstName));
    });
  }

  /// Active + online riders with live active-order counts.
  Stream<List<RiderOption>> watchAssignableRidersLive() {
    return _db.collection('delivery_boys').snapshots().asyncMap((snap) async {
      final ordersSnap = await _db
          .collection('orders')
          .where('isDelivered', isEqualTo: false)
          .limit(400)
          .get();
      final activeByRider = <String, int>{};
      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        if (data['isCancelled'] == true) continue;
        final rid =
            data['deliveryBoyId']?.toString() ??
            data['delivery_boy_id']?.toString() ??
            '';
        if (rid.isEmpty) continue;
        activeByRider[rid] = (activeByRider[rid] ?? 0) + 1;
      }

      final options = <RiderOption>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final rider = DeliveryPersonModel.fromFirestore(data, doc.id);
        final isOnline =
            data['isOnline'] == true || data['online_status'] == true;
        if (!rider.isActive) continue;
        options.add(
          RiderOption(
            rider: rider,
            activeOrders: activeByRider[rider.id] ?? 0,
            isOnline: isOnline,
          ),
        );
      }
      options.sort((a, b) {
        if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
        return a.activeOrders.compareTo(b.activeOrders);
      });
      return options;
    });
  }
}
