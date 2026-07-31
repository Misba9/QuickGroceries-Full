import 'dart:async';
import 'dart:ui' as ui;

import 'package:app_links/app_links.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/firebase/firebase_bootstrap.dart';
import 'package:quickgrocery/core/loading/loading_constants.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_shell.dart';
import 'package:quickgrocery/core/startup/shared_preferences_provider.dart';
import 'package:quickgrocery/core/startup/widgets/firebase_startup_gate.dart';
import 'package:quickgrocery/core/widgets/startup_failure_screen.dart';
import 'package:quickgrocery/l10n/app_localizations.dart';
// Riverpod and `package:provider` both export `ChangeNotifierProvider`
// and `Consumer`. Restrict Riverpod to `ProviderScope` here so the legacy
// Provider symbols remain unambiguous everywhere else in the app.
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderScope, ConsumerWidget, WidgetRef;
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/localization/locale_provider.dart';
import 'package:quickgrocery/core/localization/app_locales.dart';
import 'package:quickgrocery/core/theme/theme.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/core/push/fcm_push_initializer.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/realtime/realtime_bootstrap.dart';
import 'package:quickgrocery/view/auth/services/auth_provider.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/cart/services/cart_service.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/orders/services/order_service.dart';
import 'package:quickgrocery/view/payment/services/payment_service.dart';
import 'package:quickgrocery/view/product_view/services/product_view_service.dart';
import 'package:quickgrocery/view/profile/services/profile_service.dart';
import 'package:quickgrocery/view/search/services/search_service.dart';
import 'package:quickgrocery/view/tracking/services/tracking_service.dart';
import 'package:quickgrocery/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quickgrocery/view/wishlist/services/wishlist_service.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/cart_bootstrap.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/global_cart_overlay.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseWithRetry(maxAttempts: 4);
  RealtimeBootstrap.configureFirestore();
  if (kDebugMode) {
    debugPrint(
      '[FCM:bg] received title=${message.notification?.title} '
      'body=${message.notification?.body} data=${message.data}',
    );
  }
  if (!kIsWeb) {
    await FcmPushInitializer.ensureInitialized();
    await FcmPushInitializer.handleRemoteMessage(
      message,
      source: 'fcm_background',
      listenerId: 'background_handler',
    );
  }
}

StreamSubscription<Uri>? _referralLinkSub;

/// Captures referral codes from HTTPS / custom-scheme deep links
/// (replaces Firebase Dynamic Links).
Future<void> handleReferralAfterInstall() async {
  try {
    final appLinks = AppLinks();
    final initial = await appLinks.getInitialLink();
    if (initial != null) {
      await _storePendingReferralCode(initial);
    }
    await _referralLinkSub?.cancel();
    _referralLinkSub = appLinks.uriLinkStream.listen(
      (uri) => _storePendingReferralCode(uri),
      onError: (Object error) {
        if (kDebugMode) debugPrint('Deep link error: $error');
      },
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Deep link init failed: $e');
  }
}

void _installCrashlyticsHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

Future<void> _storePendingReferralCode(Uri deepLink) async {
  final code = deepLink.queryParameters['code'] ??
      deepLink.queryParameters['ref'] ??
      '';
  if (code.trim().isEmpty) return;
  final pref = await SharedPreferences.getInstance();
  await pref.setString('pending_referral_code', code.trim());
}

/// Strings (case-insensitive substrings) that we silence from `print` output
/// in debug builds. These are debug spam from third-party packages we
/// can't directly modify (e.g. `animate_do 3.3.9` left a stray
/// `print("animate: $animate")` in `animate_do_mixins.dart:100`).
const List<String> _silencedPrintFragments = [
  'animate: ',
];

bool _shouldSilencePrint(String? message) {
  if (message == null || message.isEmpty) return false;
  for (final frag in _silencedPrintFragments) {
    if (message.contains(frag)) return true;
  }
  return false;
}

void _configureProductionErrorPresentation() {
  if (kDebugMode) return;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 16),
              Text(
                'This part of the app couldn’t be shown.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Go back or restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  };
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppStartupLog.markAppStart();

  try {
    // Critical path only: prefs for correct theme/locale on first paint.
    // Firebase / Crashlytics / FCM / App Check / RC run after first frame
    // inside [FirebaseStartupGate] and [PostHomeStartup].
    _configureProductionErrorPresentation();

    final prefs = await SharedPreferences.getInstance();
    AppStartupLog.milestone('Preferences loaded');

    AppStartupLog.log('runApp');
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );

    // Non-critical: overlap with first Flutter frames.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_precacheLaunchLogo());
      unawaited(handleReferralAfterInstall());
    });
  } catch (e, st) {
    FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st));
    runApp(
      StartupFailureScreen(
        error: e,
        onRetry: _bootstrap,
      ),
    );
  }
}

