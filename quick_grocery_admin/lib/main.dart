import 'package:quick_grocery_admin/view/auth/services/login_service.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';
import 'package:quick_grocery_admin/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quick_grocery_admin/view/home/screens/home_screen.dart';
import 'package:quick_grocery_admin/view/home/services/dash_board_services.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';
import 'package:quick_grocery_admin/view/users/services/user_service.dart';
import 'package:quick_grocery_admin/view/delivery_settings/services/delivery_settings_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_service.dart';
import 'package:quick_grocery_admin/view/platform_fee/services/platform_fee_service.dart';
import 'package:quick_grocery_admin/view/analytics/services/analytics_service.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/notification_admin_service.dart';
import 'package:quick_grocery_admin/view/app_content_management/services/app_content_management_service.dart';
import 'package:quick_grocery_admin/view/support_settings/services/support_settings_service.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_notification_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_dashboard_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_sound_prefs.dart';
import 'package:quick_grocery_admin/view/operations/widgets/admin_notification_realtime_host.dart';
import 'package:quick_grocery_admin/view/auth/screens/login_screen.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      storageBucket: "quikgroceries.firebasestorage.app",
      apiKey: "AIzaSyAP3YkC0R7qvX28VbNZ2L486lRCA4hRH4c",
      appId: "1:970937777233:web:5a78d782494d55836e0c70",
      messagingSenderId: "970937777233",
      projectId: "quikgroceries",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProductService()),
        ChangeNotifierProvider(create: (context) => UserService()),
        ChangeNotifierProvider(create: (context) => VendorService()),
        ChangeNotifierProvider(create: (context) => OrderService()),
        ChangeNotifierProvider(create: (context) => LoginService()),
        ChangeNotifierProvider(create: (context) => DeliveryBoyService()),
        ChangeNotifierProvider(create: (context) => DashBoardServices()),
        ChangeNotifierProvider(create: (context) => DeliveryZoneService()),
        ChangeNotifierProvider(create: (context) => PlatformFeeService()),
        ChangeNotifierProvider(create: (context) => DeliverySettingsService()),
        ChangeNotifierProvider(create: (context) => AnalyticsService()),
        ChangeNotifierProvider(create: (context) => NotificationAdminService()),
        ChangeNotifierProvider(
          create: (context) => AppContentManagementService(),
        ),
        ChangeNotifierProvider(
          create: (context) => SupportSettingsService(),
        ),
        ChangeNotifierProvider(create: (_) => AdminNotificationService()),
        ChangeNotifierProvider(create: (_) => OpsDashboardService()),
        ChangeNotifierProvider(create: (_) => OpsSoundPrefs()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quick Grocery Admin',
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
          useMaterial3: true,
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasData && snap.data != null) {
              return const AdminNotificationRealtimeHost(
                child: HomeScreen(),
              );
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
