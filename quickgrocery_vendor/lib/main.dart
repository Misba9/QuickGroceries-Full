import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery_vendor/core/fcm_bootstrap.dart';
import 'package:quickgrocery_vendor/core/vendor_notification_hub.dart';
import 'package:quickgrocery_vendor/core/vendor_push_initializer.dart';
import 'package:quickgrocery_vendor/services/preference_service.dart';
import 'package:quickgrocery_vendor/maintenance/maintenance_gate.dart';
import 'view/auth/auth_wrapper.dart';
import 'style/app_color.dart';

@pragma('vm:entry-point')
Future<void> vendorFcmBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint(
      '[VendorNotify] FCM background type=${message.data['type']} '
      'orderId=${message.data['orderId']}',
    );
  }
  await VendorPushInitializer.ensureInitialized();
  await VendorPushInitializer.showFromRemoteMessage(message);
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

  FirebaseMessaging.onMessage.listen((msg) async {
    await VendorPushInitializer.handleForegroundMessage(msg);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
    if (kDebugMode) {
      debugPrint('[VendorNotify] notification opened app data=${msg.data}');
    }
    await VendorNotificationHub.instance.handleFcmPayload(msg.data);
  });

  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    if (kDebugMode) {
      debugPrint('[VendorNotify] cold start from notification data=${initial.data}');
    }
    await VendorNotificationHub.instance.handleFcmPayload(initial.data);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickGrocery Vendor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColor.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColor.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const VendorMaintenanceGate(child: AuthWrapper()),
    );
  }
}
