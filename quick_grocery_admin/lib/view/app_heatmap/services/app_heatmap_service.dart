import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_admin/view/app_heatmap/models/app_heatmap_models.dart';

class AppHeatmapService {
  AppHeatmapService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const viewsCol = 'app_screen_views';
  static const statsCol = 'app_screen_stats';

  /// Canonical app surfaces shown on the phone heatmap (even if count is 0).
  static const canonicalScreens = <(String key, String label)>[
    ('tab:home', 'Home'),
    ('tab:categories', 'Categories'),
    ('tab:offers', 'Offers'),
    ('tab:ai_chat', 'AI Chat'),
    ('tab:profile', 'Profile'),
    ('route:/search', 'Search'),
    ('route:/product', 'Product'),
    ('route:/cart', 'Cart'),
    ('route:/checkout', 'Checkout'),
    ('route:/payment', 'Payment'),
    ('route:/orders-list', 'Orders'),
    ('route:/order-tracking', 'Tracking'),
    ('route:/notifications', 'Notifications'),
    ('route:/location', 'Location'),
    ('route:/address', 'Addresses'),
    ('route:/combo-detail', 'Combo'),
    ('route:/login', 'Login'),
  ];

  Stream<List<AppScreenStat>> watchStats() {
    return _db.collection(statsCol).snapshots().map(
          (s) => s.docs.map(AppScreenStat.fromDoc).toList(growable: false),
        );
  }

