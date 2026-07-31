import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_admin/view/ai_chat/models/ai_chat_admin_models.dart';

/// Read-only admin access to persisted user AI chat transcripts.
class AiChatAdminService {
  AiChatAdminService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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
}
