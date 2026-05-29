import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/models/delivery_zone_model.dart';

class DeliveryZoneService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DeliveryZoneModel> _deliveryZones = [];
  bool _isLoading = false;
  bool _lastLookupFailed = false;

  List<DeliveryZoneModel> get deliveryZones => _deliveryZones;
  bool get isLoading => _isLoading;
  bool get lastLookupFailed => _lastLookupFailed;

  /// Fetch all delivery zones from Firestore
  Future<void> fetchDeliveryZones() async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('delivery_zones')
          .orderBy('created_at', descending: true)
          .get();

      _deliveryZones = snapshot.docs.map((doc) {
        return DeliveryZoneModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching delivery zones: $e');
    }
  }

  /// Get delivery zone by pin code
  /// Returns the first active zone that contains the pin code, or null if not found
  Future<DeliveryZoneModel?> getZoneByPinCode(String pinCode) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('delivery_zones')
          .where('pin_codes', arrayContains: pinCode)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _lastLookupFailed = false;
        return null;
      }

      _lastLookupFailed = false;
      return DeliveryZoneModel.fromFirestore(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    } catch (e) {
      _lastLookupFailed = true;
      debugPrint('Error getting zone by pin code: $e');
      return null;
    }
  }

  /// Check if a pin code is serviceable
  Future<bool> isPinCodeServiceable(String pinCode) async {
    final zone = await getZoneByPinCode(pinCode);
    return zone != null;
  }
}
