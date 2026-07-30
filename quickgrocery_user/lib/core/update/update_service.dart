import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/update/app_store_updater.dart';
import 'package:quickgrocery/core/update/app_update_config.dart';
import 'package:quickgrocery/core/update/play_store_updater.dart';
import 'package:quickgrocery/core/update/remote_config_service.dart';
import 'package:quickgrocery/core/update/update_dialog.dart';
import 'package:quickgrocery/core/update/update_mode.dart';
import 'package:quickgrocery/core/update/update_preferences.dart';
import 'package:quickgrocery/core/update/version_checker.dart';

/// Cross-platform in-app update orchestrator for the User app.
///
/// Call [checkAndPrompt] after splash, after login, and on app resume.
/// Checks are throttled to once every [throttle] (default 6 hours) unless a
/// force update is required.
class AppUpdateService {
  AppUpdateService({
    this.mode = UpdateMode.remoteControlled,
    this.throttle = const Duration(hours: 6),
    this.remoteConfigKey = 'user_app_update',
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
  bool _pendingRetry = false;

  /// Injectable fakes for tests.
  String? fakeInstalledVersion;
  AppUpdateConfig? fakeConfig;

  static const unsafeRoutes = {
    AppRoutes.otp,
    AppRoutes.login,
    AppRoutes.payment,
    AppRoutes.checkout,
    AppRoutes.orderTracking,
  };

  bool get isSafeToShow {
    final top = appRouteObserver.topRouteName;
    if (top == null) return true;
    // Allow force-update even on tracking once delivered — caller decides.
    return !unsafeRoutes.contains(top);
  }

  Future<void> checkAndPrompt(
    BuildContext context, {
    bool ignoreThrottle = false,
    bool forceUnsafeOk = false,
  }) async {
    if (mode == UpdateMode.disabled) return;
    if (_dialogVisible) {
      _pendingRetry = true;
      return;
    }
    if (!forceUnsafeOk && !isSafeToShow) {
      if (kDebugMode) {
        debugPrint(
          '[AppUpdate] defer — unsafe route=${appRouteObserver.topRouteName}',
        );
      }
      _pendingRetry = true;
      return;
    }

    final prefs = await _prefsFuture;
    if (!context.mounted) return;

    // Complete a pending flexible install first.
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

      if (kDebugMode) {
        debugPrint(
          '[AppUpdate] decision available=${decision.updateAvailable} '
          'force=${decision.forceUpdate}',
        );
      }

      if (!decision.shouldPrompt) {
        await prefs.markChecked();
        return;
      }

      // Optional updates respect throttle; force always prompts.
      if (!decision.forceUpdate &&
          !ignoreThrottle &&
          !prefs.shouldCheck(throttle: throttle, forceBypass: false)) {
        if (kDebugMode) debugPrint('[AppUpdate] throttled');
        return;
      }

      await prefs.markChecked();
      if (!context.mounted) return;
      await _present(context, decision);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[AppUpdate] check failed: $e\n$st');
    }
  }

  Future<void> flushPendingIfSafe(BuildContext context) async {
    if (!_pendingRetry) return;
    if (!isSafeToShow || _dialogVisible) return;
    _pendingRetry = false;
    await checkAndPrompt(context);
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
          // Force dialog cannot be dismissed via Later — re-show shortly.
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
        return false;
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
        if (kDebugMode) {
          debugPrint('[AppUpdate] Play update unavailable — opening listing');
        }
        final ok = await _play.openPlayStoreListing();
        if (!ok && context.mounted) {
          AppSnackBar.info(
            'Could not open the Play Store. Try again later.',
            context: context,
          );
        }
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

      // Fallback: immediate if allowed, else listing.
      if (info.immediateUpdateAllowed) {
        await _play.performImmediateUpdate();
      } else {
        await _play.openPlayStoreListing();
      }
      return;
    }

    if (isIos) {
      final opened = await _appStore.openAppStore();
      if (!opened && context.mounted) {
        AppSnackBar.info(
          'Could not open the App Store. Try again later.',
          context: context,
        );
      }
      return;
    }

    // Other platforms — open Play listing as a best-effort fallback.
    await _play.openPlayStoreListing();
  }
}
