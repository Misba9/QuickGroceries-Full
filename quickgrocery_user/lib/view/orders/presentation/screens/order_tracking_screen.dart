import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/view/cart/screen/cart_screen.dart';

import '../../domain/order_models.dart';
import '../providers/orders_providers.dart';
import '../providers/reorder_controller.dart';
import '../widgets/eta_pill.dart';
import '../widgets/live_tracking_map.dart';
import '../widgets/order_actions_bar.dart';
import '../widgets/order_timeline_widget.dart';
import '../widgets/rider_card.dart';
import 'support_chat_screen.dart';

/// Modern Zepto/Blinkit-style live tracking screen.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

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
        content: const Text('You will not be charged. This cannot be undone.'),
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

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdStreamProvider(widget.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Track order'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
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
              ? ref.watch(riderLocationStreamProvider(order.deliveryBoyId))
              : const AsyncValue<RiderLocation?>.data(null);

          final canCancel = !order.isCancelled &&
              !order.isDelivered &&
              order.status == OrderStatus.pending;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.status.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  EtaPill(eta: eta, status: order.status),
                ],
              ),
              const SizedBox(height: 14),
              LiveTrackingMap(
                dropLocation: order.dropLatLng,
                rider: riderAsync.value,
              ),
              const SizedBox(height: 14),
              RiderCard(
                rider: riderAsync.value,
                order: order,
                onChat: _openSupport,
              ),
              const SizedBox(height: 14),
              if (order.deliveryInstructions.isNotEmpty)
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
                        child: Text(
                          order.deliveryInstructions,
                          style: TextStyle(color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              OrderTimelineWidget(entries: timeline),
              const SizedBox(height: 14),
              OrderActionsBar(
                busyAction: _busyAction,
                onReorder: () => _runReorder(order),
                onInvoice: () => _runInvoice(order),
                onSupport: _openSupport,
              ),
              if (canCancel) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _confirmCancel(order),
                  child: Text(
                    'Cancel order',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
