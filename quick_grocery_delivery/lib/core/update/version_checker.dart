import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quick_grocery_delivery/core/update/app_update_config.dart';
import 'package:quick_grocery_delivery/core/update/version_compare.dart';

class VersionChecker {
  VersionChecker({PackageInfo? packageInfo}) : _packageInfo = packageInfo;

  final PackageInfo? _packageInfo;

  Future<String> installedVersion({String? fakeInstalled}) async {
    if (fakeInstalled != null) return fakeInstalled;
    if (_packageInfo != null) return _packageInfo.version;
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<UpdateDecision> evaluate(
    AppUpdateConfig config, {
    String? fakeInstalled,
  }) async {
    final installed = await installedVersion(fakeInstalled: fakeInstalled);
    final belowMin = isVersionLower(installed, config.minimumSupportedVersion);
    final hasNewer = isVersionHigher(config.latestVersion, installed);
    final force = config.forceUpdate || belowMin;
    final available = hasNewer || force;

    if (kDebugMode) {
      debugPrint(
        '[AppUpdate] installed=$installed latest=${config.latestVersion} '
        'force=$force available=$available',
      );
    }

    return UpdateDecision(
      installedVersion: installed,
      config: config,
      updateAvailable: available,
      forceUpdate: force,
    );
  }
}
