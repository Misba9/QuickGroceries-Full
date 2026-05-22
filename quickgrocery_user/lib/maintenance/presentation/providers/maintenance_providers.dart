import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/maintenance/data/maintenance_repository.dart';
import 'package:quickgrocery/maintenance/domain/maintenance_config.dart';
import 'package:quickgrocery/maintenance/domain/maintenance_evaluator.dart';
import 'package:quickgrocery/maintenance/domain/maintenance_status.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => MaintenanceRepository(),
);

final maintenanceConfigStreamProvider =
    StreamProvider<MaintenanceConfig>((ref) {
  return ref.watch(maintenanceRepositoryProvider).watchConfig();
});

final onlineDriversCountProvider = StreamProvider<int>((ref) {
  return ref.watch(maintenanceRepositoryProvider).watchOnlineDriversCount();
});

/// Combined effective status — refreshes with Firestore + driver count.
final maintenanceStatusProvider = StreamProvider<MaintenanceStatus>((ref) {
  final repo = ref.watch(maintenanceRepositoryProvider);
  final controller = StreamController<MaintenanceStatus>();

  MaintenanceConfig? lastConfig;
  int? lastDrivers;

  void emitStatus() {
    if (lastConfig == null) return;
    controller.add(
      MaintenanceEvaluator.evaluate(
        config: lastConfig!,
        now: DateTime.now(),
        onlineDriversCount: lastDrivers,
      ),
    );
  }

  final sub1 = repo.watchConfig().listen((c) {
    lastConfig = c;
    emitStatus();
  });
  final sub2 = repo.watchOnlineDriversCount().listen((n) {
    lastDrivers = n;
    emitStatus();
  });

  // Tick every second for countdown + schedule boundaries.
  final timer = Timer.periodic(const Duration(seconds: 1), (_) => emitStatus());

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Periodic API refresh (every 30s) for retry / offline recovery.
final maintenanceRefreshProvider = Provider<void>((ref) {
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    ref.invalidate(maintenanceConfigStreamProvider);
  });
  ref.onDispose(timer.cancel);
});

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Whether user app should show full maintenance screen.
final userAppMaintenanceBlockedProvider = Provider<bool>((ref) {
  final status = ref.watch(maintenanceStatusProvider).valueOrNull;
  if (status == null) return false;
  if (!status.config.enabled) {
    return status.showFullScreenBlock && !status.config.legacyStoreActive;
  }
  return status.showFullScreenBlock;
});
