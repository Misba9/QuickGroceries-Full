import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quickgrocery/models/delivery_zone_model.dart';

/// Shared Firestore lookup for admin-configured [delivery_zones].
abstract final class DeliveryZoneLookup {
  static String normalizePin(String raw) => raw.trim();

  /// Resolves a postal / pin code from stored value or address text.
  static String? resolvePin({
    String? storedPin,
    String? addressText,
  }) {
    final stored = storedPin?.trim();
    if (stored != null && stored.isNotEmpty) {
      return normalizePin(stored);
    }
    final text = addressText?.trim();
    if (text == null || text.isEmpty) return null;

    for (final pattern in [
      RegExp(r'\b\d{6}\b'), // India
      RegExp(r'\b\d{5}\b'), // Pakistan, US, etc.
      RegExp(r'\b\d{4}\b'),
    ]) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(0);
    }
    return null;
  }

  /// Whether any active delivery zone exists (restrictions enabled).
  static Future<bool> hasActiveZones(FirebaseFirestore firestore) async {
    try {
      final snap = await firestore
          .collection('delivery_zones')
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('[DeliveryZoneLookup] hasActiveZones: $e');
      return false;
    }
  }

  /// Finds an active zone containing [rawPin].
  ///
  /// Uses a single-field [arrayContains] query (no composite index) and
  /// filters [is_active] on the client.
  static Future<DeliveryZoneModel?> findActiveZoneByPin(
    FirebaseFirestore firestore,
    String rawPin,
  ) async {
    final pin = normalizePin(rawPin);
    if (pin.isEmpty) return null;

    try {
      final snap = await firestore
          .collection('delivery_zones')
          .where('pin_codes', arrayContains: pin)
          .limit(10)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['is_active'] == false) continue;
        return DeliveryZoneModel.fromFirestore(data, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[DeliveryZoneLookup] findActiveZoneByPin: $e');
      rethrow;
    }
  }
}

enum DeliveryZoneCheckResult {
  serviceable,
  notServiceable,
  noZonesConfigured,
  missingPin,
  lookupFailed,
}
