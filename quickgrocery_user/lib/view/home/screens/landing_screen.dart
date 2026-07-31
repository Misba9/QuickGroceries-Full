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
import 'package:quickgrocery/core/review/order_review_bootstrap.dart';
import 'package:quickgrocery/core/update/update_bootstrap.dart';
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
        await AndroidAppBackground.moveTaskToBack();
      },
      child: MaintenanceGate(
        child: legacy.Selector<HomeProvider, int>(
          selector: (_, p) => p.selectedIndex,
          builder: (context, selectedIndex, _) {
            final provider =
                legacy.Provider.of<HomeProvider>(context, listen: false);
            return Scaffold(
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const GuestModeBanner(),
                    Expanded(
                      // Background shells are no-ops until
                      // [PostHomeStartup.homeVisible] — they must not delay
                      // the first Home paint.
                      child: DeliveryPricingUpdateListener(
                        child: AppUpdateBootstrap(
                          child: OrderReviewBootstrap(
                            child: PromotionPopupBootstrap(
                              child: IndexedStack(
                                key: ValueKey<String>('tabs-$localeKey'),
                                index: selectedIndex,
                                children: [
                                  for (var i = 0;
                                      i < provider.pages.length;
                                      i++)
                                    HeroMode(
                                      enabled: selectedIndex == i,
                                      child: provider.pages[i],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: PremiumFiveTabNav(
                key: ValueKey<String>('nav-$localeKey'),
                currentIndex: selectedIndex,
                onTap: provider.onSelectedChange,
              ),
            );
          },
        ),
      ),
    );
  }
}
