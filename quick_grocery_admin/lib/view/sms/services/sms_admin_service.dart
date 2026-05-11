import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/view/sms/models/sms_models.dart';
import 'package:quick_grocery_admin/view/sms/services/admin_sms_auth.dart';
import 'package:quick_grocery_admin/view/sms/services/sms_functions_client.dart';

/// Row from customer search — [docId] is the Firestore document id (path key).
class SmsUserSearchRow {
  SmsUserSearchRow({required this.docId, required this.customer});

  final String docId;
  final CustomerModel customer;
}

/// Firestore collections + Cloud Functions orchestration for SMS admin.
class SmsAdminService extends ChangeNotifier {
  SmsAdminService({
    FirebaseFirestore? firestore,
    SmsFunctionsClient? functionsClient,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _fn = functionsClient ?? SmsFunctionsClient();

  final FirebaseFirestore _db;
  final SmsFunctionsClient _fn;

  static const templatesCol = 'sms_templates';
  static const campaignsCol = 'sms_campaigns';
  static const logsCol = 'sms_logs';

  bool busy = false;
  String? lastError;

  /// Prefix search in memory (first [cap] customers) — good for small/medium DBs.
  Future<List<SmsUserSearchRow>> searchCustomers(String query,
      {int cap = 300}) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];
    final snap = await _db.collection('customers').limit(cap).get();
    final list = <SmsUserSearchRow>[];
    for (final d in snap.docs) {
      final c = CustomerModel.fromFirestore(d.data(), d.id);
      final match = c.name.toLowerCase().contains(q) ||
          c.phoneNumber.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q);
      if (match) {
        list.add(SmsUserSearchRow(docId: d.id, customer: c));
        if (list.length >= 20) break;
      }
    }
    return list;
  }

  Stream<List<SmsTemplate>> watchTemplates() {
    return _db
        .collection(templatesCol)
        .orderBy('title')
        .snapshots()
        .map((s) => s.docs.map(SmsTemplate.fromDoc).toList());
  }

  Stream<List<SmsLog>> watchLogs({int limit = 200}) {
    return _db
        .collection(logsCol)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(SmsLog.fromDoc).toList());
  }

  Stream<List<SmsCampaign>> watchRecentCampaigns() {
    return _db
        .collection(campaignsCol)
        .orderBy('createdAt', descending: true)
        .limit(25)
        .snapshots()
        .map((s) => s.docs.map(SmsCampaign.fromDoc).toList());
  }

  Future<void> saveTemplate({
    String? id,
    required String title,
    required String message,
    String type = 'promotion',
  }) async {
    final doc = id == null
        ? _db.collection(templatesCol).doc()
        : _db.collection(templatesCol).doc(id);
    await doc.set(
      SmsTemplate(
        id: doc.id,
        title: title,
        message: message,
        type: type,
      ).toWrite(),
      SetOptions(merge: true),
    );
  }

  Future<void> deleteTemplate(String id) async {
    await _db.collection(templatesCol).doc(id).delete();
  }

  Future<void> sendSingle({
    required String phone,
    required String message,
    String? userId,
    String? title,
  }) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      await _fn.sendSingleSMS(
        phone: phone,
        message: message,
        userId: userId,
        title: title,
      );
    } catch (e) {
      lastError = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String> enqueueBroadcast({
    required String title,
    required String message,
    required String targetType,
    DateTime? scheduledAt,
  }) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final res = await _fn.enqueueBroadcastSMS(
        title: title,
        message: message,
        targetType: targetType,
        scheduledAt: scheduledAt,
      );
      return (res['campaignId'] ?? res['id'] ?? '').toString();
    } catch (e) {
      lastError = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> resumeBroadcast(String campaignId) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      await _fn.resumeBroadcastSMS(campaignId: campaignId);
    } catch (e) {
      lastError = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> retryFailed({int max = 25}) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      await _fn.retryFailedSMS(max: max);
    } catch (e) {
      lastError = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Refreshes ID token so new custom claims appear on the client.
  Future<void> refreshAuthToken() async {
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
  }

  /// Sets full notification claims when this user exists in Firestore `admins`.
  Future<Map<String, dynamic>> syncClaimsFromAdminsFirestore() async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final r = await _fn.syncAdminClaimsFromAdmins();
      await refreshAuthToken();
      return r;
    } catch (e) {
      lastError = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// One-time self-elevate when `ADMIN_BOOTSTRAP_SECRET` is set on Cloud Functions.
  Future<Map<String, dynamic>> applyAdminClaimsBootstrap(String secret) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final r = await _fn.setAdminClaims(bootstrapSecret: secret.trim());
      await refreshAuthToken();
      return r;
    } catch (e) {
      lastError = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Existing elevated admin can grant another Firebase Auth user full admin SMS claims.
  Future<Map<String, dynamic>> promoteUserToAdmin(String targetUid) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final r = await _fn.setAdminClaims(uid: targetUid.trim());
      await refreshAuthToken();
      return r;
    } catch (e) {
      lastError = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  static Future<bool> canManageSms({bool forceRefresh = true}) =>
      currentUserCanManageSms(forceRefresh: forceRefresh);
}
