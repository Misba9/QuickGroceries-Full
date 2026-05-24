import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/model/vendor_request_model.dart';
import 'package:quick_grocery_admin/view/vendor/services/admin_vendor_request_client.dart';

class VendorRequestService extends ChangeNotifier {
  VendorRequestService({
    FirebaseFirestore? firestore,
    AdminVendorRequestClient? client,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _client = client ?? AdminVendorRequestClient();

  final FirebaseFirestore _firestore;
  final AdminVendorRequestClient _client;

  List<VendorRequestModel>? requests;
  String? actionError;
  String? actionMessage;
  bool isActionLoading = false;
  String filterStatus = 'all';

  Stream<List<VendorRequestModel>> watchRequests() {
    if (kDebugMode) {
      debugPrint('[VendorRequestService] watching vendor_requests');
    }
    return _firestore
        .collection('vendor_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      if (kDebugMode) {
        debugPrint('[VendorRequestService] ${snap.docs.length} request(s)');
      }
      return snap.docs
          .map((d) => VendorRequestModel.fromFirestore(d.data(), d.id))
          .toList();
    });
  }

  Future<void> loadRequests() async {
    try {
      if (kDebugMode) {
        debugPrint('[VendorRequestService] loading vendor_requests');
      }
      final snap = await _firestore
          .collection('vendor_requests')
          .orderBy('createdAt', descending: true)
          .get();
      requests = snap.docs
          .map((d) => VendorRequestModel.fromFirestore(d.data(), d.id))
          .toList();
      if (kDebugMode) {
        debugPrint('[VendorRequestService] loaded ${requests!.length} request(s)');
      }
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[VendorRequestService] load error: $e\n$st');
      }
      actionError = e.toString();
      notifyListeners();
    }
  }

  List<VendorRequestModel> filtered(List<VendorRequestModel> all) {
    if (filterStatus == 'all') return all;
    return all.where((r) => r.status == filterStatus).toList();
  }

  void setFilter(String status) {
    filterStatus = status;
    notifyListeners();
  }

  void clearMessages() {
    actionError = null;
    actionMessage = null;
    notifyListeners();
  }

  Future<bool> approve(String requestId) async {
    isActionLoading = true;
    actionError = null;
    actionMessage = null;
    notifyListeners();
    try {
      final result = await _client.approve(requestId);
      actionMessage =
          'Vendor approved. Auth UID: ${result['authUid'] ?? 'created'}.';
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[VendorRequestService] approve error: $e\n$st');
      }
      actionError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reject(String requestId, String reason) async {
    isActionLoading = true;
    actionError = null;
    actionMessage = null;
    notifyListeners();
    try {
      await _client.reject(requestId, reason: reason);
      actionMessage = 'Request rejected.';
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[VendorRequestService] reject error: $e\n$st');
      }
      actionError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    isActionLoading = true;
    actionError = null;
    actionMessage = null;
    notifyListeners();
    try {
      await _client.deleteRequest(requestId);
      actionMessage = 'Request deleted.';
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[VendorRequestService] delete error: $e\n$st');
      }
      actionError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }
}
