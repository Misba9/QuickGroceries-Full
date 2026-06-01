import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/services/driver_earnings_service.dart';
import 'package:quick_grocery_delivery/services/driver_profile_service.dart';
import 'package:quick_grocery_delivery/widgets/driver_stat_card.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  EarningsSnapshot _snap = EarningsSnapshot.empty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = context.read<OrderService>();
    final snap = await DriverEarningsService().compute(cachedOrders: orders.orders);
    if (mounted) setState(() { _snap = snap; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DriverProfileService>().profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DriverStatCard(
                    label: 'Delivery rating',
                    value: _snap.avgRating > 0
                        ? '${_snap.avgRating.toStringAsFixed(1)} / 5'
                        : (profile?.driverRating ?? 0) > 0
                            ? '${profile!.driverRating.toStringAsFixed(1)} / 5'
                            : '—',
                    icon: Icons.star_outline,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DriverStatCard(
                          label: 'Acceptance rate',
                          value: '${_snap.acceptanceRate.toStringAsFixed(0)}%',
                          icon: Icons.thumb_up_alt_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DriverStatCard(
                          label: 'On-time',
                          value: '${(profile?.onTimePercent ?? 92).toStringAsFixed(0)}%',
                          icon: Icons.schedule,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DriverStatCard(
                    label: 'Completed trips',
                    value: '${_snap.completed}',
                    icon: Icons.local_shipping_outlined,
                    subtitle: '${_snap.cancelled} cancelled · ${_snap.pendingOffers} pending offers',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Customer feedback',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Ratings from delivered orders appear here. Keep acceptance high and deliver on time to improve your score.',
                        style: TextStyle(height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
