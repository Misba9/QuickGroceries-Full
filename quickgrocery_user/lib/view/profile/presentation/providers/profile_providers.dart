import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/view/orders/domain/order_models.dart';
import 'package:quickgrocery/view/orders/presentation/providers/orders_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/profile_models.dart';

final customerProfileStreamProvider =
    StreamProvider.autoDispose<ProfileData?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream<ProfileData?>.value(null);
  }
  return FirebaseFirestore.instance
      .collection('customers')
      .doc(uid)
      .snapshots()
      .map((snap) {
    try {
      if (!snap.exists) return null;
      return ProfileData.fromFirestore(snap.data()!, uid);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Profile] customerProfileStream parse error: $e\n$st');
      }
      return null;
    }
  });
});

final wishlistCountProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection('products')
      .where('is_favorite', arrayContains: uid)
      .snapshots()
      .map((s) => s.docs.length);
});

final addressCountProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection('address')
      .where('user_id', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.length);
});

final userAddressesStreamProvider =
    StreamProvider.autoDispose<List<AddressModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(const []);
  return FirebaseFirestore.instance
      .collection('address')
      .where('user_id', isEqualTo: uid)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) {
            try {
              return AddressModel.fromFirestore(d.data(), d.id);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('[Profile] address parse error: $e');
              }
              return null;
            }
          })
          .whereType<AddressModel>()
          .toList());
});

final orderCountsProvider =
    Provider.autoDispose<AsyncValue<OrderCounts>>((ref) {
  final ordersAsync = ref.watch(userOrdersStreamProvider);
  return ordersAsync.whenData((list) {
    var pending = 0;
    var delivered = 0;
    var cancelled = 0;
    var returned = 0;
    for (final o in list) {
      if (o.isCancelled) {
        cancelled++;
      } else if (o.isDelivered) {
        delivered++;
      } else if (o.status.id.contains('return')) {
        returned++;
      } else {
        pending++;
      }
    }
    return OrderCounts(
      pending: pending,
      delivered: delivered,
      cancelled: cancelled,
      returned: returned,
    );
  });
});

final activeOrderProvider = Provider.autoDispose<LiveOrder?>((ref) {
  final ordersAsync = ref.watch(userOrdersStreamProvider);
  return ordersAsync.maybeWhen(
    data: (list) {
      for (final o in list) {
        if (!o.isCancelled && !o.isDelivered) return o;
      }
      return null;
    },
    orElse: () => null,
  );
});

final notificationPreferencesProvider =
    StateNotifierProvider.autoDispose<NotificationPreferencesNotifier,
        NotificationPreferences>((ref) {
  return NotificationPreferencesNotifier();
});

class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesNotifier() : super(const NotificationPreferences()) {
    _load();
  }

  static const _prefix = 'notif_pref_';

  Future<void> _load() async {
    final pref = await SharedPreferences.getInstance();
    state = NotificationPreferences(
      orderUpdates: pref.getBool('${_prefix}orderUpdates') ?? true,
      offersDiscounts: pref.getBool('${_prefix}offersDiscounts') ?? true,
      walletUpdates: pref.getBool('${_prefix}walletUpdates') ?? true,
      productAlerts: pref.getBool('${_prefix}productAlerts') ?? true,
      promotionalMessages: pref.getBool('${_prefix}promotionalMessages') ?? false,
      deliveryNotifications:
          pref.getBool('${_prefix}deliveryNotifications') ?? true,
    );
  }

  Future<void> update(NotificationPreferences prefs) async {
    state = prefs;
    final pref = await SharedPreferences.getInstance();
    for (final e in prefs.toMap().entries) {
      await pref.setBool('$_prefix${e.key}', e.value);
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('customers').doc(uid).set(
        {'notification_preferences': prefs.toMap()},
        SetOptions(merge: true),
      );
    }
  }

  Future<void> toggle(String key, bool value) async {
    final map = state.toMap();
    map[key] = value;
    await update(NotificationPreferences.fromMap(map));
  }
}
