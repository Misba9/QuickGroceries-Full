import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/auth/partner_auth_api.dart';
import '../core/auth/password_reset_result.dart';
import '../core/auth/vendor_auth_errors.dart';
import '../core/auth/vendor_login_result.dart';
import '../models/vendor_model.dart';
import 'firebase_service.dart';
import 'preference_service.dart';
import 'vendor_document_service.dart';
import 'vendor_signup_pending_service.dart';

/// Vendor authentication: Firebase Auth + Firestore `vendors/{uid}`,
/// with partner Cloud Function fallback for legacy admin-created accounts.
class VendorAuthService {
  VendorAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    PartnerAuthApi? partnerApi,
    VendorDocumentService? documentService,
    VendorSignupPendingService? pendingService,
  })  : _auth = auth ?? FirebaseService.auth,
        _firestore = firestore ?? FirebaseService.firestore,
        _partnerApi = partnerApi ?? PartnerAuthApi(),
        _documents = documentService ?? VendorDocumentService(),
        _pending = pendingService ?? VendorSignupPendingService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final PartnerAuthApi _partnerApi;
  final VendorDocumentService _documents;
  final VendorSignupPendingService _pending;

  User? get currentUser => _auth.currentUser;

  Future<VendorLoginResult> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    VendorAuthErrors.logDebug('login email=$normalizedEmail');
    if (kDebugMode) {
      print('email: $normalizedEmail');
      print('password length: ${password.length}');
    }

    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const VendorLoginResult.failure('Enter email and password.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final uid = credential.user?.uid;
      VendorAuthErrors.logDebug('Firebase Auth UID=$uid');
      if (kDebugMode) {
        print('auth.uid: $uid');
      }

      if (uid == null || uid.isEmpty) {
        await _logoutSafely();
        return const VendorLoginResult.failure('Vendor account not found');
      }

      final vendor = await _fetchVendorAtUid(uid);
      if (vendor == null) {
        VendorAuthErrors.logDebug(
          'missing vendor doc uid=$uid path=${FirebaseService.vendorDocPath(uid)}',
        );
        await _logoutSafely();
        return const VendorLoginResult.failure('Vendor account not found');
      }

      final blocked = VendorModel.loginBlockedReason(vendor.toFirestore());
      if (blocked != null) {
        VendorAuthErrors.logDebug('login blocked: $blocked');
        await _logoutSafely();
        return VendorLoginResult.failure(blocked);
      }

      await _persistSession(vendor, sessionVersion: null, forcePasswordChange: false);
      VendorAuthErrors.logDebug('login success vendorId=${vendor.id} uid=$uid');
      return VendorLoginResult.success(vendor);
    } on FirebaseAuthException catch (e) {
      VendorAuthErrors.logDebug('FirebaseAuth code=${e.code} message=${e.message}');

      if (await _pending.isPending(normalizedEmail)) {
        return const VendorLoginResult.failure('Waiting for admin approval');
      }

      if (e.code == 'wrong-password') {
        return const VendorLoginResult.failure('Invalid password');
      }
      if (e.code == 'user-not-found') {
        return const VendorLoginResult.failure('Vendor account not approved yet');
      }
      if (e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        return const VendorLoginResult.failure('Invalid password');
      }
      if (e.code == 'user-disabled') {
        return const VendorLoginResult.failure('Your account is blocked');
      }
      if (_shouldTryPartnerLogin(e)) {
        return _loginViaPartner(normalizedEmail, password);
      }
      return VendorLoginResult.failure(_messageFromAuthException(e));
    } catch (e) {
      VendorAuthErrors.logDebug('login error: $e');
      await _logoutSafely();
      return VendorLoginResult.failure(VendorAuthErrors.fromException(e));
    }
  }

  Future<VendorModel?> _fetchVendorAtUid(String uid) async {
    try {
      final doc = await _documents.fetchByUid(uid);
      if (kDebugMode) {
        print('doc.exists: ${doc.exists}');
      }
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      if (doc.id != uid) {
        VendorAuthErrors.logDebug(
          'vendor doc id mismatch: doc.id=${doc.id} auth.uid=$uid',
        );
        return null;
      }
      return VendorModel.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      VendorAuthErrors.logDebug('fetchVendorAtUid: ${e.code} ${e.message}');
      return null;
    }
  }

  bool _shouldTryPartnerLogin(FirebaseAuthException e) {
    return e.code == 'user-not-found';
  }

  Future<VendorLoginResult> _loginViaPartner(
    String email,
    String password,
  ) async {
    VendorAuthErrors.logDebug('trying partner login fallback');
    try {
      final result = await _partnerApi.login(email, password);
      if (result['success'] != true) {
        final msg = result['error']?.toString() ?? 'Invalid email or password.';
        return VendorLoginResult.failure(msg);
      }

      final partnerId = result['partnerId'] as String?;
      if (partnerId == null || partnerId.isEmpty) {
        return const VendorLoginResult.failure('Invalid email or password.');
      }

      VendorAuthErrors.logDebug(
        'partner login partnerId=$partnerId path=${FirebaseService.vendorDocPath(partnerId)}',
      );

      final profile = Map<String, dynamic>.from(
        (result['profile'] as Map?)?.cast<String, dynamic>() ?? {},
      );
      profile['id'] = partnerId;

      final blocked = VendorModel.loginBlockedReason(profile);
      if (blocked != null) {
        return VendorLoginResult.failure(blocked);
      }

      final vendor = await _loadLegacyVendorDocument(
        vendorId: partnerId,
        profileFallback: profile,
      );

      if (vendor == null) {
        return const VendorLoginResult.failure('Vendor account not found');
      }

      final sessionVersion = (result['sessionVersion'] as num?)?.toInt() ?? 0;
      final forceChange = result['forcePasswordChange'] == true;
      await _ensureFirestoreAuthSession();
      await _persistSession(
        vendor,
        sessionVersion: sessionVersion,
        forcePasswordChange: forceChange,
      );
      return VendorLoginResult.success(vendor);
    } on VendorAuthException catch (e) {
      return VendorLoginResult.failure(e.message);
    } catch (e) {
      return VendorLoginResult.failure(VendorAuthErrors.fromException(e));
    }
  }

  Future<VendorModel?> _loadLegacyVendorDocument({
    required String vendorId,
    required Map<String, dynamic> profileFallback,
  }) async {
    try {
      final doc = await _documents.fetchByUid(vendorId);
      if (doc.exists && doc.data() != null) {
        return VendorModel.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      VendorAuthErrors.logDebug('legacy vendor load: $e');
    }
    return VendorModel.fromFirestore(profileFallback, vendorId);
  }

  Future<void> _ensureFirestoreAuthSession() async {
    if (_auth.currentUser != null) return;
    try {
      await _auth.signInAnonymously();
      VendorAuthErrors.logDebug(
        'anonymous Firebase session uid=${_auth.currentUser?.uid}',
      );
    } catch (e) {
      VendorAuthErrors.logDebug('anonymous sign-in failed: $e');
    }
  }

  Future<void> _persistSession(
    VendorModel vendor, {
    required int? sessionVersion,
    required bool forcePasswordChange,
  }) async {
    await PreferenceService.saveVendorId(vendor.id);
    await PreferenceService.saveVendorProfileCache(vendor.toFirestore());
    if (sessionVersion != null) {
      await PreferenceService.saveSessionVersion(sessionVersion);
    }
    await PreferenceService.setForcePasswordChange(forcePasswordChange);
  }

  Future<void> _logoutSafely() async {
    await FirebaseService.signOutSafely();
    await PreferenceService.clearVendorData();
  }

  Future<PasswordResetResult> sendPasswordResetEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    VendorAuthErrors.logDebug('password reset email=$normalized');
    if (kDebugMode) {
      print('email: $normalized');
    }

    if (normalized.isEmpty || !normalized.contains('@')) {
      throw VendorAuthException('Enter a valid email address.');
    }

    if (await _pending.isPending(normalized)) {
      throw VendorAuthException(
        'Waiting for admin approval. Reset password after your account is approved.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: normalized);
      VendorAuthErrors.logDebug('sendPasswordResetEmail success');
      if (kDebugMode) {
        print('Password reset email sent to: $normalized');
      }
      return const PasswordResetResult(
        message: 'Password reset email sent successfully',
      );
    } on FirebaseAuthException catch (e) {
      VendorAuthErrors.logDebug(
        'reset FirebaseAuth code=${e.code} message=${e.message}',
      );

      if (e.code == 'user-not-found') {
        throw VendorAuthException('Vendor account not approved yet');
      }
      if (e.code == 'network-request-failed') {
        throw VendorAuthException(
          'Network error. Check your connection and try again.',
        );
      }
      throw VendorAuthException(_messageFromAuthException(e));
    } catch (e) {
      VendorAuthErrors.logDebug('password reset error: $e');
      throw VendorAuthException(VendorAuthErrors.fromException(e));
    }
  }

  Future<VendorModel?> restoreSession() async {
    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      VendorAuthErrors.logDebug('restore Firebase uid=${user.uid}');
      if (kDebugMode) {
        print('Vendor UID: ${user.uid}');
      }
      final vendor = await _fetchVendorAtUid(user.uid);
      if (vendor != null &&
          VendorModel.loginBlockedReason(vendor.toFirestore()) == null) {
        return vendor;
      }
      await _logoutSafely();
    }

    final vendorId = await PreferenceService.getVendorId();
    if (vendorId == null || vendorId.isEmpty) return null;

    final sessionOk = await isPartnerSessionValid(vendorId);
    if (!sessionOk) {
      await PreferenceService.clearVendorData();
      return null;
    }

    return getVendorById(vendorId);
  }

  Future<bool> isPartnerSessionValid(String vendorId) async {
    try {
      final version = await PreferenceService.getSessionVersion();
      if (version == null) return true;
      final check = await _partnerApi.checkSession(
        partnerId: vendorId,
        sessionVersion: version,
      );
      return check['valid'] == true;
    } catch (e) {
      VendorAuthErrors.logDebug('session check failed: $e');
      return false;
    }
  }

  Future<VendorModel?> getVendorById(String vendorId) async {
    try {
      final doc = await _documents.fetchByUid(vendorId);
      if (doc.exists && doc.data() != null) {
        return VendorModel.fromFirestore(doc.data()!, doc.id);
      }
    } on FirebaseException catch (e) {
      VendorAuthErrors.logDebug('getVendorById: ${e.code}');
    }

    final cached = await PreferenceService.getVendorProfileCache();
    if (cached != null &&
        (cached['id']?.toString() ?? vendorId) == vendorId) {
      VendorAuthErrors.logDebug('getVendorById using cache');
      return VendorModel.fromFirestore(cached, vendorId);
    }
    return null;
  }

  Future<void> updateVendor(VendorModel vendor) async {
    final data = vendor.toFirestore();
    data.remove('password');
    await _firestore
        .doc(FirebaseService.vendorDocPath(vendor.id))
        .set(data, SetOptions(merge: true));
    await PreferenceService.saveVendorProfileCache(vendor.toFirestore());
  }

  Future<void> logout() async {
    await _logoutSafely();
  }

  Future<bool> shouldForcePasswordChange() =>
      PreferenceService.getForcePasswordChange();

  String _messageFromAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
      case 'invalid-login-credentials':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This vendor account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
