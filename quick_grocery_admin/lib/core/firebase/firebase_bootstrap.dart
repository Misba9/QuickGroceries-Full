import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/firebase_options.dart';

/// Single entry for Firebase + auth persistence (web).
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;

  /// Call after [WidgetsFlutterBinding.ensureInitialized]. Safe to call more than once.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await _configureAuthPersistence();
    _initialized = true;
  }

  static Future<void> _configureAuthPersistence() async {
    if (!kIsWeb) return;
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FirebaseBootstrap] setPersistence failed: $e\n$st');
      }
    }
  }
}
