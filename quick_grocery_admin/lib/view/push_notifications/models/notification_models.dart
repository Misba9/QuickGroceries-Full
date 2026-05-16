import 'package:cloud_firestore/cloud_firestore.dart';

/// `notification_templates/{id}`
class NotificationTemplate {
  NotificationTemplate({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.imageUrl,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final String? imageUrl;
  final DateTime? updatedAt;

  factory NotificationTemplate.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['updatedAt'];
    return NotificationTemplate(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      message: (d['message'] ?? '').toString(),
      type: (d['type'] ?? 'general').toString(),
      imageUrl: d['imageUrl']?.toString(),
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toWrite() => {
        'title': title,
        'message': message,
        'type': type,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

/// `notification_campaigns/{id}`
class NotificationCampaign {
  NotificationCampaign({
    required this.id,
    required this.title,
    required this.message,
    required this.topic,
    required this.status,
    required this.sentCount,
    required this.failedCount,
    this.openedCount,
    this.scheduledAt,
    this.createdAt,
    this.kind,
    this.targetUserId,
    this.imageUrl,
    this.redirectType,
  });

  final String id;
  final String title;
  final String message;
  final String topic;
  final String status;
  final int sentCount;
  final int failedCount;
  final int? openedCount;
  final DateTime? scheduledAt;
  final DateTime? createdAt;
  final String? kind;
  final String? targetUserId;
  final String? imageUrl;
  final String? redirectType;

  factory NotificationCampaign.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    DateTime? dt(dynamic v) =>
        v is Timestamp ? v.toDate() : (v is DateTime ? v : null);
    return NotificationCampaign(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      message: (d['message'] ?? '').toString(),
      topic: (d['topic'] ?? '').toString(),
      status: (d['status'] ?? 'pending').toString(),
      sentCount: (d['sentCount'] as num?)?.toInt() ?? 0,
      failedCount: (d['failedCount'] as num?)?.toInt() ?? 0,
      openedCount: (d['openedCount'] as num?)?.toInt(),
      scheduledAt: dt(d['scheduledAt']),
      createdAt: dt(d['createdAt']),
      kind: d['kind']?.toString(),
      targetUserId: d['targetUserId']?.toString(),
      imageUrl: d['imageUrl']?.toString(),
      redirectType: d['redirectType']?.toString(),
    );
  }
}

/// `notification_logs/{id}`
class NotificationLog {
  NotificationLog({
    required this.id,
    required this.userId,
    required this.phone,
    required this.message,
    required this.status,
    required this.provider,
    this.title,
    this.topic,
    this.campaignId,
    this.error,
    this.createdAt,
    this.imageUrl,
    this.deepLink,
    this.redirectType,
    this.openedCount,
    this.messageId,
  });

  final String id;
  final String userId;
  final String phone;
  final String message;
  final String status;
  final String provider;
  final String? title;
  final String? topic;
  final String? campaignId;
  final String? error;
  final DateTime? createdAt;
  final String? imageUrl;
  final String? deepLink;
  final String? redirectType;
  final int? openedCount;
  final String? messageId;

  factory NotificationLog.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return NotificationLog(
      id: doc.id,
      userId: (d['userId'] ?? '').toString(),
      phone: (d['phone'] ?? '').toString(),
      message: (d['message'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      provider: (d['provider'] ?? 'FCM').toString(),
      title: d['title']?.toString(),
      topic: d['topic']?.toString(),
      campaignId: d['campaignId']?.toString(),
      error: d['error']?.toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
      imageUrl: d['imageUrl']?.toString(),
      deepLink: d['deepLink']?.toString(),
      redirectType: d['redirectType']?.toString(),
      openedCount: (d['openedCount'] as num?)?.toInt(),
      messageId: d['messageId']?.toString(),
    );
  }
}
