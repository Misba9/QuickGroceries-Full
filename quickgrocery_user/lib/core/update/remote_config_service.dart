import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/update/app_update_config.dart';

/// Fetches the JSON update payload from Firebase Remote Config.
///
/// Default parameter for the User app: [remoteConfigKey] = `user_app_update`.
class UpdateRemoteConfigService {
  UpdateRemoteConfigService({
    this.remoteConfigKey = 'user_app_update',
    FirebaseRemoteConfig? remoteConfig,
  }) : _rc = remoteConfig ?? FirebaseRemoteConfig.instance;

  final String remoteConfigKey;
  final FirebaseRemoteConfig _rc;

  /// Fetch + activate, then parse JSON. Returns [AppUpdateConfig.defaults]
  /// on any failure so the app continues gracefully.
  Future<AppUpdateConfig> fetchConfig({
    Duration minimumFetchInterval = const Duration(hours: 1),
  }) async {
    try {
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 12),
          minimumFetchInterval: minimumFetchInterval,
        ),
      );
      await _rc.setDefaults({
        remoteConfigKey: jsonEncode(AppUpdateConfig.defaults.toJson()),
      });
      await _rc.fetchAndActivate();

      final raw = _rc.getString(remoteConfigKey).trim();
      if (raw.isEmpty) {
        if (kDebugMode) {
          debugPrint('[AppUpdate] RC key "$remoteConfigKey" empty');
        }
        return AppUpdateConfig.defaults;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        if (kDebugMode) {
          debugPrint('[AppUpdate] RC value is not a JSON object');
        }
        return AppUpdateConfig.defaults;
      }
      final config =
          AppUpdateConfig.fromJson(Map<String, dynamic>.from(decoded));
      if (kDebugMode) {
        debugPrint(
          '[AppUpdate] RC loaded key=$remoteConfigKey '
          'latest=${config.latestVersion} min=${config.minimumSupportedVersion} '
          'force=${config.forceUpdate}',
        );
      }
      return config;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] RC fetch failed: $e');
      return AppUpdateConfig.defaults;
    }
  }
}
