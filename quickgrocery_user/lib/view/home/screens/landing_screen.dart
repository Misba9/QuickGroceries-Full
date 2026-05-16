import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/core/widgets/firestore_connection_lost.dart';
import 'package:quickgrocery/core/widgets/floating_cart_pill.dart';
import 'package:quickgrocery/core/widgets/premium_five_tab_nav.dart';
import 'package:quickgrocery/view/delivery/presentation/delivery_pricing_update_listener.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_shimmer.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/promotion_popup_bootstrap.dart';
import 'package:quickgrocery/not_available_screen.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _adminStreamKey = 0;

  Stream<DocumentSnapshot> _adminDocStream() {
    return FirebaseFirestore.instance
        .collection('admins')
        .doc('4elRGQlC662hdcE1a1Ls')
        .snapshots();
  }

  void _reconnectAdminStream() {
    setState(() => _adminStreamKey++);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      key: ValueKey<int>(_adminStreamKey),
      stream: _adminDocStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FirestoreConnectionLost(
            error: snapshot.error!,
            onRetry: _reconnectAdminStream,
          );
        }

        if (!snapshot.hasData) {
          return HomeShimmer.landingTabShell();
        }

        if (!snapshot.data!.exists) {
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
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: PremiumFiveTabNav.floatingOverlayBodyBottom(
                          context,
                        ),
                        child: const FloatingCartPill(),
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
