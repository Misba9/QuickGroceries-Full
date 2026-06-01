import 'dart:async';

import 'package:quick_grocery_admin/core/realtime/admin_live_sync.dart';
import 'package:quick_grocery_admin/core/realtime/firestore_sync_cache.dart';
import 'package:quick_grocery_admin/model/address_model.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreSyncCache<CustomerModel> _customersCache =
      FirestoreSyncCache<CustomerModel>();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customersSub;
  AdminLiveSyncState usersSyncState = const AdminLiveSyncState();
  String? usersError;

  List<CustomerModel>? customers;
  List<AddressModel>? addresses;
  List<OrderModel>? orders;
  List<CustomerModel> filteredCustomers = [];
  String _searchQuery = '';

  UserService() {
    ensureUsersListener();
  }

  void ensureUsersListener() {
    if (_customersSub != null) return;
    usersSyncState = usersSyncState.copyWith(isLoading: true);
    notifyListeners();

    _customersSub = _db.collection('customers').snapshots().listen(
      (snap) {
        _customersCache.applySnapshot(
          snap,
          (data, id) => CustomerModel.fromFirestore(data, id),
        );
        customers = _customersCache.sorted(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        _applyUserSearch();
        usersSyncState = AdminLiveSyncState.fromSnapshotMetadata(
          snap.metadata,
          previous: usersSyncState,
        );
        usersError = null;
        notifyListeners();
      },
      onError: (Object e) {
        usersError = e.toString();
        usersSyncState = usersSyncState.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: e.toString(),
        );
        notifyListeners();
      },
    );
  }

  void _applyUserSearch() {
    final all = customers ?? [];
    if (_searchQuery.isEmpty) {
      filteredCustomers = List.from(all);
    } else {
      final q = _searchQuery.toLowerCase();
      filteredCustomers = all
          .where((user) => user.name.toLowerCase().contains(q))
          .toList();
    }
  }

  Future<void> fetchUsers() async {
    ensureUsersListener();
  }

  @override
  void dispose() {
    _customersSub?.cancel();
    super.dispose();
  }

  void toggleChange(int i) {
    final list = customers;
    if (list == null || i < 0 || i >= list.length) return;
    final c = list[i];
    list[i] = c.copyWith(isBlocked: !c.isBlocked);
    _applyUserSearch();
    notifyListeners();
  }

  Future<void> getAddress(String id) async {
    try {
      // Get the products collection from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('address')
          .where('user_id', isEqualTo: id)
          .get();

      addresses = snapshot.docs.map((doc) {
        return AddressModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> getOrders(String id) async {
    try {
      orders = null;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('uuid', isEqualTo: id)
          .get();
      orders = snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (e) {}
  }

  void searchUsers(String query) {
    _searchQuery = query.trim();
    _applyUserSearch();
    notifyListeners();
  }
}
