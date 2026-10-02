import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/account/account_deletion_exception.dart';

/// Deletes the signed-in customer's personal data + Firebase Auth user.
///
/// Only operates on [FirebaseAuth.instance.currentUser.uid] — never accepts
/// an arbitrary UID. Shared catalog collections are not deleted; the user's
/// UID is removed from favorite arrays only.
class AccountDeletionService {
  AccountDeletionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const _batchLimit = 450;

  /// Phase 1: remove user-owned Firestore/Storage data for [uid].
  /// Must run while the user is still authenticated.
  Future<void> deleteUserOwnedData(String uid) async {
    if (uid.isEmpty) {
      throw AccountDeletionException(AccountDeletionErrorKind.notSignedIn);
    }
    final current = _auth.currentUser;
    if (current == null || current.uid != uid) {
      throw AccountDeletionException(AccountDeletionErrorKind.notSignedIn);
    }

    try {
      // Capture profile image URL before wiping the customer doc.
      String? profileImageUrl;
      try {
        final snap = await _db.collection('customers').doc(uid).get();
        profileImageUrl = (snap.data()?['profile_image'] ?? '').toString();
        if (profileImageUrl.isEmpty) profileImageUrl = null;
      } catch (_) {}

      // Stop pushes early.
      await _safeUpdate('customers/$uid', {
        'fcmToken': FieldValue.delete(),
        'fcm_token': FieldValue.delete(),
        'fcmTopics': FieldValue.delete(),
      });

      await _deleteSubcollection('notifications/$uid/items');
      await _safeDeleteDoc('notifications/$uid');
      await _deleteSubcollection('customers/$uid/notification_inbox');

      await _safeDeleteDoc('cart/$uid');
      await _deleteQuery(
        _db.collection('abandoned_carts').where('userId', isEqualTo: uid),
      );

      await _deleteQuery(
        _db.collection('address').where('user_id', isEqualTo: uid),
      );

      await _deleteQuery(
        _db
            .collection('order_idempotency')
            .where('uid', isEqualTo: uid),
      );

      await _deleteQuery(
        _db
            .collection('tip_transactions')
            .where('customerId', isEqualTo: uid),
      );

      await _deleteQuery(
        _db.collection('coupon_usages').where('userId', isEqualTo: uid),
      );

      // Reviews + review images.
      final ratings = await _db
          .collection('ratings')
          .where('user_id', isEqualTo: uid)
          .get();
      for (final doc in ratings.docs) {
        await _safeDeleteDoc(doc.reference.path);
      }
      await _deleteStorageFolder('review_images/$uid');

      // Wishlist / favorites — strip UID only (do not delete products).
      await _stripUidFromProductArrays(uid);

      // Anonymize order PII (retain financial records; clear personal data).
      await _anonymizeOrders(uid);

      // Referral artifacts owned by this user.
      await _deleteQuery(
        _db.collection('referral_codes').where('user_id', isEqualTo: uid),
      );
      await _deleteQuery(
        _db.collection('referrals').where('referrer_id', isEqualTo: uid),
      );
      await _deleteQuery(
        _db.collection('referrals').where('referred_user_id', isEqualTo: uid),
      );

      // Clear reverse referral pointers on other customers (best-effort).
      try {
        final referred = await _db
            .collection('customers')
            .where('referred_by', isEqualTo: uid)
            .limit(50)
            .get();
        for (final doc in referred.docs) {
          await _safeUpdate(doc.reference.path, {
            'referred_by': FieldValue.delete(),
            'referral_code_used': FieldValue.delete(),
            'referral_id': FieldValue.delete(),
          });
        }
      } catch (_) {}

      if (profileImageUrl != null) {
        await _deleteStorageUrl(profileImageUrl);
      }

      await _safeDeleteDoc('users/$uid');

      // Customer profile is required for Apple-compliant deletion — fail hard.
      try {
        await _db.collection('customers').doc(uid).delete();
      } on FirebaseException catch (e) {
        throw _mapFirebaseException(e);
      }
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      if (e is AccountDeletionException) rethrow;
      throw AccountDeletionException(
        AccountDeletionErrorKind.dataFailed,
        message: e.toString(),
        cause: e,
      );
    }
  }

