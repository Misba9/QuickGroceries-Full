import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_dashboard_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_order_queue_manager.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_order_priority.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_order_status_theme.dart';
import 'package:quick_grocery_admin/view/orders/widgets/new_orders_dispatch_queue.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_details_drawer.dart';

/// Live order queue with search, filters, and scrollable cards.
class OpsLiveOrderQueue extends StatefulWidget {
  const OpsLiveOrderQueue({super.key});

  @override
  State<OpsLiveOrderQueue> createState() => _OpsLiveOrderQueueState();
}

class _OpsLiveOrderQueueState extends State<OpsLiveOrderQueue> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  OpsQueueStatus? _statusFilter;
  OpsOrderPriority? _priorityFilter;
  bool _highOnly = false;

  void _openOrder(OrderModel order) {
    showOrderDetailsDrawer(context, order);
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<OpsDashboardService>();
    final queue = OpsOrderQueueManager.filterQueue(
      queue: ops.liveOrders,
      search: _search.text,
      statusFilter: _statusFilter,
      priorityFilter: _priorityFilter,
      highPriorityOnly: _highOnly,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Live order queue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                '${queue.length} active',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Newest first · updates in real time',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          _toolbar(),
          const SizedBox(height: 12),
          if (ops.isLoadingOrders)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (ops.ordersError != null)
            Column(
              children: [
                _emptyMessage('Could not load orders', ops.ordersError!),
                TextButton.icon(
                  onPressed: ops.retryOrdersStream,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            )
          else if (queue.isEmpty)
            _emptyMessage(
              'No active orders',
              _search.text.isNotEmpty || _statusFilter != null || _highOnly
                  ? 'Try clearing filters'
                  : 'New orders will appear here instantly',
            )
          else
            SizedBox(
              height: 420,
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: ListView.separated(
                  controller: _scroll,
                  itemCount: queue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final live = queue[i];
                    final order = OrderModel.fromFirestore(live.raw, live.id);
                    return LiveOrderQueueCard(
                      order: order,
                      onView: _openOrder,
                      total: live.total,
                      paymentLabel: live.paymentLabel,
                      riderLabel: live.riderName,
                      etaLabel: live.etaLabel,
                      orderTimeLabel: _placedLabel(live.elapsedLabel),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 40,
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search orders…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        _filterChip(
          label: 'High priority',
          selected: _highOnly,
          onSelected: (v) => setState(() {
            _highOnly = v;
            if (v) _priorityFilter = null;
          }),
        ),
        PopupMenuButton<OpsQueueStatus?>(
          tooltip: 'Status',
          onSelected: (v) => setState(() => _statusFilter = v),
          itemBuilder: (context) => [
            const PopupMenuItem(value: null, child: Text('All statuses')),
            ...OpsQueueStatus.values.map(
              (s) => PopupMenuItem(
                value: s,
                child: Text(OpsOrderStatusTheme.label(s)),
              ),
            ),
          ],
          child: _menuButton(
            _statusFilter == null
                ? 'Status'
                : OpsOrderStatusTheme.label(_statusFilter!),
          ),
        ),
        PopupMenuButton<OpsOrderPriority?>(
          tooltip: 'Priority',
          onSelected: (v) => setState(() {
            _priorityFilter = v;
            if (v != null) _highOnly = false;
          }),
          itemBuilder: (context) => [
            const PopupMenuItem(value: null, child: Text('All priorities')),
            ...OpsOrderPriority.values.map(
              (p) => PopupMenuItem(
                value: p,
                child: Text(OpsOrderPriorityRules.label(p)),
              ),
            ),
          ],
          child: _menuButton(
            _priorityFilter == null
                ? 'Priority'
                : OpsOrderPriorityRules.label(_priorityFilter!),
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() {
            _search.clear();
            _statusFilter = null;
            _priorityFilter = null;
            _highOnly = false;
          }),
          icon: const Icon(Icons.filter_alt_off, size: 18),
          label: const Text('Clear'),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _menuButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }

  Widget _emptyMessage(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _placedLabel(String elapsed) {
    final trimmed = elapsed.trim();
    if (trimmed.isEmpty || trimmed == '—') return 'Placed —';
    if (trimmed.toLowerCase() == 'just now') return 'Placed just now';
    return 'Placed $trimmed ago';
  }
}
