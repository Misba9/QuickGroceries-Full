import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/analytics/admin_date_ranges.dart';
import 'package:quick_grocery_admin/model/address_model.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_crm_models.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_segment.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_sort.dart';
import 'package:quick_grocery_admin/view/customers/utils/customer_stats_aggregator.dart';

/// Real-time customers + orders streams with simple filtering, sorting, and pagination.
class CustomerAdminService extends ChangeNotifier {
  CustomerAdminService() {
    _listen();
  }

  final _db = FirebaseFirestore.instance;

  bool isLoading = true;
  String? errorMessage;

  CustomerSegment segment = CustomerSegment.allCustomers;
  CustomerQuickFilter quickFilter = CustomerQuickFilter.none;
  String searchQuery = '';

  CustomerSortField sortField = CustomerSortField.lastActive;
  bool sortAscending = false;

  int pageSize = 50;
  int visibleCount = 50;

  CustomerListSummary summary = const CustomerListSummary();
  List<CustomerEnriched> _enriched = [];

  List<AddressModel>? profileAddresses;
  List<OrderModel>? profileOrders;
  bool profileLoading = false;

  List<Map<String, dynamic>> _customerDocs = [];
  List<Map<String, dynamic>> _orderDocs = [];
  Map<String, CustomerOrderStats> _orderStats = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  Timer? _searchDebounce;
  Timer? _notifyDebounce;
  bool _disposed = false;
  int _dataVersion = 0;
  int _sortedCacheKey = -1;
  List<CustomerEnriched>? _sortedCache;

  final TextEditingController searchController = TextEditingController();

  List<CustomerEnriched> get enriched => _enriched;
  List<CustomerEnriched> get filtered => _filteredList();
  List<CustomerEnriched> get sortedFiltered => _sortedList();
  List<CustomerEnriched> get paged =>
      sortedFiltered.take(visibleCount).toList(growable: false);
  bool get hasMore => visibleCount < sortedFiltered.length;

  int get _listCacheKey => Object.hash(
    segment,
    quickFilter,
    searchQuery.trim().toLowerCase(),
    sortField,
    sortAscending,
    _dataVersion,
  );

  void _listen() {
    _customersSub = _db
        .collection('customers')
        .snapshots()
        .listen(
          (snap) {
            _customerDocs = snap.docs
                .map((d) => {...d.data(), 'id': d.id})
                .toList();
            _customerDocs.sort((a, b) {
              final ta = _parse(a['createdAt'] ?? a['created_date']);
              final tb = _parse(b['createdAt'] ?? b['created_date']);
              return (tb ?? DateTime(0)).compareTo(ta ?? DateTime(0));
            });
            _rebuild();
            _invalidateSortCache();
            isLoading = false;
            errorMessage = null;
            _scheduleNotify();
          },
          onError: (Object e, StackTrace st) {
            if (kDebugMode) {
              debugPrint('CustomerAdminService customers: $e\n$st');
            }
            errorMessage = e.toString();
            isLoading = false;
            _scheduleNotify();
          },
        );

    _ordersSub = _db
        .collection('orders')
        .snapshots()
        .listen(
          (snap) {
            _orderDocs = snap.docs
                .map((d) => {...d.data(), 'id': d.id})
                .toList();
            _orderStats = CustomerStatsAggregator.fromOrderMaps(_orderDocs);
            _rebuild();
            _invalidateSortCache();
            _scheduleNotify();
          },
          onError: (Object e) {
            if (kDebugMode) debugPrint('CustomerAdminService orders: $e');
          },
        );
  }

  void _rebuild() {
    final totalRevenue = CustomerStatsAggregator.totalDeliveredRevenue(
      _orderDocs,
    );

    _enriched = _customerDocs.map((d) {
      final c = CustomerModel.fromFirestore(d, d['id'].toString());
      final uid = c.id.isNotEmpty ? c.id : c.docId;
      final stats = _orderStats[uid] ?? CustomerOrderStats.empty;

      final last = c.lastActiveTs ?? stats.lastOrderAt;
      final online =
          c.isOnline ||
          (last != null && DateTime.now().difference(last).inMinutes < 5);

      return CustomerEnriched(
        customer: c.copyWith(isOnline: online),
        stats: stats,
      );
    }).toList();

    summary = CustomerStatsAggregator.summarize(
      customers: _enriched,
      totalRevenue: totalRevenue,
    );
    _dataVersion++;
  }

