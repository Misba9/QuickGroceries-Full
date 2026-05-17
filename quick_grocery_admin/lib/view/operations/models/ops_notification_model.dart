import 'package:cloud_firestore/cloud_firestore.dart';

enum OpsNotificationCategory {
  orders,
  users,
  vendors,
  payments,
  stock,
  delivery,
  system,
  security,
  promotions,
}

enum OpsNotificationPriority { low, normal, high, urgent }

OpsNotificationCategory categoryFromString(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'users':
      return OpsNotificationCategory.users;
    case 'vendors':
      return OpsNotificationCategory.vendors;
    case 'payments':
      return OpsNotificationCategory.payments;
    case 'stock':
      return OpsNotificationCategory.stock;
    case 'delivery':
      return OpsNotificationCategory.delivery;
    case 'system':
      return OpsNotificationCategory.system;
    case 'security':
      return OpsNotificationCategory.security;
    case 'promotions':
      return OpsNotificationCategory.promotions;
    default:
      return OpsNotificationCategory.orders;
  }
}

OpsNotificationPriority priorityFromString(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'low':
      return OpsNotificationPriority.low;
    case 'high':
      return OpsNotificationPriority.high;
    case 'urgent':
      return OpsNotificationPriority.urgent;
    default:
      return OpsNotificationPriority.normal;
  }
}

class OpsNotificationModel {
  OpsNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.read,
    required this.createdAt,
    this.soundAlert = false,
    this.soundType = 'orders',
    this.priority = OpsNotificationPriority.normal,
    this.sticky = false,
    this.metadata = const {},
    this.targetAdminId = '',
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final OpsNotificationCategory category;
  final bool read;
  final bool soundAlert;
  final String soundType;
  final OpsNotificationPriority priority;
  final bool sticky;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;
  final String targetAdminId;

  bool get isUrgent => priority == OpsNotificationPriority.urgent;

  String? get orderId => metadata['orderId']?.toString();

  factory OpsNotificationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final meta = d['metadata'];
    return OpsNotificationModel(
      id: doc.id,
      title: (d['notification_title'] ?? d['title'])?.toString() ?? '',
      message: (d['notification_message'] ?? d['message'])?.toString() ?? '',
      type: (d['notification_type'] ?? d['type'])?.toString() ?? '',
      category: categoryFromString(d['category']?.toString()),
      read: d['is_read'] == true || d['read'] == true,
      soundAlert: d['soundAlert'] == true,
      soundType: d['sound_type']?.toString() ?? 'orders',
      priority: priorityFromString(
        d['priority_level']?.toString(),
      ),
      sticky: d['sticky'] == true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
          (d['created_at'] as Timestamp?)?.toDate(),
      metadata: meta is Map
          ? Map<String, dynamic>.from(meta as Map)
          : const {},
      targetAdminId: d['targetAdminId']?.toString() ?? '',
    );
  }
}
