import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/core/widgets/floating_cart_pill.dart';
import 'package:quickgrocery/core/widgets/modern_bottom_nav.dart';
import 'package:quickgrocery/not_available_screen.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Foreground notifications are handled by the system tray.
      // Hook into [message] here if a custom in-app banner is desired.
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null && mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(notification.title ?? ''),
            content: SingleChildScrollView(
              child: Text(notification.body ?? ''),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admins')
          .doc('4elRGQlC662hdcE1a1Ls')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('something_went_wrong'.tr())),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const NotActiveScreen();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isActive = data['isActive'] as bool? ?? false;
        if (!isActive) return const NotActiveScreen();

        return Consumer<HomeProvider>(
          builder: (context, provider, _) {
            return Scaffold(
              body: Stack(
                children: [
                  IndexedStack(
                    index: provider.selectedIndex,
                    children: provider.pages,
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: FloatingCartPill(),
                  ),
                ],
              ),
              bottomNavigationBar: SafeArea(
                top: false,
                maintainBottomViewPadding: true,
                child: ModernBottomNav(
                  currentIndex: provider.selectedIndex,
                  onTap: provider.onSelectedChange,
                  items: const [
                    ModernBottomNavItem(
                      label: 'Home',
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                    ),
                    ModernBottomNavItem(
                      label: 'Categories',
                      icon: Icons.grid_view_outlined,
                      activeIcon: Icons.grid_view_rounded,
                    ),
                    ModernBottomNavItem(
                      label: 'Orders',
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long_rounded,
                    ),
                    ModernBottomNavItem(
                      label: 'Profile',
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
