import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/view/delivery_tips/models/delivery_tip_settings.dart';
import 'package:quickgrocery/view/delivery_tips/services/delivery_tip_service.dart';
import 'package:quickgrocery/view/orders/domain/order_models.dart';
import 'package:quickgrocery/view/payment/data/razorpay_order_client.dart';
import 'package:quickgrocery/view/payment/domain/razorpay_payment_result.dart';
import 'package:quickgrocery/view/payment/services/payment_service.dart';

/// Active-order tip increase card (assigned → out for delivery).
class DeliveryTipTrackingCard extends StatefulWidget {
  const DeliveryTipTrackingCard({
    super.key,
    required this.order,
    required this.settings,
  });

  final LiveOrder order;
  final DeliveryTipSettings settings;

  @override
  State<DeliveryTipTrackingCard> createState() =>
      _DeliveryTipTrackingCardState();
}

class _DeliveryTipTrackingCardState extends State<DeliveryTipTrackingCard> {
  final _tipService = deliveryTipServiceProvider;
  bool _loading = false;
  double? _optimisticTip;

  double get _displayTip => _optimisticTip ?? widget.order.deliveryPartnerTip;

  bool get _isCod {
    final id = widget.order.paymentMethodId.toLowerCase();
    return id.isEmpty || id == 'cod';
  }

  Future<bool> _confirmCodTip() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add delivery tip'),
        content: const Text(
          'Tip will be collected along with order payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _applyTipDelta(int delta) async {
    if (_loading || delta <= 0) return;

    final current = _displayTip;
    final newTotal = current + delta;
    if (newTotal > widget.settings.maxTipAmount) {
      AppSnackBar.error(
        'Maximum tip is ₹${widget.settings.maxTipAmount}.',
        context: context,
      );
      return;
    }

    if (_isCod) {
      final confirmed = await _confirmCodTip();
      if (!confirmed || !mounted) return;
      await _commitTipDelta(
        delta,
        paymentStatus: 'cod_pending',
      );
      return;
    }

    await _payOnlineAndApply(delta);
  }

  Future<void> _payOnlineAndApply(int delta) async {
    setState(() => _loading = true);
    final payment = Provider.of<PaymentService>(context, listen: false);
    var paymentCompleted = false;

    try {
      final session = await RazorpayOrderClient().createTipOrder(
        amountRupees: delta.toDouble(),
        groceryOrderId: widget.order.id,
      );
      if (!mounted) return;
      payment.openCheckoutSession(
        session: session,
        name: widget.order.customerName.isNotEmpty
            ? widget.order.customerName
            : 'Quick Grocery',
        description: 'Delivery partner tip',
        onPaymentSuccess: (RazorpayPaymentResult result) async {
          paymentCompleted = true;
          if (!mounted) return;
          try {
            await RazorpayOrderClient().confirmTipPayment(
              groceryOrderId: widget.order.id,
              payment: result,
              tipDeltaRupees: delta,
            );
            if (!mounted) return;
            setState(() {
              _optimisticTip = _displayTip + delta;
              _loading = false;
            });
            AppSnackBar.success(
              'Tip of ₹$delta added. Thank you!',
              context: context,
            );
          } catch (e) {
            if (mounted) {
              setState(() => _loading = false);
              AppSnackBar.error(
                e is StateError
                    ? e.message
                    : 'Tip payment could not be verified.',
                context: context,
              );
            }
          }
        },
        onPaymentError: (message) {
          if (!mounted || paymentCompleted) return;
          setState(() => _loading = false);
          AppSnackBar.error(
            message.isNotEmpty ? message : 'Payment was not completed.',
            context: context,
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppSnackBar.error(
          e is StateError ? e.message : 'Could not start tip payment.',
          context: context,
        );
      }
    }
  }

  Future<void> _commitTipDelta(
    int delta, {
    String? paymentRef,
    String paymentStatus = 'pending',
  }) async {
    if (_loading) return;
    setState(() => _loading = true);

    final oldTip = _displayTip;
    if (kDebugMode) {
      debugPrint(
        'TIP TAP: orderId=${widget.order.id} oldTip=$oldTip delta=$delta',
      );
    }

    try {
      final result = await _tipService.addTipDelta(
        orderId: widget.order.id,
        delta: delta,
        paymentRef: paymentRef,
        paymentStatus: paymentStatus,
      );
      if (!mounted) return;
      setState(() => _optimisticTip = result.newTip);
      AppSnackBar.success(
        '🎉 Thank you! ₹${result.delta.toStringAsFixed(0)} tip added successfully.',
        context: context,
      );
    } on DeliveryTipException catch (e) {
      if (mounted) AppSnackBar.error(e.message, context: context);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(
          'Could not update tip. Please try again.',
          context: context,
        );
      }
      debugPrint('TIP UI ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _customTip() async {
    if (_loading) return;
    final ctrl = TextEditingController();
    final minTotal = _displayTip.ceil() + 1;
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom tip'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'New total (min ₹$minTotal)',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim()) ?? 0;
              Navigator.pop(ctx, v);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= _displayTip) return;
    final capped = amount.clamp(0, widget.settings.maxTipAmount.toDouble());
    final delta = (capped - _displayTip).round();
    if (delta <= 0) return;
    await _applyTipDelta(delta);
  }

  @override
  void didUpdateWidget(DeliveryTipTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.deliveryPartnerTip != widget.order.deliveryPartnerTip) {
      _optimisticTip = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.settings.enabled || !widget.order.canIncreaseTip) {
      return const SizedBox.shrink();
    }
    if (widget.order.isDelivered || widget.order.isCancelled) {
      return const SizedBox.shrink();
    }

    final current = _displayTip;
    final boostOptions = [10, 20, 50]
        .where((d) => current + d <= widget.settings.maxTipAmount)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primary.withValues(alpha: 0.12),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Color(0xFFE6A800)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thank Your Delivery Partner',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            current > 0
                ? 'Current Delivery Partner Tip: ₹${current.toStringAsFixed(0)}'
                : 'Add a tip to appreciate your delivery partner',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppSurface.textSecondary,
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 4),
            Text(
              'Updating tip…',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppSurface.textSecondary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in boostOptions)
                  ActionChip(
                    label: Text('Add ₹$d'),
                    onPressed: () => _applyTipDelta(d),
                  ),
                ActionChip(
                  label: const Text('Custom Tip'),
                  onPressed: _customTip,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
