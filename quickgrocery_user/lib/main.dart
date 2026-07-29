import 'dart:async';
import 'dart:ui' as ui;

import 'package:app_links/app_links.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/firebase/firebase_bootstrap.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_shell.dart';
import 'package:quickgrocery/core/startup/deferred_startup.dart';
import 'package:quickgrocery/core/startup/shared_preferences_provider.dart';
import 'package:quickgrocery/core/widgets/startup_failure_screen.dart';
import 'package:quickgrocery/l10n/app_localizations.dart';
// Riverpod and `package:provider` both export `ChangeNotifierProvider`
// and `Consumer`. Restrict Riverpod to `ProviderScope` here so the legacy
// Provider symbols remain unambiguous everywhere else in the app.
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderScope, ConsumerWidget, WidgetRef;
import 'package:quickgrocery/core/design/app_theme.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/localization/locale_provider.dart';
import 'package:quickgrocery/core/localization/app_locales.dart';
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
    // Critical path only: Firebase + prefs → first Flutter frame.
    // App Check / Phone Auth / FCM topics run in [DeferredStartup].
    await initializeFirebaseWithRetry();
    AppStartupLog.milestone('Firebase initialized');
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
    _installCrashlyticsHandlers();
    RealtimeBootstrap.configureFirestore();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _configureProductionErrorPresentation();

    final prefs = await SharedPreferences.getInstance();
    AppStartupLog.milestone('Preferences loaded');

    unawaited(handleReferralAfterInstall());
    AppStartupLog.log('runApp');
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );
    DeferredStartup.scheduleAfterFirstFrame();
  } catch (e, st) {
    try {
      await FirebaseCrashlytics.instance.recordError(e, st, fatal: true);
    } catch (_) {}
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
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (context) => CategoryService()),
        ChangeNotifierProvider(create: (context) => ProductViewService()),
        ChangeNotifierProvider(create: (context) => CartService()),
        ChangeNotifierProvider(create: (context) => AddressService()),
        ChangeNotifierProvider(create: (context) => OrderService()),
        ChangeNotifierProvider(create: (context) => PaymentService()),
        ChangeNotifierProvider(create: (context) => TrackingService()),
        ChangeNotifierProvider(create: (context) => SearchService()),
        ChangeNotifierProvider(create: (context) => ProfileService()),
        ChangeNotifierProvider(create: (context) => DeliveryZoneService()),
        ChangeNotifierProvider(create: (context) => WishlistService()),
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
        scaffoldMessengerKey: AppSnackBar.messengerKey,
        builder: (context, child) {
          return Directionality(
            textDirection: AppLocales.isRtl(locale)
                ? ui.TextDirection.rtl
                : ui.TextDirection.ltr,
            child: GlobalCartOverlay(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        navigatorObservers: [appRouteObserver],
        home: const RealtimeBootstrap(
          child: CartBootstrap(
            child: AppBootstrapShell(),
          ),
        ),
      ),
    );
  }
}
