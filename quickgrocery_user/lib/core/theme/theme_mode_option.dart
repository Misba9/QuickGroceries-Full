import 'package:flutter/material.dart';

/// User-selected appearance: light, dark, or follow the device.
enum AppThemeModeOption {
  light,
  dark,
  system,
}

extension AppThemeModeOptionX on AppThemeModeOption {
  String get storageValue => switch (this) {
        AppThemeModeOption.light => 'light',
        AppThemeModeOption.dark => 'dark',
        AppThemeModeOption.system => 'system',
      };

  ThemeMode get materialThemeMode => switch (this) {
        AppThemeModeOption.light => ThemeMode.light,
        AppThemeModeOption.dark => ThemeMode.dark,
        AppThemeModeOption.system => ThemeMode.system,
      };

  String get label => switch (this) {
        AppThemeModeOption.light => 'Light',
        AppThemeModeOption.dark => 'Dark',
        AppThemeModeOption.system => 'System Default',
      };

  static AppThemeModeOption fromStorage(String? raw) {
    switch (raw) {
      case 'light':
        return AppThemeModeOption.light;
      case 'dark':
        return AppThemeModeOption.dark;
      case 'system':
      case null:
      case '':
        return AppThemeModeOption.system;
      default:
        return AppThemeModeOption.system;
    }
  }

  /// Resolves preference against the platform brightness.
  Brightness resolveBrightness(Brightness platformBrightness) {
    return switch (this) {
      AppThemeModeOption.light => Brightness.light,
      AppThemeModeOption.dark => Brightness.dark,
      AppThemeModeOption.system => platformBrightness,
    };
  }
}
