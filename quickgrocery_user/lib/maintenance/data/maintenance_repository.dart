import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/maintenance/domain/maintenance_config.dart';
import 'package:rxdart/rxdart.dart';

/// Firestore access for maintenance config + online driver count.
class MaintenanceRepository {
  MaintenanceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<MaintenanceConfig>? _sharedConfig;
  Stream<int>? _sharedDrivers;

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection(MaintenanceConfig.collection)
      .doc(MaintenanceConfig.documentId);
  DocumentReference<Map<String, dynamic>> get _legacyDoc => _firestore
      .collection(MaintenanceConfig.legacyCollection)
      .doc(MaintenanceConfig.legacyDocumentId);

  Stream<MaintenanceConfig> watchConfig() {
    return _sharedConfig ??= _createConfigWatch().shareReplay(maxSize: 1);
  }

  Stream<MaintenanceConfig> _createConfigWatch() {
    late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
        systemSub;
    late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
        legacySub;

    var systemExists = false;
    Map<String, dynamic>? systemData;
    Map<String, dynamic>? legacyData;

    final controller = StreamController<MaintenanceConfig>();

    void emit() {
      controller.add(
        MaintenanceConfig.fromMap(systemExists ? systemData : legacyData),
      );
    }

    controller.onListen = () {
      systemSub = _doc.snapshots().listen((snap) {
        systemExists = snap.exists;
        systemData = snap.data();
        emit();
      }, onError: controller.addError);
      legacySub = _legacyDoc.snapshots().listen((snap) {
        legacyData = snap.data();
        if (!systemExists) emit();
      }, onError: controller.addError);
    };
    controller.onCancel = () async {
      await systemSub.cancel();
      await legacySub.cancel();
    };

    return controller.stream;
  }

  Future<MaintenanceConfig> fetchConfig() async {
    final snap = await _doc.get(const GetOptions(source: Source.server));
    if (snap.exists) {
      return MaintenanceConfig.fromMap(snap.data());
    }
    final legacy = await _legacyDoc.get(
      const GetOptions(source: Source.server),
    );
    return MaintenanceConfig.fromMap(legacy.data());
  }

  /// Count delivery partners marked online for smart driver rules.
  Stream<int> watchOnlineDriversCount() {
    return _sharedDrivers ??= _firestore
        .collection('delivery_boys')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.length)
        .shareReplay(maxSize: 1);
  }
}
