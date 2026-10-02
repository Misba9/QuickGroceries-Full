import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:quick_grocery_admin/view/ai_chat/models/ai_chat_admin_models.dart';

/// Admin access to persisted user AI chat transcripts.
///
/// Live updates via Firestore; [listSessionsViaCallable] uses Admin SDK when
/// client rules block reads or for manual refresh.
class AiChatAdminService {
  AiChatAdminService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _fn = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  static const sessionsCollection = 'ai_chat_sessions';

  Stream<List<AiChatSession>> watchSessions({int limit = 80}) {
    return _db
        .collection(sessionsCollection)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AiChatSession.fromDoc(d))
              .toList(growable: false),
        );
  }

  Stream<List<AiChatMessageDoc>> watchMessages(String sessionDocId) {
    return _db
        .collection(sessionsCollection)
        .doc(sessionDocId)
        .collection('messages')
        .orderBy('createdAtMs')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AiChatMessageDoc.fromDoc(d))
              .toList(growable: false),
        );
  }

  Future<List<AiChatSession>> listSessionsViaCallable({int limit = 80}) async {
    final result = await _fn
        .httpsCallable('listAiChatSessionsCallable')
        .call({'limit': limit});
    final data = Map<String, dynamic>.from(result.data as Map? ?? {});
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((raw) {
          final m = Map<String, dynamic>.from(raw);
          return AiChatSession(
            id: (m['id'] ?? '').toString(),
            uid: (m['uid'] ?? '').toString(),
            sessionId: (m['sessionId'] ?? '').toString(),
            lastMessage: (m['lastMessage'] ?? '').toString(),
            customerName: (m['customerName'] ?? '').toString(),
            customerPhone: (m['customerPhone'] ?? '').toString(),
            lastIntent: (m['lastIntent'] ?? '').toString(),
            lastSource: (m['lastSource'] ?? '').toString(),
            messageCount: (m['messageCount'] is num)
                ? (m['messageCount'] as num).toInt()
                : 0,
            updatedAt: _parseIso(m['updatedAt']),
            createdAt: _parseIso(m['createdAt']),
          );
        })
        .toList(growable: false);
  }

  Future<List<AiChatMessageDoc>> listMessagesViaCallable(
    String sessionDocId,
  ) async {
    final result = await _fn
        .httpsCallable('listAiChatMessagesCallable')
        .call({'sessionDocId': sessionDocId});
    final data = Map<String, dynamic>.from(result.data as Map? ?? {});
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((raw) {
          final m = Map<String, dynamic>.from(raw);
          final products = m['productIds'];
          return AiChatMessageDoc(
            id: (m['id'] ?? '').toString(),
            role: (m['role'] ?? 'assistant').toString(),
            text: (m['text'] ?? '').toString(),
            createdAtMs: (m['createdAtMs'] is num)
                ? (m['createdAtMs'] as num).toInt()
                : 0,
            intent: m['intent']?.toString(),
            source: m['source']?.toString(),
            productIds: products is List
                ? products.map((e) => e.toString()).toList()
                : const [],
            latencyMs:
                m['latencyMs'] is num ? (m['latencyMs'] as num).toInt() : null,
            createdAt: _parseIso(m['createdAt']),
          );
        })
        .toList(growable: false);
  }

  static DateTime? _parseIso(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
