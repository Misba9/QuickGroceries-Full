/// Global human-readable duration formatting for admin, orders, and delivery UIs.
abstract final class DurationFormat {
  /// Compact duration: `45m`, `2h 15m`, `1d 4h`.
  static String formatDuration(
    Duration d, {
    bool allowDays = true,
    bool zeroAsDash = false,
  }) {
    if (d.isNegative) {
      return formatDuration(d.abs(), allowDays: allowDays, zeroAsDash: zeroAsDash);
    }
    final totalMinutes = d.inMinutes;
    if (totalMinutes <= 0) {
      return zeroAsDash ? '—' : '0m';
    }
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (allowDays && hours >= 24) {
      final days = hours ~/ 24;
      final remHours = hours % 24;
      if (remHours == 0 && minutes == 0) return '${days}d';
      if (minutes == 0) return '${days}d ${remHours}h';
      return '${days}d ${remHours}h ${minutes}m';
    }

    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Elapsed since [from] until [now].
  static String formatElapsed(
    DateTime? from, {
    DateTime? now,
    bool suffixAgo = true,
  }) {
    if (from == null) return '—';
    final end = (now ?? DateTime.now()).toLocal();
    final start = from.toLocal();
    final diff = end.difference(start);
    if (diff.inMinutes < 1) return 'Just now';
    final text = formatDuration(diff);
    return suffixAgo ? '$text ago' : text;
  }

  /// Time remaining until [target] from [now].
  static String formatRemaining(
    DateTime target, {
    DateTime? now,
  }) {
    final end = target.toLocal();
    final start = (now ?? DateTime.now()).toLocal();
    if (!end.isAfter(start)) return '0m';
    return formatDuration(end.difference(start));
  }

  /// Late by duration after [deadline].
  static String formatLate(
    DateTime deadline, {
    DateTime? now,
    String prefix = 'Late by ',
  }) {
    final end = (now ?? DateTime.now()).toLocal();
    final due = deadline.toLocal();
    if (!end.isAfter(due)) return '';
    return '$prefix${formatDuration(end.difference(due))}';
  }

  /// ETA label: clock time if on time, or late/remaining text.
  static String formatEta({
    required DateTime? createdAt,
    Duration sla = const Duration(minutes: 45),
    DateTime? now,
    bool showClockWhenOnTime = true,
  }) {
    if (createdAt == null) return '—';
    final n = (now ?? DateTime.now()).toLocal();
    final eta = createdAt.toLocal().add(sla);
    if (n.isAfter(eta)) {
      final late = formatLate(eta, now: n);
      return late.isEmpty ? '—' : late;
    }
    if (!showClockWhenOnTime) {
      return '${formatRemaining(eta, now: n)} left';
    }
    final h = eta.hour.toString().padLeft(2, '0');
    final min = eta.minute.toString().padLeft(2, '0');
    return 'ETA $h:$min';
  }
}
