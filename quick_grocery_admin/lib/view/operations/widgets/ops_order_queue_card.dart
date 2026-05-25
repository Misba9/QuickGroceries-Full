import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_dashboard_models.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_firestore_helpers.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_order_priority.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_order_status_theme.dart';
import 'package:quick_grocery_admin/view/operations/widgets/ops_order_timeline_strip.dart';

class OpsOrderQueueCard extends StatefulWidget {
  const OpsOrderQueueCard({super.key, required this.order});

  final OpsLiveOrder order;

  @override
  State<OpsOrderQueueCard> createState() => _OpsOrderQueueCardState();
}

class _OpsOrderQueueCardState extends State<OpsOrderQueueCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final theme = OpsOrderStatusTheme.colors(o.status);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final priorityColor = switch (o.priority) {
      OpsOrderPriority.high => const Color(0xFFB91C1C),
      OpsOrderPriority.medium => const Color(0xFFEA580C),
      OpsOrderPriority.low => const Color(0xFF64748B),
    };

    Widget card = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: o.isNew
                ? const Color(0xFF2563EB)
                : (_hovered ? theme.border : Colors.grey.shade200),
            width: o.isNew ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
              blurRadius: _hovered ? 16 : 8,
              offset: Offset(0, _hovered ? 6 : 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.bg,
                  child: Text(
                    OpsFirestoreHelpers.initials(o.customerName),
                    style: TextStyle(
                      color: theme.fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${OpsFirestoreHelpers.shortOrderId(o.id)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _badge(o.statusLabel, theme.bg, theme.fg, theme.border),
                          if (o.isNew) ...[
                            const SizedBox(width: 6),
                            _pulseBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        o.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(o.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _badge(
                      OpsOrderPriorityRules.label(o.priority),
                      priorityColor.withValues(alpha: 0.12),
                      priorityColor,
                      priorityColor.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.storefront_outlined, o.vendorName),
            const SizedBox(height: 4),
            _infoRow(
              Icons.delivery_dining_outlined,
              o.riderName,
              highlight: o.riderName == 'Unassigned',
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _infoRow(Icons.payments_outlined, o.paymentLabel),
                ),
                Text(
                  o.elapsedLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    o.etaLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OpsOrderTimelineStrip(timeline: o.timeline),
          ],
        ),
      ),
    );

    if (o.isNew) {
      card = card
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 2.seconds,
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
          );
    }

    return card;
  }

  Widget _infoRow(IconData icon, String text, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? const Color(0xFFB45309) : Colors.grey.shade800,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color bg, Color fg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _pulseBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.08, 1.08),
          duration: 900.ms,
        );
  }
}
