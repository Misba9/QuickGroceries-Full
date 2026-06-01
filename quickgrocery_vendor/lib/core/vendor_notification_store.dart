import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;

/// Persists vendor notifications in Firestore for the Notification Center.
class VendorNotificationStore {
  VendorNotificationStore._();

  static CollectionReference<Map<String, dynamic>> _col(String vendorId) =>
      FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('notifications');

  static Stream<List<VendorStoredNotification>> watch(String vendorId) {
    return _col(vendorId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => VendorStoredNotification.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  static Future<void> writeLocal({
    required String vendorId,
    required String type,
    required String title,
    required String body,
    String orderId = '',
    String customerName = '',
    double amount = 0,
  }) async {
    try {
      await _col(vendorId).add({
        'type': type,
        'title': title,
        'body': body,
        'orderId': orderId,
        'customerName': customerName,
        'amount': amount,
        'read': false,
        'source': 'vendor_app',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VendorNotify] local notification write failed: $e');
      }
    }
  }

  static Future<void> markRead(String vendorId, String notificationId) async {
    await _col(vendorId).doc(notificationId).update({'read': true});
  }

  static Future<void> markAllRead(String vendorId) async {
    final snap = await _col(vendorId).where('read', isEqualTo: false).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}

class VendorStoredNotification {
  const VendorStoredNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.orderId,
    required this.customerName,
    required this.amount,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String orderId;
  final String customerName;
  final double amount;
  final bool read;
  final DateTime? createdAt;

  factory VendorStoredNotification.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime? createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) createdAt = raw.toDate();

    return VendorStoredNotification(
      id: id,
      type: (data['type'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? data['message'] ?? '').toString(),
      orderId: (data['orderId'] ?? '').toString(),
      customerName: (data['customerName'] ?? '').toString(),
      amount: _toDouble(data['amount']),
      read: data['read'] == true,
      createdAt: createdAt,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  IconData get icon {
    switch (type) {
      case 'new_order':
        return Icons.shopping_cart;
      case 'rider_assigned':
      case 'driver_assigned':
        return Icons.delivery_dining;
      case 'order_cancelled':
        return Icons.cancel;
      case 'payment_released':
      case 'payment_received':
        return Icons.payments;
      case 'order_delivered':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }
}
