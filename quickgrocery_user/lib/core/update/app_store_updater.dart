import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:quickgrocery/core/update/store_links.dart';
import 'package:quickgrocery/core/update/version_compare.dart';

/// iOS App Store version check + open listing (no Android-style IAU).
class AppStoreUpdater {
  AppStoreUpdater({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  String? _cachedAppStoreId;

  /// Returns the App Store version string, or null on failure.
  Future<String?> fetchStoreVersion({
    String bundleId = StoreLinks.iosBundleId,
  }) async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return null;
    }
    try {
      final uri = Uri.https('itunes.apple.com', '/lookup', {
        'bundleId': bundleId,
      });
      final res = await _http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) {
        if (kDebugMode) {
          debugPrint('[AppUpdate] App Store lookup empty for $bundleId');
        }
        return null;
      }
      final first = results.first as Map<String, dynamic>;
      _cachedAppStoreId = first['trackId']?.toString();
      final version = first['version']?.toString();
      if (kDebugMode) {
        debugPrint(
          '[AppUpdate] App Store version=$version id=$_cachedAppStoreId',
        );
      }
      return version;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] App Store lookup failed: $e');
      return null;
    }
  }

  /// True when App Store version is newer than [installed].
  Future<bool> isUpdateAvailable(String installed) async {
    final store = await fetchStoreVersion();
    if (store == null || store.isEmpty) return false;
    return isVersionHigher(store, installed);
  }

  Future<bool> openAppStore() async {
    try {
      var id = StoreLinks.iosAppStoreId.trim();
      if (id.isEmpty) {
        id = (_cachedAppStoreId ?? '').trim();
      }
      if (id.isEmpty) {
        await fetchStoreVersion();
        id = (_cachedAppStoreId ?? '').trim();
      }
      if (id.isEmpty) {
        if (kDebugMode) {
          debugPrint('[AppUpdate] App Store id unknown — cannot open listing');
        }
        return false;
      }
      final uri = Uri.parse(StoreLinks.ios(appStoreId: id));
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] open App Store failed: $e');
    }
    return false;
  }
}
