import 'package:firebase_core/firebase_core.dart';

/// Shared Firebase config for admin + secondary vendor-auth app.
class AdminFirebaseOptions {
  AdminFirebaseOptions._();

  static const FirebaseOptions current = FirebaseOptions(
    storageBucket: 'quikgroceries.firebasestorage.app',
    apiKey: 'AIzaSyAP3YkC0R7qvX28VbNZ2L486lRCA4hRH4c',
    appId: '1:970937777233:web:5a78d782494d55836e0c70',
    messagingSenderId: '970937777233',
    projectId: 'quikgroceries',
  );
}
