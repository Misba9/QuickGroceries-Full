import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// HTTPS callable bridge — FCM sends run in Cloud Functions (Gen2 `onCall`).
///
/// Uses the same [FirebaseApp] as the rest of the admin panel and explicit
/// [HttpsCallableOptions] so Flutter Web matches the callable protocol (no raw
/// `fetch` / CORS pitfalls from hand-rolled HTTP).
class FcmFunctionsClient {
  FcmFunctionsClient({
    FirebaseFunctions? functions,
    FirebaseApp? app,
  }) : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: app ?? Firebase.app(),
              region: _defaultRegion,
            );

  static const _defaultRegion = 'us-central1';

  /// Longer timeout for cold starts + FCM fan-out.
  static final _callableOptions = HttpsCallableOptions(
    timeout: const Duration(seconds: 120),
  );

  final FirebaseFunctions _fn;

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('You must be signed in to send notifications.');
    }
  }

  HttpsCallable _callable(String name) => _fn.httpsCallable(
        name,
        options: _callableOptions,
      );

  Future<Map<String, dynamic>> sendTopicNotification({
    required String title,
    required String message,
    String? topic,
    String? targetAudience,
    String? imageUrl,
    String? deepLink,
    String? redirectType,
    String? ctaLabel,
    String? soundType,
  }) async {
    await _ensureSignedIn();
    final res = await _callable('sendTopicNotification').call(<String, dynamic>{
      'title': title,
      'message': message,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
      if (targetAudience != null && targetAudience.isNotEmpty)
        'targetAudience': targetAudience,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (deepLink != null && deepLink.isNotEmpty) 'deepLink': deepLink,
      if (redirectType != null && redirectType.isNotEmpty)
        'redirectType': redirectType,
      if (ctaLabel != null && ctaLabel.isNotEmpty) 'ctaLabel': ctaLabel,
      if (soundType != null && soundType.isNotEmpty) 'soundType': soundType,
    });
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'ok': true};
  }

  Future<Map<String, dynamic>> sendSingleNotification({
    required String userId,
    required String title,
    required String message,
    String? imageUrl,
    String? deepLink,
    String? redirectType,
    String? ctaLabel,
    String? soundType,
  }) async {
    await _ensureSignedIn();
    final res = await _callable('sendSingleNotification').call(<String, dynamic>{
      'userId': userId,
      'title': title,
      'message': message,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (deepLink != null && deepLink.isNotEmpty) 'deepLink': deepLink,
      if (redirectType != null && redirectType.isNotEmpty)
        'redirectType': redirectType,
      if (ctaLabel != null && ctaLabel.isNotEmpty) 'ctaLabel': ctaLabel,
      if (soundType != null && soundType.isNotEmpty) 'soundType': soundType,
    });
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'ok': true};
  }

  Future<Map<String, dynamic>> scheduleNotification({
    required String title,
    required String message,
    required DateTime scheduledAt,
    String kind = 'topic',
    String? userId,
    String? topic,
    String? targetAudience,
    String? imageUrl,
    String? deepLink,
    String? redirectType,
    String? ctaLabel,
    String? soundType,
  }) async {
    await _ensureSignedIn();
    final res = await _callable('scheduleNotification').call(<String, dynamic>{
      'title': title,
      'message': message,
      'scheduledAt': scheduledAt.toIso8601String(),
      'kind': kind,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
      if (targetAudience != null && targetAudience.isNotEmpty)
        'targetAudience': targetAudience,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (deepLink != null && deepLink.isNotEmpty) 'deepLink': deepLink,
      if (redirectType != null && redirectType.isNotEmpty)
        'redirectType': redirectType,
      if (ctaLabel != null && ctaLabel.isNotEmpty) 'ctaLabel': ctaLabel,
      if (soundType != null && soundType.isNotEmpty) 'soundType': soundType,
    });
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'ok': true};
  }

  Future<Map<String, dynamic>> syncAdminClaimsFromAdmins() async {
    await _ensureSignedIn();
    final res = await _callable('syncAdminClaimsFromAdmins').call();
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'ok': true};
  }

  Future<Map<String, dynamic>> setAdminClaims({
    String? uid,
    String? bootstrapSecret,
  }) async {
    await _ensureSignedIn();
    final res = await _callable('setAdminClaims').call(<String, dynamic>{
      if (uid != null && uid.isNotEmpty) 'uid': uid,
      if (bootstrapSecret != null && bootstrapSecret.isNotEmpty)
        'bootstrapSecret': bootstrapSecret,
    });
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'ok': true};
  }
}