  Stream<List<AppScreenViewEvent>> watchRecentViews({int limit = 800}) {
    return _db
        .collection(viewsCol)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs.map(AppScreenViewEvent.fromDoc).toList(growable: false),
        );
  }

  Stream<List<AppScreenViewEvent>> watchRecentViewsFallback({int limit = 800}) {
    return _db.collection(viewsCol).limit(limit).snapshots().map((s) {
      final list = s.docs.map(AppScreenViewEvent.fromDoc).toList();
      list.sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
  }

  /// Order delivery points for the geographic heatmap.
  Stream<List<({double lat, double lng})>> watchOrderPoints({int limit = 600}) {
    return _db.collection('orders').limit(limit).snapshots().map((s) {
      final out = <({double lat, double lng})>[];
      for (final d in s.docs) {
        final data = d.data();
        final lat = _asDouble(data['lat'] ?? data['latitude']);
        final lng = _asDouble(data['lng'] ?? data['longitude']);
        if (lat == 0 && lng == 0) continue;
        if (lat.abs() > 90 || lng.abs() > 180) continue;
        out.add((lat: lat, lng: lng));
      }
      return out;
    });
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  List<ScreenHeatCell> buildScreenCells({
    required List<AppScreenStat> stats,
    List<AppScreenViewEvent> events = const [],
  }) {
    final byScreen = <String, AppScreenStat>{
      for (final s in stats) s.screen: s,
    };

    // Fill gaps from raw events if stats docs are missing.
    if (byScreen.isEmpty && events.isNotEmpty) {
      final counts = <String, int>{};
      final dwellMs = <String, int>{};
      final dwellN = <String, int>{};
      for (final e in events) {
        if (e.screen.isEmpty) continue;
        if (e.event == 'dwell') {
          dwellMs[e.screen] = (dwellMs[e.screen] ?? 0) + e.dwellMs;
          dwellN[e.screen] = (dwellN[e.screen] ?? 0) + 1;
        } else {
          counts[e.screen] = (counts[e.screen] ?? 0) + 1;
        }
      }
      for (final key in {...counts.keys, ...dwellMs.keys}) {
        final parts = key.split(':');
        byScreen[key] = AppScreenStat(
          screen: key,
          screenKind: parts.isNotEmpty ? parts.first : '',
          screenName: parts.length > 1 ? parts.sublist(1).join(':') : key,
          views: counts[key] ?? 0,
          dwellEvents: dwellN[key] ?? 0,
          totalDwellMs: dwellMs[key] ?? 0,
        );
      }
    }

    var maxViews = 0;
    for (final s in byScreen.values) {
      if (s.views > maxViews) maxViews = s.views;
    }
    if (maxViews <= 0) maxViews = 1;

    final cells = <ScreenHeatCell>[];
    final seen = <String>{};

    for (final (key, label) in canonicalScreens) {
      seen.add(key);
      final s = byScreen[key];
      final views = s?.views ?? 0;
      cells.add(
        ScreenHeatCell(
          key: key,
          label: label,
          views: views,
          intensity: views / maxViews,
          avgDwellSec: s?.avgDwellSec ?? 0,
        ),
      );
    }

    // Extra screens not in canonical list.
    final extras = byScreen.values
        .where((s) => !seen.contains(s.screen) && s.views > 0)
        .toList()
      ..sort((a, b) => b.views.compareTo(a.views));
    for (final s in extras.take(8)) {
      cells.add(
        ScreenHeatCell(
          key: s.screen,
          label: _prettyLabel(s.screenName.isEmpty ? s.screen : s.screenName),
          views: s.views,
          intensity: s.views / maxViews,
          avgDwellSec: s.avgDwellSec,
        ),
      );
    }
    return cells;
  }

  /// 7 (weekday) × 24 (hour) intensity matrix from view events.
  List<List<double>> buildTimeHeatmatrix(List<AppScreenViewEvent> events) {
    final counts = List.generate(7, (_) => List<int>.filled(24, 0));
    var max = 0;
    for (final e in events) {
      if (e.event == 'dwell') continue;
      final day = e.weekday;
      final hour = e.hour;
      if (day < 1 || day > 7 || hour < 0 || hour > 23) continue;
      final v = ++counts[day - 1][hour];
      if (v > max) max = v;
    }
    if (max == 0) max = 1;
    return [
      for (var d = 0; d < 7; d++)
        [for (var h = 0; h < 24; h++) counts[d][h] / max],
    ];
  }

  List<List<int>> buildTimeCounts(List<AppScreenViewEvent> events) {
    final counts = List.generate(7, (_) => List<int>.filled(24, 0));
    for (final e in events) {
      if (e.event == 'dwell') continue;
      final day = e.weekday;
      final hour = e.hour;
      if (day < 1 || day > 7 || hour < 0 || hour > 23) continue;
      counts[day - 1][hour]++;
    }
    return counts;
  }

  List<GeoHeatCell> buildGeoCells(
    List<({double lat, double lng})> points, {
    double cellSize = 0.01,
  }) {
    if (points.isEmpty) return const [];
    final buckets = <String, ({double latSum, double lngSum, int n})>{};
    for (final p in points) {
      final latKey = (p.lat / cellSize).floor();
      final lngKey = (p.lng / cellSize).floor();
      final key = '$latKey:$lngKey';
      final prev = buckets[key];
      if (prev == null) {
        buckets[key] = (latSum: p.lat, lngSum: p.lng, n: 1);
      } else {
        buckets[key] = (
          latSum: prev.latSum + p.lat,
          lngSum: prev.lngSum + p.lng,
          n: prev.n + 1,
        );
      }
    }
    var max = 1;
    for (final b in buckets.values) {
      if (b.n > max) max = b.n;
    }
    return buckets.values
        .map(
          (b) => GeoHeatCell(
            lat: b.latSum / b.n,
            lng: b.lngSum / b.n,
            count: b.n,
            intensity: b.n / max,
          ),
        )
        .toList(growable: false);
  }

  static String _prettyLabel(String raw) {
    var s = raw.replaceFirst(RegExp(r'^/'), '');
    s = s.replaceAll('-', ' ').replaceAll('_', ' ');
    if (s.isEmpty) return raw;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String displayLabel(String screen) {
    for (final (key, label) in canonicalScreens) {
      if (key == screen) return label;
    }
    final name = screen.contains(':') ? screen.split(':').last : screen;
    return _prettyLabel(name);
  }
}
