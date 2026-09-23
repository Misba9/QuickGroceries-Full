import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Canonical auth user stream — same source [AuthGate] relies on.
///
/// Emits [FirebaseAuth.instance.currentUser] **immediately** so the first
/// frame matches persisted sessions on cold start (Android release on physical
/// devices often delays the first [authStateChanges] event).
final authUserProvider = StreamProvider<User?>((ref) async* {
  yield FirebaseAuth.instance.currentUser;
  yield* FirebaseAuth.instance.authStateChanges();
});

/// Resolved user for synchronous checks.
///
/// Always prefer [FirebaseAuth.instance.currentUser]. After [signOut] the
/// auth stream / Riverpod [AsyncLoading] can still hold the previous [User]
/// — using that stale value makes the shell think the session is alive and
/// skip guest bootstrap (stuck splash / black screen).
User? resolveAuthUser(AsyncValue<User?> authAsync) {
  return FirebaseAuth.instance.currentUser;
}

/// True once we know whether the user is signed in or out.
bool isAuthResolved(AsyncValue<User?> authAsync) {
  if (authAsync.hasValue) return true;
  // Cold start: persisted session available before stream's first event.
  if (FirebaseAuth.instance.currentUser != null) return true;
  return !authAsync.isLoading;
}
