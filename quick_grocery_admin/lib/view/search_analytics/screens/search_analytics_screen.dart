import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/core/widgets/admin_text_selection.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/search_analytics/models/search_log_model.dart';
import 'package:quick_grocery_admin/view/search_analytics/services/search_analytics_service.dart';

class SearchAnalyticsScreen extends StatefulWidget {
  const SearchAnalyticsScreen({super.key});

  @override
  State<SearchAnalyticsScreen> createState() => _SearchAnalyticsScreenState();
}

class _SearchAnalyticsScreenState extends State<SearchAnalyticsScreen> {
  final _service = SearchAnalyticsService();
  final _filterCtrl = TextEditingController();
  bool _zeroOnly = false;
  String _platform = 'all';
  String _source = 'all';
  bool _useFallback = false;
  bool _enrichQueued = false;
  Map<String, String> _customerLabels = {};
  final Set<String> _enrichAttempted = {};

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  void _queueEnrich(List<SearchLogModel> logs) {
    if (_enrichQueued) return;
    final missing = logs
        .where(
          (e) =>
              e.userId.isNotEmpty &&
              e.userName.trim().isEmpty &&
              !_customerLabels.containsKey(e.userId) &&
              !_enrichAttempted.contains(e.userId),
        )
        .map((e) => e.userId)
        .toSet();
    if (missing.isEmpty) return;
    _enrichQueued = true;
    _enrichAttempted.addAll(missing);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final labels = await _service.resolveCustomerLabels(missing);
        if (!mounted || labels.isEmpty) return;
        setState(() => _customerLabels = {..._customerLabels, ...labels});
      } finally {
        _enrichQueued = false;
      }
    });
  }

  List<SearchLogModel> _applyFilters(List<SearchLogModel> logs) {
    final q = _filterCtrl.text.trim().toLowerCase();
    return logs.where((e) {
      if (_zeroOnly && e.hasResults) return false;
      if (_platform != 'all' &&
          !_platformLabel(e.platform).toLowerCase().contains(_platform)) {
        return false;
      }
      if (_source != 'all' && e.source.toLowerCase() != _source) return false;
      if (q.isEmpty) return true;
      final hay =
          '${e.query} ${e.displayUser} ${e.userPhone} ${e.userEmail} ${e.userId} ${e.topResultNames.join(' ')}'
              .toLowerCase();
      return hay.contains(q);
    }).toList(growable: false);
  }

  static String _platformLabel(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return '—';
    if (s.contains('android')) return 'Android';
    if (s == 'ios' || s.contains('iphone') || s.contains('ipad')) return 'iOS';
    if (s.contains('web')) return 'Web';
    return raw;
  }

  static String _sourceLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'typed':
        return 'Submit';
      case 'live':
        return 'Typing';
      case 'voice':
        return 'Voice';
      case 'recent_chip':
        return 'Recent';
      default:
        return raw.isEmpty ? '—' : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _useFallback
        ? _service.watchLogsFallback()
        : _service.watchLogs();

    return LayoutBuilder(
      builder: (context, c) {
        final pad = adminResponsivePadding(c.maxWidth);
        return ColoredBox(
          color: const Color(0xFFFFFAF0),
          child: StreamBuilder<List<SearchLogModel>>(
            stream: stream,
            builder: (context, snap) {
              if (snap.hasError && !_useFallback) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _useFallback = true);
                });
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final all = snap.data!;
              _queueEnrich(all);

              final filtered = _applyFilters(all);
              final kpis = _service.kpis(filtered);
              final top = _service.aggregateQueries(filtered);
              final zeroTop = top.where((a) => a.zeroResultCount > 0).toList()
                ..sort((a, b) => b.zeroResultCount.compareTo(a.zeroResultCount));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, pad, pad, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Search Analytics',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Live view of what customers search in the app — queries, users, platforms, and result outcomes.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        AppSpacing.h12,
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _MetricCard('Searches', '${kpis['total']}'),
                            _MetricCard(
                              'Unique queries',
                              '${kpis['uniqueQueries']}',
                            ),
                            _MetricCard(
                              'Unique users',
                              '${kpis['uniqueUsers']}',
                            ),
                            _MetricCard(
                              'Zero-result rate',
                              '${(kpis['zeroRate'] as double).toStringAsFixed(0)}%',
                            ),
                            _MetricCard(
                              'Zero results',
                              '${kpis['zeroResults']}',
                            ),
                          ],
                        ),
                        AppSpacing.h12,
                        _FilterBar(
                          controller: _filterCtrl,
                          zeroOnly: _zeroOnly,
                          platform: _platform,
                          source: _source,
                          onChanged: () => setState(() {}),
                          onZeroOnly: (v) => setState(() => _zeroOnly = v),
                          onPlatform: (v) =>
                              setState(() => _platform = v ?? 'all'),
                          onSource: (v) => setState(() => _source = v ?? 'all'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
                      children: [
                        _SectionCard(
                          title: 'Top searched queries',
                          child: _TopQueriesTable(rows: top.take(25).toList()),
                        ),
                        AppSpacing.h12,
                        _SectionCard(
                          title: 'Zero-result queries (catalog gaps)',
                          child: zeroTop.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('No zero-result searches in this view.'),
                                )
                              : _TopQueriesTable(
                                  rows: zeroTop.take(20).toList(),
                                  showZeroFocus: true,
                                ),
                        ),
                        AppSpacing.h12,
                        _SectionCard(
                          title: 'All search activity (${filtered.length})',
                          child: _DetailedLogsTable(
                            logs: filtered,
                            customerLabels: _customerLabels,
                            platformLabel: _platformLabel,
                            sourceLabel: _sourceLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.controller,
    required this.zeroOnly,
    required this.platform,
    required this.source,
    required this.onChanged,
    required this.onZeroOnly,
    required this.onPlatform,
    required this.onSource,
  });

  final TextEditingController controller;
  final bool zeroOnly;
  final String platform;
  final String source;
  final VoidCallback onChanged;
  final ValueChanged<bool> onZeroOnly;
  final ValueChanged<String?> onPlatform;
  final ValueChanged<String?> onSource;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Filter query, user, phone…',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(
          width: 150,
          child: InputDecorator(
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Platform',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: platform,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'android', child: Text('Android')),
                  DropdownMenuItem(value: 'ios', child: Text('iOS')),
                  DropdownMenuItem(value: 'web', child: Text('Web')),
                ],
                onChanged: onPlatform,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 150,
          child: InputDecorator(
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Source',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: source,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'typed', child: Text('Submit')),
                  DropdownMenuItem(value: 'live', child: Text('Typing')),
                  DropdownMenuItem(value: 'voice', child: Text('Voice')),
                  DropdownMenuItem(value: 'recent_chip', child: Text('Recent')),
                ],
                onChanged: onSource,
              ),
            ),
          ),
        ),
        FilterChip(
          label: const Text('Zero results only'),
          selected: zeroOnly,
          onSelected: onZeroOnly,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColor.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

class _TopQueriesTable extends StatelessWidget {
  const _TopQueriesTable({
    required this.rows,
    this.showZeroFocus = false,
  });

  final List<SearchQueryAggregate> rows;
  final bool showZeroFocus;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('No search data yet. Searches appear after users search in the app.'),
      );
    }
    final fmt = DateFormat('dd MMM, HH:mm');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 48,
        columns: const [
          DataColumn(label: Text('Query')),
          DataColumn(label: Text('Count'), numeric: true),
          DataColumn(label: Text('Users'), numeric: true),
          DataColumn(label: Text('Zero results'), numeric: true),
          DataColumn(label: Text('Zero %'), numeric: true),
          DataColumn(label: Text('Last searched')),
          DataColumn(label: Text('Platform')),
        ],
        rows: rows.map((r) {
          return DataRow(
            cells: [
              DataCell(AdminSelectableText(r.query, maxLines: 1)),
              DataCell(Text('${r.count}')),
              DataCell(Text('${r.userIds.length}')),
              DataCell(
                Text(
                  '${r.zeroResultCount}',
                  style: TextStyle(
                    color: r.zeroResultCount > 0
                        ? Colors.red.shade700
                        : null,
                    fontWeight:
                        showZeroFocus ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
              DataCell(Text('${r.zeroResultRate.toStringAsFixed(0)}%')),
              DataCell(
                Text(
                  r.lastSearchedAt == null
                      ? '—'
                      : fmt.format(r.lastSearchedAt!.toLocal()),
                ),
              ),
              DataCell(
                Text(
                  _SearchAnalyticsScreenState._platformLabel(r.lastPlatform),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DetailedLogsTable extends StatelessWidget {
  const _DetailedLogsTable({
    required this.logs,
    required this.customerLabels,
    required this.platformLabel,
    required this.sourceLabel,
  });

  final List<SearchLogModel> logs;
  final Map<String, String> customerLabels;
  final String Function(String) platformLabel;
  final String Function(String) sourceLabel;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('No matching searches.'),
      );
    }
    final fmt = DateFormat('dd MMM yyyy, HH:mm:ss');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 64,
        columns: const [
          DataColumn(label: Text('When')),
          DataColumn(label: Text('Query')),
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Platform')),
          DataColumn(label: Text('App')),
          DataColumn(label: Text('Source')),
          DataColumn(label: Text('Results'), numeric: true),
          DataColumn(label: Text('Top matches')),
        ],
        rows: logs.take(300).map((e) {
          final label = e.userName.trim().isNotEmpty
              ? e.userName
              : (customerLabels[e.userId] ?? e.displayUser);
          final tops = e.topResultNames.isNotEmpty
              ? e.topResultNames.take(3).join(', ')
              : (e.hasResults ? '—' : 'No matches');
          return DataRow(
            cells: [
              DataCell(
                Text(
                  e.createdAt == null
                      ? '—'
                      : fmt.format(e.createdAt!.toLocal()),
                ),
              ),
              DataCell(AdminSelectableText(e.query, maxLines: 2)),
              DataCell(
                AdminSelectableText(
                  label,
                  maxLines: 1,
                ),
              ),
              DataCell(
                AdminSelectableText(
                  e.userPhone.isEmpty ? '—' : e.userPhone,
                  maxLines: 1,
                ),
              ),
              DataCell(Text(platformLabel(e.platform))),
              DataCell(Text(e.appVersion.isEmpty ? '—' : e.appVersion)),
              DataCell(Text(sourceLabel(e.source))),
              DataCell(
                Text(
                  '${e.resultCount}',
                  style: TextStyle(
                    color: e.hasResults ? null : Colors.red.shade700,
                    fontWeight: e.hasResults ? FontWeight.normal : FontWeight.w700,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 220,
                  child: AdminSelectableText(tops, maxLines: 2),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
