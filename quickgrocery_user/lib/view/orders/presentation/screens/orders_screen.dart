import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/orders/presentation/providers/orders_providers.dart';
import 'package:quickgrocery/view/orders/presentation/screens/order_tracking_screen.dart';
import 'package:quickgrocery/view/orders/presentation/widgets/order_card_modern.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Modern orders screen — three live-streamed tabs.
///
/// Class name kept as `OrdersScreeen` (the legacy mis-spelling) so all
/// existing navigation calls in the codebase keep working unchanged.
class OrdersScreeen extends ConsumerStatefulWidget {
  const OrdersScreeen({super.key});

  @override
  ConsumerState<OrdersScreeen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreeen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 3, vsync: this, initialIndex: 0);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        legacy_provider.Provider.of<HomeProvider>(context, listen: false)
            .onSelectedChange(0);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      context.l10n.orders,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabs,
                indicatorColor: AppColor.primary,
                indicatorWeight: 3,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                tabs: [
                  Tab(text: context.l10n.processing),
                  Tab(text: context.l10n.delivered),
                  Tab(text: context.l10n.cancelled),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: const [
                    _OrdersTabBody(tab: OrdersTab.processing),
                    _OrdersTabBody(tab: OrdersTab.delivered),
                    _OrdersTabBody(tab: OrdersTab.cancelled),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersTabBody extends ConsumerWidget {
  const _OrdersTabBody({required this.tab});

  final OrdersTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders = ref.watch(filteredOrdersProvider(tab));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userOrdersStreamProvider);
        await Future.delayed(const Duration(milliseconds: 250));
      },
      child: asyncOrders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load orders\n$e',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            ),
          ],
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 180,
                          child: LottieBuilder.asset(
                            'assets/lottie/no_orders.json',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No orders here yet',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final order = list[i];
              return FadeInUp(
                duration: Duration(milliseconds: 220 + i * 40),
                child: OrderCardModern(
                  order: order,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderTrackingScreen(orderId: order.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
