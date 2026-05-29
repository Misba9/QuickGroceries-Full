import 'maintenance_config.dart';

enum MaintenanceBlockReason {
  legacyStoreClosed,
  hardMaintenance,
  scheduleClosed,
  areaBlocked,
  highDemand,
  ordersStopped,
}

/// Effective runtime state for gating UI and checkout.
class MaintenanceStatus {
  const MaintenanceStatus({
    required this.kind,
    required this.config,
    this.blockReason,
    this.effectiveReopen,
    this.highDemandMessage,
    this.pauseCod = false,
    this.pauseOrders = false,
  });

  final MaintenanceStatusKind kind;
  final MaintenanceConfig config;
  final MaintenanceBlockReason? blockReason;
  final DateTime? effectiveReopen;
  final LocalizedText? highDemandMessage;
  final bool pauseCod;
  final bool pauseOrders;

  bool get showFullScreenBlock =>
      kind == MaintenanceStatusKind.blocked ||
      kind == MaintenanceStatusKind.scheduleClosed;

  bool get canBrowseApp =>
      kind == MaintenanceStatusKind.normal ||
      kind == MaintenanceStatusKind.soft ||
      kind == MaintenanceStatusKind.readOnly ||
      kind == MaintenanceStatusKind.highDemand;

  bool get canPlaceOrders {
    if (pauseOrders) return false;
    if (config.emergencyControls.stopAllOrders) return false;
    switch (kind) {
      case MaintenanceStatusKind.normal:
        return config.allowOrders;
      case MaintenanceStatusKind.soft:
        return false;
      case MaintenanceStatusKind.highDemand:
        return config.allowOrders && !pauseOrders;
      case MaintenanceStatusKind.readOnly:
        return false;
      case MaintenanceStatusKind.blocked:
      case MaintenanceStatusKind.scheduleClosed:
      case MaintenanceStatusKind.areaBlocked:
      case MaintenanceStatusKind.ordersStopped:
        return false;
    }
  }

  bool get canUseCart {
    if (!canPlaceOrders) return false;
    return config.allowCart;
  }

  bool get canPay {
    if (config.emergencyControls.disablePayments) return false;
    if (!canPlaceOrders) return false;
    return config.allowPayments;
  }

  bool get codAllowed =>
      canPay && !pauseCod && !config.emergencyControls.disableCod;

  factory MaintenanceStatus.normal({required MaintenanceConfig config}) =>
      MaintenanceStatus(kind: MaintenanceStatusKind.normal, config: config);

  factory MaintenanceStatus.softMaintenance({
    required MaintenanceConfig config,
    DateTime? effectiveReopen,
  }) => MaintenanceStatus(
    kind: MaintenanceStatusKind.soft,
    config: config,
    effectiveReopen: effectiveReopen,
  );

  factory MaintenanceStatus.readOnly({
    required MaintenanceConfig config,
    DateTime? effectiveReopen,
  }) => MaintenanceStatus(
    kind: MaintenanceStatusKind.readOnly,
    config: config,
    effectiveReopen: effectiveReopen,
  );

  factory MaintenanceStatus.blocked({
    required MaintenanceBlockReason reason,
    required MaintenanceConfig config,
    DateTime? effectiveReopen,
  }) => MaintenanceStatus(
    kind: MaintenanceStatusKind.blocked,
    config: config,
    blockReason: reason,
    effectiveReopen: effectiveReopen,
  );

  factory MaintenanceStatus.scheduleClosed({
    required MaintenanceConfig config,
    DateTime? effectiveReopen,
  }) => MaintenanceStatus(
    kind: MaintenanceStatusKind.scheduleClosed,
    config: config,
    blockReason: MaintenanceBlockReason.scheduleClosed,
    effectiveReopen: effectiveReopen,
  );

  factory MaintenanceStatus.areaBlocked({required MaintenanceConfig config}) =>
      MaintenanceStatus(
        kind: MaintenanceStatusKind.areaBlocked,
        config: config,
        blockReason: MaintenanceBlockReason.areaBlocked,
      );

  factory MaintenanceStatus.highDemand({
    required MaintenanceConfig config,
    required LocalizedText message,
    required bool pauseCod,
    required bool pauseOrders,
  }) => MaintenanceStatus(
    kind: MaintenanceStatusKind.highDemand,
    config: config,
    blockReason: MaintenanceBlockReason.highDemand,
    highDemandMessage: message,
    pauseCod: pauseCod,
    pauseOrders: pauseOrders,
  );

  factory MaintenanceStatus.ordersStopped({
    required MaintenanceConfig config,
  }) => MaintenanceStatus(
    kind: MaintenanceStatusKind.ordersStopped,
    config: config,
    blockReason: MaintenanceBlockReason.ordersStopped,
  );
}

enum MaintenanceStatusKind {
  normal,
  soft,
  readOnly,
  blocked,
  scheduleClosed,
  areaBlocked,
  highDemand,
  ordersStopped,
}
