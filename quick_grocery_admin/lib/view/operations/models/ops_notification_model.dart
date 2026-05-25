import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show IconData, Icons;
import 'package:quick_grocery_admin/core/utils/duration_format.dart';

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
    this.sourceApp = 'system',
    this.target = 'admin',
    this.soundAlert = false,
    this.soundType = 'orders',
    this.priority = OpsNotificationPriority.normal,
    this.sticky = false,
    this.metadata = const {},
    this.targetAdminId = '',
    this.collectionName = 'notifications',
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final OpsNotificationCategory category;
  final bool read;
  final String sourceApp;
  final String target;
  final bool soundAlert;
  final String soundType;
  final OpsNotificationPriority priority;
  final bool sticky;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;
  final String targetAdminId;
  final String collectionName;

  bool get isUrgent => priority == OpsNotificationPriority.urgent;

  String? get orderId =>
      metadata['orderId']?.toString() ?? metadata['order_id']?.toString();

  String? get requestId =>
      metadata['requestId']?.toString() ??
      metadata['vendorRequestId']?.toString();

  String? get userId =>
      metadata['userId']?.toString() ?? metadata['uid']?.toString();

  String? get deliveryBoyId =>
      metadata['deliveryBoyId']?.toString() ??
      metadata['riderId']?.toString();

  factory OpsNotificationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String collectionName = 'notifications',
  }) {
    final d = doc.data() ?? {};
    final dataField = d['data'];
    final metaField = d['metadata'];
    Map<String, dynamic> meta = {};
    if (dataField is Map<String, dynamic>) {
      meta = Map<String, dynamic>.from(dataField);
    } else if (metaField is Map<String, dynamic>) {
      meta = Map<String, dynamic>.from(metaField);
    }

    return OpsNotificationModel(
      id: doc.id,
      title: (d['notification_title'] ?? d['title'])?.toString() ?? '',
      message: (d['notification_message'] ?? d['message'])?.toString() ?? '',
      type: (d['notification_type'] ?? d['type'])?.toString() ?? '',
      category: categoryFromString(d['category']?.toString()),
      read: d['isRead'] == true ||
          d['is_read'] == true ||
          d['read'] == true,
      sourceApp: d['sourceApp']?.toString() ?? 'system',
      target: d['target']?.toString() ?? 'admin',
      soundAlert: d['soundAlert'] == true,
      soundType: d['sound_type']?.toString() ?? 'orders',
      priority: priorityFromString(
        d['priority']?.toString() ?? d['priority_level']?.toString(),
      ),
      sticky: d['sticky'] == true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
          (d['created_at'] as Timestamp?)?.toDate(),
      metadata: meta,
      targetAdminId: d['targetAdminId']?.toString() ?? '',
      collectionName: collectionName,
    );
  }
}

String relativeTimestamp(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inSeconds < 45) return 'Just now';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) {
    return '${DurationFormat.formatDuration(diff, allowDays: true)} ago';
  }
  return '${dt.day}/${dt.month}/${dt.year}';
}

IconData iconForCategory(OpsNotificationCategory c) {
  switch (c) {
    case OpsNotificationCategory.users:
      return Icons.person_add_outlined;
    case OpsNotificationCategory.vendors:
      return Icons.storefront_outlined;
    case OpsNotificationCategory.stock:
      return Icons.inventory_2_outlined;
    case OpsNotificationCategory.delivery:
      return Icons.delivery_dining_outlined;
    case OpsNotificationCategory.payments:
      return Icons.payments_outlined;
    case OpsNotificationCategory.security:
      return Icons.shield_outlined;
    case OpsNotificationCategory.promotions:
      return Icons.campaign_outlined;
    case OpsNotificationCategory.system:
      return Icons.insights_outlined;
    default:
      return Icons.shopping_bag_outlined;
  }
}
