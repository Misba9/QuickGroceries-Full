import 'package:cloud_firestore/cloud_firestore.dart';

class AppScreenViewEvent {
  const AppScreenViewEvent({
    required this.id,
    required this.screen,
    required this.screenKind,
    required this.screenName,
    required this.event,
    required this.dwellMs,
    required this.userId,
    required this.platform,
    required this.hour,
    required this.weekday,
    required this.createdAt,
  });

  final String id;
  final String screen;
  final String screenKind;
  final String screenName;
  final String event;
  final int dwellMs;
  final String userId;
  final String platform;
  final int hour;
  final int weekday;
  final DateTime? createdAt;

  factory AppScreenViewEvent.fromDoc(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic>
        ? raw
        : (raw is Map
            ? Map<String, dynamic>.from(raw)
            : const <String, dynamic>{});
    DateTime? createdAt;
    final ts = data['createdAt'] ?? data['clientAt'];
    if (ts is Timestamp) createdAt = ts.toDate();
    return AppScreenViewEvent(
      id: doc.id,
      screen: (data['screen'] ?? '').toString(),
      screenKind: (data['screenKind'] ?? '').toString(),
      screenName: (data['screenName'] ?? '').toString(),
      event: (data['event'] ?? 'view').toString(),
      dwellMs: (data['dwellMs'] is num) ? (data['dwellMs'] as num).toInt() : 0,
      userId: (data['userId'] ?? '').toString(),
      platform: (data['platform'] ?? '').toString(),
      hour: (data['hour'] is num) ? (data['hour'] as num).toInt() : 0,
      weekday: (data['weekday'] is num) ? (data['weekday'] as num).toInt() : 0,
      createdAt: createdAt,
    );
  }
}

class AppScreenStat {
  const AppScreenStat({
    required this.screen,
    required this.screenKind,
    required this.screenName,
    required this.views,
    required this.dwellEvents,
    required this.totalDwellMs,
  });

  final String screen;
  final String screenKind;
  final String screenName;
  final int views;
  final int dwellEvents;
  final int totalDwellMs;

  factory AppScreenStat.fromDoc(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic>
        ? raw
        : (raw is Map
            ? Map<String, dynamic>.from(raw)
            : const <String, dynamic>{});
    return AppScreenStat(
      screen: (data['screen'] ?? doc.id).toString(),
      screenKind: (data['screenKind'] ?? '').toString(),
      screenName: (data['screenName'] ?? '').toString(),
      views: (data['views'] is num) ? (data['views'] as num).toInt() : 0,
      dwellEvents:
          (data['dwellEvents'] is num) ? (data['dwellEvents'] as num).toInt() : 0,
      totalDwellMs:
          (data['totalDwellMs'] is num) ? (data['totalDwellMs'] as num).toInt() : 0,
    );
  }

  double get avgDwellSec =>
      dwellEvents == 0 ? 0 : (totalDwellMs / dwellEvents) / 1000.0;
}

class ScreenHeatCell {
  const ScreenHeatCell({
    required this.key,
    required this.label,
    required this.views,
    required this.intensity,
    required this.avgDwellSec,
  });

  final String key;
  final String label;
  final int views;
  final double intensity; // 0..1
  final double avgDwellSec;
}

class GeoHeatCell {
  const GeoHeatCell({
    required this.lat,
    required this.lng,
    required this.count,
    required this.intensity,
  });

  final double lat;
  final double lng;
  final int count;
  final double intensity;
}
