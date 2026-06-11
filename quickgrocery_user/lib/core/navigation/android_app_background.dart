import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sends the Android task to the background without destroying the activity.
abstract final class AndroidAppBackground {
  static const _channel = MethodChannel('com.quickgrocery.io/navigation');

  static Future<void> moveTaskToBack() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('moveTaskToBack');
    } on PlatformException {
      // Last-resort fallback if the platform channel is unavailable.
      SystemNavigator.pop();
    }
  }
}