  /// Phase 2: delete the Firebase Auth user. May throw
  /// [AccountDeletionErrorKind.requiresRecentLogin].
  Future<void> deleteAuthUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AccountDeletionException(AccountDeletionErrorKind.notSignedIn);
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AccountDeletionException(
          AccountDeletionErrorKind.requiresRecentLogin,
          message: e.message,
          cause: e,
        );
      }
      if (e.code == 'network-request-failed') {
        throw AccountDeletionException(
          AccountDeletionErrorKind.network,
          message: e.message,
          cause: e,
        );
      }
      throw AccountDeletionException(
        AccountDeletionErrorKind.authFailed,
        message: e.message ?? e.code,
        cause: e,
      );
    }
  }

  /// Full delete: owned data → Auth user.
  Future<void> deleteCurrentAccount({
    Future<void> Function()? onRequiresRecentLogin,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AccountDeletionException(AccountDeletionErrorKind.notSignedIn);
    }
    final uid = user.uid;

    await deleteUserOwnedData(uid);

    try {
      await deleteAuthUser();
    } on AccountDeletionException catch (e) {
      if (e.kind != AccountDeletionErrorKind.requiresRecentLogin) rethrow;
      if (onRequiresRecentLogin == null) rethrow;
      await onRequiresRecentLogin();
      // Ensure same UID after reauth.
      final refreshed = _auth.currentUser;
      if (refreshed == null || refreshed.uid != uid) {
        throw AccountDeletionException(AccountDeletionErrorKind.notSignedIn);
      }
      await deleteAuthUser();
    }
  }

  Future<void> _stripUidFromProductArrays(String uid) async {
    for (final field in const ['is_favorite', 'favorites']) {
      try {
        QuerySnapshot<Map<String, dynamic>> snap;
        do {
          snap = await _db
              .collection('products')
              .where(field, arrayContains: uid)
              .limit(100)
              .get();
          for (final doc in snap.docs) {
            await _safeUpdate(doc.reference.path, {
              'is_favorite': FieldValue.arrayRemove([uid]),
              'favorites': FieldValue.arrayRemove([uid]),
            });
          }
        } while (snap.docs.isNotEmpty);
      } catch (e) {
        if (kDebugMode) debugPrint('[AccountDeletion] strip $field failed: $e');
      }
    }
  }

  Future<void> _anonymizeOrders(String uid) async {
    try {
      final snap =
          await _db.collection('orders').where('uuid', isEqualTo: uid).get();
      for (final doc in snap.docs) {
        await _safeUpdate(doc.reference.path, {
          'name': 'Deleted User',
          'customerName': 'Deleted User',
          'mobile': '',
          'phone': '',
          'email': '',
          'address': '',
          'currentLocation': '',
          'accountDeleted': true,
          'accountDeletedAt': FieldValue.serverTimestamp(),
        });
        // Best-effort: clear support chat messages under the order.
        await _deleteSubcollection('${doc.reference.path}/support_messages');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AccountDeletion] anonymize orders failed: $e');
    }
  }

  Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snap;
      do {
        snap = await query.limit(_batchLimit).get();
        if (snap.docs.isEmpty) break;
        await _commitDeletes(snap.docs.map((d) => d.reference).toList());
      } while (snap.docs.length >= _batchLimit);
    } catch (e) {
      if (kDebugMode) debugPrint('[AccountDeletion] query delete failed: $e');
    }
  }

  Future<void> _deleteSubcollection(String path) async {
    try {
      final col = _db.collection(path);
      QuerySnapshot<Map<String, dynamic>> snap;
      do {
        snap = await col.limit(_batchLimit).get();
        if (snap.docs.isEmpty) break;
        await _commitDeletes(snap.docs.map((d) => d.reference).toList());
      } while (snap.docs.isNotEmpty);
    } catch (e) {
      if (kDebugMode) debugPrint('[AccountDeletion] subcollection $path failed: $e');
    }
  }

  Future<void> _commitDeletes(List<DocumentReference> refs) async {
    if (refs.isEmpty) return;
    WriteBatch batch = _db.batch();
    var count = 0;
    for (final ref in refs) {
      batch.delete(ref);
      count++;
      if (count >= _batchLimit) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  Future<void> _safeDeleteDoc(String path) async {
    try {
      await _db.doc(path).delete();
    } catch (e) {
      if (kDebugMode) debugPrint('[AccountDeletion] delete $path failed: $e');
    }
  }

  Future<void> _safeUpdate(String path, Map<String, dynamic> data) async {
    try {
      await _db.doc(path).update(data);
    } catch (e) {
      if (kDebugMode) debugPrint('[AccountDeletion] update $path failed: $e');
    }
  }

  Future<void> _deleteStorageFolder(String path) async {
    try {
      final list = await _storage.ref(path).listAll();
      for (final item in list.items) {
        try {
          await item.delete();
        } catch (_) {}
      }
      for (final prefix in list.prefixes) {
        await _deleteStorageFolder(prefix.fullPath);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AccountDeletion] storage folder $path failed: $e');
    }
  }

  Future<void> _deleteStorageUrl(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      if (kDebugMode) debugPrint('[AccountDeletion] storage url delete failed: $e');
    }
  }

  AccountDeletionException _mapFirebaseException(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return AccountDeletionException(
        AccountDeletionErrorKind.permissionDenied,
        message: e.message,
        cause: e,
      );
    }
    if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
      return AccountDeletionException(
        AccountDeletionErrorKind.network,
        message: e.message,
        cause: e,
      );
    }
    return AccountDeletionException(
      AccountDeletionErrorKind.dataFailed,
      message: e.message ?? e.code,
      cause: e,
    );
  }
}
