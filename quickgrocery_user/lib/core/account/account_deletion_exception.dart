/// Typed failures for Apple-compliant account deletion.
enum AccountDeletionErrorKind {
  notSignedIn,
  network,
  permissionDenied,
  requiresRecentLogin,
  authFailed,
  dataFailed,
  cancelled,
  unknown,
}

class AccountDeletionException implements Exception {
  AccountDeletionException(
    this.kind, {
    this.message,
    this.cause,
  });

  final AccountDeletionErrorKind kind;
  final String? message;
  final Object? cause;

  @override
  String toString() =>
      'AccountDeletionException($kind${message != null ? ': $message' : ''})';
}
