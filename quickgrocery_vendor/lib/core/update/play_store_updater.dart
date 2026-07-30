import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:quickgrocery_vendor/core/update/store_links.dart';

class PlayStoreUpdater {
  const PlayStoreUpdater();

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await InAppUpdate.checkForUpdate();
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] Play check failed: $e');
      return null;
    }
  }

  Future<bool> performImmediateUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] immediate failed: $e');
      await openPlayStoreListing();
      return false;
    }
  }

  Future<bool> startFlexibleUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] flexible failed: $e');
      return false;
    }
  }

  Future<bool> completeFlexibleUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      await InAppUpdate.completeFlexibleUpdate();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] complete flexible failed: $e');
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
