import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Canonical auth user stream — same source [AuthGate] relies on.
///
/// Emits [FirebaseAuth.instance.currentUser] **immediately** so the first
/// frame matches persisted sessions on cold start (Android release on physical
/// devices often delays the first [authStateChanges] event).
///
/// Safe before [Firebase.initializeApp]: yields `null` until apps exist.
final authUserProvider = StreamProvider<User?>((ref) async* {
  if (Firebase.apps.isEmpty) {
    yield null;
    return;
  }
  yield FirebaseAuth.instance.currentUser;
  yield* FirebaseAuth.instance.authStateChanges();
});

/// Resolved user for synchronous checks — prefers the synchronous getter so
/// cold-start session restore on physical devices matches [AuthGate].
User? resolveAuthUser(AsyncValue<User?> authAsync) {
  if (Firebase.apps.isEmpty) return null;
  final sync = FirebaseAuth.instance.currentUser;
  if (sync != null) return sync;
  // Signed out — never resurrect session from a stale stream event.
  if (!authAsync.isLoading) return null;
  return authAsync.valueOrNull;
}

/// True once we know whether the user is signed in or out.
bool isAuthResolved(AsyncValue<User?> authAsync) {
  if (Firebase.apps.isEmpty) return false;
  if (authAsync.hasValue) return true;
  // Cold start: persisted session available before stream's first event.
  if (FirebaseAuth.instance.currentUser != null) return true;
  return false;
}
