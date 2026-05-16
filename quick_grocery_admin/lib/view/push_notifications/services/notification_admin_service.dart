import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/view/push_notifications/models/notification_models.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/fcm_functions_client.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/notification_panel_auth.dart';

/// Row from customer search — [docId] is the Firestore document id.
class NotificationUserSearchRow {
  NotificationUserSearchRow({required this.docId, required this.customer});

  final String docId;
  final CustomerModel customer;
}

/// Firestore + Cloud Functions for FCM admin.
class NotificationAdminService extends ChangeNotifier {
  NotificationAdminService({
    FirebaseFirestore? firestore,
    FcmFunctionsClient? functionsClient,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _fn = functionsClient ?? FcmFunctionsClient();

  final FirebaseFirestore _db;
  final FcmFunctionsClient _fn;

  static const templatesCol = 'notification_templates';
  static const campaignsCol = 'notification_campaigns';
  static const logsCol = 'notification_logs';

  bool busy = false;
  String? lastError;

  Future<List<NotificationUserSearchRow>> searchCustomers(
    String query, {
    int cap = 300,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];
    final snap = await _db.collection('customers').limit(cap).get();
    final list = <NotificationUserSearchRow>[];
    for (final d in snap.docs) {
      final c = CustomerModel.fromFirestore(d.data(), d.id);
      final match = c.name.toLowerCase().contains(q) ||
          c.phoneNumber.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q);
      if (match) {
        list.add(NotificationUserSearchRow(docId: d.id, customer: c));
        if (list.length >= 20) break;
      }
    }
    return list;
  }

  Stream<List<NotificationTemplate>> watchTemplates() {
    return _db
        .collection(templatesCol)
        .orderBy('title')
        .snapshots()
        .map((s) => s.docs.map(NotificationTemplate.fromDoc).toList());
  }

  Stream<List<NotificationLog>> watchLogs({int limit = 200}) {
    return _db
        .collection(logsCol)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(NotificationLog.fromDoc).toList());
  }

  Stream<List<NotificationCampaign>> watchRecentCampaigns() {
    return _db
        .collection(campaignsCol)
        .orderBy('createdAt', descending: true)
        .limit(25)
        .snapshots()
        .map((s) => s.docs.map(NotificationCampaign.fromDoc).toList());
  }

  Future<String?> uploadBannerImage(XFile file) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final ref = FirebaseStorage.instance.ref().child(
          'notification_banners/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
    final bytes = await file.readAsBytes();
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<void> saveTemplate({
    String? id,
    required String title,
    required String message,
    String type = 'promotion',
    String? imageUrl,
  }) async {
    final doc = id == null
        ? _db.collection(templatesCol).doc()
        : _db.collection(templatesCol).doc(id);
    await doc.set(
      NotificationTemplate(
        id: doc.id,
        title: title,
        message: message,
        type: type,
        imageUrl: imageUrl,
      ).toWrite(),
      SetOptions(merge: true),
    );
  }

  Future<void> deleteTemplate(String id) async {
    await _db.collection(templatesCol).doc(id).delete();
  }

  Future<void> sendTopicPush({
    required String title,
    required String message,
    String? topic,
    String? targetAudience,
    String? imageUrl,
    String? deepLink,
    String? redirectType,
    String? ctaLabel,
    String? soundType,
  }) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      await _fn.sendTopicNotification(
        title: title,
        message: message,
        topic: topic,
        targetAudience: targetAudience,
        imageUrl: imageUrl,
        deepLink: deepLink,
        redirectType: redirectType,
        ctaLabel: ctaLabel,
        soundType: soundType,
      );
      await FirebaseAnalytics.instance.logEvent(
        name: 'admin_push_topic_sent',
        parameters: {
          'topic': topic ?? targetAudience ?? 'all_users',
        },
      );
    } catch (e) {
      lastError = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> sendSingleUserPush({
    required String userId,
    required String title,
    required String message,
    String? imageUrl,
    String? deepLink,
    String? redirectType,
    String? ctaLabel,
    String? soundType,
  }) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      await _fn.sendSingleNotification(
        userId: userId,
        title: title,
        message: message,
        imageUrl: imageUrl,
        deepLink: deepLink,
        redirectType: redirectType,
        ctaLabel: ctaLabel,
        soundType: soundType,
      );
      await FirebaseAnalytics.instance.logEvent(
        name: 'admin_push_single_sent',
      );
    } catch (e) {
      lastError = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String> scheduleTopicPush({
    required String title,
    required String message,
    required DateTime scheduledAt,
    String? topic,
    String? targetAudience,
    String? imageUrl,
    String? deepLink,
    String? redirectType,
    String? ctaLabel,
    String? soundType,
  }) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final res = await _fn.scheduleNotification(
        title: title,
        message: message,
        scheduledAt: scheduledAt,
        kind: 'topic',
        topic: topic,
        targetAudience: targetAudience,
        imageUrl: imageUrl,
        deepLink: deepLink,
        redirectType: redirectType,
        ctaLabel: ctaLabel,
        soundType: soundType,
      );
      return (res['campaignId'] ?? '').toString();
    } catch (e) {
      lastError = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshAuthToken() async {
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
  }

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

  static Future<bool> canManageNotifications({bool forceRefresh = true}) =>
      currentUserCanManageNotifications(forceRefresh: forceRefresh);
}
