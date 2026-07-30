import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'package:quick_grocery_delivery/core/update/app_update_config.dart';

class UpdateRemoteConfigService {
  UpdateRemoteConfigService({
    this.remoteConfigKey = 'delivery_app_update',
    FirebaseRemoteConfig? remoteConfig,
  }) : _rc = remoteConfig ?? FirebaseRemoteConfig.instance;

  final String remoteConfigKey;
  final FirebaseRemoteConfig _rc;

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
      if (raw.isEmpty) return AppUpdateConfig.defaults;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return AppUpdateConfig.defaults;
      final config =
          AppUpdateConfig.fromJson(Map<String, dynamic>.from(decoded));
      if (kDebugMode) {
        debugPrint(
          '[AppUpdate] RC key=$remoteConfigKey latest=${config.latestVersion} '
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
