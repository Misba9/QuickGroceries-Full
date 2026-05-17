import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_delivery/core/fcm_bootstrap.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';
import 'package:quick_grocery_delivery/features/login/login_screen.dart';
import 'package:quick_grocery_delivery/features/login/services/login_service.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// const AndroidNotificationChannel channel = AndroidNotificationChannel(
//   'high_importance_channel',
//   'High Importance Notifications',
//   sound: RawResourceAndroidNotificationSound('alert'),
//
//: 'This channel is used for important notifications.',
//   importance: Importance.high,
//   playSound: true,
// );

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('[DeliveryFCM:bg] ${message.notification?.title}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // await flutterLocalNotificationsPlugin
  //     .resolvePlatformSpecificImplementation<
  //       AndroidFlutterLocalNotificationsPlugin
  //     >()
  //     ?.createNotificationChannel(channel);
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  // ignore: unused_local_variable
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  final pref = await SharedPreferences.getInstance();
  final riderId = pref.getString('deliveryBoyId') ?? '';
  if (riderId.isNotEmpty) {
    await DeliveryFcmBootstrap.configureForRider(riderId);
  }

  runApp(MyApp(isLogged: riderId.isNotEmpty));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isLogged});
  final bool isLogged;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => OrderService()),
        ChangeNotifierProvider(create: (context) => LoginService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quick Groceries Delivery',
        theme: ThemeData(
          textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme),
          colorScheme: ColorScheme.fromSeed(seedColor: GlobalVariables.primary),
        ),
        home: isLogged ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
