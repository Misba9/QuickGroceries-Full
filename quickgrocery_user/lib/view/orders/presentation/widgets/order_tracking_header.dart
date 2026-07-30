import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

import '../../domain/order_models.dart';
import 'eta_pill.dart';

/// Blinkit/Zepto-style order summary header for the tracking screen.
class OrderTrackingHeader extends StatelessWidget {
  const OrderTrackingHeader({
    super.key,
    required this.order,
    required this.eta,
    this.showSuccess = false,
  });

  final LiveOrder order;
  final Duration eta;
  final bool showSuccess;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppSurface.of(context).border),
        boxShadow: AppShadow.dim,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.shortOrderId}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppSurface.of(context).textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      showSuccess ? 'Delivered!' : order.status.displayName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: AppSurface.of(context).text,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              if (!showSuccess) EtaPill(eta: eta, status: order.status),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Placed on',
            value: order.createdAt.millisecondsSinceEpoch == 0
                ? '—'
                : dateFmt.format(order.createdAt.toLocal()),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.payments_outlined,
            label: 'Payment',
            value: order.paymentMethodLabel,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.receipt_long_outlined,
            label: 'Order total',
            value: '₹${order.total.toStringAsFixed(0)}',
            valueStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              color: AppColor.primary,
            ),
          ),
          if (order.slotLabel != null && order.slotLabel!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Delivery slot',
              value: order.slotLabel!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppSurface.of(context).textMuted),
        SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppSurface.of(context).textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: valueStyle ??
                GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppSurface.of(context).text,
                ),
          ),
        ),
      ],
    );
  }
}
