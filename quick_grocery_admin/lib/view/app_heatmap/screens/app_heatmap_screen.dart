import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/app_heatmap/models/app_heatmap_models.dart';
import 'package:quick_grocery_admin/view/app_heatmap/services/app_heatmap_service.dart';

class AppHeatmapScreen extends StatefulWidget {
  const AppHeatmapScreen({super.key});

  @override
  State<AppHeatmapScreen> createState() => _AppHeatmapScreenState();
}

class _AppHeatmapScreenState extends State<AppHeatmapScreen>
    with SingleTickerProviderStateMixin {
  final _service = AppHeatmapService();
  late final TabController _tabs;
  bool _viewsFallback = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  static Color heatColor(double intensity) {
    final t = intensity.clamp(0.0, 1.0);
    if (t <= 0) return const Color(0xFFE2E8F0);
    // Cool → warm heat ramp (teal → amber → red).
    if (t < 0.35) {
      return Color.lerp(
        const Color(0xFF99F6E4),
        const Color(0xFFFDE68A),
        t / 0.35,
      )!;
    }
    if (t < 0.7) {
      return Color.lerp(
        const Color(0xFFFDE68A),
        const Color(0xFFFDBA74),
        (t - 0.35) / 0.35,
      )!;
    }
    return Color.lerp(
      const Color(0xFFFDBA74),
      const Color(0xFFDC2626),
      (t - 0.7) / 0.3,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final pad = adminResponsivePadding(
      MediaQuery.sizeOf(context).width,
    );

    return ColoredBox(
      color: const Color(0xFFFFFAF0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'App Heatmap',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Where customers spend time in the user app — screens, busy hours, and order locations.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                AppSpacing.h12,
                TabBar(
                  controller: _tabs,
                  labelColor: AppColor.primary,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: AppColor.primary,
                  tabs: const [
                    Tab(text: 'Screens'),
                    Tab(text: 'Busy hours'),
                    Tab(text: 'Order map'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ScreensTab(
                  service: _service,
                  heatColor: heatColor,
                  pad: pad,
                  viewsFallback: _viewsFallback,
                  onViewsError: () {
                    if (!_viewsFallback && mounted) {
                      setState(() => _viewsFallback = true);
                    }
                  },
                ),
                _BusyHoursTab(
                  service: _service,
                  heatColor: heatColor,
                  pad: pad,
                  viewsFallback: _viewsFallback,
                  onViewsError: () {
                    if (!_viewsFallback && mounted) {
                      setState(() => _viewsFallback = true);
                    }
                  },
                ),
                _OrderMapTab(service: _service, heatColor: heatColor, pad: pad),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreensTab extends StatelessWidget {
  const _ScreensTab({
    required this.service,
    required this.heatColor,
    required this.pad,
    required this.viewsFallback,
    required this.onViewsError,
  });

  final AppHeatmapService service;
  final Color Function(double) heatColor;
  final double pad;
  final bool viewsFallback;
  final VoidCallback onViewsError;

  @override
  Widget build(BuildContext context) {
    final viewsStream = viewsFallback
        ? service.watchRecentViewsFallback()
        : service.watchRecentViews();

    return StreamBuilder<List<AppScreenStat>>(
      stream: service.watchStats(),
      builder: (context, statsSnap) {
        return StreamBuilder<List<AppScreenViewEvent>>(
          stream: viewsStream,
          builder: (context, viewsSnap) {
            if (viewsSnap.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onViewsError());
            }
            final stats = statsSnap.data ?? const <AppScreenStat>[];
            final events = viewsSnap.data ?? const <AppScreenViewEvent>[];
            final cells = service.buildScreenCells(stats: stats, events: events);
            final totalViews =
                cells.fold<int>(0, (sum, c) => sum + c.views);
            final uniqueUsers = events
                .where((e) => e.userId.isNotEmpty)
                .map((e) => e.userId)
                .toSet()
                .length;

            if (!statsSnap.hasData && !viewsSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: EdgeInsets.all(pad),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Metric('Total screen views', '$totalViews'),
                    _Metric('Tracked users', '$uniqueUsers'),
                    _Metric(
                      'Hottest screen',
                      cells.isEmpty
                          ? '—'
                          : cells.reduce((a, b) => a.views >= b.views ? a : b).label,
                    ),
                  ],
                ),
                AppSpacing.h16,
                LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 900;
                    final phone = _PhoneHeatmap(
                      cells: cells,
                      heatColor: heatColor,
                    );
                    final table = _ScreenTable(cells: cells, heatColor: heatColor);
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 320, child: phone),
                          const SizedBox(width: 16),
                          Expanded(child: table),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        phone,
                        AppSpacing.h12,
                        table,
                      ],
                    );
                  },
                ),
                AppSpacing.h12,
                _Legend(heatColor: heatColor),
                if (totalViews == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'No screen activity yet. Open the user app (after deploy) and navigate — views appear here live.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BusyHoursTab extends StatelessWidget {
  const _BusyHoursTab({
    required this.service,
    required this.heatColor,
    required this.pad,
    required this.viewsFallback,
    required this.onViewsError,
  });

  final AppHeatmapService service;
  final Color Function(double) heatColor;
  final double pad;
  final bool viewsFallback;
  final VoidCallback onViewsError;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final stream = viewsFallback
        ? service.watchRecentViewsFallback()
        : service.watchRecentViews();

    return StreamBuilder<List<AppScreenViewEvent>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onViewsError());
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snap.data!;
        final matrix = service.buildTimeHeatmatrix(events);
        final counts = service.buildTimeCounts(events);
        final hourTotals = List<int>.filled(24, 0);
        for (var d = 0; d < 7; d++) {
          for (var h = 0; h < 24; h++) {
            hourTotals[h] += counts[d][h];
          }
        }
        var peakHour = 0;
        for (var h = 1; h < 24; h++) {
          if (hourTotals[h] > hourTotals[peakHour]) peakHour = h;
        }

        return ListView(
          padding: EdgeInsets.all(pad),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric('Events sampled', '${events.where((e) => e.event != 'dwell').length}'),
                _Metric(
                  'Peak hour',
                  '${peakHour.toString().padLeft(2, '0')}:00',
                ),
              ],
            ),
            AppSpacing.h16,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Week × hour activity',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 40),
                              for (var h = 0; h < 24; h++)
                                SizedBox(
                                  width: 22,
                                  child: Text(
                                    h % 3 == 0 ? '$h' : '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ),
                            ],
                          ),
                          for (var d = 0; d < 7; d++)
                            Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    _days[d],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                for (var h = 0; h < 24; h++)
                                  Tooltip(
                                    message:
                                        '${_days[d]} ${h.toString().padLeft(2, '0')}:00 — ${counts[d][h]} views',
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        color: heatColor(matrix[d][h]),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    AppSpacing.h12,
                    _Legend(heatColor: heatColor),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderMapTab extends StatefulWidget {
  const _OrderMapTab({
    required this.service,
    required this.heatColor,
    required this.pad,
  });

  final AppHeatmapService service;
  final Color Function(double) heatColor;
  final double pad;

  @override
  State<_OrderMapTab> createState() => _OrderMapTabState();
}

class _OrderMapTabState extends State<_OrderMapTab> {
  final _map = MapController();
  bool _fitted = false;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _fit(List<GeoHeatCell> cells) {
    if (_fitted || cells.isEmpty) return;
    _fitted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final points = cells.map((c) => LatLng(c.lat, c.lng)).toList();
      if (points.length == 1) {
        _map.move(points.first, 12);
        return;
      }
      _map.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<({double lat, double lng})>>(
      stream: widget.service.watchOrderPoints(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cells = widget.service.buildGeoCells(snap.data!);
        _fit(cells);

        return Padding(
          padding: EdgeInsets.all(widget.pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _Metric('Order points', '${snap.data!.length}'),
                  _Metric('Hot zones', '${cells.length}'),
                ],
              ),
              AppSpacing.h12,
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: cells.isEmpty
                      ? Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Text(
                            'No order coordinates yet. Orders with lat/lng appear as heat zones.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                      : FlutterMap(
                          mapController: _map,
                          options: MapOptions(
                            initialCenter: LatLng(cells.first.lat, cells.first.lng),
                            initialZoom: 11,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'quick_grocery_admin',
                            ),
                            CircleLayer(
                              circles: [
                                for (final c in cells)
                                  CircleMarker(
                                    point: LatLng(c.lat, c.lng),
                                    radius: 18 + (c.intensity * 42),
                                    color: widget
                                        .heatColor(c.intensity)
                                        .withValues(alpha: 0.45),
                                    borderColor: widget
                                        .heatColor(c.intensity)
                                        .withValues(alpha: 0.85),
                                    borderStrokeWidth: 1.5,
                                    useRadiusInMeter: false,
                                  ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                for (final c in cells.where((e) => e.count >= 2))
                                  Marker(
                                    point: LatLng(c.lat, c.lng),
                                    width: 36,
                                    height: 36,
                                    child: Center(
                                      child: Text(
                                        '${c.count}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
              AppSpacing.h8,
              _Legend(heatColor: widget.heatColor),
            ],
          ),
        );
      },
    );
  }
}

class _PhoneHeatmap extends StatelessWidget {
  const _PhoneHeatmap({required this.cells, required this.heatColor});

  final List<ScreenHeatCell> cells;
  final Color Function(double) heatColor;

  ScreenHeatCell? _byKey(String key) {
    for (final c in cells) {
      if (c.key == key) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget cell(String key, {double height = 44}) {
      final c = _byKey(key);
      final intensity = c?.intensity ?? 0;
      final views = c?.views ?? 0;
      final label = c?.label ?? key;
      return Tooltip(
        message: '$label — $views views'
            '${(c?.avgDwellSec ?? 0) > 0 ? ', avg ${c!.avgDwellSec.toStringAsFixed(1)}s' : ''}',
        child: Container(
          height: height,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: heatColor(intensity),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Text(
            '$label${views > 0 ? ' · $views' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: intensity > 0.55 ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'User app heat',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              width: 260,
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        cell('tab:home', height: 52),
                        cell('route:/search'),
                        cell('route:/product'),
                        cell('route:/cart'),
                        cell('route:/checkout', height: 40),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            for (final key in [
                              'tab:categories',
                              'tab:offers',
                              'tab:ai_chat',
                              'tab:profile',
                            ])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: cell(key, height: 48),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenTable extends StatelessWidget {
  const _ScreenTable({required this.cells, required this.heatColor});

  final List<ScreenHeatCell> cells;
  final Color Function(double) heatColor;

  @override
  Widget build(BuildContext context) {
    final rows = [...cells]..sort((a, b) => b.views.compareTo(a.views));
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          columns: const [
            DataColumn(label: Text('Screen')),
            DataColumn(label: Text('Views'), numeric: true),
            DataColumn(label: Text('Avg dwell'), numeric: true),
            DataColumn(label: Text('Heat')),
          ],
          rows: rows
              .where((c) => c.views > 0 || AppHeatmapService.canonicalScreens
                  .any((e) => e.$1 == c.key))
              .take(20)
              .map(
                (c) => DataRow(
                  cells: [
                    DataCell(Text(c.label)),
                    DataCell(Text('${c.views}')),
                    DataCell(
                      Text(
                        c.avgDwellSec <= 0
                            ? '—'
                            : '${c.avgDwellSec.toStringAsFixed(1)}s',
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 72,
                        height: 14,
                        decoration: BoxDecoration(
                          color: heatColor(c.intensity),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
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
            Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
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

class _Legend extends StatelessWidget {
  const _Legend({required this.heatColor});
  final Color Function(double) heatColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Low', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        for (final t in [0.0, 0.25, 0.5, 0.75, 1.0])
          Container(
            width: 28,
            height: 12,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: heatColor(t),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 8),
        Text('High', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
