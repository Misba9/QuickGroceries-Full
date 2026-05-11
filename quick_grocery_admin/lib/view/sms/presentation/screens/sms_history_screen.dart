import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/sms/models/sms_models.dart';
import 'package:quick_grocery_admin/view/sms/presentation/widgets/sms_access_gate.dart';
import 'package:quick_grocery_admin/view/sms/services/sms_admin_service.dart';

enum _SmsHistoryRange { today, week, month, all }

class SmsHistoryScreen extends StatefulWidget {
  const SmsHistoryScreen({super.key});

  @override
  State<SmsHistoryScreen> createState() => _SmsHistoryScreenState();
}

class _SmsHistoryScreenState extends State<SmsHistoryScreen> {
  _SmsHistoryRange _range = _SmsHistoryRange.week;

  bool _inRange(DateTime? t) {
    if (t == null) return false;
    final now = DateTime.now();
    switch (_range) {
      case _SmsHistoryRange.today:
        return t.year == now.year && t.month == now.month && t.day == now.day;
      case _SmsHistoryRange.week:
        return now.difference(t).inDays <= 7;
      case _SmsHistoryRange.month:
        return now.difference(t).inDays <= 30;
      case _SmsHistoryRange.all:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_jm();
    return SmsAccessGate(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'SMS History',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                SegmentedButton<_SmsHistoryRange>(
                  segments: const [
                    ButtonSegment(
                      value: _SmsHistoryRange.today,
                      label: Text('Today'),
                    ),
                    ButtonSegment(
                      value: _SmsHistoryRange.week,
                      label: Text('Week'),
                    ),
                    ButtonSegment(
                      value: _SmsHistoryRange.month,
                      label: Text('Month'),
                    ),
                    ButtonSegment(
                      value: _SmsHistoryRange.all,
                      label: Text('All'),
                    ),
                  ],
                  selected: {_range},
                  onSelectionChanged: (s) =>
                      setState(() => _range = s.first),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<SmsAdminService>(
                builder: (context, svc, _) {
                  return StreamBuilder<List<SmsLog>>(
                    stream: svc.watchLogs(limit: 500),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final filtered =
                          snap.data!.where((e) => _inRange(e.createdAt)).toList();
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No SMS in this range.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
                      }
                      return LayoutBuilder(
                        builder: (context, c) {
                          return Scrollbar(
                            thumbVisibility: c.maxWidth > 600,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: c.maxWidth.clamp(640, 1400),
                                ),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade100,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Recipient')),
                                    DataColumn(label: Text('Phone')),
                                    DataColumn(label: Text('Message')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Provider')),
                                    DataColumn(label: Text('When')),
                                  ],
                                  rows: filtered.map((e) {
                                    final ok = e.status == 'sent';
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(
                                          e.userId.isEmpty ? '—' : e.userId,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                        DataCell(Text(e.phone)),
                                        DataCell(
                                          SizedBox(
                                            width: 260,
                                            child: Text(
                                              e.message,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: ok
                                                  ? Colors.green.shade50
                                                  : Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              e.status,
                                              style: TextStyle(
                                                color: ok
                                                    ? Colors.green.shade800
                                                    : Colors.red.shade800,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(e.provider)),
                                        DataCell(Text(
                                          e.createdAt != null
                                              ? df.format(e.createdAt!.toLocal())
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
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Consumer<SmsAdminService>(
              builder: (context, svc, _) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: svc.busy
                        ? null
                        : () async {
                            try {
                              await svc.retryFailed(max: 25);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Retry job finished'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry failed (server)'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
