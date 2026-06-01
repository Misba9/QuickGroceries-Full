import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;

class DeliveryNotificationStore {
  DeliveryNotificationStore._();

  static CollectionReference<Map<String, dynamic>> _col(String riderId) =>
      FirebaseFirestore.instance
          .collection('delivery_boys')
          .doc(riderId)
          .collection('notifications');

  static Stream<List<DeliveryStoredNotification>> watch(String riderId) {
    return _col(riderId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => DeliveryStoredNotification.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  static Future<void> markAllRead(String riderId) async {
    final snap = await _col(riderId).where('read', isEqualTo: false).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}

class DeliveryStoredNotification {
  const DeliveryStoredNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.orderId,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String orderId;
  final bool read;
  final DateTime? createdAt;

  factory DeliveryStoredNotification.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime? createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) createdAt = raw.toDate();

    return DeliveryStoredNotification(
      id: id,
      type: (data['type'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? data['message'] ?? '').toString(),
      orderId: (data['orderId'] ?? '').toString(),
      read: data['read'] == true,
      createdAt: createdAt,
    );
  }

  IconData get icon {
    switch (type) {
      case 'order_cancelled':
        return Icons.cancel;
      case 'delivery_assigned':
      case 'driver_assigned':
        return Icons.delivery_dining;
      default:
        return Icons.notifications;
    }
  }
}
