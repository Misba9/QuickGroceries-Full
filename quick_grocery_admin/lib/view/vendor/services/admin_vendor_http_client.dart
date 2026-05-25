import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quick_grocery_admin/core/firebase/admin_firebase_options.dart';

/// CORS-safe HTTP calls for Flutter Web when callable transport fails.
class AdminVendorHttpClient {
  static const _region = 'us-central1';
  static String get _projectId => AdminFirebaseOptions.current.projectId;

  static String _url(String name) =>
      'https://$_region-$_projectId.cloudfunctions.net/$name';

  static Future<String?> _bearerToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  static Future<Map<String, dynamic>> post(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final token = await _bearerToken();
    if (token == null) {
      throw Exception('Sign in to the admin panel first.');
    }

    if (kDebugMode) {
      debugPrint('[AdminVendorHttp] POST $functionName');
    }

    final res = await http.post(
      Uri.parse(_url(functionName)),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final err = data['error']?.toString() ?? res.body;
      throw Exception(err.isEmpty ? 'HTTP ${res.statusCode}' : err);
    }

    if (data['success'] == false) {
      throw Exception(data['error']?.toString() ?? 'Request failed.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> migrateVendorAuth({
    required String vendorDocId,
    required String password,
  }) =>
      post('adminMigrateVendorAuthHttp', {
        'vendorDocId': vendorDocId,
        'password': password,
      });

  static Future<Map<String, dynamic>> restoreVendorAuth({
    String? vendorDocId,
    String? shopName,
    required String password,
  }) =>
      post('adminRestoreVendorAuthHttp', {
        if (vendorDocId != null && vendorDocId.isNotEmpty)
          'vendorDocId': vendorDocId,
        if (shopName != null && shopName.isNotEmpty) 'shopName': shopName,
        'password': password,
      });
}
