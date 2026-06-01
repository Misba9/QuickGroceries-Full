import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/home/pages/home_page.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/features/payment/screens/scan_pay_screen.dart';
import 'package:quick_grocery_delivery/services/driver_earnings_service.dart';
import 'package:quick_grocery_delivery/services/driver_profile_service.dart';
import 'package:quick_grocery_delivery/support/support_contact_sheet.dart';
import 'package:quick_grocery_delivery/widgets/driver_stat_card.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  final _earningsService = DriverEarningsService();
  OrderService? _orders;
  EarningsSnapshot _earnings = EarningsSnapshot.empty;
  bool _loadingEarnings = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orders = context.read<OrderService>();
      _orders!.addListener(_loadEarnings);
      context.read<DriverProfileService>().startListening();
      _loadEarnings();
      _orders!.getDeliveryBoy();
      _orders!.startRealtimeOrders();
      _orders!.getOrders();
      _orders!.updateAdminFcmToken();
    });
  }

  @override
  void dispose() {
    _orders?.removeListener(_loadEarnings);
    super.dispose();
  }

  Future<void> _loadEarnings() async {
    if (!mounted) return;
    setState(() => _loadingEarnings = true);
    final orders = context.read<OrderService>();
    final snap = await _earningsService.compute(cachedOrders: orders.orders);
    await _earningsService.syncStatsToProfile(snap);
    if (mounted) {
      setState(() {
        _earnings = snap;
        _loadingEarnings = false;
      });
    }
  }

  Future<void> _refresh() async {
    await context.read<OrderService>().getOrders();
    await _loadEarnings();
  }

  @override
  Widget build(BuildContext context) {
    final profileSvc = context.watch<DriverProfileService>();
    final profile = profileSvc.profile;
    final orders = context.watch<OrderService>();

    return Scaffold(
      backgroundColor: GlobalVariables.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: GlobalVariables.background,
                title: const Text(
                  'Driver Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.support_agent_outlined),
                    onPressed: () => SupportContactSheet.show(context),
                  ),
                  if (profile != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CircleAvatar(
                        backgroundImage:
                            profile.image.isNotEmpty ? NetworkImage(profile.image) : null,
                        child: profile.image.isEmpty
                            ? Text(profile.name.isNotEmpty ? profile.name[0] : '?')
                            : null,
                      ),
                    ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _OnlineStatusCard(profileSvc: profileSvc),
                    const SizedBox(height: 12),
                    _ScanPayBanner(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanPayScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loadingEarnings)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ))
                    else ...[
                      const Text(
                        'Earnings',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DriverStatCard(
                              label: 'Today',
                              value: '₹${_earnings.today.toStringAsFixed(0)}',
                              icon: Icons.today_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DriverStatCard(
                              label: 'This week',
                              value: '₹${_earnings.week.toStringAsFixed(0)}',
                              icon: Icons.date_range_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DriverStatCard(
                              label: 'This month',
                              value: '₹${_earnings.month.toStringAsFixed(0)}',
                              icon: Icons.calendar_month_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DriverStatCard(
                              label: 'Total',
                              value: '₹${_earnings.total.toStringAsFixed(0)}',
                              icon: Icons.account_balance_wallet_outlined,
                              subtitle: 'Pending ₹${(profile?.pendingPayout ?? 0).toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Deliveries',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DriverStatCard(
                              label: 'Completed',
                              value: '${_earnings.completed}',
                              icon: Icons.check_circle_outline,
                              accent: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DriverStatCard(
                              label: 'Cancelled',
                              value: '${_earnings.cancelled}',
                              icon: Icons.cancel_outlined,
                              accent: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DriverStatCard(
                              label: 'Pending offers',
                              value: '${_earnings.pendingOffers}',
                              icon: Icons.notifications_active_outlined,
                              accent: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DriverStatCard(
                              label: 'In progress',
                              value: '${_earnings.inProgress}',
                              icon: Icons.delivery_dining,
                              accent: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DriverStatCard(
                        label: 'Rating · Acceptance',
                        value: _earnings.avgRating > 0
                            ? '${_earnings.avgRating.toStringAsFixed(1)} ★'
                            : '—',
                        subtitle:
                            '${_earnings.acceptanceRate.toStringAsFixed(0)}% acceptance · ${_earnings.riderCancellations} rider cancels',
                        icon: Icons.star_outline,
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Pending offers',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    if (orders.newOrders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No new orders right now'),
                      )
                    else
                      ...orders.newOrders.take(5).map((cart) {
                        return OrderPendingCard(
                          products: cart.products,
                          isFastDelivery: cart.deliveryType == 'fast',
                          status: cart.orderStatus,
                          onTap: () => orders.showConfirmationDialog(
                            context,
                            cart.id,
                            cart.uuid,
                          ),
                          date: cart.createdDate.length >= 10
                              ? cart.createdDate.substring(0, 10)
                              : cart.createdDate,
                          orderId: cart.id.length > 6 ? cart.id.substring(0, 6) : cart.id,
                          customerName: cart.customerName,
                          customerAddress: cart.address,
                        );
                      }),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineStatusCard extends StatelessWidget {
  const _OnlineStatusCard({required this.profileSvc});
  final DriverProfileService profileSvc;

  @override
  Widget build(BuildContext context) {
    final p = profileSvc.profile;
    if (p == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${p.name.isNotEmpty ? p.name : 'Driver'}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              _statusLabel(p.availability),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SegmentedButton<DriverAvailability>(
              segments: const [
                ButtonSegment(
                  value: DriverAvailability.online,
                  label: Text('Online'),
                  icon: Icon(Icons.check_circle_outline),
                ),
                ButtonSegment(
                  value: DriverAvailability.offline,
                  label: Text('Offline'),
                  icon: Icon(Icons.power_settings_new),
                ),
                ButtonSegment(
                  value: DriverAvailability.paused,
                  label: Text('Pause'),
                  icon: Icon(Icons.pause_circle_outline),
                ),
              ],
              selected: {p.availability},
              onSelectionChanged: p.isActive
                  ? (s) => profileSvc.setAvailability(s.first)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(DriverAvailability a) {
    switch (a) {
      case DriverAvailability.online:
        return 'Online — available for new assignments';
      case DriverAvailability.offline:
        return 'Offline — not receiving assignments';
      case DriverAvailability.paused:
        return 'Paused — temporarily unavailable';
    }
  }
}

class _ScanPayBanner extends StatelessWidget {
  const _ScanPayBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GlobalVariables.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              const Icon(Icons.qr_code_scanner, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan & Pay',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text('Verify customer payments instantly'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
