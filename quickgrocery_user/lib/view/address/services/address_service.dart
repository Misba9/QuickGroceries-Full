import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:latlong2/latlong.dart';

class AddressService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _addresstype = 'HOME';
  bool _isLoading = false;
  /// When non-null, [addAddress] updates this document instead of creating one.
  String? _editingAddressId;
  List<AddressModel>? addresses;
  LatLng? latLng;
  String _address = 'Loading...';
  String? _pinCode; // Store extracted pin code
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController areaController = TextEditingController();
  String get address => _address;
  String? get pinCode => _pinCode;
  int _selectedIndex = 0;
  final dateTime = DateTime.now();
  void onLatlongChanged(LatLng ponint) {
    latLng = ponint;
    notifyListeners();
    print(latLng.toString());
  }

  Future<void> onLatLongUpdatedinHome(BuildContext context, LatLng lat) async {
    latLng = lat;
    List<Placemark> placemarks = await placemarkFromCoordinates(
      lat.latitude,
      lat.longitude,
    );
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];

      _address =
          '${place.subLocality} ${place.street}, ${place.locality} ${place.postalCode} ${place.country}';
      _pinCode = place.postalCode; // Extract pin code
      addressController.text = _address;
      notifyListeners();

      // checkServiceArea(context, vendor!.lat, vendor!.lng);
      Navigator.pop(context);
    }
    notifyListeners();
  }

  Future<void> getCurrentLocation(BuildContext context) async {
    try {
      _isLoading = true;

      // 🔹 Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLoading = false;
        notifyListeners();
        _showLocationDialog(context);
        return;
      }

      // 🔹 Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _isLoading = false;
          notifyListeners();
          _showLocationDialog(context);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isLoading = false;
        notifyListeners();
        _showLocationDialog(context);
        return;
      }

      // 🔹 Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latLng = LatLng(position.latitude, position.longitude);

      // 🔹 Convert coordinates to readable address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        _address =
            '${place.subLocality ?? ''} ${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}';
        _pinCode = place.postalCode; // Extract pin code
        addressController.text = _address;
        log(latLng.toString());
      } else {
        _address = 'Address not found';
        _pinCode = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _address = 'Error fetching location';
      notifyListeners();
      debugPrint('Error getting location: $e');
    }
  }

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Location'),
        content: const Text(
          'Please enable location services:\n\n'
          '1. Open Settings\n'
          '2. Go to Location\n'
          '3. Turn it ON',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Clears the form for a brand-new address (checkout / first-time add).
  void prepareNewAddress() {
    _editingAddressId = null;
    nameController.clear();
    mobileController.clear();
    addressController.clear();
    areaController.clear();
    _addresstype = 'HOME';
    notifyListeners();
  }

  /// Prefills controllers for editing an existing saved address.
  void loadAddressForEdit(AddressModel model) {
    _editingAddressId = model.id;
    nameController.text = model.name;
    mobileController.text = model.mobile;
    addressController.text = model.address;
    areaController.text = model.area;
    _addresstype = model.type;
    notifyListeners();
  }

  Future<void> addAddress(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      if (_editingAddressId != null) {
        await _firestore.collection('address').doc(_editingAddressId).update({
          'name': nameController.text.trim(),
          'mobile': mobileController.text.trim(),
          'address': addressController.text.trim(),
          'area': areaController.text.trim(),
          'type': _addresstype,
          'lastEdited': FieldValue.serverTimestamp(),
        });
      } else {
        final docRef = await _firestore.collection('address').add({
          'id': '',
          'name': nameController.text.trim(),
          'mobile': mobileController.text.trim(),
          'address': addressController.text.trim(),
          'area': areaController.text.trim(),
          'type': _addresstype,
          'createdAt': FieldValue.serverTimestamp(),
          'lastEdited': FieldValue.serverTimestamp(),
          'user_id': uid,
        });
        await docRef.update({'id': docRef.id});
      }
      _isLoading = false;
      _editingAddressId = null;
      notifyListeners();
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateAddress(String newAddress) {
    _address = newAddress;
    // Try to extract pin code from address string
    _pinCode = _extractPinCodeFromAddress(newAddress);
    notifyListeners();
  }

  /// Extract pin code from address string
  /// Looks for 6-digit numbers (Indian pin code format)
  String? _extractPinCodeFromAddress(String address) {
    // Try to find a 6-digit number in the address
    final regex = RegExp(r'\b\d{6}\b');
    final match = regex.firstMatch(address);
    return match?.group(0);
  }

  /// Set pin code directly
  void setPinCode(String? pinCode) {
    _pinCode = pinCode;
    notifyListeners();
  }

  int get selectedIndex => _selectedIndex;

  bool get isLoading => _isLoading;
  String get addressType => _addresstype;

  void addressTypeChange(String type) {
    _addresstype = type;
    notifyListeners();
  }

  void selectedIndexChange(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  Future<void> getAddress() async {
    try {
      // Get the products collection from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('address')
          .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      // Map Firestore documents to ProductModel instances
      addresses = snapshot.docs.map((doc) {
        return AddressModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners(); // Notify UI or listeners if you're using a state management solution
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> deleteAddress(BuildContext context, String id) async {
    await _firestore.collection('address').doc(id).delete();
    await getAddress();
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Hard-delete without popping routes — used after swipe-to-dismiss UI.
  Future<void> removeAddress(String id) async {
    await _firestore.collection('address').doc(id).delete();
    await getAddress();
  }
}
