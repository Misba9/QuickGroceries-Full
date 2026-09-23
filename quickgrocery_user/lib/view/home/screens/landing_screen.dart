import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:quickgrocery/core/localization/locale_provider.dart';
import 'package:quickgrocery/core/navigation/android_app_background.dart';
import 'package:quickgrocery/core/navigation/home_tab_observer.dart';
import 'package:quickgrocery/core/widgets/premium_five_tab_nav.dart';
import 'package:quickgrocery/view/home/presentation/widgets/guest_mode_banner.dart';
import 'package:quickgrocery/maintenance/presentation/widgets/maintenance_gate.dart';
import 'package:quickgrocery/view/delivery/presentation/delivery_pricing_update_listener.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/promotion_popup_bootstrap.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    HomeTabObserver.selectedIndexListenable.value =
        legacy.Provider.of<HomeProvider>(context, listen: false).selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final localeKey = ref.watch(localeProvider).toLanguageTag();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final provider = legacy.Provider.of<HomeProvider>(context, listen: false);
        if (provider.selectedIndex != 0) {
          provider.onSelectedChange(0);
          return;
        }
        // Home tab on Android: move task to background (Blinkit/Zepto-style).
        await AndroidAppBackground.moveTaskToBack();
      },
      child: MaintenanceGate(
        child: legacy.Consumer<HomeProvider>(
          builder: (context, provider, _) {
            final pages = provider.pages;
            final selected = provider.selectedIndex;
            return Scaffold(
              body: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: const GuestModeBanner(),
                  ),
                  Expanded(
                    child: DeliveryPricingUpdateListener(
                      child: PromotionPopupBootstrap(
                        child: IndexedStack(
                          key: ValueKey<String>('tabs-$localeKey'),
                          index: selected,
                          children: [
                            // IndexedStack keeps every tab mounted. Only
                            // HeroMode actually drops offstage heroes from
                            // the navigator's flight scan; a second
                            // HeroController does not.
                            for (var i = 0; i < pages.length; i++)
                              HeroMode(
                                enabled: i == selected,
                                child: pages[i],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: PremiumFiveTabNav(
                key: ValueKey<String>('nav-$localeKey'),
                currentIndex: selected,
                onTap: provider.onSelectedChange,
              ),
            );
          },
        ),
      ),
    );
  }
}
