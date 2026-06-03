import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/firebase/firebase_bootstrap.dart';
import 'package:quickgrocery/core/firestore/firestore_retry.dart';
import 'package:quickgrocery/core/widgets/startup_failure_screen.dart';
// Riverpod and `package:provider` both export `ChangeNotifierProvider`
// and `Consumer`. Restrict Riverpod to `ProviderScope` here so the legacy
// Provider symbols remain unambiguous everywhere else in the app.
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderScope, Consumer;
import 'package:quickgrocery/core/design/app_theme.dart';
import 'package:quickgrocery/core/localization/app_locales.dart';
import 'package:quickgrocery/core/push/fcm_bootstrap.dart';
import 'package:quickgrocery/core/push/fcm_push_initializer.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/realtime/realtime_bootstrap.dart';
import 'package:quickgrocery/services/language_service.dart';
import 'package:quickgrocery/view/auth/services/auth_provider.dart';
import 'package:quickgrocery/view/auth/auth_gate.dart';
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
import 'package:provider/provider.dart' as legacy_provider show Consumer;
import 'package:shared_preferences/shared_preferences.dart';
import 'view/home/screens/landing_screen.dart';
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
    await FcmPushInitializer.showForeground(message);
  }
}

/// App Check must be active when enforcement is on in Firebase Console.
/// Use [AndroidProvider.debug] in debug builds/emulators; register the debug
/// token in Firebase Console → App Check → Manage debug tokens.
///
/// Wrapped in try/catch so a misconfigured Firebase project (e.g. App Check
/// API not enabled) cannot block app startup or crash the splash. The
/// 403 you may see in logs is benign in debug — Firebase falls back to a
/// placeholder token automatically. Enable the API at:
/// https://console.developers.google.com/apis/api/firebaseappcheck.googleapis.com/overview
Future<void> configureFirebaseAppCheck() async {
  if (kIsWeb) return;

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
    if (kDebugMode) {
      try {
        final token = await FirebaseAppCheck.instance.getToken(true);
        debugPrint(
          '[AppCheck] debug token (register in Firebase Console → App Check → '
          'Manage debug tokens if Auth is enforced):\n$token',
        );
      } catch (tokenError) {
        debugPrint('[AppCheck] could not fetch debug token: $tokenError');
      }
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint(
        '[AppCheck] activation failed (continuing without enforcement): $e',
      );
      debugPrintStack(stackTrace: st);
    }
  }
}

// Handle Referral
Future<void> handleReferralAfterInstall() async {
  final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks
      .instance
      .getInitialLink();

  if (initialLink != null) {
    await _storePendingReferralCode(initialLink.link);
  }

  FirebaseDynamicLinks.instance.onLink
      .listen((PendingDynamicLinkData data) async {
        await _storePendingReferralCode(data.link);
      })
      .onError((error) {
        print("Dynamic Link Error: $error");
      });
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

  try {
    await initializeFirebaseWithRetry();
    // Realtime layer needs offline persistence configured BEFORE any
    // Firestore handle is acquired; configure first so the very first
    // listener inherits the right cache settings.
    RealtimeBootstrap.configureFirestore();
    await configureFirebaseAppCheck();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize EasyLocalization
    await EasyLocalization.ensureInitialized();
    await FcmBootstrap.configure();

    _configureProductionErrorPresentation();

    handleReferralAfterInstall();
    runApp(const ProviderScope(child: MyApp()));
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
      // Re-emit uncaught zone errors via Flutter's normal error pipeline
      // so Crashlytics / dev tooling still see them.
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (_shouldSilencePrint(line)) return;
        parent.print(zone, line);
      },
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final pref = SharedPreferences.getInstance();
    return FutureBuilder<SharedPreferences>(
      future: pref,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final savedLanguageCode =
            snapshot.data!.getString('selected_language_code') ?? 'en';
        final savedCountryCode =
            snapshot.data!.getString('selected_country_code') ?? 'US';

        final startLocale = AppLocales.fromPreference(
          savedLanguageCode,
          savedCountryCode,
        );

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
            ChangeNotifierProvider(create: (context) => LanguageService()),
            ChangeNotifierProvider(create: (context) => DeliveryZoneService()),
            ChangeNotifierProvider(create: (context) => WishlistService()),
          ],
          child: EasyLocalization(
            supportedLocales: AppLocales.supported,
            path: 'assets/translations',
            fallbackLocale: AppLocales.fallback,
            startLocale: startLocale,
            useOnlyLangCode: false,
            child: legacy_provider.Consumer<LanguageService>(
              builder: (context, languageService, _) {
                final locale = context.locale;
                return Builder(
                  builder: (context) => MaterialApp(
                    navigatorKey: rootNavigatorKey,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    locale: locale,
                    debugShowCheckedModeBanner: false,
                    title: 'QuickGrocery',
                    theme: AppTheme.light(),
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
                    home: Consumer(
                      builder: (context, ref, _) {
                        return RealtimeBootstrap(
                          child: CartBootstrap(
                            child: StreamBuilder(
                              stream: FirebaseAuth.instance.authStateChanges(),
                              builder: (context, userSnp) {
                                return const AuthGate();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
