import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/core/layout/admin_page_wrapper.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_eta_utils.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_row_actions.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_status_badge.dart';

/// Urgent dispatch queue — unassigned / delayed orders with quick actions.
class PendingDispatchQueue extends StatelessWidget {
  const PendingDispatchQueue({
    super.key,
    required this.orders,
    required this.onView,
  });

  final List<OrderModel> orders;
  final OrderDrawerCallback onView;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Dispatch queue',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${orders.length} waiting',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No orders waiting for assignment',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final stripHeight = _dispatchQueueStripHeight(context);
                return SizedBox(
                  height: stripHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: orders.length.clamp(0, 12),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: LiveOrderQueueCard(
                          order: orders[i],
                          onView: onView,
                          width: _dispatchCardWidth(constraints.maxWidth),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Vertical space for one dispatch card (badges, slot, ETA row) — scales with text.
double _dispatchQueueStripHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
  return 224 * scale;
}

double _dispatchCardWidth(double parentMaxWidth) {
  if (parentMaxWidth <= 0 || !parentMaxWidth.isFinite) return 300;
  final w = (parentMaxWidth * 0.42).clamp(260.0, 340.0);
  return w;
}

class LiveOrderQueueCard extends StatefulWidget {
  const LiveOrderQueueCard({
    super.key,
    required this.order,
    this.onView,
    this.width,
    this.total,
    this.paymentLabel,
    this.riderLabel,
    this.orderTimeLabel,
    this.etaLabel,
  });

  final OrderModel order;
  final OrderDrawerCallback? onView;
  final double? width;
  final double? total;
  final String? paymentLabel;
  final String? riderLabel;
  final String? orderTimeLabel;
  final String? etaLabel;

  @override
  State<LiveOrderQueueCard> createState() => _LiveOrderQueueCardState();
}

class _LiveOrderQueueCardState extends State<LiveOrderQueueCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final total = widget.total ?? order.getTotalAmount();
    final paymentLabel =
        widget.paymentLabel ?? (order.isPaid ? 'Online' : 'COD');
    final paymentOnline = order.isPaid || _looksOnlinePayment(paymentLabel);
    final riderLabel =
        widget.riderLabel ??
        (order.deliveryBoyId.trim().isEmpty ? 'Unassigned' : 'Assigned');
    final assigned =
        order.deliveryBoyId.trim().isNotEmpty ||
        riderLabel.toLowerCase() != 'unassigned';
    final etaLabel = widget.etaLabel ?? OrderEtaUtils.etaLabel(order);
    final orderTime =
        widget.orderTimeLabel ?? 'Placed ${OrderEtaUtils.minutesSince(order)}';
    final late = OrderEtaUtils.lateLabel(order);
    final delayed =
        OrderEtaUtils.isDelayed(order) ||
        late.isNotEmpty ||
        etaLabel.toLowerCase().contains('late');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        clipBehavior: Clip.antiAlias,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        width: widget.width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: delayed ? const Color(0xFFFFF1F2) : const Color(0xFFFAFAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: delayed
                ? const Color(0xFFFECACA)
                : (_hovered
                      ? AppColor.primary.withValues(alpha: 0.28)
                      : const Color(0xFFE5E7EB)),
            width: delayed ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.03),
              blurRadius: _hovered ? 18 : 8,
              offset: Offset(0, _hovered ? 8 : 3),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${_shortId(order.id)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (delayed)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626),
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 28,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    OrderStatusBadge(order: order, compact: true),
                    const SizedBox(width: 6),
                    _pill(
                      paymentLabel,
                      paymentOnline
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      paymentOnline
                          ? Colors.green.shade800
                          : Colors.orange.shade900,
                    ),
                    const SizedBox(width: 6),
                    _pill(
                      assigned ? riderLabel : 'Unassigned',
                      assigned ? Colors.blue.shade50 : Colors.orange.shade50,
                      assigned ? Colors.blue.shade800 : Colors.orange.shade900,
                      icon: assigned
                          ? Icons.delivery_dining_rounded
                          : Icons.person_add_alt_1_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _metaLine(Icons.schedule_rounded, orderTime),
              if (order.deliverySlot != null) ...[
                const SizedBox(height: 3),
                _metaLine(
                  Icons.local_shipping_outlined,
                  order.deliverySlotLabel,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _etaChip(
                      late.isNotEmpty ? late : etaLabel,
                      isLate:
                          late.isNotEmpty ||
                          etaLabel.toLowerCase().contains('late'),
                    ),
                  ),
                  if (widget.onView != null) ...[
                    const SizedBox(width: 6),
                    OrderRowActions(order: order, onView: widget.onView!),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _shortId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(id.length - 8).toUpperCase();
  }

  static bool _looksOnlinePayment(String label) {
    final s = label.toLowerCase();
    return s.contains('paid') ||
        s.contains('online') ||
        s.contains('upi') ||
        s.contains('card') ||
        s.contains('wallet');
  }

  Widget _metaLine(IconData icon, String text) {
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
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _etaChip(String label, {required bool isLate}) {
    final bg = isLate ? const Color(0xFFFEE2E2) : Colors.white;
    final fg = isLate ? const Color(0xFFB91C1C) : const Color(0xFF334155);
    final border = isLate ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB);
    final text = label.startsWith('ETA') || label.startsWith('Late')
        ? label
        : 'ETA $label';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
