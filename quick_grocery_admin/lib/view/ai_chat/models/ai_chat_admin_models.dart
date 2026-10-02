import 'package:cloud_firestore/cloud_firestore.dart';

class AiChatSession {
  const AiChatSession({
    required this.id,
    required this.uid,
    required this.sessionId,
    required this.lastMessage,
    required this.customerName,
    required this.customerPhone,
    required this.lastIntent,
    required this.lastSource,
    required this.messageCount,
    this.updatedAt,
    this.createdAt,
  });

  final String id;
  final String uid;
  final String sessionId;
  final String lastMessage;
  final String customerName;
  final String customerPhone;
  final String lastIntent;
  final String lastSource;
  final int messageCount;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  String get displayName {
    if (customerName.isNotEmpty) return customerName;
    if (customerPhone.isNotEmpty) return customerPhone;
    if (uid.length > 8) return 'User ${uid.substring(0, 8)}…';
    return uid.isEmpty ? 'Unknown user' : uid;
  }

  factory AiChatSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AiChatSession(
      id: doc.id,
      uid: (d['uid'] ?? '').toString(),
      sessionId: (d['sessionId'] ?? '').toString(),
      lastMessage: (d['lastMessage'] ?? '').toString(),
      customerName: (d['customerName'] ?? '').toString(),
      customerPhone: (d['customerPhone'] ?? '').toString(),
      lastIntent: (d['lastIntent'] ?? '').toString(),
      lastSource: (d['lastSource'] ?? '').toString(),
      messageCount: (d['messageCount'] is num)
          ? (d['messageCount'] as num).toInt()
          : 0,
      updatedAt: _ts(d['updatedAt']),
      createdAt: _ts(d['createdAt']),
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

class AiChatMessageDoc {
  const AiChatMessageDoc({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAtMs,
    this.intent,
    this.source,
    this.productIds = const [],
    this.latencyMs,
    this.createdAt,
  });

  final String id;
  final String role;
  final String text;
  final int createdAtMs;
  final String? intent;
  final String? source;
  final List<String> productIds;
  final int? latencyMs;
  final DateTime? createdAt;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory AiChatMessageDoc.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final products = d['productIds'];
    return AiChatMessageDoc(
      id: doc.id,
      role: (d['role'] ?? 'assistant').toString(),
      text: (d['text'] ?? '').toString(),
      createdAtMs: (d['createdAtMs'] is num)
          ? (d['createdAtMs'] as num).toInt()
          : 0,
      intent: d['intent']?.toString(),
      source: d['source']?.toString(),
      productIds: products is List
          ? products.map((e) => e.toString()).toList()
          : const [],
      latencyMs:
          d['latencyMs'] is num ? (d['latencyMs'] as num).toInt() : null,
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
