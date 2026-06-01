import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// 500ms vibration for new-order alerts (mobile only).
class VendorAlertVibration {
  VendorAlertVibration._();

  static Future<void> pulseNewOrder() async {
    if (kIsWeb) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;
      await Vibration.vibrate(duration: 500);
      if (kDebugMode) {
        debugPrint('[VendorNotify] vibration played (500ms)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VendorNotify] vibration failed: $e');
      }
    }
  }
}
