import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/delivery_tips/models/delivery_tips_settings_model.dart';
import 'package:quick_grocery_admin/view/delivery_tips/services/delivery_tips_admin_service.dart';
import 'package:quick_grocery_admin/view/delivery_tips/services/delivery_tips_export_service.dart';
import 'package:quick_grocery_admin/view/delivery_tips/widgets/delivery_tips_settings_panel.dart';

class DeliveryTipsManagementScreen extends StatefulWidget {
  const DeliveryTipsManagementScreen({super.key});

  @override
  State<DeliveryTipsManagementScreen> createState() =>
      _DeliveryTipsManagementScreenState();
}

class _DeliveryTipsManagementScreenState
    extends State<DeliveryTipsManagementScreen> {
  final _service = DeliveryTipsAdminService();
  DeliveryTipsDashboardStats? _stats;
  List<DeliveryTipReportRow> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final stats = await _service.aggregateStats();
      final rows = await _service.fetchReportRows();
      if (mounted) {
        setState(() {
          _stats = stats;
          _rows = rows;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DeliveryTipsSettingsModel>(
      stream: _service.watchSettings(),
      builder: (context, settingsSnap) {
        final settings =
            settingsSnap.data ?? DeliveryTipsSettingsModel.defaults();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: Color(0xFFE6A800)),
                  AppSpacing.w10,
                  const Expanded(
                    child: Text(
                      'Delivery Tips Management',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              AppSpacing.h15,
              DeliveryTipsSettingsPanel(
                initial: settings,
                onSave: _service.saveSettings,
              ),
              AppSpacing.h20,
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_stats != null) ...[
                _StatsGrid(stats: _stats!),
                AppSpacing.h20,
                _TopRidersCard(riders: _stats!.topRiders),
                AppSpacing.h20,
                _ReportsSection(
                  rows: _rows,
                  onExportCsv: () =>
                      DeliveryTipsExportService.exportCsv(context, _rows),
                  onExportExcel: () =>
                      DeliveryTipsExportService.exportExcel(context, _rows),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final DeliveryTipsDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatTile(
          label: 'Total Tips Collected',
          value: '₹${stats.totalTipsCollected.toStringAsFixed(0)}',
          icon: Icons.savings_outlined,
        ),
        _StatTile(
          label: 'Orders with tips',
          value: '${stats.orderCount}',
          icon: Icons.receipt_long_outlined,
        ),
        _StatTile(
          label: 'Top partner tips',
          value: stats.topRiders.isEmpty
              ? '—'
              : '₹${(stats.topRiders.first['totalTips'] as num?)?.toStringAsFixed(0) ?? '0'}',
          icon: Icons.emoji_events_outlined,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColor.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopRidersCard extends StatelessWidget {
  const _TopRidersCard({required this.riders});
  final List<Map<String, dynamic>> riders;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Tipped Delivery Partners',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (riders.isEmpty)
              const Text('No tip data yet')
            else
              ...riders.take(10).map(
                    (r) => ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        child: Icon(Icons.delivery_dining, size: 18),
                      ),
                      title: Text('${r['riderName'] ?? r['riderId']}'),
                      trailing: Text(
                        '₹${(r['totalTips'] as num?)?.toStringAsFixed(0) ?? '0'}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ReportsSection extends StatelessWidget {
  const _ReportsSection({
    required this.rows,
    required this.onExportCsv,
    required this.onExportExcel,
  });

  final List<DeliveryTipReportRow> rows;
  final VoidCallback onExportCsv;
  final VoidCallback onExportExcel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tip Reports',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onExportCsv,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('CSV'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onExportExcel,
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
                  label: const Text('Excel'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Order ID')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Delivery Partner')),
                  DataColumn(label: Text('Tip')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Status')),
                ],
                rows: rows
                    .map(
                      (r) => DataRow(
                        cells: [
                          DataCell(Text(r.orderId.length > 8
                              ? r.orderId.substring(r.orderId.length - 8)
                              : r.orderId)),
                          DataCell(Text(r.customerName)),
                          DataCell(Text(
                            r.deliveryPartnerName.isNotEmpty
                                ? r.deliveryPartnerName
                                : r.deliveryPartnerId,
                          )),
                          DataCell(Text('₹${r.tipAmount.toStringAsFixed(0)}')),
                          DataCell(Text(
                            r.createdAt == null
                                ? '—'
                                : DateFormat('d MMM yyyy').format(r.createdAt!),
                          )),
                          DataCell(Text(r.tipStatus)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
