import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/layout/admin_page_wrapper.dart';
import 'package:quick_grocery_admin/view/push_notifications/models/notification_models.dart';
import 'package:quick_grocery_admin/view/push_notifications/presentation/widgets/push_access_gate.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/notification_admin_service.dart';

enum _HistoryRange { today, week, month, all }

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  _HistoryRange _range = _HistoryRange.week;
  final ScrollController _tableScrollController = ScrollController();

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }

  bool _inRange(DateTime? t) {
    if (t == null) return false;
    final now = DateTime.now();
    switch (_range) {
      case _HistoryRange.today:
        return t.year == now.year && t.month == now.month && t.day == now.day;
      case _HistoryRange.week:
        return now.difference(t).inDays <= 7;
      case _HistoryRange.month:
        return now.difference(t).inDays <= 30;
      case _HistoryRange.all:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_jm();
    return PushAccessGate(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Delivery status, opens (when users tap), and CTR sample from recent logs.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 720;
                if (narrow) {
                  return SegmentedButton<_HistoryRange>(
                    segments: const [
                      ButtonSegment(
                        value: _HistoryRange.today,
                        label: Text('Today'),
                      ),
                      ButtonSegment(
                        value: _HistoryRange.week,
                        label: Text('Week'),
                      ),
                      ButtonSegment(
                        value: _HistoryRange.month,
                        label: Text('Month'),
                      ),
                      ButtonSegment(
                        value: _HistoryRange.all,
                        label: Text('All'),
                      ),
                    ],
                    selected: {_range},
                    onSelectionChanged: (s) => setState(() => _range = s.first),
                  );
                }
                return Row(
                  children: [
                    const Spacer(),
                    SegmentedButton<_HistoryRange>(
                      segments: const [
                        ButtonSegment(
                          value: _HistoryRange.today,
                          label: Text('Today'),
                        ),
                        ButtonSegment(
                          value: _HistoryRange.week,
                          label: Text('Week'),
                        ),
                        ButtonSegment(
                          value: _HistoryRange.month,
                          label: Text('Month'),
                        ),
                        ButtonSegment(
                          value: _HistoryRange.all,
                          label: Text('All'),
                        ),
                      ],
                      selected: {_range},
                      onSelectionChanged: (s) =>
                          setState(() => _range = s.first),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<NotificationLog>>(
                stream: context
                    .read<NotificationAdminService>()
                    .watchLogs(limit: 500),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final filtered =
                      snap.data!.where((e) => _inRange(e.createdAt)).toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: AdminSectionCard(
                        child: Text(
                          'No notifications in this range.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }
                  final sent =
                      filtered.where((e) => e.status == 'sent').length;
                  final failed =
                      filtered.where((e) => e.status == 'failed').length;
                  final opens = filtered.fold<int>(
                    0,
                    (a, e) => a + (e.openedCount ?? 0),
                  );
                  final ctr = sent == 0 ? 0.0 : (opens / sent * 100);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _miniStat('Sent', '$sent'),
                          _miniStat('Failed', '$failed'),
                          _miniStat('Opens (sum)', '$opens'),
                          _miniStat(
                            'CTR (approx)',
                            '${ctr.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: AdminSectionCard(
                          padding: const EdgeInsets.all(12),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              return Scrollbar(
                                controller: _tableScrollController,
                                thumbVisibility: c.maxWidth > 600,
                                child: SingleChildScrollView(
                                  controller: _tableScrollController,
                                  scrollDirection: Axis.horizontal,
                                  primary: false,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: math.max(c.maxWidth, 720),
                                    ),
                                    child: DataTable(
                                      headingRowColor:
                                          WidgetStateProperty.all(
                                        Colors.grey.shade100,
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('Title')),
                                        DataColumn(
                                          label: Text('Topic / user'),
                                        ),
                                        DataColumn(label: Text('Message')),
                                        DataColumn(label: Text('Status')),
                                        DataColumn(label: Text('Opens')),
                                        DataColumn(label: Text('When')),
                                      ],
                                      rows: filtered.map((e) {
                                        final ok = e.status == 'sent';
                                        final who =
                                            (e.topic ?? '').isNotEmpty
                                                ? e.topic!
                                                : (e.userId.isEmpty
                                                    ? '—'
                                                    : e.userId);
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(
                                              e.title ?? '—',
                                              overflow: TextOverflow.ellipsis,
                                            )),
                                            DataCell(Text(
                                              who,
                                              overflow: TextOverflow.ellipsis,
                                            )),
                                            DataCell(
                                              Text(
                                                e.message,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: ok
                                                      ? Colors.green.shade50
                                                      : Colors.red.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    8,
                                                  ),
                                                ),
                                                child: Text(
                                                  e.status,
                                                  style: TextStyle(
                                                    color: ok
                                                        ? Colors
                                                            .green.shade800
                                                        : Colors
                                                            .red.shade800,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(
                                              '${e.openedCount ?? 0}',
                                            )),
                                            DataCell(Text(
                                              e.createdAt != null
                                                  ? df.format(
                                                      e.createdAt!.toLocal(),
                                                    )
                                                  : '—',
                                            )),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
