import 'package:connectivity_plus/connectivity_plus.dart';

/// Lightweight connectivity helper for phone auth.
abstract final class PhoneAuthNetwork {
  static Future<bool> hasConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isEmpty) return false;
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      // If the plugin fails, allow the request — Firebase will error if offline.
      return true;
    }
  }
}
