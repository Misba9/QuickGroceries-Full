import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cart_models.dart';

/// Default delivery slots — Express + a handful of 2-hour windows for today
/// and tomorrow. In a future iteration these can come from Firestore (per
/// zone / per pin code) but the user-facing logic stays identical.
final deliverySlotsProvider = Provider.autoDispose<List<DeliverySlot>>((ref) {
  final now = DateTime.now();
  final slots = <DeliverySlot>[
    DeliverySlot(
      id: 'express',
      label: 'Express · in 15-20 min',
      start: now,
      end: now.add(const Duration(minutes: 20)),
      isExpress: true,
    ),
  ];

  final today = DateTime(now.year, now.month, now.day);
  final windows = const [
    [9, 11],
    [11, 13],
    [13, 15],
    [15, 17],
    [17, 19],
    [19, 21],
  ];

  void addWindowsForDay(DateTime day, String prefix) {
    for (final w in windows) {
      final start = day.add(Duration(hours: w[0]));
      final end = day.add(Duration(hours: w[1]));
      if (end.isBefore(now.add(const Duration(minutes: 60)))) continue;
      final label = '$prefix · ${_fmt(start)} – ${_fmt(end)}';
      slots.add(DeliverySlot(
        id: '${day.toIso8601String().split("T").first}-${w[0]}',
        label: label,
        start: start,
        end: end,
        isExpress: false,
      ));
    }
  }

  addWindowsForDay(today, 'Today');
  addWindowsForDay(today.add(const Duration(days: 1)), 'Tomorrow');
  return slots;
});

String _fmt(DateTime t) {
  final h = t.hour;
  final period = h >= 12 ? 'PM' : 'AM';
  final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$hour12 $period';
}
