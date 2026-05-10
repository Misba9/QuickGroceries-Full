/// Domain-level failure used by all home repositories.
///
/// Avoids leaking `FirebaseException` / network errors into the UI layer.
class HomeFailure implements Exception {
  const HomeFailure(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() =>
      'HomeFailure(${code ?? '-'}): $message${cause == null ? '' : ' (cause: $cause)'}';
}
