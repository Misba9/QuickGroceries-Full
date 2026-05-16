import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quickgrocery/view/app_content/models/app_content_config.dart';

/// Reads `app_content/main` — shared with the admin panel.
class AppContentRepository {
  AppContentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const collection = 'app_content';
  static const documentId = 'main';

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection(collection).doc(documentId);

  Stream<AppContentConfig> watch() {
    return _doc.snapshots().map(
          (snap) => AppContentConfig.fromMap(snap.data()),
        );
  }
}
