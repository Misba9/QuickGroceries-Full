import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import 'package:quickgrocery_vendor/core/update/app_store_updater.dart';
import 'package:quickgrocery_vendor/core/update/app_update_config.dart';
import 'package:quickgrocery_vendor/core/update/play_store_updater.dart';
import 'package:quickgrocery_vendor/core/update/remote_config_service.dart';
import 'package:quickgrocery_vendor/core/update/update_dialog.dart';
import 'package:quickgrocery_vendor/core/update/update_mode.dart';
import 'package:quickgrocery_vendor/core/update/update_preferences.dart';
import 'package:quickgrocery_vendor/core/update/version_checker.dart';

/// In-app update orchestrator for the Vendor app.
class AppUpdateService {
  AppUpdateService({
    this.mode = UpdateMode.remoteControlled,
    this.throttle = const Duration(hours: 6),
    this.remoteConfigKey = 'vendor_app_update',
    UpdateRemoteConfigService? remoteConfig,
    VersionChecker? versionChecker,
    PlayStoreUpdater? playStoreUpdater,
    AppStoreUpdater? appStoreUpdater,
    UpdatePreferences? preferences,
  })  : _remote = remoteConfig ??
            UpdateRemoteConfigService(remoteConfigKey: remoteConfigKey),
        _versions = versionChecker ?? VersionChecker(),
        _play = playStoreUpdater ?? const PlayStoreUpdater(),
        _appStore = appStoreUpdater ?? AppStoreUpdater(),
        _prefsFuture = preferences != null
            ? Future.value(preferences)
            : UpdatePreferences.create();

  final UpdateMode mode;
  final Duration throttle;
  final String remoteConfigKey;

  final UpdateRemoteConfigService _remote;
  final VersionChecker _versions;
  final PlayStoreUpdater _play;
  final AppStoreUpdater _appStore;
  final Future<UpdatePreferences> _prefsFuture;

  bool _dialogVisible = false;

  String? fakeInstalledVersion;
  AppUpdateConfig? fakeConfig;

  /// Optional gate — set false during OTP / payment screens.
  bool Function()? isSafeToShow;

  Future<void> checkAndPrompt(
    BuildContext context, {
    bool ignoreThrottle = false,
  }) async {
    if (mode == UpdateMode.disabled) return;
    if (_dialogVisible) return;
    if (isSafeToShow != null && !isSafeToShow!()) return;

    final prefs = await _prefsFuture;
    if (!context.mounted) return;

    if (prefs.flexibleUpdateReady) {
      final restart = await showRestartToInstallDialog(context);
      if (!context.mounted) return;
      if (restart) {
        await _play.completeFlexibleUpdate();
        await prefs.setFlexibleUpdateReady(false);
      }
      return;
    }

    try {
      final config = fakeConfig ?? await _remote.fetchConfig();
      final decision = await _versions.evaluate(
        config,
        fakeInstalled: fakeInstalledVersion,
      );

      if (!decision.shouldPrompt) {
        await prefs.markChecked();
        return;
      }

      if (!decision.forceUpdate &&
          !ignoreThrottle &&
          !prefs.shouldCheck(throttle: throttle, forceBypass: false)) {
        return;
      }

      await prefs.markChecked();
      if (!context.mounted) return;
      await _present(context, decision);
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] check failed: $e');
    }
  }

  Future<void> _present(BuildContext context, UpdateDecision decision) async {
    if (_dialogVisible || !context.mounted) return;
    _dialogVisible = true;
    try {
      final force = _resolveForce(decision);
      final action = await showAppUpdateDialog(
        context,
        config: decision.config,
        forceUpdate: force,
        installedVersion: decision.installedVersion,
        latestVersion: decision.config.latestVersion,
      );
      if (!context.mounted) return;
      if (action != UpdateDialogAction.updateNow) {
        if (force && context.mounted) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (context.mounted) {
            _dialogVisible = false;
            await _present(context, decision);
          }
        }
        return;
      }
      await _applyUpdate(context, force: force);
    } finally {
      _dialogVisible = false;
    }
  }

  bool _resolveForce(UpdateDecision decision) {
    switch (mode) {
      case UpdateMode.disabled:
      case UpdateMode.flexible:
        return false;
      case UpdateMode.immediate:
        return true;
      case UpdateMode.remoteControlled:
        return decision.forceUpdate;
    }
  }

  Future<void> _applyUpdate(BuildContext context, {required bool force}) async {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isIos = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isAndroid) {
      final info = await _play.checkForUpdate();
      if (info == null ||
          info.updateAvailability != UpdateAvailability.updateAvailable) {
        await _play.openPlayStoreListing();
        return;
      }
      if (force && info.immediateUpdateAllowed) {
        await _play.performImmediateUpdate();
        return;
      }
      if (info.flexibleUpdateAllowed) {
        final started = await _play.startFlexibleUpdate();
        if (!started) {
          await _play.openPlayStoreListing();
          return;
        }
        final prefs = await _prefsFuture;
        await prefs.setFlexibleUpdateReady(true);
        if (!context.mounted) return;
        final restart = await showRestartToInstallDialog(context);
        if (restart) {
          await _play.completeFlexibleUpdate();
          await prefs.setFlexibleUpdateReady(false);
        }
        return;
      }
      if (info.immediateUpdateAllowed) {
        await _play.performImmediateUpdate();
      } else {
        await _play.openPlayStoreListing();
      }
      return;
    }

    if (isIos) {
      await _appStore.openAppStore();
      return;
    }

    await _play.openPlayStoreListing();
  }
}
