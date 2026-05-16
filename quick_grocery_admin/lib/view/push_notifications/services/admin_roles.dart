import 'package:flutter/foundation.dart';

/// Token-based access for push / notifications (align with Cloud Functions).
bool hasNotificationAccessFromClaims(Map<Object?, Object?> claims) {
  if (claims['superAdmin'] == true) return true;
  if (claims['admin'] == true) return true;
  if (claims['smsAdmin'] == true) return true;
  if (claims['notificationsAdmin'] == true) return true;
  final r = claims['role'];
  if (r == 'admin' || r == 'superAdmin' || r == 'smsAdmin') return true;
  return false;
}

bool hasSmsPanelAccess(Map<Object?, Object?> claims) =>
    hasNotificationAccessFromClaims(claims);

/// Can promote other users via `setAdminClaims` (not bootstrap).
bool hasElevatedAdmin(Map<Object?, Object?> claims) {
  if (claims['superAdmin'] == true) return true;
  if (claims['admin'] == true) return true;
  if (claims['notificationsAdmin'] == true) return true;
  final r = claims['role'];
  if (r == 'superAdmin' || r == 'admin') return true;
  return false;
}

void debugLogNotificationAuth({
  required String uid,
  String? email,
  required Map<Object?, Object?> claims,
  required bool allowed,
  String? reason,
}) {
  if (!kDebugMode) return;
  final claimStr = Map<String, Object?>.fromEntries(
    claims.entries.map((e) => MapEntry(e.key.toString(), e.value)),
  );
  debugPrint(
    '[NotificationAuth] uid=$uid email=$email allowed=$allowed '
    '${reason != null ? "reason=$reason " : ""}claims=$claimStr',
  );
}
