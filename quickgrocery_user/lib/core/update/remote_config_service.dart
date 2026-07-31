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

  AppUpdateConfig? _cached;
  Future<AppUpdateConfig>? _inFlight;

  /// Fetch + activate, then parse JSON. Returns [AppUpdateConfig.defaults]
  /// on any failure so the app continues gracefully.
  ///
  /// Process-cached: duplicate cold-start callers share one RC round-trip.
  Future<AppUpdateConfig> fetchConfig({
    Duration minimumFetchInterval = const Duration(hours: 1),
  }) async {
    if (_cached != null) return _cached!;
    return _inFlight ??= _fetchConfig(minimumFetchInterval: minimumFetchInterval)
        .whenComplete(() => _inFlight = null);
  }

  Future<AppUpdateConfig> _fetchConfig({
    required Duration minimumFetchInterval,
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
        return _cached = AppUpdateConfig.defaults;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return _cached = AppUpdateConfig.defaults;
      }
      final config =
          AppUpdateConfig.fromJson(Map<String, dynamic>.from(decoded));
      return _cached = config;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] RC fetch failed: $e');
      return _cached = AppUpdateConfig.defaults;
    }
  }
}
