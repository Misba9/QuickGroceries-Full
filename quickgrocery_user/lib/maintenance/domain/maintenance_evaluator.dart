import 'maintenance_config.dart';
import 'maintenance_status.dart';

/// Computes effective maintenance state from config + schedule + context.
class MaintenanceEvaluator {
  const MaintenanceEvaluator._();

  static MaintenanceStatus evaluate({
    required MaintenanceConfig config,
    required DateTime now,
    int? onlineDriversCount,
  }) {
    if (!config.userAppEnabled) {
      return MaintenanceStatus.blocked(
        reason: MaintenanceBlockReason.hardMaintenance,
        config: config,
        effectiveReopen: config.reopenTime,
      );
    }

    if (!config.storeOpen || !config.legacyStoreActive) {
      return MaintenanceStatus.blocked(
        reason: MaintenanceBlockReason.legacyStoreClosed,
        config: config,
        effectiveReopen: config.reopenTime ?? _nextScheduleOpen(config, now),
      );
    }

    if (!config.orderingEnabled || !config.allowOrders) {
      return MaintenanceStatus.ordersStopped(config: config);
    }

    final scheduleClosed = _isScheduleClosed(config, now);
    final emergency = config.schedule.emergencyClose;

    if (scheduleClosed || emergency) {
      return MaintenanceStatus.scheduleClosed(
        config: config,
        effectiveReopen: _nextScheduleOpen(config, now) ?? config.reopenTime,
      );
    }

    final driverControlPausesOrders =
        config.driverSmartControl.pauseOrdering ||
        config.driverSmartControl.autoPauseCod;
    if (driverControlPausesOrders &&
        config.driverSmartControl.enabled &&
        onlineDriversCount != null &&
        onlineDriversCount < config.driverSmartControl.minDriversOnline) {
      return MaintenanceStatus.highDemand(
        config: config,
        message: config.driverSmartControl.highDemandMessage,
        pauseCod: config.driverSmartControl.autoPauseCod,
        pauseOrders: config.driverSmartControl.pauseOrdering,
      );
    }

    if (config.emergencyControls.stopAllOrders) {
      return MaintenanceStatus.ordersStopped(config: config);
    }

    if (!config.enabled || !config.affectsUserApp) {
      return MaintenanceStatus.normal(config: config);
    }

    switch (config.mode) {
      case 'hard':
        return MaintenanceStatus.blocked(
          reason: MaintenanceBlockReason.hardMaintenance,
          config: config,
          effectiveReopen: config.reopenTime,
        );
      case 'read_only':
        return MaintenanceStatus.readOnly(
          config: config,
          effectiveReopen: config.reopenTime,
        );
      case 'soft':
      default:
        return MaintenanceStatus.softMaintenance(
          config: config,
          effectiveReopen: config.reopenTime,
        );
    }
  }

  static bool _isScheduleClosed(MaintenanceConfig config, DateTime now) {
    final s = config.schedule;
    if (!s.enabled) return false;
    if (s.emergencyClose) return true;
    if (s.weeklyHolidays.contains(now.weekday)) return true;

    for (final fest in s.festivalClosures) {
      final start = DateTime.tryParse(fest['start'] ?? '');
      final end = DateTime.tryParse(fest['end'] ?? '');
      if (start != null &&
          end != null &&
          !now.isBefore(start) &&
          now.isBefore(end)) {
        return true;
      }
    }

    final open = _parseHm(s.dailyOpenTime);
    final close = _parseHm(s.dailyCloseTime);
    if (open == null || close == null) return false;

    final minutes = now.hour * 60 + now.minute;
    final openMin = open.$1 * 60 + open.$2;
    final closeMin = close.$1 * 60 + close.$2;

    if (openMin < closeMin) {
      return minutes < openMin || minutes >= closeMin;
    }
    // Overnight window e.g. 22:00 - 08:00
    return minutes >= closeMin && minutes < openMin;
  }

  static DateTime? _nextScheduleOpen(MaintenanceConfig config, DateTime now) {
    final s = config.schedule;
    if (!s.enabled || !s.autoReopen) return config.reopenTime;
    final open = _parseHm(s.dailyOpenTime);
    if (open == null) return config.reopenTime;
    var candidate = DateTime(now.year, now.month, now.day, open.$1, open.$2);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static (int, int)? _parseHm(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }
}
