import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/core/widgets/floating_cart_pill.dart';
import 'package:quickgrocery/core/widgets/premium_five_tab_nav.dart';
import 'package:quickgrocery/view/delivery/presentation/delivery_pricing_update_listener.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/promotion_popup_bootstrap.dart';
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
              body: DeliveryPricingUpdateListener(
                child: PromotionPopupBootstrap(
                  child: Stack(
                    children: [
                      IndexedStack(
                        index: provider.selectedIndex,
                        children: provider.pages,
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 76,
                        child: FloatingCartPill(),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: PremiumFiveTabNav(
                currentIndex: provider.selectedIndex,
                onTap: provider.onSelectedChange,
              ),
            );
          },
        );
      },
    );
  }
}
