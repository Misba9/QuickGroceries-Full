import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/feedback/show_top_error_toast.dart';
import 'package:quickgrocery/view/delivery_tips/models/delivery_tip_settings.dart';
import 'package:quickgrocery/view/delivery_tips/services/delivery_tip_service.dart';
import 'package:quickgrocery/view/orders/domain/order_models.dart';
import 'package:quickgrocery/view/orders/presentation/widgets/delivered_celebration.dart';
import 'package:quickgrocery/view/payment/services/payment_service.dart';

/// Post-delivery feedback: rate delivery + optional extra tip.
Future<void> showPostDeliveryTipSheet({
  required BuildContext context,
  required LiveOrder order,
  required DeliveryTipSettings settings,
}) {
  if (!settings.enabled) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PostDeliveryTipSheet(order: order, settings: settings),
  );
}

class _PostDeliveryTipSheet extends StatefulWidget {
  const _PostDeliveryTipSheet({
    required this.order,
    required this.settings,
  });

  final LiveOrder order;
  final DeliveryTipSettings settings;

  @override
  State<_PostDeliveryTipSheet> createState() => _PostDeliveryTipSheetState();
}

class _PostDeliveryTipSheetState extends State<_PostDeliveryTipSheet> {
  final _tipService = deliveryTipServiceProvider;
  int? _selected;
  bool _loading = false;

  bool get _isCod {
    final id = widget.order.paymentMethodId.toLowerCase();
    return id.isEmpty || id == 'cod';
  }

  Future<bool> _confirmCodTip() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add extra tip'),
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

  Future<void> _submit() async {
    final extra = _selected ?? 0;
    if (extra <= 0) {
      Navigator.pop(context);
      return;
    }
    final newTotal = widget.order.deliveryPartnerTip + extra;
    if (newTotal > widget.settings.maxTipAmount) {
      showTopErrorToast(
        context,
        'Maximum tip is ₹${widget.settings.maxTipAmount}.',
      );
      return;
    }
    if (_loading) return;

    if (_isCod) {
      final confirmed = await _confirmCodTip();
      if (!confirmed || !mounted) return;
      await _commitDelta(extra, paymentStatus: 'cod_pending');
      return;
    }

    final payment = Provider.of<PaymentService>(context, listen: false);
    var paymentCompleted = false;
    payment.openCheckout(
      extra.toDouble(),
      widget.order.customerName.isNotEmpty
          ? widget.order.customerName
          : 'Quick Grocery',
      'Delivery partner tip',
      onPaymentSuccess: (paymentId) async {
        paymentCompleted = true;
        if (!mounted) return;
        await _commitDelta(
          extra,
          paymentRef: paymentId,
          paymentStatus: 'paid',
        );
      },
      onPaymentError: (message) {
        if (!mounted || paymentCompleted) return;
        showTopErrorToast(
          context,
          message.isNotEmpty ? message : 'Payment was not completed.',
        );
      },
    );
  }

  Future<void> _commitDelta(
    int delta, {
    String? paymentRef,
    String paymentStatus = 'pending',
  }) async {
    setState(() => _loading = true);
    try {
      final result = await _tipService.addTipDelta(
        orderId: widget.order.id,
        delta: delta,
        allowAfterDelivered: true,
        paymentRef: paymentRef,
        paymentStatus: paymentStatus,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Thank you! ₹${result.delta.toStringAsFixed(0)} tip added successfully.',
          ),
        ),
      );
    } on DeliveryTipException catch (e) {
      if (mounted) showTopErrorToast(context, e.message);
    } catch (e) {
      if (mounted) {
        showTopErrorToast(context, 'Could not update tip. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.settings.suggestedTips;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How was your delivery?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Color(0xFFE6A800)),
              title: const Text('Rate Delivery'),
              trailing: const Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              onTap: () {
                Navigator.pop(context);
                showOrderRatingSheet(
                  context: context,
                  orderId: widget.order.id,
                  title: 'Rate delivery partner',
                  firestoreField: 'rider_rating',
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.favorite_rounded, color: Color(0xFFE6A800)),
                const SizedBox(width: 8),
                Text(
                  'Add Extra Tip',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (widget.order.deliveryPartnerTip > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Current Delivery Partner Tip: ₹${widget.order.deliveryPartnerTip.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final amount in options)
                  ChoiceChip(
                    label: Text('₹$amount'),
                    selected: _selected == amount,
                    selectedColor: AppColor.primary.withValues(alpha: 0.25),
                    onSelected: _loading
                        ? null
                        : (_) => setState(() => _selected = amount),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
