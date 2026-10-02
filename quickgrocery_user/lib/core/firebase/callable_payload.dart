import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Map<String, dynamic> sanitizeCallableData(Map<String, dynamic> data) {
  final value = _sanitizeValue(data, r'$');
  return Map<String, dynamic>.from(value as Map);
}

void debugCallableData(String functionName, Map<String, dynamic> payload) {
  if (!kDebugMode) return;
  debugPrint('========== CALLABLE PAYLOAD: $functionName ==========');
  // Redact high-risk keys before any debug dump.
  final safe = Map<String, dynamic>.from(payload);
  for (final key in safe.keys.toList()) {
    final lower = key.toLowerCase();
    if (lower.contains('token') ||
        lower.contains('otp') ||
        lower.contains('phone') ||
        lower.contains('email') ||
        lower.contains('address') ||
        lower.contains('secret') ||
        lower.contains('signature') ||
        lower.contains('payment') ||
        lower.contains('razorpay')) {
      safe[key] = '***';
    }
  }
  debugPrint(const JsonEncoder.withIndent('  ').convert(safe));
  debugPrint(_describeTypes(safe));
}

Object? _sanitizeValue(Object? value, String path) {
  if (value == null ||
      value is String ||
      value is int ||
      value is double ||
      value is bool) {
    return value;
  }
  if (value is num) return value.toDouble();
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
  if (value is GeoPoint) {
    return <String, dynamic>{
      'latitude': value.latitude,
      'longitude': value.longitude,
    };
  }
  if (value is DocumentReference) return value.path;
  if (value is Enum) return value.name;
  if (value is Iterable) {
    return value
        .map((item) => _sanitizeValue(item, '$path[]'))
        .toList(growable: false);
  }
  if (value is Map) {
    return value.map<String, dynamic>((key, item) {
      final stringKey = key.toString();
      return MapEntry(stringKey, _sanitizeValue(item, '$path.$stringKey'));
    });
  }

  throw ArgumentError(
    'Unsupported callable parameter at $path: ${value.runtimeType}',
  );
}

String _describeTypes(Object? value, [String path = r'$']) {
  final lines = <String>[];
  void walk(Object? item, String itemPath) {
    lines.add('$itemPath: ${item.runtimeType}');
    if (item is Map) {
      item.forEach((key, child) => walk(child, '$itemPath.${key.toString()}'));
    } else if (item is List) {
      for (var i = 0; i < item.length; i++) {
        walk(item[i], '$itemPath[$i]');
      }
    }
  }

  walk(value, path);
  return lines.join('\n');
}
