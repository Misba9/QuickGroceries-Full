import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:quickgrocery/core/review/review_config.dart';

/// Wraps Google Play In-App Review + Apple SKStoreReviewController via
/// [`in_app_review`], with store-listing fallbacks.
class StoreReviewService {
  StoreReviewService({
    ReviewConfig config = ReviewConfig.defaults,
    InAppReview? inAppReview,
    http.Client? httpClient,
  })  : _config = config,
        _inAppReview = inAppReview ?? InAppReview.instance,
        _http = httpClient ?? http.Client();

  final ReviewConfig _config;
  final InAppReview _inAppReview;
  final http.Client _http;

  /// Returns true when the platform reports the native API as available.
  Future<bool> isAvailable() async {
    try {
      return await _inAppReview.isAvailable();
    } catch (e) {
      if (kDebugMode) debugPrint('[OrderReview] isAvailable failed: $e');
      return false;
    }
  }

  /// Requests the system in-app review sheet.
  ///
  /// The OS may silently no-op (Apple quota / Play eligibility). Callers should
  /// treat this as best-effort and optionally offer [openStoreListing].
  Future<bool> requestReview() async {
    try {
      final available = await isAvailable();
      if (!available) {
        if (kDebugMode) {
          debugPrint('[OrderReview] native review API unavailable');
        }
        return false;
      }
      await _inAppReview.requestReview();
      if (kDebugMode) debugPrint('[OrderReview] requestReview() invoked');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[OrderReview] requestReview error: $e');
      return false;
    }
  }

  /// Opens the public store listing (always reachable; not quota-limited).
  Future<bool> openStoreListing() async {
    try {
      var appStoreId = _config.iosAppStoreId.trim();
      if (appStoreId.isEmpty &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        appStoreId = await _lookupAppStoreId(_config.iosBundleId) ?? '';
      }

      if (appStoreId.isNotEmpty) {
        await _inAppReview.openStoreListing(appStoreId: appStoreId);
        return true;
      }

      // Android / fallback: open Play Store URL.
      final uri = Uri.parse(_config.playStoreUrl);
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('[OrderReview] openStoreListing error: $e');
      return false;
    }
  }

  /// Resolves the numeric App Store id from the bundle id (iTunes Lookup API).
  Future<String?> _lookupAppStoreId(String bundleId) async {
    if (bundleId.isEmpty) return null;
    try {
      final uri = Uri.https(
        'itunes.apple.com',
        '/lookup',
        {'bundleId': bundleId},
      );
      final res = await _http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final id = first['trackId'];
      return id?.toString();
    } catch (e) {
      if (kDebugMode) debugPrint('[OrderReview] iTunes lookup failed: $e');
      return null;
    }
  }
}
