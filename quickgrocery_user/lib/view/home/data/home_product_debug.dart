import 'package:flutter/foundation.dart';

/// Debug-only logging for the dynamic home product pipeline.
///
/// Verbose traces are off by default — enable [verbose] when diagnosing
/// explore/index issues. Errors still print in debug.
bool homeProductsVerbose = false;

void logHomeProducts(String message, {bool error = false}) {
  if (!kDebugMode) return;
  if (!error && !homeProductsVerbose) return;
  debugPrint('[HomeProducts] $message');
}
