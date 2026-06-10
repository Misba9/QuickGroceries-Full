import 'package:quick_grocery_admin/model/delivery_zone_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeliveryZoneService extends ChangeNotifier {
  List<DeliveryZoneModel>? deliveryZones;
  bool isLoading = false;

  // Controllers for add/edit form
  TextEditingController zoneNameController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();
  TextEditingController deliveryChargeController = TextEditingController();
  List<String> pinCodesList = [];
  String? editingZoneId;

  Future<void> fetchDeliveryZones() async {
    try {
      isLoading = true;
      notifyListeners();

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('delivery_zones')
          .orderBy('created_at', descending: true)
          .get();

      deliveryZones = snapshot.docs.map((doc) {
        return DeliveryZoneModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching delivery zones: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDeliveryZone(BuildContext context) async {
    if (zoneNameController.text.isEmpty) {
      showValidationDialog(context, "Zone name cannot be empty.");
      return;
    }
    if (cityController.text.isEmpty) {
      showValidationDialog(context, "City cannot be empty.");
      return;
    }
    if (pinCodesList.isEmpty) {
      showValidationDialog(context, "Please add at least one pin code.");
      return;
    }
    if (deliveryChargeController.text.isEmpty) {
      showValidationDialog(context, "Delivery charge cannot be empty.");
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      double deliveryCharge =
          double.tryParse(deliveryChargeController.text) ?? 0.0;
      if (deliveryCharge < 0) {
        showValidationDialog(context, "Delivery charge cannot be negative.");
        isLoading = false;
        notifyListeners();
        return;
      }

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('delivery_zones')
          .add({
            'id': '',
            'zone_name': zoneNameController.text.trim(),
            'city': cityController.text.trim(),
            'pin_codes': pinCodesList,
            'delivery_charge': deliveryCharge,
            'is_active': true,
            'created_at': FieldValue.serverTimestamp(),
            'last_edited': FieldValue.serverTimestamp(),
          });

      String zoneId = docRef.id;
      await docRef.update({'id': zoneId});

      isLoading = false;
      showSuccessDialog(context, "Delivery zone added successfully!");
      resetFields();
      fetchDeliveryZones();
      notifyListeners();
    } catch (e) {
      print('Error adding delivery zone: $e');
      isLoading = false;
      showValidationDialog(context, "Error adding delivery zone: $e");
      notifyListeners();
    }
  }

  Future<void> updateDeliveryZone(BuildContext context, String zoneId) async {
    if (zoneNameController.text.isEmpty) {
      showValidationDialog(context, "Zone name cannot be empty.");
      return;
    }
    if (cityController.text.isEmpty) {
      showValidationDialog(context, "City cannot be empty.");
      return;
    }
    if (pinCodesList.isEmpty) {
      showValidationDialog(context, "Please add at least one pin code.");
      return;
    }
    if (deliveryChargeController.text.isEmpty) {
      showValidationDialog(context, "Delivery charge cannot be empty.");
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      double deliveryCharge =
          double.tryParse(deliveryChargeController.text) ?? 0.0;
      if (deliveryCharge < 0) {
        showValidationDialog(context, "Delivery charge cannot be negative.");
        isLoading = false;
        notifyListeners();
        return;
      }

      await FirebaseFirestore.instance
          .collection('delivery_zones')
          .doc(zoneId)
          .update({
            'zone_name': zoneNameController.text.trim(),
            'city': cityController.text.trim(),
            'pin_codes': pinCodesList,
            'delivery_charge': deliveryCharge,
            'last_edited': FieldValue.serverTimestamp(),
          });

      isLoading = false;
      showSuccessDialog(context, "Delivery zone updated successfully!");
      resetFields();
      fetchDeliveryZones();
      notifyListeners();
    } catch (e) {
      print('Error updating delivery zone: $e');
      isLoading = false;
      showValidationDialog(context, "Error updating delivery zone: $e");
      notifyListeners();
    }
  }

  Future<void> deleteDeliveryZone(BuildContext context, String zoneId) async {
    try {
      await FirebaseFirestore.instance
          .collection('delivery_zones')
          .doc(zoneId)
          .delete();

      showSuccessDialog(context, "Delivery zone deleted successfully!");
      fetchDeliveryZones();
    } catch (e) {
      print('Error deleting delivery zone: $e');
      showValidationDialog(context, "Error deleting delivery zone: $e");
    }
  }

  Future<void> toggleZoneStatus(String zoneId, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('delivery_zones')
          .doc(zoneId)
          .update({
            'is_active': !isActive,
            'last_edited': FieldValue.serverTimestamp(),
          });

      fetchDeliveryZones();
    } catch (e) {
      print('Error toggling zone status: $e');
    }
  }

  void loadZoneForEdit(DeliveryZoneModel zone) {
    editingZoneId = zone.id;
    zoneNameController.text = zone.zoneName;
    cityController.text = zone.city;
    pinCodesList = List<String>.from(zone.pinCodes);
    deliveryChargeController.text = zone.deliveryCharge.toString();
    notifyListeners();
  }

  void addPinCode() {
    final pinCode = pinCodeController.text.trim();
    if (pinCode.isNotEmpty && !pinCodesList.contains(pinCode)) {
      pinCodesList.add(pinCode);
      pinCodeController.clear();
      notifyListeners();
    }
  }

  void removePinCode(String pinCode) {
    pinCodesList.remove(pinCode);
    notifyListeners();
  }

  void resetFields() {
    zoneNameController.clear();
    cityController.clear();
    pinCodeController.clear();
    deliveryChargeController.clear();
    pinCodesList.clear();
    editingZoneId = null;
    notifyListeners();
  }

  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("Success", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void showValidationDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                "Validation Error",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Text("OK", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<DeliveryZoneModel?> getZoneByPinCode(String pinCode) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('delivery_zones')
          .where('pin_codes', arrayContains: pinCode)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DeliveryZoneModel.fromFirestore(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting zone by pin code: $e');
      return null;
    }
  }
}
