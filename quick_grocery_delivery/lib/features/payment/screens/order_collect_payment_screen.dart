import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:quick_grocery_delivery/models/payment_collection_settings.dart';
import 'package:url_launcher/url_launcher.dart';

/// COD / UPI collection — reads `app_settings/payment`, dynamic QR, confirm flows.
class OrderCollectPaymentScreen extends StatefulWidget {
  const OrderCollectPaymentScreen({super.key, required this.order});

  final OrderModel order;

  @override
  State<OrderCollectPaymentScreen> createState() =>
      _OrderCollectPaymentScreenState();
}

class _OrderCollectPaymentScreenState extends State<OrderCollectPaymentScreen> {
  bool _submitting = false;

  Future<void> _recordUpi() async {
    final amount = widget.order.payment.orderTotal;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm payment received'),
        content: Text(
          'Received ₹${amount.toStringAsFixed(0)}?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _submit('upi');
  }

  Future<void> _confirmCash() async {
    final amount = widget.order.payment.orderTotal;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cash collected?'),
        content: Text(
          'Collected ₹${amount.toStringAsFixed(0)}?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (ok == true) await _submit('cash');
  }

  Future<void> _submit(String method) async {
    setState(() => _submitting = true);
    try {
      await context.read<OrderService>().recordCodPayment(
            orderId: widget.order.id,
            collectionMethod: method,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final p = order.payment;

    if (p.isOnlinePaid || p.isPaymentCollected) {
      return _OnlinePaidScaffold(order: order, collected: p.isPaymentCollected);
    }

    final shortId =
        order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase();
    final amount = p.orderTotal;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Collect Payment'),
        backgroundColor: GlobalVariables.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<PaymentCollectionSettings>(
        stream: PaymentCollectionSettings.stream(),
        builder: (context, snap) {
          final settings = snap.data ?? PaymentCollectionSettings.empty;
          final upiPayload = settings.canShowUpiQr
              ? settings.buildUpiPayload(amount: amount, orderId: order.id)
              : '';
          final canLaunchUpi = upiPayload.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusBadge(
                label: 'COD TO COLLECT',
                color: Colors.orange.shade800,
                bg: Colors.orange.shade50,
              ),
              const SizedBox(height: 16),
              _OrderSummaryCard(
                orderNumber: shortId,
                customerName: order.customerName,
                amount: amount,
              ),
              if (settings.canShowUpiQr && upiPayload.isNotEmpty) ...[
                const SizedBox(height: 20),
                _QrCard(payload: upiPayload, amount: amount),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Ask Pay Online (Open UPI)',
                  icon: Icons.open_in_new_rounded,
                  outlined: true,
                  onTap: !canLaunchUpi || _submitting
                      ? null
                      : () => _launchUpi(upiPayload),
                ),
                const SizedBox(height: 12),
                Text(
                  'Verify customer paid via UPI, then confirm below.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  label: 'Verify Payment',
                  icon: Icons.verified_user_outlined,
                  outlined: true,
                  onTap: _submitting
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ask the customer to complete UPI payment, then confirm.',
                              ),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  label: 'Confirm Payment Received',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                  loading: _submitting,
                  onTap: _submitting ? null : _recordUpi,
                ),
              ],
              if (settings.enableCodCollection) ...[
                const SizedBox(height: 20),
                if (settings.canShowUpiQr)
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Cash Collected',
                  icon: Icons.payments_rounded,
                  outlined: true,
                  loading: _submitting,
                  onTap: _submitting ? null : _confirmCash,
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _launchUpi(String payload) async {
    try {
      final uri = Uri.parse(payload);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open UPI app.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid UPI payment link.')),
      );
    }
  }
}

class _OnlinePaidScaffold extends StatelessWidget {
  const _OnlinePaidScaffold({
    required this.order,
    required this.collected,
  });

  final OrderModel order;
  final bool collected;

  @override
  Widget build(BuildContext context) {
    final p = order.payment;
    final title = collected ? 'PAID' : 'ONLINE PAID ✅';
    final subtitle = collected
        ? '₹${p.displayPaidAmount.toStringAsFixed(0)} collected'
        : '₹${p.displayPaidAmount.toStringAsFixed(0)} — Razorpay';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: GlobalVariables.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade300, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 64, color: Colors.green.shade700),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to delivery'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bg,
  });

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w900,
          fontSize: 15,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.orderNumber,
    required this.customerName,
    required this.amount,
  });

  final String orderNumber;
  final String customerName;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _row('Order Number', '#$orderNumber'),
          const SizedBox(height: 10),
          _row('Customer Name', customerName),
          const Divider(height: 28),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              fontSize: 40,
              color: GlobalVariables.primary,
              height: 1,
            ),
          ),
          Text(
            'Amount to collect',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.payload, required this.amount});

  final String payload;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Scan to pay',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: payload,
            version: QrVersions.auto,
            size: 260,
            backgroundColor: Colors.white,
            gapless: true,
          ),
          const SizedBox(height: 12),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.outlined = false,
    this.color,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool outlined;
  final Color? color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label, style: const TextStyle(fontWeight: FontWeight.w700));

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: child,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: child,
        style: FilledButton.styleFrom(
          backgroundColor: color ?? GlobalVariables.primary,
        ),
      ),
    );
  }
}
