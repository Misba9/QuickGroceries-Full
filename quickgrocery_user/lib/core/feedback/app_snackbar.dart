import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/push/push_navigation.dart';

/// Tone for [AppSnackBar] floating bottom notifications.
enum AppSnackBarTone {
  error,
  success,
  info,
}

/// Premium bottom floating toast (Blinkit / Swiggy / Zepto style).
///
/// - Single visible toast at a time (no stacking)
/// - Dedupes identical messages within a short window
/// - SafeArea / home-indicator aware
/// - Clears above typical bottom navigation
abstract final class AppSnackBar {
  AppSnackBar._();

  /// Attach to [MaterialApp.scaffoldMessengerKey].
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const Duration duration = Duration(seconds: 3);
  static const Duration _dedupeWindow = Duration(milliseconds: 1400);

  /// Extra lift above system bottom inset so the toast clears bottom nav /
  /// floating cart (≈56–64) with a 24–32px visual gap.
  static const double bottomNavClearance = 64;

  static String? _lastMessage;
  static AppSnackBarTone? _lastTone;
  static DateTime? _lastShownAt;

  static void error(
    String message, {
    BuildContext? context,
    bool showIcon = true,
  }) {
    show(
      message,
      tone: AppSnackBarTone.error,
      context: context,
      showIcon: showIcon,
    );
  }

  static void success(
    String message, {
    BuildContext? context,
    bool showIcon = true,
  }) {
    show(
      message,
      tone: AppSnackBarTone.success,
      context: context,
      showIcon: showIcon,
    );
  }

  static void info(
    String message, {
    BuildContext? context,
    bool showIcon = false,
  }) {
    show(
      message,
      tone: AppSnackBarTone.info,
      context: context,
      showIcon: showIcon,
    );
  }

  /// Alias used by older call sites.
  static void showError(String message, {BuildContext? context}) =>
      error(message, context: context);

  static void hide([BuildContext? context]) {
    _resolveMessenger(context)?.hideCurrentSnackBar();
  }

  static void clear([BuildContext? context]) {
    _resolveMessenger(context)?.clearSnackBars();
  }

  static void show(
    String message, {
    AppSnackBarTone tone = AppSnackBarTone.error,
    BuildContext? context,
    bool showIcon = true,
    Duration? duration,
  }) {
    final text = message.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    if (_lastMessage == text &&
        _lastTone == tone &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < _dedupeWindow) {
      return;
    }

    final messenger = _resolveMessenger(context);
    if (messenger == null) return;

    final media = _mediaQuery(context) ??
        MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        );

    _lastMessage = text;
    _lastTone = tone;
    _lastShownAt = now;

    final colors = _colorsFor(tone);
    final bottom = math.max(media.viewPadding.bottom, media.padding.bottom) +
        28 +
        bottomNavClearance;
    final maxWidth = media.size.shortestSide >= 600 ? 420.0 : null;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: _AppSnackBarBody(
            message: text,
            foreground: colors.foreground,
            icon: showIcon ? colors.icon : null,
          ),
          backgroundColor: colors.background,
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          width: maxWidth,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: duration ?? AppSnackBar.duration,
          dismissDirection: DismissDirection.down,
          showCloseIcon: false,
        ),
      );
  }

  static ScaffoldMessengerState? _resolveMessenger(BuildContext? context) {
    if (context != null) {
      return ScaffoldMessenger.maybeOf(context);
    }
    final fromKey = messengerKey.currentState;
    if (fromKey != null) return fromKey;

    final navContext = rootNavigatorKey.currentContext;
    if (navContext != null) {
      return ScaffoldMessenger.maybeOf(navContext);
    }
    return null;
  }

  static MediaQueryData? _mediaQuery(BuildContext? context) {
    if (context != null) {
      return MediaQuery.maybeOf(context);
    }
    final navContext = rootNavigatorKey.currentContext;
    if (navContext != null) {
      return MediaQuery.maybeOf(navContext);
    }
    return null;
  }

  static _ToneColors _colorsFor(AppSnackBarTone tone) {
    switch (tone) {
      case AppSnackBarTone.error:
        return const _ToneColors(
          background: Color(0xFFD32F2F),
          foreground: Colors.white,
          icon: Icons.error_outline_rounded,
        );
      case AppSnackBarTone.success:
        return const _ToneColors(
          background: Color(0xFF2E7D32),
          foreground: Colors.white,
          icon: Icons.check_circle_outline_rounded,
        );
      case AppSnackBarTone.info:
        return const _ToneColors(
          background: Color(0xFF323232),
          foreground: Colors.white,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _ToneColors {
  const _ToneColors({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}

class _AppSnackBarBody extends StatelessWidget {
  const _AppSnackBarBody({
    required this.message,
    required this.foreground,
    this.icon,
  });

  final String message;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, color: foreground, size: 22),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.poppins(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// Backward-compatible alias — bottom floating error toast.
@Deprecated('Use AppSnackBar.error instead')
void showTopErrorToast(BuildContext context, String message) {
  AppSnackBar.error(message, context: context);
}
