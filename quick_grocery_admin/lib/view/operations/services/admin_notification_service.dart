import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_notification_model.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_alert_sound_service.dart';
import 'package:quick_grocery_admin/view/operations/services/browser_notification_platform.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_sound_prefs.dart';

/// Real-time admin notification center — reads `notifications` with legacy fallback.
/// Listeners start only after Firebase Auth is ready (avoids permission-denied dead streams).
class AdminNotificationService extends ChangeNotifier {
  AdminNotificationService({OpsSoundPrefs? soundPrefs}) : _soundPrefs = soundPrefs {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
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
  bool loading = false;
  String? error;
  bool usingLegacyCollection = false;
  bool hasMore = true;
  bool _triedLegacyFallback = false;
  bool _active = false;

  final Queue<OpsNotificationModel> toastQueue = Queue();
  OpsNotificationModel? latestToast;

  final Set<String> _seenIds = {};
  final Set<String> _alertedOrderIds = {};
  bool _skipInitialAlerts = true;
  bool _skipInitialOrderAlerts = true;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _feedSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  StreamSubscription<User?>? _authSub;

  void attachSoundPrefs(OpsSoundPrefs prefs) => _soundPrefs = prefs;

  /// Called after login shell mounts — requests browser permission + unlocks audio.
  Future<void> prepareClientAlerts() async {
    await requestBrowserNotificationPermission();
    await AdminAlertSoundService.unlock();
  }

  void _onAuthChanged(User? user) {
    if (user != null) {
      activate();
    } else {
      deactivate();
    }
  }

  /// Start Firestore listeners (safe to call multiple times).
  void activate() {
    if (_active) return;
    _active = true;
    _skipInitialAlerts = true;
    _skipInitialOrderAlerts = true;
    _triedLegacyFallback = false;
    _startWatching();
    _startOrdersWatch();
  }

  void deactivate() {
    if (!_active) return;
    _active = false;
    _feedSub?.cancel();
    _feedSub = null;
    _ordersSub?.cancel();
    _ordersSub = null;
    loading = false;
    notifyListeners();
  }

  void _startWatching() {
    _watchFeed(_primaryCol);
  }

  void _watchFeed(String collection) {
    _feedSub?.cancel();
    usingLegacyCollection = collection == _legacyCol;
    loading = true;
    error = null;
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
      if (collection == _primaryCol && !_triedLegacyFallback) {
        _triedLegacyFallback = true;
        _watchFeed(_legacyCol);
        return;
      }
      loading = false;
      error = _friendlyError(e);
      notifyListeners();
      if (_active && FirebaseAuth.instance.currentUser != null) {
        Future<void>.delayed(const Duration(seconds: 3), () {
          if (_active && _feedSub == null) _startWatching();
        });
      }
    });
  }

  void _startOrdersWatch() {
    _ordersSub?.cancel();
    _ordersSub = _firestore.collection('orders').snapshots().listen(
      (snap) {
        if (_skipInitialOrderAlerts) {
          for (final change in snap.docChanges) {
            if (change.type == DocumentChangeType.added) {
              _alertedOrderIds.add(change.doc.id);
            }
          }
          _skipInitialOrderAlerts = false;
          return;
        }
        for (final change in snap.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          _handleNewOrderDoc(change.doc.id, change.doc.data());
        }
      },
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('[AdminNotificationService] orders watch: $e');
        }
      },
    );
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
      for (final n in items) {
        final oid = n.orderId;
        if (oid != null && oid.isNotEmpty) _alertedOrderIds.add(oid);
      }
      _skipInitialAlerts = false;
      return;
    }

    for (final change in _newItemsFromSnapshot(items)) {
      _emitAlert(change);
    }
  }

  Iterable<OpsNotificationModel> _newItemsFromSnapshot(
    List<OpsNotificationModel> items,
  ) sync* {
    for (final n in items) {
      if (_seenIds.contains(n.id)) continue;
      _seenIds.add(n.id);
      if (n.read) continue;
      yield n;
    }
  }

  void _handleNewOrderDoc(String orderId, Map<String, dynamic>? data) {
    if (data == null) return;

    final customer =
        (data['customer_name'] ?? data['customerName'] ?? '').toString();
    final total = _orderTotal(data);
    final vendor = (data['vendorName'] ?? data['vendor_name'] ?? '').toString();

    final synthetic = OpsNotificationModel(
      id: 'order_$orderId',
      title: 'New Order Received',
      message:
          'Order #${_shortId(orderId)} · $customer · ₹${total.toStringAsFixed(0)}',
      type: 'new_order',
      category: OpsNotificationCategory.orders,
      read: false,
      createdAt: DateTime.now(),
      soundAlert: true,
      soundType: 'orders',
      priority: OpsNotificationPriority.high,
      metadata: {
        'orderId': orderId,
        'customerName': customer,
        'amount': total,
        'vendorName': vendor,
      },
    );
    _emitAlert(synthetic);
  }

  double _orderTotal(Map<String, dynamic> data) {
    final bill = data['bill'];
    if (bill is Map && bill['total'] != null) {
      return (bill['total'] as num).toDouble();
    }
    final products = data['products'];
    var sum = 0.0;
    if (products is List) {
      for (final p in products) {
        if (p is Map) {
          sum += (p['price'] as num? ?? 0) * (p['itemCount'] as num? ?? 1);
        }
      }
    }
    return sum + (data['delivery_charge'] as num? ?? 0).toDouble();
  }

  String _shortId(String id) =>
      id.length > 6 ? id.substring(id.length - 6) : id;

  void _emitAlert(OpsNotificationModel n) {
    final orderId = n.orderId;
    if (orderId != null && orderId.isNotEmpty) {
      if (_alertedOrderIds.contains(orderId)) return;
      _alertedOrderIds.add(orderId);
    }

    toastQueue.add(n);
    latestToast = n;
    notifyListeners();

    if (n.soundAlert) {
      _playSound(n.soundType, orderId: orderId);
    }

    if (n.type == 'new_order') {
      _showBrowserAlert(n);
    }
  }

  void _showBrowserAlert(OpsNotificationModel n) {
    final meta = n.metadata;
    final orderId = n.orderId ?? '';
    final shortId = _shortId(orderId);
    final amount = meta['amount'];
    final amountStr = amount is num
        ? '₹${amount.toStringAsFixed(0)}'
        : (amount?.toString() ?? '');
    unawaited(
      showBrowserNotification(
        title: 'New Order Received',
        body: orderId.isNotEmpty
            ? 'Order #$shortId${amountStr.isNotEmpty ? ' · $amountStr' : ''}'
            : n.message,
        tag: orderId.isNotEmpty ? 'order_$orderId' : n.id,
      ),
    );
  }

  void _playSound(String soundType, {String? orderId}) {
    final prefs = _soundPrefs;
    if (prefs == null || !prefs.enabled) return;
    unawaited(
      AdminAlertSoundService.playForSoundType(
        soundType,
        enabled: prefs.enabled,
        volume: prefs.volume,
        orderId: orderId,
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
    if (!n.id.startsWith('order_')) {
      await _docCollection(n).doc(n.id).delete();
    }
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
    _authSub?.cancel();
    _feedSub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }
}
