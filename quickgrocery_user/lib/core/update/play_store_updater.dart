import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:quickgrocery/core/update/store_links.dart';

/// Android Play In-App Updates (flexible + immediate).
///
/// No-ops safely on non-Android platforms.
class PlayStoreUpdater {
  const PlayStoreUpdater();

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (kDebugMode) {
        debugPrint(
          '[AppUpdate] Play check availability=${info.updateAvailability} '
          'immediate=${info.immediateUpdateAllowed} '
          'flexible=${info.flexibleUpdateAllowed}',
        );
      }
      return info;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] Play check failed: $e');
      return null;
    }
  }

  /// Full-screen blocking update (critical).
  Future<bool> performImmediateUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      if (kDebugMode) debugPrint('[AppUpdate] immediate update started');
      final result = await InAppUpdate.performImmediateUpdate();
      if (kDebugMode) {
        debugPrint('[AppUpdate] immediate result=$result');
      }
      return result == AppUpdateResult.success;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] immediate failed: $e');
      await openPlayStoreListing();
      return false;
    }
  }

  /// Background download for flexible updates.
  Future<bool> startFlexibleUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      if (kDebugMode) debugPrint('[AppUpdate] flexible download started');
      final result = await InAppUpdate.startFlexibleUpdate();
      if (kDebugMode) {
        debugPrint('[AppUpdate] flexible download result=$result');
      }
      return result == AppUpdateResult.success;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] flexible download failed: $e');
      return false;
    }
  }

  /// Install a downloaded flexible update (restarts the app).
  Future<bool> completeFlexibleUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      await InAppUpdate.completeFlexibleUpdate();
      if (kDebugMode) debugPrint('[AppUpdate] flexible install success');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] flexible install failed: $e');
      return false;
    }
  }

  Future<bool> openPlayStoreListing() async {
    try {
      final uri = Uri.parse(StoreLinks.android);
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] open Play Store failed: $e');
    }
    return false;
  }
}