/// Real entrypoint — wraps [_bootstrap] in a custom [Zone] that
/// silences known noisy debug `print()` output from third-party packages
/// we can't directly modify (see [_silencedPrintFragments]).
///
/// `debugPrint` is unaffected — only `print()` from inside this zone is
/// filtered. In release builds the zone is still installed but the
/// silenced fragments are usually compiled out by tree-shaking.
Future<void> main() async {
  await runZonedGuarded(
    _bootstrap,
    (error, stack) {
      // Crashlytics may not be ready yet (Firebase is post-frame).
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (_shouldSilencePrint(line)) return;
        // Never emit print() in release (PII / token risk).
        if (kReleaseMode) return;
        parent.print(zone, line);
      },
    ),
  );
}

/// Warm the brand logo into [ImageCache] without stalling [runApp].
Future<void> _precacheLaunchLogo() async {
  try {
    final provider = const AssetImage(LoadingConstants.logoAsset);
    final stream = provider.resolve(ImageConfiguration.empty);
    final done = Completer<void>();
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
      onError: (Object _, StackTrace? __) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    await done.future.timeout(
      const Duration(milliseconds: 200),
      onTimeout: () {},
    );
  } catch (_) {}
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeOption = ref.watch(themeModeProvider);

    return MultiProvider(
      providers: [
        // lazy: true (default) — construct only on first read, not at runApp.
        ChangeNotifierProvider(create: (_) => AuthService(), lazy: true),
        ChangeNotifierProvider(create: (_) => HomeProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => CategoryService(), lazy: true),
        ChangeNotifierProvider(create: (_) => ProductViewService(), lazy: true),
        ChangeNotifierProvider(create: (_) => CartService(), lazy: true),
        ChangeNotifierProvider(create: (_) => AddressService(), lazy: true),
        ChangeNotifierProvider(create: (_) => OrderService(), lazy: true),
        ChangeNotifierProvider(create: (_) => PaymentService(), lazy: true),
        ChangeNotifierProvider(create: (_) => TrackingService(), lazy: true),
        ChangeNotifierProvider(create: (_) => SearchService(), lazy: true),
        ChangeNotifierProvider(create: (_) => ProfileService(), lazy: true),
        ChangeNotifierProvider(create: (_) => DeliveryZoneService(), lazy: true),
        ChangeNotifierProvider(create: (_) => WishlistService(), lazy: true),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        localeListResolutionCallback: (locales, supported) {
          if (locales == null || locales.isEmpty) {
            return AppLocales.fallback;
          }
          return AppLocales.resolve(locales.first);
        },
        debugShowCheckedModeBanner: false,
        title: 'QuickGrocery',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeOption.materialThemeMode,
        themeAnimationDuration: AppTheme.animationDuration,
        themeAnimationCurve: Curves.easeInOut,
        scaffoldMessengerKey: AppSnackBar.messengerKey,
        builder: (context, child) {
          ThemeSystemUi.apply(context);
          return AnimatedTheme(
            data: Theme.of(context),
            duration: AppTheme.animationDuration,
            curve: Curves.easeInOut,
            child: Directionality(
              textDirection: AppLocales.isRtl(locale)
                  ? ui.TextDirection.rtl
                  : ui.TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        navigatorObservers: [appRouteObserver],
        home: FirebaseStartupGate(
          backgroundMessageHandler: _firebaseMessagingBackgroundHandler,
          onCrashlyticsHandlersInstalled: _installCrashlyticsHandlers,
          // Cart overlay only after Firebase — avoids Auth before initializeApp.
          child: const GlobalCartOverlay(
            child: RealtimeBootstrap(
              child: CartBootstrap(
                child: AppBootstrapShell(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
