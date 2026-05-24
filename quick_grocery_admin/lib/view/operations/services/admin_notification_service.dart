import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_notification_model.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_alert_sound_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_sound_prefs.dart';

/// Real-time admin notification center — reads `notifications` with legacy fallback.
class AdminNotificationService extends ChangeNotifier {
  AdminNotificationService({OpsSoundPrefs? soundPrefs}) : _soundPrefs = soundPrefs {
    _startWatching();
  }

  final _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  OpsSoundPrefs? _soundPrefs;

  static const _pageSize = 50;
  static const _primaryCol = 'notifications';
  static const _legacyCol = 'admin_notifications';

  int unreadCount = 0;
  List<OpsNotificationModel> recent = [];
  bool loading = true;
  String? error;
  bool usingLegacyCollection = false;
  bool hasMore = true;
  bool _triedLegacyFallback = false;

  final Queue<OpsNotificationModel> toastQueue = Queue();
  OpsNotificationModel? latestToast;

  final Set<String> _seenIds = {};
  bool _skipInitialAlerts = true;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _feedSub;

  void attachSoundPrefs(OpsSoundPrefs prefs) => _soundPrefs = prefs;

  void _startWatching() {
    _watchFeed(_primaryCol);
  }

  void _watchFeed(String collection) {
    _feedSub?.cancel();
    usingLegacyCollection = collection == _legacyCol;
    loading = true;
    notifyListeners();

    _feedSub = _firestore
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .listen((snap) {
      final items = snap.docs
          .map(
            (d) => OpsNotificationModel.fromDoc(
              d,
              collectionName: collection,
            ),
          )
          .where((n) => n.target.isEmpty || n.target == 'admin')
          .toList();

      if (collection == _primaryCol &&
          items.isEmpty &&
          !_triedLegacyFallback) {
        _triedLegacyFallback = true;
        _watchFeed(_legacyCol);
        return;
      }

      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      hasMore = snap.docs.length >= _pageSize;
      _handleIncoming(items);
      recent = items;
      unreadCount = items.where((n) => !n.read).length;
      loading = false;
      error = null;
      notifyListeners();
    }, onError: (Object e) {
      if (kDebugMode) {
        debugPrint('[AdminNotificationService] feed($collection): $e');
      }
      if (collection == _primaryCol) {
        _watchFeed(_legacyCol);
        return;
      }
      loading = false;
      error = _friendlyError(e);
      notifyListeners();
    });
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('failed-precondition')) {
      return 'Firestore index missing. Deploy firestore.indexes.json then retry.';
    }
    if (msg.contains('permission-denied')) {
      return 'Permission denied. Sign in as admin and deploy Firestore rules.';
    }
    return msg;
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
        volume: prefs.volume,
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

  /// Client-side filter — avoids composite Firestore indexes.
  List<OpsNotificationModel> filtered({
    OpsNotificationCategory? category,
    String query = '',
  }) {
    var items = recent;
    if (category != null) {
      items = items.where((n) => n.category == category).toList();
    }
    return filterByQuery(items, query);
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
              n.type.toLowerCase().contains(q) ||
              n.sourceApp.toLowerCase().contains(q),
        )
        .toList();
  }

  CollectionReference<Map<String, dynamic>> _docCollection(
    OpsNotificationModel n,
  ) =>
      _firestore.collection(
        n.collectionName.isNotEmpty ? n.collectionName : _primaryCol,
      );

  Future<void> markRead(String id, {String? collectionName}) async {
    final col = collectionName ?? (usingLegacyCollection ? _legacyCol : _primaryCol);
    await _firestore.collection(col).doc(id).update({
      'read': true,
      'is_read': true,
      'isRead': true,
    });
  }

  Future<void> markAllRead() async {
    final unread = recent.where((n) => !n.read).toList();
    if (unread.isEmpty) return;
    final batch = _firestore.batch();
    for (final n in unread) {
      batch.update(_docCollection(n).doc(n.id), {
        'read': true,
        'is_read': true,
        'isRead': true,
      });
    }
    await batch.commit();
  }

  Future<void> deleteNotification(OpsNotificationModel n) async {
    await _docCollection(n).doc(n.id).delete();
    _seenIds.remove(n.id);
    recent = recent.where((x) => x.id != n.id).toList();
    unreadCount = recent.where((x) => !x.read).length;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasMore || _lastDoc == null || loading) return;
    final col = usingLegacyCollection ? _legacyCol : _primaryCol;
    try {
      final snap = await _firestore
          .collection(col)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize)
          .get();
      if (snap.docs.isEmpty) {
        hasMore = false;
        notifyListeners();
        return;
      }
      _lastDoc = snap.docs.last;
      hasMore = snap.docs.length >= _pageSize;
      final more = snap.docs
          .map((d) => OpsNotificationModel.fromDoc(d, collectionName: col))
          .where((n) => n.target.isEmpty || n.target == 'admin')
          .toList();
      final existing = recent.map((e) => e.id).toSet();
      recent = [
        ...recent,
        ...more.where((n) => !existing.contains(n.id)),
      ];
      unreadCount = recent.where((n) => !n.read).length;
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AdminNotificationService] loadMore: $e\n$st');
      }
    }
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
    _feedSub?.cancel();
    super.dispose();
  }
}
