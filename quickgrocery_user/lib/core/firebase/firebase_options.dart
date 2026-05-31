import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase project `quikgroceries` — must match admin panel & Cloud Functions.
///
/// Android uses values from `android/app/google-services.json`.
/// iOS requires `ios/Runner/GoogleService-Info.plist` from Firebase Console
/// (same project). Run `flutterfire configure` if you add the plist.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web uses firebase_bootstrap web options.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBd3A_4BYlsczbs76kU30p11o4-cwkFDK8',
    appId: '1:970937777233:android:bd216adee4a01c456e0c70',
    messagingSenderId: '970937777233',
    projectId: 'quikgroceries',
    storageBucket: 'quikgroceries.firebasestorage.app',
  );

  /// Replace GOOGLE_APP_ID + REVERSED_CLIENT_ID via `flutterfire configure`
  /// after downloading the iOS app from Firebase Console (bundle:
  /// com.ahmed.quickgrocery).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBd3A_4BYlsczbs76kU30p11o4-cwkFDK8',
    appId: '1:970937777233:ios:0000000000000000000000',
    messagingSenderId: '970937777233',
    projectId: 'quikgroceries',
    storageBucket: 'quikgroceries.firebasestorage.app',
    iosBundleId: 'com.ahmed.quickgrocery',
  );

  /// Must match REVERSED_CLIENT_ID in GoogleService-Info.plist / Info.plist.
  static const String iosReversedClientId =
      'com.googleusercontent.apps.970937777233-REPLACE_WITH_FIREBASE_CONSOLE_CLIENT_ID';
}
