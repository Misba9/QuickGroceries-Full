import 'package:flutter/foundation.dart';

/// Safe semver-ish comparison (`1.2.0`, `1.2`, `1.2.0+8` → ignores build).
///
/// Returns:
/// - negative if [a] < [b]
/// - 0 if equal
/// - positive if [a] > [b]
int compareVersions(String a, String b) {
  final left = _parts(a);
  final right = _parts(b);
  final len = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < len; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l.compareTo(r);
  }
  return 0;
}

bool isVersionLower(String installed, String minimum) =>
    compareVersions(installed, minimum) < 0;

bool isVersionHigher(String latest, String installed) =>
    compareVersions(latest, installed) > 0;

List<int> _parts(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return const [0];
  // Strip build metadata (`1.0.7+8`) and prerelease (`1.0.0-beta`).
  final plus = s.indexOf('+');
  if (plus >= 0) s = s.substring(0, plus);
  final dash = s.indexOf('-');
  if (dash >= 0) s = s.substring(0, dash);
  final chunks = s.split('.');
  final out = <int>[];
  for (final c in chunks) {
    final n = int.tryParse(c.replaceAll(RegExp(r'[^0-9]'), ''));
    out.add(n ?? 0);
  }
  if (out.isEmpty) {
    if (kDebugMode) debugPrint('[AppUpdate] version parse failed: "$raw"');
    return const [0];
  }
  return out;
}