  List<CustomerEnriched> _filteredList() {
    var list = List<CustomerEnriched>.from(_enriched);
    final todayStart = AdminDateRanges.todayStart;
    final weekAgo = todayStart.subtract(const Duration(days: 7));

    switch (segment) {
      case CustomerSegment.allCustomers:
        break;
      case CustomerSegment.activeUsers:
        list = list.where((e) {
          if (_isBlocked(e)) return false;
          final last = e.customer.lastActiveTs ?? e.stats.lastOrderAt;
          return last != null && !last.isBefore(todayStart);
        }).toList();
      case CustomerSegment.blockedUsers:
        list = list.where(_isBlocked).toList();
      case CustomerSegment.newUsers:
        list = list.where((e) {
          final j = e.customer.createdAtTs;
          return j != null && !j.isBefore(weekAgo);
        }).toList();
    }

    switch (quickFilter) {
      case CustomerQuickFilter.none:
        break;
      case CustomerQuickFilter.highSpending:
        list = list.where((e) => e.stats.totalSpend >= 5000).toList();
      case CustomerQuickFilter.noOrders:
        list = list.where((e) => e.stats.totalOrders == 0).toList();
    }

    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) {
        final c = e.customer;
        final hay = '${c.name} ${c.phoneNumber} ${c.email} ${e.displayId}'
            .toLowerCase();
        return hay.contains(q);
      }).toList();
    }

    return list;
  }

  List<CustomerEnriched> _sortedList() {
    final key = _listCacheKey;
    if (_sortedCache != null && _sortedCacheKey == key) {
      return _sortedCache!;
    }

    final list = List<CustomerEnriched>.from(_filteredList());
    list.sort((a, b) {
      final result = switch (sortField) {
        CustomerSortField.name => _compareString(
          a.customer.name,
          b.customer.name,
        ),
        CustomerSortField.orders => a.stats.totalOrders.compareTo(
          b.stats.totalOrders,
        ),
        CustomerSortField.spend => a.stats.totalSpend.compareTo(
          b.stats.totalSpend,
        ),
        CustomerSortField.lastActive => _compareDate(
          a.customer.lastActiveTs ?? a.stats.lastOrderAt,
          b.customer.lastActiveTs ?? b.stats.lastOrderAt,
        ),
      };
      return sortAscending ? result : -result;
    });

    _sortedCache = list;
    _sortedCacheKey = key;
    return list;
  }

  static int _compareString(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  static int _compareDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  static bool _isBlocked(CustomerEnriched e) =>
      e.customer.isBlocked ||
      e.customer.status == CustomerAccountStatus.blocked;

  void setSegment(CustomerSegment s) {
    if (segment == s) return;
    segment = s;
    quickFilter = CustomerQuickFilter.none;
    visibleCount = pageSize;
    _invalidateSortCache();
    notifyListeners();
  }

  void setQuickFilter(CustomerQuickFilter f) {
    quickFilter = quickFilter == f ? CustomerQuickFilter.none : f;
    visibleCount = pageSize;
    _invalidateSortCache();
    notifyListeners();
  }

  void setSearch(String value) {
    if (searchQuery == value) return;
    searchQuery = value;
    visibleCount = pageSize;
    _invalidateSortCache();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!_disposed) notifyListeners();
    });
  }

  void toggleSort(CustomerSortField field) {
    if (sortField == field) {
      sortAscending = !sortAscending;
    } else {
      sortField = field;
      sortAscending = field.defaultAscending;
    }
    visibleCount = pageSize;
    _invalidateSortCache();
    notifyListeners();
  }

  String sortHintFor(CustomerSortField field) {
    if (sortField != field) return '';
    return field.hintFor(sortAscending);
  }

  void loadMore() {
    visibleCount += pageSize;
    notifyListeners();
  }

  Future<void> setBlocked(String docId, bool blocked) async {
    await _db.collection('customers').doc(docId).set({
      'is_blocked': blocked,
      'account_status': blocked ? 'blocked' : 'active',
    }, SetOptions(merge: true));
  }

  Future<void> deleteCustomer(String docId) async {
    await _db.collection('customers').doc(docId).delete();
  }

  Future<void> loadProfile(String uid) async {
    profileLoading = true;
    profileAddresses = null;
    profileOrders = null;
    notifyListeners();
    try {
      final addrSnap = await _db
          .collection('address')
          .where('user_id', isEqualTo: uid)
          .get();
      profileAddresses = addrSnap.docs
          .map((d) => AddressModel.fromFirestore(d.data(), d.id))
          .toList();

      final orderSnap = await _db
          .collection('orders')
          .where('uuid', isEqualTo: uid)
          .get();
      profileOrders =
          orderSnap.docs
              .map((d) => OrderModel.fromFirestore(d.data(), d.id))
              .toList()
            ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
    } catch (e) {
      if (kDebugMode) debugPrint('loadProfile: $e');
    } finally {
      profileLoading = false;
      notifyListeners();
    }
  }

  CustomerEnriched? findEnriched(String docId) {
    for (final e in _enriched) {
      if (e.displayId == docId) return e;
    }
    return null;
  }

  void _invalidateSortCache() {
    _sortedCache = null;
    _sortedCacheKey = -1;
  }

  static DateTime? _parse(dynamic v) {
    if (v is Timestamp) return v.toDate().toLocal();
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  void _scheduleNotify() {
    if (_disposed) return;
    _notifyDebounce?.cancel();
    _notifyDebounce = Timer(const Duration(milliseconds: 60), () {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _customersSub?.cancel();
    _ordersSub?.cancel();
    _searchDebounce?.cancel();
    _notifyDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
