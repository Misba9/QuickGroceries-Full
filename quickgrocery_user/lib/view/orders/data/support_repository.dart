import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Per-order support thread persisted under
/// `orders/{orderId}/support_messages/{messageId}`.
///
/// Document shape:
///   { author: 'customer' | 'support', text: '...', createdAt: ts, uid }
@immutable
class SupportMessage {
  final String id;
  final String author;
  final String text;
  final DateTime? createdAt;

  const SupportMessage({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  bool get fromCustomer => author == 'customer';

  factory SupportMessage.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    final ts = data['createdAt'];
    DateTime? created;
    if (ts is Timestamp) created = ts.toDate();
    return SupportMessage(
      id: d.id,
      author: (data['author'] ?? 'support').toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: created,
    );
  }
}

class SupportRepository {
  SupportRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String orderId) =>
      _firestore
          .collection('orders')
          .doc(orderId)
          .collection('support_messages');

  Stream<List<SupportMessage>> watch(String orderId) {
    return _col(orderId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(SupportMessage.fromDoc).toList());
  }

  Future<void> send(String orderId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    await _col(orderId).add({
      'author': 'customer',
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'uid': user?.uid ?? '',
    });
  }
}
