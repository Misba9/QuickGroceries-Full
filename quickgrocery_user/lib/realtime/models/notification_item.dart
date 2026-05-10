import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification fanned out by Cloud Functions to the user's
/// per-uid feed: `notifications/{uid}/items/{notifId}`.
///
/// **Schema (writer = Cloud Function or Admin tooling):**
/// ```json
/// {
///   "title": "Order accepted",
///   "body":  "Asha is on the way with your order.",
///   "type":  "order" | "offer" | "delivery" | "system",
///   "targetId": "<orderId | productId | offerId | url>",
///   "deepLink": "/orders/abc123",     // optional
///   "imageUrl": "...",                // optional
///   "read": false,
///   "createdAt": Timestamp
/// }
/// ```
enum NotificationKind { order, offer, delivery, system, unknown }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.targetId,
    required this.deepLink,
    required this.imageUrl,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final NotificationKind kind;
  final String targetId;
  final String deepLink;
  final String imageUrl;
  final bool read;
  final DateTime? createdAt;

  factory NotificationItem.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return NotificationItem(
      id: id,
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      kind: _kindOf(data['type']?.toString()),
      targetId: data['targetId']?.toString() ?? '',
      deepLink: data['deepLink']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      read: data['read'] as bool? ?? false,
      createdAt: _asDateTime(data['createdAt']),
    );
  }
}

NotificationKind _kindOf(String? s) {
  switch (s) {
    case 'order':
      return NotificationKind.order;
    case 'offer':
      return NotificationKind.offer;
    case 'delivery':
      return NotificationKind.delivery;
    case 'system':
      return NotificationKind.system;
    default:
      return NotificationKind.unknown;
  }
}

DateTime? _asDateTime(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return DateTime.tryParse(v.toString());
}
