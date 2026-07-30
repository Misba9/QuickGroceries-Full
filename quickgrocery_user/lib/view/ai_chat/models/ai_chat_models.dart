import 'package:cloud_firestore/cloud_firestore.dart';

/// Role of a message in the grocery AI chat.
enum AiChatRole { user, assistant, system }

/// Delivery status of a chat message.
enum AiChatStatus { sending, sent, error }

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.status = AiChatStatus.sent,
    this.productIds = const [],
    this.quickReplies = const [],
    this.intent,
    this.source,
    this.errorLabel,
  });

  final String id;
  final AiChatRole role;
  final String text;
  final DateTime createdAt;
  final AiChatStatus status;
  final List<String> productIds;
  final List<String> quickReplies;
  final String? intent;
  final String? source;
  final String? errorLabel;

  bool get isUser => role == AiChatRole.user;
  bool get isAssistant => role == AiChatRole.assistant;

  AiChatMessage copyWith({
    AiChatStatus? status,
    String? text,
    List<String>? productIds,
    List<String>? quickReplies,
    String? intent,
    String? source,
    String? errorLabel,
  }) {
    return AiChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      createdAt: createdAt,
      status: status ?? this.status,
      productIds: productIds ?? this.productIds,
      quickReplies: quickReplies ?? this.quickReplies,
      intent: intent ?? this.intent,
      source: source ?? this.source,
      errorLabel: errorLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'productIds': productIds,
        'quickReplies': quickReplies,
        'intent': intent,
        'source': source,
      };

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    AiChatRole role = AiChatRole.assistant;
    final r = (json['role'] ?? '').toString();
    if (r == 'user') role = AiChatRole.user;
    if (r == 'system') role = AiChatRole.system;

    AiChatStatus status = AiChatStatus.sent;
    final s = (json['status'] ?? '').toString();
    if (s == 'sending') status = AiChatStatus.sending;
    if (s == 'error') status = AiChatStatus.error;

    return AiChatMessage(
      id: (json['id'] ?? '').toString(),
      role: role,
      text: (json['text'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      status: status,
      productIds: (json['productIds'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      quickReplies: (json['quickReplies'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      intent: json['intent']?.toString(),
      source: json['source']?.toString(),
    );
  }

  Map<String, String> toApiHistoryTurn() => {
        'role': isUser ? 'user' : 'assistant',
        'text': text,
      };
}

class AiChatResponse {
  const AiChatResponse({
    required this.reply,
    required this.productIds,
    required this.quickReplies,
    required this.intent,
    required this.source,
    required this.latencyMs,
    required this.sessionId,
  });

  final String reply;
  final List<String> productIds;
  final List<String> quickReplies;
  final String intent;
  final String source;
  final int latencyMs;
  final String sessionId;

  factory AiChatResponse.fromMap(Map<String, dynamic> data) {
    return AiChatResponse(
      reply: (data['reply'] ?? '').toString().trim(),
      productIds: (data['productIds'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      quickReplies: (data['quickReplies'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      intent: (data['intent'] ?? 'general').toString(),
      source: (data['source'] ?? 'catalog').toString(),
      latencyMs: (data['latencyMs'] as num?)?.toInt() ?? 0,
      sessionId: (data['sessionId'] ?? 'default').toString(),
    );
  }
}

/// Lightweight product snapshot for chat cards (fetched by ids).
class AiChatProductCard {
  const AiChatProductCard({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.discountPrice,
    required this.rating,
    required this.inStock,
  });

  final String id;
  final String name;
  final String image;
  final double price;
  final double discountPrice;
  final double rating;
  final bool inStock;

  bool get hasOffer => discountPrice > 0 && discountPrice < price;

  factory AiChatProductCard.fromFirestore(String id, Map<String, dynamic> data) {
    double n(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0;
    }

    final price = n(data['price']);
    final slash = n(data['slashedPrice'] ?? data['discountPrice']);
    final stock = n(data['stock']).toInt();
    return AiChatProductCard(
      id: id,
      name: (data['name'] ?? 'Product').toString(),
      image: (data['image'] ?? data['imageUrl'] ?? '').toString(),
      price: price,
      discountPrice: slash > 0 && slash < price ? slash : price,
      rating: n(data['rating']),
      inStock: stock > 0 && data['isAvailable'] != false,
    );
  }

  static Future<List<AiChatProductCard>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final unique = ids.toSet().take(6).toList();
    final db = FirebaseFirestore.instance;
    final out = <AiChatProductCard>[];
    // Firestore whereIn limit 10 — we already cap at 6.
    final snap = await db
        .collection('products')
        .where(FieldPath.documentId, whereIn: unique)
        .get();
    final byId = {for (final d in snap.docs) d.id: d.data()};
    for (final id in unique) {
      final data = byId[id];
      if (data == null) continue;
      out.add(AiChatProductCard.fromFirestore(id, data));
    }
    return out;
  }
}
