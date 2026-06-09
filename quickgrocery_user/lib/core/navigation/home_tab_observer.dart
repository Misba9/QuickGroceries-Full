import 'package:flutter/foundation.dart';

/// Tracks the bottom-tab index without requiring [BuildContext] above the
/// navigator. Updated by [HomeProvider.onSelectedChange] and read by
/// [GlobalCartVisibility].
class HomeTabObserver {
  HomeTabObserver._();

  static final ValueNotifier<int> selectedIndexListenable = ValueNotifier(0);
}
