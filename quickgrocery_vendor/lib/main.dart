import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery_vendor/core/fcm_bootstrap.dart';
import 'package:quickgrocery_vendor/core/update/update_bootstrap.dart';
import 'package:quickgrocery_vendor/core/vendor_notification_router.dart';
import 'package:quickgrocery_vendor/core/vendor_push_initializer.dart';
import 'package:quickgrocery_vendor/services/preference_service.dart';
import 'package:quickgrocery_vendor/maintenance/maintenance_gate.dart';
import 'view/auth/auth_wrapper.dart';
import 'style/vendor_app_theme.dart';

@pragma('vm:entry-point')
Future<void> vendorFcmBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await VendorPushInitializer.ensureInitialized();
  await VendorPushInitializer.handleBackgroundMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await VendorPushInitializer.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(vendorFcmBackgroundHandler);

  final vendorId = await PreferenceService.getVendorId();
  if (vendorId != null && vendorId.isNotEmpty) {
    try {
      await VendorFcmBootstrap.configureForVendor(vendorId);
    } catch (_) {}
  }

  await VendorPushInitializer.attachMessagingListeners();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: VendorNotificationRouter.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Vendor Quick QuickGroceries',
      theme: VendorAppTheme.light(),
      darkTheme: VendorAppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AppUpdateBootstrap(
        child: VendorMaintenanceGate(child: AuthWrapper()),
      ),
    );
  }
}
