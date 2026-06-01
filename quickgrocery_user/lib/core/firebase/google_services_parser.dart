import 'dart:convert';

import 'package:flutter/services.dart';

/// Parsed fields from `android/app/google-services.json`.
class GoogleServicesConfig {
  const GoogleServicesConfig({
    required this.projectId,
    required this.projectNumber,
    required this.storageBucket,
    required this.clients,
  });

  final String projectId;
  final String projectNumber;
  final String storageBucket;
  final List<GoogleServicesClient> clients;

  GoogleServicesClient? clientForPackage(String packageName) {
    final matches =
        clients.where((c) => c.packageName == packageName).toList();
    if (matches.isEmpty) return null;
    return matches.first;
  }

  GoogleServicesClient? clientForAppId(String appId) {
    try {
      return clients.firstWhere((c) => c.mobileSdkAppId == appId);
    } catch (_) {
      return null;
    }
  }

  static Future<GoogleServicesConfig?> loadFromAssets({
    String assetPath = 'android/app/google-services.json',
  }) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return parse(raw);
    } catch (_) {
      return null;
    }
  }

  static GoogleServicesConfig? parse(String rawJson) {
    try {
      final json = jsonDecode(rawJson) as Map<String, dynamic>;
      final projectInfo = json['project_info'] as Map<String, dynamic>? ?? {};
      final clientList = json['client'] as List<dynamic>? ?? [];
      final clients = <GoogleServicesClient>[];
      for (final entry in clientList) {
        final client = GoogleServicesClient.fromJson(entry as Map<String, dynamic>);
        if (client.packageName.isNotEmpty) {
          clients.add(client);
        }
      }
      return GoogleServicesConfig(
        projectId: projectInfo['project_id'] as String? ?? '',
        projectNumber: projectInfo['project_number'] as String? ?? '',
        storageBucket: projectInfo['storage_bucket'] as String? ?? '',
        clients: clients,
      );
    } catch (_) {
      return null;
    }
  }
}

class GoogleServicesClient {
  const GoogleServicesClient({
    required this.mobileSdkAppId,
    required this.packageName,
    required this.apiKey,
    required this.oauthClients,
  });

  final String mobileSdkAppId;
  final String packageName;
  final String apiKey;
  final List<GoogleOAuthClient> oauthClients;

  int get oauthClientCount => oauthClients.length;

  bool get hasAndroidOAuthClient =>
      oauthClients.any((c) => c.clientType == 3 && c.androidPackage != null);

  factory GoogleServicesClient.fromJson(Map<String, dynamic> json) {
    final info = json['client_info'] as Map<String, dynamic>? ?? {};
    final android = info['android_client_info'] as Map<String, dynamic>?;
    final apiKeys = json['api_key'] as List<dynamic>? ?? [];
    final apiKey = apiKeys.isNotEmpty
        ? (apiKeys.first as Map<String, dynamic>)['current_key'] as String? ??
              ''
        : '';
    final oauthRaw = json['oauth_client'] as List<dynamic>? ?? [];
    final oauthClients = oauthRaw
        .map((e) => GoogleOAuthClient.fromJson(e as Map<String, dynamic>))
        .toList();
    return GoogleServicesClient(
      mobileSdkAppId: info['mobilesdk_app_id'] as String? ?? '',
      packageName: android?['package_name'] as String? ?? '',
      apiKey: apiKey,
      oauthClients: oauthClients,
    );
  }
}

class GoogleOAuthClient {
  const GoogleOAuthClient({
    required this.clientId,
    required this.clientType,
    this.androidPackage,
    this.certificateHash,
  });

  final String clientId;
  final int clientType;
  final String? androidPackage;
  final String? certificateHash;

  factory GoogleOAuthClient.fromJson(Map<String, dynamic> json) {
    final androidInfo = json['android_info'] as Map<String, dynamic>?;
    return GoogleOAuthClient(
      clientId: json['client_id'] as String? ?? '',
      clientType: json['client_type'] as int? ?? 0,
      androidPackage: androidInfo?['package_name'] as String?,
      certificateHash: androidInfo?['certificate_hash'] as String?,
    );
  }
}
