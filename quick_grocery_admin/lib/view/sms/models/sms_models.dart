import 'package:cloud_firestore/cloud_firestore.dart';

/// `sms_templates/{id}`
class SmsTemplate {
  SmsTemplate({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime? updatedAt;

  factory SmsTemplate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['updatedAt'];
    return SmsTemplate(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      message: (d['message'] ?? '').toString(),
      type: (d['type'] ?? 'general').toString(),
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toWrite() => {
        'title': title,
        'message': message,
        'type': type,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

/// `sms_campaigns/{id}`
class SmsCampaign {
  SmsCampaign({
    required this.id,
    required this.title,
    required this.message,
    required this.targetType,
    required this.status,
    required this.sentCount,
    required this.failedCount,
    this.scheduledAt,
    this.createdAt,
    this.lastCustomerDocId,
    this.totalTargets,
  });

  final String id;
  final String title;
  final String message;
  final String targetType;
  final String status;
  final int sentCount;
  final int failedCount;
  final DateTime? scheduledAt;
  final DateTime? createdAt;
  final String? lastCustomerDocId;
  final int? totalTargets;

  factory SmsCampaign.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? dt(dynamic v) =>
        v is Timestamp ? v.toDate() : (v is DateTime ? v : null);
    return SmsCampaign(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      message: (d['message'] ?? '').toString(),
      targetType: (d['targetType'] ?? 'all_users').toString(),
      status: (d['status'] ?? 'pending').toString(),
      sentCount: (d['sentCount'] as num?)?.toInt() ?? 0,
      failedCount: (d['failedCount'] as num?)?.toInt() ?? 0,
      scheduledAt: dt(d['scheduledAt']),
      createdAt: dt(d['createdAt']),
      lastCustomerDocId: d['lastCustomerDocId']?.toString(),
      totalTargets: (d['totalTargets'] as num?)?.toInt(),
    );
  }
}

/// `sms_logs/{id}`
class SmsLog {
  SmsLog({
    required this.id,
    required this.userId,
    required this.phone,
    required this.message,
    required this.status,
    required this.provider,
    this.title,
    this.campaignId,
    this.error,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String phone;
  final String message;
  final String status;
  final String provider;
  final String? title;
  final String? campaignId;
  final String? error;
  final DateTime? createdAt;

  factory SmsLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return SmsLog(
      id: doc.id,
      userId: (d['userId'] ?? '').toString(),
      phone: (d['phone'] ?? '').toString(),
      message: (d['message'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      provider: (d['provider'] ?? 'Twilio').toString(),
      title: d['title']?.toString(),
      campaignId: d['campaignId']?.toString(),
      error: d['error']?.toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
