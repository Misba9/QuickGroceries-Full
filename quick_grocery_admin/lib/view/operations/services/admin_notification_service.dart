import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_notification_model.dart';

/// Real-time admin notification center (`admin_notifications` collection).
class AdminNotificationService extends ChangeNotifier {
  AdminNotificationService() {
    _watchUnread();
    _watchRecent();
  }

  final _firestore = FirebaseFirestore.instance;
  static const _pageSize = 40;

  int unreadCount = 0;
  List<OpsNotificationModel> recent = [];
  bool loading = true;
  String? error;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _unreadSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _recentSub;

  void _watchUnread() {
    _unreadSub = _firestore
        .collection('admin_notifications')
        .where('read', isEqualTo: false)
        .limit(200)
        .snapshots()
        .listen((snap) {
      unreadCount = snap.size;
      notifyListeners();
    }, onError: (Object e) {
      if (kDebugMode) debugPrint('[AdminNotificationService] unread: $e');
    });
  }

  void _watchRecent() {
    _recentSub = _firestore
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .listen((snap) {
      recent = snap.docs.map(OpsNotificationModel.fromDoc).toList();
      loading = false;
      error = null;
      notifyListeners();
    }, onError: (Object e) {
      loading = false;
      error = e.toString();
      notifyListeners();
    });
  }

  Stream<List<OpsNotificationModel>> streamPage({
    OpsNotificationCategory? category,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> q = _firestore
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);
    if (category != null) {
      q = q.where('category', isEqualTo: category.name);
    }
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    return q.snapshots().map(
          (s) => s.docs.map(OpsNotificationModel.fromDoc).toList(),
        );
  }

  Future<void> markRead(String id) async {
    await _firestore.collection('admin_notifications').doc(id).update({
      'read': true,
    });
  }

  Future<void> markAllRead() async {
    final batch = _firestore.batch();
    final snap = await _firestore
        .collection('admin_notifications')
        .where('read', isEqualTo: false)
        .limit(100)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    _recentSub?.cancel();
    super.dispose();
  }
}
