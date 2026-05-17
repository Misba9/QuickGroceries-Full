import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_delivery/models/delivery_boy_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverProfileService extends ChangeNotifier {
  DriverProfileService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  DeliveryBoyProfile? profile;
  bool loading = true;
  String? error;

  Future<String> _riderId() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('deliveryBoyId') ?? '';
  }

  void startListening() async {
    await _profileSub?.cancel();
    final id = await _riderId();
    if (id.isEmpty) {
      loading = false;
      notifyListeners();
      return;
    }
    _profileSub = _db.collection('delivery_boys').doc(id).snapshots().listen(
      (snap) {
        loading = false;
        if (!snap.exists) {
          profile = null;
          error = 'Profile not found';
        } else {
          profile = DeliveryBoyProfile.fromFirestore(snap.data()!, snap.id);
          error = null;
        }
        notifyListeners();
      },
      onError: (e) {
        loading = false;
        error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    final id = await _riderId();
    if (id.isEmpty) return;
    final snap = await _db.collection('delivery_boys').doc(id).get();
    if (snap.exists) {
      profile = DeliveryBoyProfile.fromFirestore(snap.data()!, snap.id);
    }
    notifyListeners();
  }

  Future<void> setOnlineStatus(bool online) async {
    final id = await _riderId();
    if (id.isEmpty) return;
    await _db.collection('delivery_boys').doc(id).set({
      'isOnline': online,
      'online_status': online,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setPauseDeliveries(bool pause) async {
    final id = await _riderId();
    if (id.isEmpty) return;
    await _db.collection('delivery_boys').doc(id).set({
      'pause_deliveries': pause,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfile(DeliveryBoyProfile p) async {
    final id = await _riderId();
    if (id.isEmpty) return;
    await _db.collection('delivery_boys').doc(id).set(p.toProfilePatch(), SetOptions(merge: true));
  }

  Future<void> updateDocument(String type, String url) async {
    final id = await _riderId();
    if (id.isEmpty) return;
    await _db.collection('delivery_boys').doc(id).update({
      'documents.$type.url': url,
      'documents.$type.status': 'pending',
      'documents.$type.uploadedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> requestWithdrawal(double amount) async {
    final id = await _riderId();
    if (id.isEmpty) return;
    final p = profile;
    if (p == null || amount <= 0 || amount > p.walletBalance) {
      throw Exception('Invalid withdrawal amount');
    }
    await _db.collection('driver_wallet_requests').add({
      'driver_id': id,
      'amount': amount,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('delivery_boys').doc(id).set({
      'pending_payout': FieldValue.increment(amount),
      'wallet_balance': FieldValue.increment(-amount),
    }, SetOptions(merge: true));
    await _db.collection('delivery_boys').doc(id).collection('wallet_transactions').add({
      'type': 'withdrawal_request',
      'amount': -amount,
      'note': 'Withdrawal requested',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchWalletTransactions() async* {
    final id = await _riderId();
    if (id.isEmpty) {
      yield [];
      return;
    }
    yield* _db
        .collection('delivery_boys')
        .doc(id)
        .collection('wallet_transactions')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}
