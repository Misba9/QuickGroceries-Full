import 'package:quick_grocery_admin/core/firebase/admin_firebase_options.dart';
import 'package:quick_grocery_admin/view/auth/services/login_service.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';
import 'package:quick_grocery_admin/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quick_grocery_admin/view/home/screens/home_screen.dart';
import 'package:quick_grocery_admin/view/home/services/dash_board_services.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';
import 'package:quick_grocery_admin/view/customers/services/customer_admin_service.dart';
import 'package:quick_grocery_admin/view/delivery_settings/services/delivery_settings_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_request_service.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_service.dart';
import 'package:quick_grocery_admin/view/platform_fee/services/platform_fee_service.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/notification_admin_service.dart';
import 'package:quick_grocery_admin/view/app_content_management/services/app_content_management_service.dart';
import 'package:quick_grocery_admin/view/support_settings/services/support_settings_service.dart';
import 'package:quick_grocery_admin/view/maintenance/services/maintenance_management_service.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_notification_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_dashboard_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_sound_prefs.dart';
import 'package:quick_grocery_admin/view/operations/widgets/admin_notification_realtime_host.dart';
import 'package:quick_grocery_admin/view/auth/screens/login_screen.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      debugPrint(details.stack?.toString() ?? '');
    }
    FlutterError.presentError(details);
  };

  await Firebase.initializeApp(
    options: AdminFirebaseOptions.current,
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
        ChangeNotifierProvider(create: (context) => CustomerAdminService()),
        ChangeNotifierProvider(create: (context) => VendorService()),
        ChangeNotifierProvider(create: (context) => VendorRequestService()),
        ChangeNotifierProvider(create: (context) => OrderService()),
        ChangeNotifierProvider(create: (context) => LoginService()),
        ChangeNotifierProvider(create: (context) => DeliveryBoyService()),
        ChangeNotifierProvider(create: (context) => DashBoardServices()),
        ChangeNotifierProvider(create: (context) => DeliveryZoneService()),
        ChangeNotifierProvider(create: (context) => PlatformFeeService()),
        ChangeNotifierProvider(create: (context) => DeliverySettingsService()),
        ChangeNotifierProvider(create: (context) => NotificationAdminService()),
        ChangeNotifierProvider(
          create: (context) => AppContentManagementService(),
        ),
        ChangeNotifierProvider(
          create: (context) => SupportSettingsService(),
        ),
        ChangeNotifierProvider(
          create: (context) => MaintenanceManagementService(),
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
