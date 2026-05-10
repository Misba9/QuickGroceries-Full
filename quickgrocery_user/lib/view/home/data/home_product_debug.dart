import 'package:flutter/foundation.dart';

/// Debug-only logging for the dynamic home product pipeline.
///
/// Enable verbose traces during development; stays silent in release builds.
void logHomeProducts(String message) {
  if (kDebugMode) {
    debugPrint('[HomeProducts] $message');
  }
}
