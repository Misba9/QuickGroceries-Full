import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/maintenance_config_model.dart';

enum OpsLevel { active, warning, critical, inactive }

enum MaintenanceSyncStatus { idle, saving, synced, failed }

class OpsChipStatus {
  const OpsChipStatus({
    required this.label,
    required this.level,
    required this.detail,
  });

  final String label;
  final OpsLevel level;
  final String detail;
}

class MaintenanceOpsSnapshot {
  const MaintenanceOpsSnapshot({
    required this.store,
    required this.ordering,
    required this.userApp,
    required this.vendorApp,
    required this.driverApp,
    required this.activeSummary,
  });

  final OpsChipStatus store;
  final OpsChipStatus ordering;
  final OpsChipStatus userApp;
  final OpsChipStatus vendorApp;
  final OpsChipStatus driverApp;
  final List<String> activeSummary;
}

MaintenanceOpsSnapshot computeOpsSnapshot(MaintenanceConfigModel c) {
  final e = c.emergencyControls;
  final sched = c.schedule;

  final storeOpen = c.legacyStoreActive && !sched.emergencyClose;
  final store = storeOpen
      ? OpsChipStatus(
          label: 'OPEN',
          level: OpsLevel.active,
          detail: sched.enabled
              ? 'Open ${sched.dailyOpenTime} – ${sched.dailyCloseTime}'
              : 'Store accepting orders',
        )
      : OpsChipStatus(
          label: sched.emergencyClose ? 'EMERGENCY CLOSED' : 'CLOSED',
          level: OpsLevel.critical,
          detail: 'Store is not accepting traffic',
        );

  final OpsChipStatus ordering;
  if (e.stopAllOrders) {
    ordering = const OpsChipStatus(
      label: 'STOPPED',
      level: OpsLevel.critical,
      detail: 'All orders blocked',
    );
  } else if (c.enabled && !c.allowOrders) {
    ordering = const OpsChipStatus(
      label: 'LIMITED',
      level: OpsLevel.warning,
      detail: 'Maintenance restrictions on checkout',
    );
  } else if (!c.legacyStoreActive) {
    ordering = const OpsChipStatus(
      label: 'LIMITED',
      level: OpsLevel.warning,
      detail: 'Legacy store flag off',
    );
  } else {
    ordering = const OpsChipStatus(
      label: 'ACTIVE',
      level: OpsLevel.active,
      detail: 'Orders flowing normally',
    );
  }

  OpsChipStatus appStatus({
    required bool affected,
    required String name,
  }) {
    if (!affected || !c.enabled) {
      return OpsChipStatus(
        label: 'ACTIVE',
        level: OpsLevel.active,
        detail: '$name running normally',
      );
    }
    final level = c.mode == 'hard' ? OpsLevel.critical : OpsLevel.warning;
    return OpsChipStatus(
      label: c.mode == 'hard' ? 'BLOCKED' : 'MAINTENANCE',
      level: level,
      detail: '${c.mode.toUpperCase()} maintenance · $name',
    );
  }

  final summary = <String>[];
  if (c.enabled) {
    summary.add('Maintenance mode: ${c.mode.toUpperCase()}');
    final apps = <String>[];
    if (c.affectedUserApp) apps.add('User app');
    if (c.affectedVendorApp) apps.add('Vendor app');
    if (c.affectedDriverApp) apps.add('Driver app');
    summary.add(
      apps.isEmpty ? 'Affected apps: none' : 'Affected: ${apps.join(', ')}',
    );
  } else {
    summary.add('Maintenance mode: OFF');
  }
  if (sched.enabled) {
    summary.add('Store timing: ${sched.dailyOpenTime} – ${sched.dailyCloseTime}');
  } else {
    summary.add('Store timing: always on');
  }
  summary.add('Auto reopen: ${sched.autoReopen ? 'ENABLED' : 'DISABLED'}');
  summary.add(
    c.reopenTime != null
        ? 'Reopen countdown: ${c.reopenTime!.toLocal()}'
        : 'Scheduled maintenance: NONE',
  );
  if (e.stopAllOrders) summary.add('⚠ Stop all orders: ON');
  if (e.disableCod) summary.add('⚠ COD disabled');

  return MaintenanceOpsSnapshot(
    store: store,
    ordering: ordering,
    userApp: appStatus(affected: c.affectedUserApp, name: 'User'),
    vendorApp: appStatus(affected: c.affectedVendorApp, name: 'Vendor'),
    driverApp: appStatus(affected: c.affectedDriverApp, name: 'Driver'),
    activeSummary: summary,
  );
}

Color opsLevelColor(OpsLevel level) {
  switch (level) {
    case OpsLevel.active:
      return const Color(0xFF16A34A);
    case OpsLevel.warning:
      return const Color(0xFFD97706);
    case OpsLevel.critical:
      return const Color(0xFFDC2626);
    case OpsLevel.inactive:
      return const Color(0xFF94A3B8);
  }
}

Color opsLevelBackground(OpsLevel level) {
  return opsLevelColor(level).withValues(alpha: 0.12);
}
