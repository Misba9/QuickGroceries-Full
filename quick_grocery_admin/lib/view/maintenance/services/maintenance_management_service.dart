import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/maintenance_config_model.dart';
import 'package:quick_grocery_admin/view/maintenance/ops/maintenance_audit_entry.dart';
import 'package:quick_grocery_admin/view/maintenance/ops/maintenance_ops_helpers.dart';

/// Admin editor for `app_config/maintenance` — operations control center.
class MaintenanceManagementService extends ChangeNotifier {
  MaintenanceManagementService() {
    _listenConfig();
    _listenAudit();
    _attachDirtyListeners();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MaintenanceConfigModel config = MaintenanceConfigModel.defaults;
  MaintenanceConfigModel _baseline = MaintenanceConfigModel.defaults;

  bool loading = true;
  bool saving = false;
  String? error;
  MaintenanceSyncStatus syncStatus = MaintenanceSyncStatus.idle;
  DateTime? lastSyncedAt;
  DateTime? lastRemoteUpdateAt;
  int dirtyChangeCount = 0;
  int _pulseTick = 0;
  int _uiListeners = 0;
  Timer? _debounceNotify;
  bool get livePulse => _pulseTick.isEven;

  List<MaintenanceAuditEntry> auditLogs = [];
  String auditFilter = '';

  // Controllers
  final titleEn = TextEditingController();
  final titleTe = TextEditingController();
  final titleHi = TextEditingController();
  final titleAr = TextEditingController();
  final subtitleEn = TextEditingController();
  final messageEn = TextEditingController();
  final supportPhone = TextEditingController();
  final supportEmail = TextEditingController();
  final lottieUrl = TextEditingController();
  final bannerUrl = TextEditingController();
  final reopenDate = TextEditingController();
  final reopenTime = TextEditingController();
  final openTime = TextEditingController(text: '08:00');
  final closeTime = TextEditingController(text: '22:00');
  final timezone = TextEditingController(text: 'Asia/Kolkata');
  final festivalJson = TextEditingController();
  final disabledPincodes = TextEditingController();
  final disabledCities = TextEditingController();
  final maxRadius = TextEditingController();
  final settingsSearch = TextEditingController();

  bool _syncingControllers = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _configSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _auditSub;
  Timer? _pulseTimer;

  bool get isDirty => dirtyChangeCount > 0;
  bool get firebaseConnected => !loading && error == null;
  MaintenanceConfigModel get previewConfig => _buildDraftConfig();
  MaintenanceOpsSnapshot get opsSnapshot => computeOpsSnapshot(previewConfig);

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection(MaintenanceConfigModel.collection)
      .doc(MaintenanceConfigModel.documentId);

  /// Call from [MaintenanceManagementScreen.initState].
  void attachUi() {
    _uiListeners++;
    if (_uiListeners == 1) {
      _startPulse();
    }
  }

  /// Call from [MaintenanceManagementScreen.dispose].
  void detachUi() {
    if (_uiListeners <= 0) return;
    _uiListeners--;
    if (_uiListeners == 0) {
      _stopPulse();
      _debounceNotify?.cancel();
    }
  }

  void _notifyUi() {
    if (_uiListeners > 0) notifyListeners();
  }

  void _startPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_uiListeners <= 0) return;
      _pulseTick++;
      _scheduleNotify();
    });
  }

  void _stopPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
  }

  void _scheduleNotify() {
    _debounceNotify?.cancel();
    _debounceNotify = Timer(const Duration(milliseconds: 120), () {
      if (_uiListeners > 0) notifyListeners();
    });
  }

  void _listenConfig() {
    _configSub = _doc.snapshots().listen(
      (snap) {
        loading = false;
        error = snap.metadata.hasPendingWrites ? null : error;
        final remote = MaintenanceConfigModel.fromMap(snap.data());
        lastRemoteUpdateAt = remote.updatedAt ?? DateTime.now();

        if (!isDirty && !saving) {
          config = remote;
          _baseline = remote;
          _syncControllers();
          if (syncStatus == MaintenanceSyncStatus.saving) {
            syncStatus = MaintenanceSyncStatus.synced;
            lastSyncedAt = DateTime.now();
          }
        }
        if (_uiListeners > 0) _scheduleNotify();
      },
      onError: (Object e) {
        loading = false;
        error = e.toString();
        syncStatus = MaintenanceSyncStatus.failed;
        if (_uiListeners > 0) notifyListeners();
      },
    );
  }

  void _listenAudit() {
    _auditSub = _firestore
        .collection('maintenance_logs')
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .listen(
      (snap) {
        auditLogs = snap.docs.map(MaintenanceAuditEntry.fromDoc).toList();
        if (_uiListeners > 0) _scheduleNotify();
      },
      onError: (_) {},
    );
  }

  void _attachDirtyListeners() {
    final ctrls = [
      titleEn,
      titleTe,
      titleHi,
      titleAr,
      subtitleEn,
      messageEn,
      supportPhone,
      supportEmail,
      lottieUrl,
      bannerUrl,
      reopenDate,
      reopenTime,
      openTime,
      closeTime,
      timezone,
      disabledPincodes,
      disabledCities,
      maxRadius,
    ];
    for (final c in ctrls) {
      c.addListener(_recomputeDirty);
    }
  }

  void _syncControllers() {
    _syncingControllers = true;
    titleEn.text = config.title.en;
    titleTe.text = config.title.te;
    titleHi.text = config.title.hi;
    titleAr.text = config.title.ar;
    subtitleEn.text = config.subtitle.en;
    messageEn.text = config.message.en;
    supportPhone.text = config.supportPhone;
    supportEmail.text = config.supportEmail;
    lottieUrl.text = config.lottieUrl;
    bannerUrl.text = config.bannerImageUrl;
    if (config.reopenTime != null) {
      reopenDate.text =
          '${config.reopenTime!.year}-${config.reopenTime!.month.toString().padLeft(2, '0')}-${config.reopenTime!.day.toString().padLeft(2, '0')}';
      reopenTime.text =
          '${config.reopenTime!.hour.toString().padLeft(2, '0')}:${config.reopenTime!.minute.toString().padLeft(2, '0')}';
    } else {
      reopenDate.clear();
      reopenTime.clear();
    }
    openTime.text = config.schedule.dailyOpenTime;
    closeTime.text = config.schedule.dailyCloseTime;
    timezone.text = config.schedule.timezone;
    disabledPincodes.text =
        config.areaAvailability.disabledPincodes.join(', ');
    disabledCities.text = config.areaAvailability.disabledCities.join(', ');
    maxRadius.text =
        config.areaAvailability.maxDeliveryRadiusKm?.toString() ?? '';
    _syncingControllers = false;
    _recomputeDirty();
  }

  Future<void> ensureDocument() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      await _doc.set(MaintenanceConfigModel.defaults.toWriteMap());
    }
  }

  void updateConfig(MaintenanceConfigModel next) {
    config = next;
    _recomputeDirty();
  }

  void _recomputeDirty() {
    if (_syncingControllers) return;
    dirtyChangeCount = _countChanges(_baseline, _buildDraftConfig());
    if (_uiListeners > 0) _scheduleNotify();
  }

  int _countChanges(MaintenanceConfigModel a, MaintenanceConfigModel b) {
    var n = 0;
    final ma = a.toWriteMap();
    final mb = b.toWriteMap();
    ma.remove('updatedAt');
    mb.remove('updatedAt');
    for (final key in mb.keys) {
      final va = ma[key];
      final vb = mb[key];
      if (va.toString() != vb.toString()) n++;
    }
    return n;
  }

  MaintenanceConfigModel _buildDraftConfig() {
    return config.copyWith(
      title: LocalizedTextMap(
        en: titleEn.text.trim(),
        te: titleTe.text.trim().isEmpty ? titleEn.text.trim() : titleTe.text.trim(),
        hi: titleHi.text.trim().isEmpty ? titleEn.text.trim() : titleHi.text.trim(),
        ar: titleAr.text.trim().isEmpty ? titleEn.text.trim() : titleAr.text.trim(),
      ),
      subtitle: config.subtitle.copyWithEn(subtitleEn.text.trim()),
      message: config.message.copyWithEn(messageEn.text.trim()),
      reopenTime: _parseReopen(),
      clearReopenTime: reopenDate.text.trim().isEmpty,
      supportPhone: supportPhone.text.trim(),
      supportEmail: supportEmail.text.trim(),
      lottieUrl: lottieUrl.text.trim(),
      bannerImageUrl: bannerUrl.text.trim(),
      schedule: config.schedule.copyWith(
        dailyOpenTime: openTime.text.trim(),
        dailyCloseTime: closeTime.text.trim(),
        timezone: timezone.text.trim(),
      ),
      areaAvailability: config.areaAvailability.copyWith(
        disabledPincodes: _splitCsv(disabledPincodes.text),
        disabledCities: _splitCsv(disabledCities.text),
        maxDeliveryRadiusKm: double.tryParse(maxRadius.text.trim()),
      ),
    );
  }

  void discardChanges() {
    config = _baseline;
    _syncControllers();
    syncStatus = MaintenanceSyncStatus.idle;
    _logLocal('discard_draft');
    _notifyUi();
  }

  DateTime? _parseReopen() {
    final d = reopenDate.text.trim();
    final t = reopenTime.text.trim();
    if (d.isEmpty) return null;
    final combined = t.isEmpty ? '${d}T00:00:00' : '${d}T$t:00';
    return DateTime.tryParse(combined);
  }

  List<String> _splitCsv(String raw) => raw
      .split(RegExp(r'[,\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<bool> save({String? logAction}) async {
    saving = true;
    syncStatus = MaintenanceSyncStatus.saving;
    error = null;
    _notifyUi();
    try {
      final next = _buildDraftConfig().copyWith(
        updatedBy: FirebaseAuth.instance.currentUser?.uid,
      );

      await _doc.set(next.toWriteMap(), SetOptions(merge: true));
      config = next;
      _baseline = next;
      dirtyChangeCount = 0;

      await _logLocal(logAction ?? 'admin_save');
      syncStatus = MaintenanceSyncStatus.synced;
      lastSyncedAt = DateTime.now();
      return true;
    } catch (e) {
      error = e.toString();
      syncStatus = MaintenanceSyncStatus.failed;
      return false;
    } finally {
      saving = false;
      _notifyUi();
    }
  }

  Future<void> _logLocal(String action) async {
    try {
      await _firestore.collection('maintenance_logs').add({
        'action': action,
        'config': _buildDraftConfig().toWriteMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'adminUid': FirebaseAuth.instance.currentUser?.uid,
        'adminEmail': FirebaseAuth.instance.currentUser?.email,
      });
    } catch (_) {}
  }

  void setAuditFilter(String q) {
    auditFilter = q;
    _scheduleNotify();
  }

  List<MaintenanceAuditEntry> get filteredAuditLogs {
    if (auditFilter.trim().isEmpty) return auditLogs;
    final q = auditFilter.toLowerCase();
    return auditLogs
        .where(
          (e) =>
              e.displayAction.toLowerCase().contains(q) ||
              (e.adminUid ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void dispose() {
    _configSub?.cancel();
    _auditSub?.cancel();
    _pulseTimer?.cancel();
    _debounceNotify?.cancel();
    titleEn.dispose();
    titleTe.dispose();
    titleHi.dispose();
    titleAr.dispose();
    subtitleEn.dispose();
    messageEn.dispose();
    supportPhone.dispose();
    supportEmail.dispose();
    lottieUrl.dispose();
    bannerUrl.dispose();
    reopenDate.dispose();
    reopenTime.dispose();
    openTime.dispose();
    closeTime.dispose();
    timezone.dispose();
    festivalJson.dispose();
    disabledPincodes.dispose();
    disabledCities.dispose();
    maxRadius.dispose();
    settingsSearch.dispose();
    super.dispose();
  }
}

extension _LocalizedCopy on LocalizedTextMap {
  LocalizedTextMap copyWithEn(String en) =>
      LocalizedTextMap(en: en, te: te, hi: hi, ar: ar);
}

extension _ScheduleCopy on MaintenanceSchedule {
  MaintenanceSchedule copyWith({
    String? dailyOpenTime,
    String? dailyCloseTime,
    String? timezone,
  }) =>
      MaintenanceSchedule(
        enabled: enabled,
        dailyOpenTime: dailyOpenTime ?? this.dailyOpenTime,
        dailyCloseTime: dailyCloseTime ?? this.dailyCloseTime,
        timezone: timezone ?? this.timezone,
        weeklyHolidays: weeklyHolidays,
        festivalClosures: festivalClosures,
        emergencyClose: emergencyClose,
        autoReopen: autoReopen,
      );
}

extension _AreaCopy on AreaAvailability {
  AreaAvailability copyWith({
    List<String>? disabledPincodes,
    List<String>? disabledCities,
    double? maxDeliveryRadiusKm,
  }) =>
      AreaAvailability(
        enabled: enabled,
        disabledPincodes: disabledPincodes ?? this.disabledPincodes,
        disabledCities: disabledCities ?? this.disabledCities,
        disabledZoneIds: disabledZoneIds,
        maxDeliveryRadiusKm: maxDeliveryRadiusKm ?? this.maxDeliveryRadiusKm,
      );
}
