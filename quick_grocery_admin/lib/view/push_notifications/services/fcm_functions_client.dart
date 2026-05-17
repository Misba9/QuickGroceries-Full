import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTPS bridge for FCM admin sends.
///
/// **Mobile / desktop:** Gen2 `onCall` via [cloud_functions] (built-in CORS).
/// **Web:** POST to `*Http` Cloud Functions with `cors({ origin: true })` so
/// localhost and hosted admin panels avoid browser CORS blocks.
class FcmFunctionsClient {
  FcmFunctionsClient({
    FirebaseFunctions? functions,
    FirebaseApp? app,
    http.Client? httpClient,
  })  : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: app ?? Firebase.app(),
              region: _defaultRegion,
            ),
        _http = httpClient ?? http.Client(),
        _projectId = (app ?? Firebase.app()).options.projectId;

  static const _defaultRegion = 'us-central1';

  static final _callableOptions = HttpsCallableOptions(
    timeout: const Duration(seconds: 120),
  );

  final FirebaseFunctions _fn;
  final http.Client _http;
  final String? _projectId;

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('You must be signed in to send notifications.');
    }
  }

  HttpsCallable _callable(String name) => _fn.httpsCallable(
        name,
        options: _callableOptions,
      );

  String _httpFunctionUrl(String httpFunctionName) {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) {
      throw StateError('Firebase projectId is missing.');
    }
    return 'https://$_defaultRegion-$projectId.cloudfunctions.net/$httpFunctionName';
  }

  Future<Map<String, dynamic>> _invoke(
    String callableName,
    String httpFunctionName,
    Map<String, dynamic> payload,
  ) async {
    await _ensureSignedIn();

    if (kIsWeb) {
      return _postHttp(httpFunctionName, payload);
    }

    final res = await _callable(callableName).call(payload);
    return _mapResponse(res.data);
  }

  Future<Map<String, dynamic>> _postHttp(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to send notifications.');
    }
    final token = await user.getIdToken();
    final url = Uri.parse(_httpFunctionUrl(functionName));

    final response = await _http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 120));

    Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(response.body);
      parsed = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      throw Exception(
        'Invalid response (${response.statusCode}): ${response.body}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        parsed['error']?.toString() ??
            'Request failed (${response.statusCode})',
      );
    }

    if (parsed['success'] == false) {
      throw Exception(parsed['error']?.toString() ?? 'Request failed');
    }

    return parsed;
  }

  Map<String, dynamic> _mapResponse(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'success': true, 'ok': true};
  }

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
    return _invoke(
      'sendTopicNotification',
      'sendTopicNotificationHttp',
      <String, dynamic>{
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
      },
    );
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
    return _invoke(
      'sendSingleNotification',
      'sendSingleNotificationHttp',
      <String, dynamic>{
        'userId': userId,
        'title': title,
        'message': message,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        if (deepLink != null && deepLink.isNotEmpty) 'deepLink': deepLink,
        if (redirectType != null && redirectType.isNotEmpty)
          'redirectType': redirectType,
        if (ctaLabel != null && ctaLabel.isNotEmpty) 'ctaLabel': ctaLabel,
        if (soundType != null && soundType.isNotEmpty) 'soundType': soundType,
      },
    );
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
    final payload = <String, dynamic>{
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
    };

    if (kIsWeb) {
      // Schedule uses callable only (no HTTP mirror yet); Gen2 cors:true handles web.
      final res = await _callable('scheduleNotification').call(payload);
      return _mapResponse(res.data);
    }

    final res = await _callable('scheduleNotification').call(payload);
    return _mapResponse(res.data);
  }

  Future<Map<String, dynamic>> syncAdminClaimsFromAdmins() async {
    await _ensureSignedIn();
    final res = await _callable('syncAdminClaimsFromAdmins').call();
    return _mapResponse(res.data);
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
    return _mapResponse(res.data);
  }
}
