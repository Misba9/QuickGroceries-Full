import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/theme/app_text_styles.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';

class OrdersOverviewHeader extends StatelessWidget {
  const OrdersOverviewHeader({
    super.key,
    this.onRefresh,
    this.lastRefreshed,
  });

  final VoidCallback? onRefresh;
  final DateTime? lastRefreshed;

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<OrderService>();
    final pending = svc.analytics.pendingOrders;
    final delayed = svc.analytics.delayedOrdersCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orders Overview', style: AppTextStyles.heading),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time operations command center',
                    style: AppTextStyles.dashboardSubtitle,
                  ),
                ],
              ),
            ),
            if (onRefresh != null)
              IconButton.filledTonal(
                tooltip: 'Refresh data',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _LiveTicker(
          pending: pending,
          delayed: delayed,
          unassigned: svc.analytics.unassignedRiderCount,
          isLoading: svc.isLoading,
          lastRefreshed: lastRefreshed,
        ),
      ],
    );
  }
}

class _LiveTicker extends StatelessWidget {
  const _LiveTicker({
    required this.pending,
    required this.delayed,
    required this.unassigned,
    required this.isLoading,
    this.lastRefreshed,
  });

  final int pending;
  final int delayed;
  final int unassigned;
  final bool isLoading;
  final DateTime? lastRefreshed;

  @override
  Widget build(BuildContext context) {
    final timeLabel = lastRefreshed != null
        ? 'Updated ${_formatTime(lastRefreshed!)}'
        : 'Live';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isLoading ? Colors.grey : const Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$pending active · $unassigned need rider · $delayed delayed · $timeLabel',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (delayed > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Alert',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.red.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
