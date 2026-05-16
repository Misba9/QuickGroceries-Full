import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quickgrocery/view/support/models/support_settings_config.dart';

/// Reads `support_settings/main` — shared with admin panel.
class SupportSettingsRepository {
  SupportSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const collection = 'support_settings';
  static const documentId = 'main';

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection(collection).doc(documentId);

  Stream<SupportSettingsConfig> watch() {
    return _doc.snapshots().map(
          (snap) => SupportSettingsConfig.fromMap(snap.data()),
        );
  }
}
