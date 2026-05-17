import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery_vendor/core/fcm_bootstrap.dart';
import 'package:quickgrocery_vendor/services/preference_service.dart';
import 'view/auth/auth_wrapper.dart';
import 'style/app_color.dart';

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('[VendorFCM:bg] ${message.notification?.title}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  final vendorId = await PreferenceService.getVendorId();
  if (vendorId != null && vendorId.isNotEmpty) {
    await VendorFcmBootstrap.configureForVendor(vendorId);
  }
  FirebaseMessaging.onMessage.listen((msg) {
    if (kDebugMode) {
      debugPrint('[VendorFCM:fg] ${msg.notification?.title}');
    }
  });
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
      home: const AuthWrapper(),
    );
  }
}
