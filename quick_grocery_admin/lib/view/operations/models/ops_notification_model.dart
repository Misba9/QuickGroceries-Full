import 'package:cloud_firestore/cloud_firestore.dart';

enum OpsNotificationCategory {
  orders,
  users,
  vendors,
  payments,
  stock,
  delivery,
  system,
}

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
    default:
      return OpsNotificationCategory.orders;
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
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;
  final String targetAdminId;

  String? get orderId => metadata['orderId']?.toString();

  factory OpsNotificationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final meta = d['metadata'];
    return OpsNotificationModel(
      id: doc.id,
      title: d['title']?.toString() ?? '',
      message: d['message']?.toString() ?? '',
      type: d['type']?.toString() ?? '',
      category: categoryFromString(d['category']?.toString()),
      read: d['read'] == true,
      soundAlert: d['soundAlert'] == true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      metadata: meta is Map
          ? Map<String, dynamic>.from(meta as Map)
          : const {},
      targetAdminId: d['targetAdminId']?.toString() ?? '',
    );
  }
}
