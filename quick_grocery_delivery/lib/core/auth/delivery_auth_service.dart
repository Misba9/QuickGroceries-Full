import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'delivery_auth_errors.dart';
import 'delivery_session_prefs.dart';
import 'partner_auth_api.dart';
import '../fcm_bootstrap.dart';
import '../../models/delivery_boy_model.dart';

class DeliveryLoginResult {
  const DeliveryLoginResult._({
    required this.success,
    this.deliveryBoyId,
    this.forcePasswordChange = false,
    this.error,
  });

  final bool success;
  final String? deliveryBoyId;
  final bool forcePasswordChange;
  final String? error;

  const DeliveryLoginResult.success(
    String deliveryBoyId, {
    bool forcePasswordChange = false,
  }) : this._(
          success: true,
          deliveryBoyId: deliveryBoyId,
          forcePasswordChange: forcePasswordChange,
        );

  const DeliveryLoginResult.failure(String message)
      : this._(success: false, error: message);
}

/// Delivery authentication: Firebase Auth + Firestore `delivery_boys/{uid}`,
/// with partner Cloud Function fallback for legacy admin-created accounts.
class DeliveryAuthService {
  DeliveryAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    PartnerAuthApi? partnerApi,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _partnerApi = partnerApi ?? PartnerAuthApi();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final PartnerAuthApi _partnerApi;

  User? get currentUser => _auth.currentUser;

  Future<DeliveryLoginResult> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    DeliveryAuthErrors.logDebug('login email=$normalizedEmail');

    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const DeliveryLoginResult.failure('Enter email and password.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final uid = credential.user?.uid;
      DeliveryAuthErrors.logDebug('Firebase Auth UID=$uid');

      if (uid == null || uid.isEmpty) {
        await _logoutSafely();
        return const DeliveryLoginResult.failure('Delivery account not found.');
      }

      final blocked = await _blockedReason(uid);
      if (blocked != null) {
        await _logoutSafely();
        return DeliveryLoginResult.failure(blocked);
      }

      await _persistSession(uid);
      await DeliveryFcmBootstrap.configureForRider(uid);
      return DeliveryLoginResult.success(uid);
    } on FirebaseAuthException catch (e) {
      DeliveryAuthErrors.logDebug('FirebaseAuth code=${e.code}');

      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        return _loginViaPartner(normalizedEmail, password);
      }
      if (e.code == 'wrong-password') {
        return const DeliveryLoginResult.failure('Invalid password.');
      }
      if (e.code == 'user-disabled') {
        return const DeliveryLoginResult.failure('Your account has been suspended.');
      }
      return DeliveryLoginResult.failure(
        DeliveryAuthErrors.fromFirebaseAuthException(e),
      );
    } catch (e) {
      DeliveryAuthErrors.logDebug('login error: $e');
      await _logoutSafely();
      return DeliveryLoginResult.failure(DeliveryAuthErrors.fromException(e));
    }
  }

  Future<String?> restoreSession() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        DeliveryAuthErrors.logDebug('restore Firebase uid=${user.uid}');
        final blocked = await _blockedReason(user.uid);
        if (blocked == null) {
          await _persistSession(user.uid);
          await DeliveryFcmBootstrap.configureForRider(user.uid);
          return user.uid;
        }
        await _logoutSafely();
      }

      final id = await DeliverySessionPrefs.deliveryBoyId();
      if (id == null || id.isEmpty) return null;

      final version = await DeliverySessionPrefs.sessionVersion();
      if (version != null) {
        final check = await _partnerApi.checkSession(
          partnerId: id,
          sessionVersion: version,
        );
        if (check['valid'] != true) {
          await _logoutSafely();
          return null;
        }
      }

      final blocked = await _blockedReason(id);
      if (blocked != null) {
        await _logoutSafely();
        return null;
      }

      return id;
    } catch (e) {
      DeliveryAuthErrors.logDebug('restoreSession error: $e');
      await _logoutSafely();
      return null;
    }
  }

  Future<bool> validateStoredSession() async {
    final restored = await restoreSession();
    return restored != null && restored.isNotEmpty;
  }

  Future<void> logout() async {
    await _logoutSafely();
  }

  Future<String?> _blockedReason(String uid) async {
    try {
      final doc = await _firestore.collection('delivery_boys').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return 'Delivery boy data not found.';
      }
      final data = doc.data()!;
      final isActive = data['isActive'] == true || data['is_active'] == true;
      if (!isActive) {
        return 'Your account has been suspended.';
      }
      return null;
    } on FirebaseException catch (e) {
      DeliveryAuthErrors.logDebug('blockedReason: ${e.code}');
      if (e.code == 'permission-denied') {
        return 'Unable to load delivery profile. Please sign in again.';
      }
      return 'Could not verify delivery account.';
    }
  }

  Future<DeliveryLoginResult> _loginViaPartner(
    String email,
    String password,
  ) async {
    DeliveryAuthErrors.logDebug('trying partner login fallback');
    try {
      final result = await _partnerApi.login(email, password);
      if (result['success'] != true) {
        final msg = result['error']?.toString() ?? 'Invalid email or password.';
        return DeliveryLoginResult.failure(msg);
      }

      final partnerId = result['partnerId'] as String?;
      if (partnerId == null || partnerId.isEmpty) {
        return const DeliveryLoginResult.failure('Invalid email or password.');
      }

      final blocked = await _blockedReason(partnerId);
      if (blocked != null) {
        return DeliveryLoginResult.failure(blocked);
      }

      final sessionVersion = (result['sessionVersion'] as num?)?.toInt() ?? 0;
      final forceChange = result['forcePasswordChange'] == true;

      await DeliverySessionPrefs.saveLogin(
        deliveryBoyId: partnerId,
        sessionVersion: sessionVersion,
        forcePasswordChange: forceChange,
      );
      await DeliveryFcmBootstrap.configureForRider(partnerId);

      return DeliveryLoginResult.success(
        partnerId,
        forcePasswordChange: forceChange,
      );
    } catch (e) {
      return DeliveryLoginResult.failure(DeliveryAuthErrors.fromException(e));
    }
  }

  Future<void> _persistSession(String deliveryBoyId) async {
    await DeliverySessionPrefs.saveLogin(
      deliveryBoyId: deliveryBoyId,
      sessionVersion: 0,
      forcePasswordChange: false,
    );
  }

  Future<void> _logoutSafely() async {
    try {
      await DeliveryFcmBootstrap.clearForLogout();
    } catch (e) {
      DeliveryAuthErrors.logDebug('clearForLogout: $e');
    }
    try {
      await _auth.signOut();
    } catch (e) {
      DeliveryAuthErrors.logDebug('signOut: $e');
    }
    await DeliverySessionPrefs.clear();
  }

  Future<DeliveryBoyModel?> fetchProfile(String uid) async {
    try {
      final doc = await _firestore.collection('delivery_boys').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return DeliveryBoyModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      DeliveryAuthErrors.logDebug('fetchProfile: $e');
      return null;
    }
  }
}
