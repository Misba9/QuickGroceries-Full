import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/review/review_service.dart';
import 'package:quickgrocery/view/home/screens/landing_screen.dart';

import '../../domain/order_models.dart';
import '../providers/orders_providers.dart';
import '../providers/reorder_controller.dart';
import '../widgets/delivered_celebration.dart';
import 'package:quickgrocery/view/delivery_tips/models/delivery_tip_settings.dart';
import 'package:quickgrocery/view/delivery_tips/services/delivery_tip_service.dart';
import 'package:quickgrocery/view/delivery_tips/widgets/delivery_tip_tracking_card.dart';
import 'package:quickgrocery/view/delivery_tips/widgets/post_delivery_tip_sheet.dart';
import '../widgets/live_tracking_map.dart';
import '../widgets/order_navigation_actions.dart';
import '../widgets/order_actions_bar.dart';
import '../widgets/order_details_card.dart';
import '../widgets/order_timeline_widget.dart';
import '../widgets/order_tracking_header.dart';
import '../widgets/rider_card.dart';
import 'support_chat_screen.dart';
import 'package:quickgrocery/core/loading/loading.dart';

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
  DeliveryTipSettings _tipSettings = DeliveryTipSettings.defaults();
  bool _postDeliverySheetShown = false;
  bool _experienceReviewScheduled = false;

  @override
  void initState() {
    super.initState();
    deliveryTipServiceProvider.fetchSettings().then((s) {
      if (mounted) setState(() => _tipSettings = s);
    });
  }

  /// Tip sheet first (if enabled from checkout), then "Rate Your Order".
  Future<void> _schedulePostDeliveryFlow(LiveOrder order) async {
    // Let the Delivered celebration paint before any modal.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (widget.fromCheckout &&
        _tipSettings.enabled &&
        !_postDeliverySheetShown) {
      _postDeliverySheetShown = true;
      await showPostDeliveryTipSheet(
        context: context,
        order: order,
        settings: _tipSettings,
      );
      if (!mounted) return;
    }

    final uid = OrderReviewService.currentUserId() ?? order.legacy.uuid;
    if (uid.isEmpty) return;

    final svc = await OrderReviewService.instance();
    if (!mounted) return;
    await svc.maybePromptForOrder(
      context: context,
      orderId: order.id,
      userId: uid,
      delay: true,
      forceOnDeliveredScreen: true,
    );
  }

  Future<void> _runReorder(LiveOrder order) async {
    setState(() => _busyAction = 'reorder');
    final result =
        await ref.read(reorderControllerProvider).reorder(order);
    if (!mounted) return;
    setState(() => _busyAction = null);

    if (result.nothingAdded) {
      AppSnackBar.error(
        'None of these items are available right now',
        context: context,
      );
      return;
    }

    final summary = result.unavailable.isEmpty
        ? 'Added ${result.added.length} items to your cart'
        : 'Added ${result.added.length} · ${result.unavailable.length} unavailable';
    AppSnackBar.success(summary, context: context);

    Navigator.push(context, AppPageRoutes.cart());
  }

  Future<void> _runInvoice(LiveOrder order) async {
    setState(() => _busyAction = 'invoice');
    try {
      await ref.read(invoiceServiceProvider).generateAndShare(order);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error('Could not generate invoice: $e', context: context);
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
    final surface = AppSurface.of(context);

    return PopScope(
      canPop: !widget.fromCheckout,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: surface.scaffold,
        appBar: AppBar(
          title: Text(
            'Track order',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          backgroundColor: surface.card,
          foregroundColor: surface.textPrimary,
          elevation: 0.5,
          leading: BackButton(onPressed: _onBack),
        ),
        body: orderAsync.when(
          loading: () => AppLoading.center,
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 48, color: surface.iconInactive),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load order details',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: surface.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check your connection and try again.',
                    style: GoogleFonts.poppins(color: surface.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => ref.invalidate(orderByIdStreamProvider(widget.orderId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (order) {
            if (order == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Order not found',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }

            final timeline = buildTimeline(order);
            final eta = ref.watch(etaProvider(order.id));
  final riderAsync = order.hasRider
      ? ref.watch(riderLocationStreamProvider((order.deliveryBoyId, order.id)))
      : const AsyncValue<RiderLocation?>.data(null);
            final rider = riderAsync.value;
            final isDelivered = order.isDelivered;

            // Delivered → tip (optional) → experience review (once per order).
            if (isDelivered && !_experienceReviewScheduled) {
              _experienceReviewScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                unawaited(_schedulePostDeliveryFlow(order));
              });
            }

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
                          storeLocation: order.storeLatLng,
                          rider: rider,
                          eta: eta,
                        ),
                        const SizedBox(height: 10),
                        OrderNavigationActions(order: order, rider: rider),
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
                      if (!isDelivered && order.canIncreaseTip)
                        DeliveryTipTrackingCard(
                          order: order,
                          settings: _tipSettings,
                        ),
                      if (!isDelivered && order.canIncreaseTip)
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
                      AppSnackBar.info(
                        'Delivery partner not assigned yet',
                        context: context,
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
    final surface = AppSurface.of(context);
    return Material(
      elevation: 8,
      shadowColor: surface.shadow,
      color: surface.card,
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
                        backgroundColor: surface.textPrimary,
                        foregroundColor: surface.card,
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
