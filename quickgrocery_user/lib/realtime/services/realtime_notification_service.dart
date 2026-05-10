import 'package:cloud_firestore/cloud_firestore.dart';

/// Realtime in-app notifications feed at `notifications/{uid}/items`.
///
/// Cloud Functions / Admin tooling write items here in addition to (or
/// instead of) sending FCM. A dedicated per-uid sub-collection keeps
/// reads cheap, isolates rules per user, and avoids `arrayUnion` write
/// fan-out.
///
/// Schema: see [NotificationItem].
class RealtimeNotificationService {
  RealtimeNotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _root = 'notifications';
  static const String _items = 'items';

  CollectionReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection(_root).doc(uid).collection(_items);

  Stream<QuerySnapshot<Map<String, dynamic>>> watch(
    String uid, {
    int limit = 50,
  }) {
    return _userRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Live "unread count" — drives the bell badge in the app bar.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchUnread(String uid) {
    return _userRef(uid).where('read', isEqualTo: false).snapshots();
  }

  Future<void> markAsRead(String uid, String notificationId) {
    return _userRef(uid).doc(notificationId).update({'read': true});
  }

  Future<void> markAllAsRead(String uid) async {
    final snap = await _userRef(uid).where('read', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    if (snap.docs.isNotEmpty) await batch.commit();
  }
}
