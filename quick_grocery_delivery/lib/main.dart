import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_delivery/core/delivery_notification_router.dart';
import 'package:quick_grocery_delivery/core/delivery_push_initializer.dart';
import 'package:quick_grocery_delivery/core/fcm_bootstrap.dart';
import 'package:quick_grocery_delivery/core/update/update_bootstrap.dart';
import 'package:quick_grocery_delivery/constants/delivery_branding.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/login/auth_gate.dart';
import 'package:quick_grocery_delivery/maintenance/maintenance_gate.dart';
import 'package:quick_grocery_delivery/features/login/services/login_service.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/services/driver_profile_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level background handler — registered once from [main].
/// Must not show a second tray entry when FCM already includes `notification`.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await DeliveryPushInitializer.ensureInitialized();
  await DeliveryPushInitializer.handleBackgroundMessage(message);
  if (kDebugMode) {
    debugPrint(
      '[DeliveryFCM:bg] messageId=${message.messageId} '
      'eventId=${message.data['eventId']} '
      'orderId=${message.data['orderId']} '
      'type=${message.data['type']} '
      'hasNotification=${message.notification != null}',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Register background handler exactly once (before runApp).
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Foreground: do not let iOS/Android auto-present; we show one local notif.
  await messaging.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: true,
    sound: false,
  );

  await DeliveryPushInitializer.ensureInitialized();
  DeliveryPushInitializer.attachMessagingListeners();

  final pref = await SharedPreferences.getInstance();
  final riderId =
      FirebaseAuth.instance.currentUser?.uid ??
      pref.getString('deliveryBoyId') ??
      '';
  if (riderId.isNotEmpty) {
    await DeliveryFcmBootstrap.configureForRider(riderId);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => OrderService()),
        ChangeNotifierProvider(create: (context) => LoginService()),
        ChangeNotifierProvider(create: (context) => DriverProfileService()),
      ],
      child: MaterialApp(
        navigatorKey: DeliveryNotificationRouter.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: DeliveryBranding.appName,
        theme: ThemeData(
          textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme),
          colorScheme: ColorScheme.fromSeed(seedColor: GlobalVariables.primary),
        ),
        home: const AppUpdateBootstrap(
          child: DriverMaintenanceGate(child: AuthGate()),
        ),
      ),
    );
  }
}
