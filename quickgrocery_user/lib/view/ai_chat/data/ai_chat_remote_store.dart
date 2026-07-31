import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Best-effort write of AI chat turns to Firestore for the admin inbox.
///
/// Primary path is Cloud Function `persistAiChatTurn`; this mirrors the same
/// schema so sessions still appear if the function write was skipped.
class AiChatRemoteStore {
  AiChatRemoteStore({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const sessionsCollection = 'ai_chat_sessions';

  Future<void> persistTurn({
    required String sessionId,
    required String userMessage,
    required String reply,
    List<String> productIds = const [],
    List<String> quickReplies = const [],
    String intent = '',
    String source = '',
    int latencyMs = 0,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    var safeSession = sessionId.replaceAll(RegExp(r'[/\s]'), '_');
    if (safeSession.length > 120) {
      safeSession = safeSession.substring(0, 120);
    }
    if (safeSession.isEmpty) safeSession = 'default';

    var sessionDocId = '${uid}_$safeSession';
    if (sessionDocId.length > 700) {
      sessionDocId = sessionDocId.substring(0, 700);
    }

    try {
      final sessionRef = _db.collection(sessionsCollection).doc(sessionDocId);
      final messagesCol = sessionRef.collection('messages');
      final now = FieldValue.serverTimestamp();
      final tick = DateTime.now().millisecondsSinceEpoch;

      String customerName = '';
      String customerPhone = '';
      try {
        final cust = await _db.collection('customers').doc(uid).get();
        final d = cust.data();
        if (d != null) {
          customerName = (d['name'] ?? d['userName'] ?? '').toString().trim();
          customerPhone =
              (d['phoneNumber'] ?? d['phone'] ?? '').toString().trim();
        }
      } catch (_) {}

      final preview = userMessage.length > 160
          ? '${userMessage.substring(0, 157)}…'
          : userMessage;

      final existing = await sessionRef.get();
      final meta = <String, dynamic>{
        'uid': uid,
        'sessionId': safeSession,
        'updatedAt': now,
        'lastMessage': preview,
        'lastRole': 'assistant',
        'lastIntent': intent,
        'lastSource': source,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'messageCount': FieldValue.increment(2),
        if (!existing.exists) 'createdAt': now,
      };

      final batch = _db.batch();
      batch.set(sessionRef, meta, SetOptions(merge: true));
      batch.set(messagesCol.doc(), {
        'role': 'user',
        'text': userMessage.length > 4000
            ? userMessage.substring(0, 4000)
            : userMessage,
        'createdAt': now,
        'createdAtMs': tick,
        'uid': uid,
      });
      batch.set(messagesCol.doc(), {
        'role': 'assistant',
        'text': reply.length > 8000 ? reply.substring(0, 8000) : reply,
        'createdAt': now,
        'createdAtMs': tick + 1,
        'uid': uid,
        'productIds': productIds.take(12).toList(),
        'quickReplies': quickReplies.take(8).toList(),
        'intent': intent,
        'source': source,
        'latencyMs': latencyMs,
      });
      await batch.commit();
    } catch (e, st) {
      // Never block chat UX if admin mirror fails (rules / network).
      if (kDebugMode) {
        debugPrint('[AiChatRemoteStore] persist failed: $e\n$st');
      }
    }
  }
}
