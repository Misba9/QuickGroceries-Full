import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/admin_roles.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/notification_access_config.dart';

/// Resolves whether the signed-in user may use the Push Notifications panel.
///
/// Order: custom claims → Firestore `admins` collection (same as login) →
/// [kNotificationAdminEmailAllowlist] → optional signed-in fallback.
Future<bool> currentUserCanManageNotifications({bool forceRefresh = true}) async {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null) {
    debugLogNotificationAuth(
      uid: '',
      email: null,
      claims: const {},
      allowed: false,
      reason: 'no_user',
    );
    return false;
  }

  final t = await u.getIdTokenResult(forceRefresh);
  final c = t.claims ?? {};

  if (hasNotificationAccessFromClaims(c)) {
    debugLogNotificationAuth(
      uid: u.uid,
      email: u.email,
      claims: c,
      allowed: true,
      reason: 'claims',
    );
    return true;
  }

  final email = u.email?.trim();
  if (email != null && email.isNotEmpty) {
    final lower = email.toLowerCase();
    if (kNotificationAdminEmailAllowlist.contains(lower)) {
      debugLogNotificationAuth(
        uid: u.uid,
        email: u.email,
        claims: c,
        allowed: true,
        reason: 'email_allowlist',
      );
      return true;
    }

    for (final variant in _emailQueryVariants(email)) {
      final snap = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: variant)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        debugLogNotificationAuth(
          uid: u.uid,
          email: u.email,
          claims: c,
          allowed: true,
          reason: 'firestore_admins',
        );
        return true;
      }
    }
  }

  if (kAllowNotificationPanelForAnySignedInUser) {
    debugLogNotificationAuth(
      uid: u.uid,
      email: u.email,
      claims: c,
      allowed: true,
      reason: 'signed_in_fallback',
    );
    return true;
  }

  debugLogNotificationAuth(
    uid: u.uid,
    email: u.email,
    claims: c,
    allowed: false,
    reason: 'denied',
  );
  return false;
}

Iterable<String> _emailQueryVariants(String email) sync* {
  yield email;
  final t = email.trim();
  if (t != email) yield t;
  final lower = t.toLowerCase();
  if (lower != t) yield lower;
}
