import 'package:flutter/foundation.dart';

/// Fires when [LandingScreen] is mounted — used to refresh the floating cart
/// overlay after auth splash / maintenance gates on cold start.
class HomeShellObserver {
  HomeShellObserver._();

  static final ValueNotifier<int> readyTick = ValueNotifier(0);

  static void markReady() {
    readyTick.value++;
  }
}
