import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/maintenance/domain/maintenance_config.dart';

/// Firestore access for maintenance config + online driver count.
class MaintenanceRepository {
  MaintenanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection(MaintenanceConfig.collection)
      .doc(MaintenanceConfig.documentId);

  Stream<MaintenanceConfig> watchConfig() {
    return _doc.snapshots().map(
          (snap) => MaintenanceConfig.fromMap(snap.data()),
        );
  }

  Future<MaintenanceConfig> fetchConfig() async {
    final snap = await _doc.get();
    return MaintenanceConfig.fromMap(snap.data());
  }

  /// Count delivery partners marked online for smart driver rules.
  Stream<int> watchOnlineDriversCount() {
    return _firestore
        .collection('delivery_boys')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.length);
  }
}
