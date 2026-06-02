import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/view/cart/screen/cart_screen.dart';
import 'package:quickgrocery/view/home/screens/landing_screen.dart';

import '../../domain/order_models.dart';
import '../providers/orders_providers.dart';
import '../providers/reorder_controller.dart';
import '../widgets/delivered_celebration.dart';
import '../widgets/live_tracking_map.dart';
import '../widgets/order_actions_bar.dart';
import '../widgets/order_details_card.dart';
import '../widgets/order_timeline_widget.dart';
import '../widgets/order_tracking_header.dart';
import '../widgets/rider_card.dart';
import 'support_chat_screen.dart';

/// Modern Zepto/Blinkit-style live order tracking screen.
///
/// Subscribes to Firestore order + rider streams — no manual refresh needed.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.fromCheckout = false,
  });

  final String orderId;
  final bool fromCheckout;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  String? _busyAction;

  Future<void> _runReorder(LiveOrder order) async {
    setState(() => _busyAction = 'reorder');
    final result =
        await ref.read(reorderControllerProvider).reorder(order);
    if (!mounted) return;
    setState(() => _busyAction = null);

    final messenger = ScaffoldMessenger.of(context);
    if (result.nothingAdded) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('None of these items are available right now'),
        ),
      );
      return;
    }

    final summary = result.unavailable.isEmpty
        ? 'Added ${result.added.length} items to your cart'
        : 'Added ${result.added.length} · ${result.unavailable.length} unavailable';
    messenger.showSnackBar(SnackBar(content: Text(summary)));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  Future<void> _runInvoice(LiveOrder order) async {
    setState(() => _busyAction = 'invoice');
    try {
      await ref.read(invoiceServiceProvider).generateAndShare(order);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate invoice: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  void _openSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupportChatScreen(orderId: widget.orderId),
      ),
    );
  }

  Future<void> _confirmCancel(LiveOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text(
          'You can cancel before the rider picks up your order. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(ordersRepositoryProvider)
        .cancelOrder(order.id, reason: 'Cancelled by customer');
  }

  void _onBack() {
    if (widget.fromCheckout) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (_) => false,
      );
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdStreamProvider(widget.orderId));

    return PopScope(
      canPop: !widget.fromCheckout,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: Text(
            'Track order',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          leading: BackButton(onPressed: _onBack),
        ),
        body: orderAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (order) {
            if (order == null) {
              return const Center(child: Text('Order not found'));
            }

            final timeline = buildTimeline(order);
            final eta = ref.watch(etaProvider(order.id));
  final riderAsync = order.hasRider
      ? ref.watch(riderLocationStreamProvider((order.deliveryBoyId, order.id)))
      : const AsyncValue<RiderLocation?>.data(null);
            final rider = riderAsync.value;
            final isDelivered = order.isDelivered;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    children: [
                      if (isDelivered)
                        DeliveredCelebration(
                          order: order,
                          onRateRider: () => showOrderRatingSheet(
                            context: context,
                            orderId: order.id,
                            title: 'Rate delivery partner',
                            firestoreField: 'rider_rating',
                          ),
                          onRateVendor: () => showOrderRatingSheet(
                            context: context,
                            orderId: order.id,
                            title: 'Rate vendor',
                            firestoreField: 'vendor_rating',
                          ),
                        )
                      else if (order.isLiveTracking) ...[
                        OrderTrackingHeader(order: order, eta: eta),
                        const SizedBox(height: 14),
                        LiveTrackingMap(
                          dropLocation: order.dropLatLng,
                          rider: rider,
                          eta: eta,
                        ),
                        const SizedBox(height: 14),
                      ] else if (!isDelivered) ...[
                        OrderTrackingHeader(order: order, eta: eta),
                        const SizedBox(height: 14),
                      ],
                      RiderCard(
                        rider: rider,
                        order: order,
                        onChat: _openSupport,
                      ),
                      const SizedBox(height: 14),
                      if (!order.structuredInstructions.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.amber.shade100),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.note_alt_outlined,
                                  color: Colors.amber.shade900),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: order.structuredInstructions
                                      .displayLines()
                                      .map(
                                        (line) => Text(
                                          line,
                                          style: TextStyle(
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        'Live status',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OrderTimelineWidget(entries: timeline),
                      const SizedBox(height: 14),
                      OrderDetailsCard(order: order),
                      if (order.canCustomerCancel) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _confirmCancel(order),
                          child: Text(
                            'Cancel order',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                      const SizedBox(height: 88),
                    ],
                  ),
                ),
                _StickyActions(
                  order: order,
                  busyAction: _busyAction,
                  onReorder: () => _runReorder(order),
                  onInvoice: () => _runInvoice(order),
                  onSupport: _openSupport,
                  onCallRider: () async {
                    final phone = rider?.phone ?? '';
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delivery partner not assigned yet'),
                        ),
                      );
                      return;
                    }
                    await RiderCard.launchCall(phone);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StickyActions extends StatelessWidget {
  const _StickyActions({
    required this.order,
    required this.busyAction,
    required this.onReorder,
    required this.onInvoice,
    required this.onSupport,
    required this.onCallRider,
  });

  final LiveOrder order;
  final String? busyAction;
  final VoidCallback onReorder;
  final VoidCallback onInvoice;
  final VoidCallback onSupport;
  final VoidCallback onCallRider;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (order.hasRider && !order.isDelivered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onCallRider,
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Call delivery partner'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              OrderActionsBar(
                busyAction: busyAction,
                onReorder: onReorder,
                onInvoice: onInvoice,
                onSupport: onSupport,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
