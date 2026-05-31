import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/core/widgets/floating_cart_pill.dart';
import 'package:quickgrocery/core/widgets/premium_five_tab_nav.dart';
import 'package:quickgrocery/maintenance/presentation/widgets/maintenance_gate.dart';
import 'package:quickgrocery/services/language_service.dart';
import 'package:quickgrocery/view/delivery/presentation/delivery_pricing_update_listener.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/promotion_popup_bootstrap.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, _) {
        final localeKey = languageService.currentLocale.toLanguageTag();

        return MaintenanceGate(
          child: Consumer<HomeProvider>(
            builder: (context, provider, _) {
              return Scaffold(
                body: DeliveryPricingUpdateListener(
                  child: PromotionPopupBootstrap(
                    child: Stack(
                      children: [
                        IndexedStack(
                          key: ValueKey(localeKey),
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
                  key: ValueKey('nav-$localeKey'),
                  currentIndex: provider.selectedIndex,
                  onTap: provider.onSelectedChange,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
