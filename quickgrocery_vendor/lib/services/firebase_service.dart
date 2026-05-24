import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Shared Firebase accessors for the vendor app.
class FirebaseService {
  FirebaseService._();

  static const String vendorsCollection = 'vendors';

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static FirebaseAuth get auth => FirebaseAuth.instance;

  static String vendorDocPath(String uid) => '$vendorsCollection/$uid';

  static DocumentReference<Map<String, dynamic>> vendorDoc(String uid) {
    return firestore.doc(vendorDocPath(uid));
  }

  static Future<void> ensureInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  static Future<void> signOutSafely() async {
    try {
      await auth.signOut();
    } catch (_) {}
  }
}
