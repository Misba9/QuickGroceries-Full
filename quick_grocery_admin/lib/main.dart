import 'package:quick_grocery_admin/view/auth/services/login_service.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';
import 'package:quick_grocery_admin/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quick_grocery_admin/view/home/screens/home_screen.dart';
import 'package:quick_grocery_admin/view/home/services/dash_board_services.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';
import 'package:quick_grocery_admin/view/users/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_service.dart';
import 'package:quick_grocery_admin/view/platform_fee/services/platform_fee_service.dart';
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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quick Grocery Admin',
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
          useMaterial3: true,
        ),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, userSnp) {
            if (userSnp.hasData) {
              return const HomeScreen();
            }
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}
