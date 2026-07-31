import 'package:package_info_plus/package_info_plus.dart';

import 'package:quickgrocery/core/update/app_update_config.dart';
import 'package:quickgrocery/core/update/version_compare.dart';

/// Compares the installed app version against Remote Config.
class VersionChecker {
  VersionChecker({PackageInfo? packageInfo}) : _packageInfo = packageInfo;

  final PackageInfo? _packageInfo;

  /// Resolve installed version (injectable for tests).
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

    return UpdateDecision(
      installedVersion: installed,
      config: config,
      updateAvailable: available,
      forceUpdate: force,
    );
  }
}
