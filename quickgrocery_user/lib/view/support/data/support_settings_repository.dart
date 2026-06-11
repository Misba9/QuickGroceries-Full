import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/view/support/models/support_settings.dart';

/// Reads admin **Settings → Support Settings** (`support_settings/main`).
class SupportSettingsRepository {
  SupportSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const collection = 'support_settings';
  static const documentId = 'main';

  Stream<SupportSettings> watch() {
    return _firestore
        .collection(collection)
        .doc(documentId)
        .snapshots()
        .map((snap) => SupportSettings.fromMap(snap.data()));
  }
}
