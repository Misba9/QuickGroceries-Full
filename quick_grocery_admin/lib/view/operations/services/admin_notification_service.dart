import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_notification_model.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_alert_sound_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_sound_prefs.dart';

/// Real-time admin notification center (`admin_notifications` collection).
class AdminNotificationService extends ChangeNotifier {
  AdminNotificationService({OpsSoundPrefs? soundPrefs})
      : _soundPrefs = soundPrefs {
    _watchUnread();
    _watchRecent();
  }

  final _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  OpsSoundPrefs? _soundPrefs;

  static const _pageSize = 50;

  int unreadCount = 0;
  List<OpsNotificationModel> recent = [];
  bool loading = true;
  String? error;

  final Queue<OpsNotificationModel> toastQueue = Queue();
  OpsNotificationModel? latestToast;

  final Set<String> _seenIds = {};
  bool _skipInitialAlerts = true;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _unreadSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _recentSub;

  void attachSoundPrefs(OpsSoundPrefs prefs) => _soundPrefs = prefs;

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
      error = e.toString();
      notifyListeners();
    });
  }

  void _watchRecent() {
    _recentSub = _firestore
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .listen((snap) {
      final items = snap.docs.map(OpsNotificationModel.fromDoc).toList();
      _handleIncoming(items);
      recent = items;
      loading = false;
      error = null;
      notifyListeners();
    }, onError: (Object e) {
      loading = false;
      error = e.toString();
      if (kDebugMode) debugPrint('[AdminNotificationService] recent: $e');
      notifyListeners();
    });
  }

  void _handleIncoming(List<OpsNotificationModel> items) {
    if (_skipInitialAlerts) {
      _seenIds.addAll(items.map((e) => e.id));
      _skipInitialAlerts = false;
      return;
    }
    for (final n in items) {
      if (_seenIds.contains(n.id)) continue;
      _seenIds.add(n.id);
      if (n.read) continue;
      toastQueue.add(n);
      latestToast = n;
      if (n.soundAlert) {
        _playSound(n.soundType);
      }
    }
  }

  void _playSound(String soundType) {
    final prefs = _soundPrefs;
    if (prefs == null || !prefs.enabled) return;
    unawaited(
      AdminAlertSoundService.playForSoundType(
        soundType,
        enabled: prefs.enabled,
      ),
    );
  }

  OpsNotificationModel? consumeToast() {
    if (toastQueue.isEmpty) return null;
    final n = toastQueue.removeFirst();
    if (toastQueue.isEmpty) latestToast = null;
    notifyListeners();
    return n;
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

  List<OpsNotificationModel> filterByQuery(
    List<OpsNotificationModel> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (n) =>
              n.title.toLowerCase().contains(q) ||
              n.message.toLowerCase().contains(q) ||
              n.type.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> markRead(String id) async {
    await _firestore.collection('admin_notifications').doc(id).update({
      'read': true,
      'is_read': true,
    });
  }

  Future<void> markAllRead() async {
    final snap = await _firestore
        .collection('admin_notifications')
        .where('read', isEqualTo: false)
        .limit(100)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true, 'is_read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('admin_notifications').doc(id).delete();
    _seenIds.remove(id);
    recent = recent.where((n) => n.id != id).toList();
    notifyListeners();
  }

  Future<String?> seedTestNotification() async {
    try {
      final result =
          await _functions.httpsCallable('seedAdminTestNotification').call();
      final data = result.data;
      if (data is Map) return data['id']?.toString();
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[AdminNotificationService] seed: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    _recentSub?.cancel();
    super.dispose();
  }
}
