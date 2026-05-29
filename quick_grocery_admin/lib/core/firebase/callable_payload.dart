import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Map<String, dynamic> sanitizeCallableData(Map<String, dynamic> data) {
  final value = _sanitizeValue(data, r'$');
  return Map<String, dynamic>.from(value as Map);
}

void debugCallableData(String functionName, Map<String, dynamic> payload) {
  debugPrint('========== CALLABLE PAYLOAD: $functionName ==========');
  debugPrint(const JsonEncoder.withIndent('  ').convert(payload));
  debugPrint(_describeTypes(payload));
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
    return {'latitude': value.latitude, 'longitude': value.longitude};
  }
  if (value is DocumentReference) return value.path;
  if (value is Enum) return value.name;
  if (value is Iterable) {
    return value
        .map((v) => _sanitizeValue(v, '$path[]'))
        .toList(growable: false);
  }
  if (value is Map) {
    return value.map<String, dynamic>((key, v) {
      final stringKey = key.toString();
      return MapEntry(stringKey, _sanitizeValue(v, '$path.$stringKey'));
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
