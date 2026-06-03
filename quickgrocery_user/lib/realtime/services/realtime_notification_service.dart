import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quickgrocery/core/firestore/firestore_retry.dart';

/// Realtime in-app notifications feed at `notifications/{uid}/items`.
///
/// Also syncs read state to `customers/{uid}/notification_inbox` (FCM writes).
///
/// Schema: see [NotificationItem].
class RealtimeNotificationService {
  RealtimeNotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _root = 'notifications';
  static const String _items = 'items';
  static const int _batchLimit = 450;

  CollectionReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection(_root).doc(uid).collection(_items);

  CollectionReference<Map<String, dynamic>> _inboxRef(String uid) =>
      _firestore.collection('customers').doc(uid).collection('notification_inbox');

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

  Future<void> markAsRead(String uid, String notificationId) async {
    await withFirestoreRetry(
      () => _userRef(uid).doc(notificationId).update({'read': true}),
    );
    try {
      await withFirestoreRetry(
        () => _inboxRef(uid).doc(notificationId).update({'read': true}),
      );
    } catch (_) {
      /* inbox doc may use a different id */
    }
  }

  Future<void> markAllAsRead(String uid) async {
    await Future.wait([
      _markAllUnreadIn(_userRef(uid)),
      _markAllUnreadIn(_inboxRef(uid)),
    ]);
  }

  Future<void> _markAllUnreadIn(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    final snap = await withFirestoreRetry(
      () => col.orderBy('createdAt', descending: true).limit(100).get(),
    );
    final unread =
        snap.docs.where((d) => d.data()['read'] != true).toList();
    if (unread.isEmpty) return;

    for (var i = 0; i < unread.length; i += _batchLimit) {
      final batch = _firestore.batch();
      final end = (i + _batchLimit < unread.length)
          ? i + _batchLimit
          : unread.length;
      for (var j = i; j < end; j++) {
        batch.update(unread[j].reference, {'read': true});
      }
      await withFirestoreRetry(() => batch.commit());
    }
  }
}
