/// Local timezone day/week/month boundaries (defaults to device local — set for India in app if needed).
abstract final class AdminDateRanges {
  static DateTime get nowLocal => DateTime.now().toLocal();

  static DateTime startOfLocalDay([DateTime? ref]) {
    final n = (ref ?? nowLocal).toLocal();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime endOfLocalDayExclusive(DateTime dayStart) =>
      dayStart.add(const Duration(days: 1));

  static DateTime get todayStart => startOfLocalDay();

  static DateTime get todayEndExclusive => endOfLocalDayExclusive(todayStart);

  static DateTime get yesterdayStart =>
      todayStart.subtract(const Duration(days: 1));

  static DateTime get yesterdayEndExclusive => todayStart;

  /// Monday 00:00 of the week containing [ref].
  static DateTime startOfLocalWeek([DateTime? ref]) {
    final n = startOfLocalDay(ref);
    final weekday = n.weekday; // Mon=1
    return n.subtract(Duration(days: weekday - 1));
  }

  static DateTime get weekStart => startOfLocalWeek();

  static DateTime get weekEndExclusive => todayEndExclusive;

  /// Rolling last 7 days including today (6 days back + today).
  static DateTime get rolling7Start =>
      todayStart.subtract(const Duration(days: 6));

  static DateTime startOfLocalMonth([DateTime? ref]) {
    final n = (ref ?? nowLocal).toLocal();
    return DateTime(n.year, n.month, 1);
  }

  static DateTime get monthStart => startOfLocalMonth();

  static DateTime get monthEndExclusive => todayEndExclusive;

  static bool isOnLocalDay(DateTime? dt, DateTime dayStart) {
    if (dt == null) return false;
    final local = dt.toLocal();
    return !local.isBefore(dayStart) &&
        local.isBefore(endOfLocalDayExclusive(dayStart));
  }

  static bool isInRange(
    DateTime? dt,
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    if (dt == null) return false;
    final local = dt.toLocal();
    return !local.isBefore(startInclusive) && local.isBefore(endExclusive);
  }
}
