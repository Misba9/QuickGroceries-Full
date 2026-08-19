import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickgrocery/core/user/user_profile_repository.dart';
import 'package:quickgrocery/core/delivery/delivery_zone_lookup.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/view/address/data/guest_address_store.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressService extends ChangeNotifier {
  AddressService() {
    _restoreFuture = _restoreFromPrefs();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserProfileRepository _profileRepo = UserProfileRepository();
  static const _cacheAddressIdKey = 'selected_address_id';
  static const _cacheLatKey = 'selected_address_latitude';
  static const _cacheLngKey = 'selected_address_longitude';
  static const _cachePinKey = 'selected_address_pin_code';
  static const _cacheServiceableKey = 'selected_address_serviceable';
  static const _cacheTimestampKey = 'selected_address_validated_at';
  static const _validationTtl = Duration(hours: 12);

  late final Future<void> _restoreFuture;
  Future<void> get ready => _restoreFuture;

  String _addresstype = 'HOME';
  bool _isLoading = false;

  /// When non-null, [addAddress] updates this document instead of creating one.
  String? _editingAddressId;
  List<AddressModel>? addresses;
  LatLng? latLng;
  String _address = 'Loading...';
  String? _pinCode;
  String? _selectedAddressId;
  bool _isAddressValidated = false;
  bool _cachedServiceable = false;
  DateTime? _validatedAt;
  bool _cacheRestored = false;
  int _validationMutation = 0;

  /// Session-only: skip service-area gate until explicit invalidation or expiry.
  bool _sessionServiceCheckBypass = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController areaController = TextEditingController();
  String get address => _address;
  String? get pinCode => _pinCode;
  String? get selectedAddressId => _selectedAddressId;
  bool get isAddressValidated => _isAddressValidated;
  bool get cachedServiceable => _cachedServiceable;
  bool get cacheRestored => _cacheRestored;
  bool get validationExpired {
    final at = _validatedAt;
    if (at == null) return true;
    return DateTime.now().difference(at) > _validationTtl;
  }

  bool get hasValidatedServiceableAddress =>
      _sessionServiceCheckBypass ||
      (_isAddressValidated && _cachedServiceable && !validationExpired);

  /// True when the app should not show the service-area blocker this session.
  bool get shouldBypassServiceAreaCheck => hasValidatedServiceableAddress;

  bool hasValidatedServiceablePin(String? pin) {
    if (!hasValidatedServiceableAddress) return false;
    final cachedPin = _pinCode?.trim();
    final target = pin?.trim();
    if (cachedPin == null || cachedPin.isEmpty) return true;
    if (target == null || target.isEmpty) return true;
    return cachedPin == target;
  }

  /// Pin for the currently selected saved address, if any.
  String? get activeDeliveryPin {
    final fromStored = DeliveryZoneLookup.resolvePin(storedPin: _pinCode);
    if (fromStored != null && fromStored.isNotEmpty) return fromStored;

    final fromCurrent = DeliveryZoneLookup.resolvePin(addressText: _address);
    if (fromCurrent != null && fromCurrent.isNotEmpty) return fromCurrent;

    final list = addresses;
    if (list == null || list.isEmpty) return null;
    final i = _selectedIndex.clamp(0, list.length - 1);
    final a = list[i];
    return DeliveryZoneLookup.resolvePin(
      addressText: '${a.address} ${a.area}',
    );
  }

  bool get hasSavedAddresses =>
      addresses != null && addresses!.isNotEmpty;

  int _selectedIndex = 0;
  Future<void> _deleteChain = Future.value();
  final dateTime = DateTime.now();
  void onLatlongChanged(LatLng ponint, {bool invalidateValidation = false}) {
    latLng = ponint;
    if (invalidateValidation) {
      invalidateAddressValidation();
    }
    notifyListeners();
  }

  Future<void> onLatLongUpdatedinHome(BuildContext context, LatLng lat) async {
    latLng = lat;
    invalidateAddressValidation(notify: false);
    List<Placemark> placemarks = await placemarkFromCoordinates(
      lat.latitude,
      lat.longitude,
    );
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];

      _address =
          '${place.subLocality} ${place.street}, ${place.locality} ${place.postalCode} ${place.country}';
      _pinCode = place.postalCode;
      addressController.text = _address;
      notifyListeners();

      Navigator.pop(context);
    }
    notifyListeners();
  }

  Future<void> getCurrentLocation(
    BuildContext context, {
    bool force = false,
  }) async {
    if (!force && hasValidatedServiceableAddress) {
      debugPrint('AddressService: using cached validated address');
      return;
    }
    if (!force && hasSavedAddresses) {
      debugPrint('AddressService: using saved address — skip GPS');
      return;
    }
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

      // Check permission — do not re-prompt if already granted.
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
      if (force) {
        invalidateAddressValidation(notify: false);
      }

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
    mobileController.text = _verifiedMobileDigits();
    addressController.clear();
    areaController.clear();
    _addresstype = 'HOME';
    notifyListeners();
  }

  /// Prefills controllers for editing an existing saved address.
  void loadAddressForEdit(AddressModel model) {
    _editingAddressId = model.id;
    nameController.text = model.name;
    final savedMobile = model.mobile.trim();
    mobileController.text = savedMobile.isNotEmpty
        ? savedMobile
        : _verifiedMobileDigits();
    addressController.text = model.address;
    areaController.text = model.area;
    _addresstype = model.type;
    notifyListeners();
  }

  /// Verified login phone as 10-digit local number for address forms.
  String _verifiedMobileDigits() {
    return AddressModel.localMobileDigits(
      FirebaseAuth.instance.currentUser?.phoneNumber,
    );
  }

  String _mobileForSave() {
    final entered = mobileController.text.trim();
    if (entered.isNotEmpty) return entered;
    return _verifiedMobileDigits();
  }

  Future<void> addAddress(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      if (_editingAddressId != null) {
        await _firestore.collection('address').doc(_editingAddressId).update({
          'name': nameController.text.trim(),
          'mobile': _mobileForSave(),
          'address': addressController.text.trim(),
          'area': areaController.text.trim(),
          'type': _addresstype,
          'lastEdited': FieldValue.serverTimestamp(),
        });
        _selectedAddressId = _editingAddressId;
      } else {
        final docRef = await _firestore.collection('address').add({
          'id': '',
          'name': nameController.text.trim(),
          'mobile': _mobileForSave(),
          'address': addressController.text.trim(),
          'area': areaController.text.trim(),
          'type': _addresstype,
          'createdAt': FieldValue.serverTimestamp(),
          'lastEdited': FieldValue.serverTimestamp(),
          'user_id': uid,
        });
        await docRef.update({'id': docRef.id});
        _selectedAddressId = docRef.id;
      }
      _address = '${addressController.text.trim()}, ${areaController.text.trim()}';
      _pinCode = DeliveryZoneLookup.resolvePin(
          addressText: _address,
          storedPin: _pinCode,
        ) ??
        _pinCode;
      await invalidateAddressValidation(notify: false);
      _isLoading = false;
      _editingAddressId = null;
      notifyListeners();
      await _syncProfileAddress();
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateAddress(String newAddress) {
    _address = newAddress;
    // Try to extract pin code from address string
    _pinCode = DeliveryZoneLookup.resolvePin(
          storedPin: newAddress,
          addressText: newAddress,
        );
    invalidateAddressValidation(notify: false);
    notifyListeners();
  }

  /// Updates preview line + pin from reverse-geocode while picking on the map.
  /// Does not invalidate session validation until the user confirms location.
  void applyMapGeocode(Placemark p) {
    final parts = <String>[];
    void add(String? s) {
      if (s == null) return;
      final t = s.trim();
      if (t.isEmpty) return;
      parts.add(t);
    }

    add(p.name);
    add(p.street);
    add(p.subLocality);
    add(p.locality);
    add(p.postalCode);
    add(p.administrativeArea);
    _address = parts.isEmpty ? 'Address not found' : parts.join(', ');
    _pinCode = DeliveryZoneLookup.resolvePin(
      storedPin: p.postalCode,
      addressText: _address,
    );
    notifyListeners();
  }

  /// Extract pin code from address string (legacy helper).
  String? _extractPinCodeFromAddress(String address) =>
      DeliveryZoneLookup.resolvePin(addressText: address);

  /// Set pin code directly
  void setPinCode(String? pinCode) {
    _pinCode = pinCode;
    invalidateAddressValidation(notify: false);
    notifyListeners();
  }

  int get selectedIndex {
    final list = addresses;
    if (list == null || list.isEmpty) return 0;
    return _selectedIndex.clamp(0, list.length - 1);
  }

  AddressModel? get selectedAddress {
    final list = addresses;
    if (list == null || list.isEmpty) return null;
    return list[selectedIndex];
  }

  bool get isLoading => _isLoading;
  String get addressType => _addresstype;

  void addressTypeChange(String type) {
    _addresstype = type;
    notifyListeners();
  }

  void selectedIndexChange(int index) {
    selectAddress(index);
  }

  void selectAddress(int index) {
    final list = addresses;
    if (list == null || index < 0 || index >= list.length) return;
    final selected = list[index];
    final sameAddress = selected.id == _selectedAddressId;
    _selectedIndex = index;
    _selectedAddressId = selected.id;
    _address = '${selected.address}, ${selected.area}';
    _pinCode = DeliveryZoneLookup.resolvePin(
          addressText: _address,
          storedPin: _pinCode,
        ) ??
        _pinCode;
    if (!sameAddress) {
      invalidateAddressValidation(notify: false);
    }
    notifyListeners();
    unawaited(_syncProfileAddress());
  }

  Future<void> getAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('address')
          .where('user_id', isEqualTo: uid)
          .get();

      // Map Firestore documents to ProductModel instances
      addresses = snapshot.docs.map((doc) {
        return AddressModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      _normalizeSelection();
      await _syncProfileAddress();

      notifyListeners(); // Notify UI or listeners if you're using a state management solution
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching products: $e');
    }
  }

  Future<void> deleteAddress(BuildContext context, String id) async {
    await removeAddress(id);
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Hard-delete without popping routes — used from the address book UI.
  /// Deletes are serialized and the local list updates immediately so rapid
  /// multi-delete cannot leave a stale [selectedIndex].
  Future<void> removeAddress(String id) {
    final op = _deleteChain.then((_) => _removeAddressImpl(id));
    _deleteChain = op.catchError((Object _) {});
    return op;
  }

  Future<void> _removeAddressImpl(String id) async {
    if (id.isEmpty) return;

    final list = addresses;
    if (list == null) {
      try {
        await _firestore.collection('address').doc(id).delete();
      } catch (e) {
        debugPrint('AddressService: delete failed $id: $e');
      }
      await getAddress();
      return;
    }

    final removeIndex = list.indexWhere((a) => a.id == id);
    if (removeIndex < 0) {
      try {
        await _firestore.collection('address').doc(id).delete();
      } catch (e) {
        debugPrint('AddressService: delete failed $id: $e');
      }
      return;
    }

    addresses = List<AddressModel>.from(list)..removeAt(removeIndex);
    _reconcileSelectionAfterRemoval(
      removedIndex: removeIndex,
      removedId: id,
    );
    notifyListeners();

    try {
      await _firestore.collection('address').doc(id).delete();
      if (addresses == null || addresses!.isEmpty) {
        await invalidateAddressValidation(notify: false);
      }
      await _syncProfileAddress();
      notifyListeners();
    } catch (e) {
      debugPrint('AddressService: delete failed $id: $e');
      await getAddress();
    }
  }

  void _reconcileSelectionAfterRemoval({
    required int removedIndex,
    required String removedId,
  }) {
    final list = addresses;
    if (list == null || list.isEmpty) {
      _selectedIndex = 0;
      _selectedAddressId = null;
      _address = 'Loading...';
      return;
    }

    final removedWasSelected =
        _selectedAddressId == removedId || _selectedIndex == removedIndex;

    if (removedWasSelected) {
      final newIndex = removedIndex.clamp(0, list.length - 1);
      _selectedIndex = newIndex;
      _selectedAddressId = list[newIndex].id;
    } else if (_selectedIndex > removedIndex) {
      _selectedIndex -= 1;
    }

    _normalizeSelection();
  }

  Future<void> restoreValidatedAddress() => _restoreFuture;

  Future<void> _restoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedAddressId = prefs.getString(_cacheAddressIdKey);
    final lat = prefs.getDouble(_cacheLatKey);
    final lng = prefs.getDouble(_cacheLngKey);
    if (lat != null && lng != null) {
      latLng = LatLng(lat, lng);
    }
    _pinCode = prefs.getString(_cachePinKey) ?? _pinCode;
    _cachedServiceable = prefs.getBool(_cacheServiceableKey) ?? false;
    final millis = prefs.getInt(_cacheTimestampKey);
    _validatedAt = millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis);
    final expired = validationExpired;
    _isAddressValidated = _cachedServiceable && !expired;
    _sessionServiceCheckBypass = _isAddressValidated && _cachedServiceable;
    _cacheRestored = true;
    _applyCachedSelection();
    notifyListeners();
  }

  Future<void> markAddressValidated({
    required bool serviceable,
    String? addressId,
    String? pinCode,
  }) async {
    final mutation = ++_validationMutation;
    _selectedAddressId = addressId ?? _selectedAddressId ?? _currentAddressId;
    _pinCode = pinCode ?? _pinCode;
    _cachedServiceable = serviceable;
    _isAddressValidated = true;
    _validatedAt = DateTime.now();
    _sessionServiceCheckBypass = serviceable;

    final prefs = await SharedPreferences.getInstance();
    if (mutation != _validationMutation) return;
    final id = _selectedAddressId;
    if (id != null && id.isNotEmpty) {
      await prefs.setString(_cacheAddressIdKey, id);
    }
    final point = latLng;
    if (point != null) {
      await prefs.setDouble(_cacheLatKey, point.latitude);
      await prefs.setDouble(_cacheLngKey, point.longitude);
    }
    final pin = _pinCode;
    if (pin != null && pin.isNotEmpty) {
      await prefs.setString(_cachePinKey, pin);
    }
    await prefs.setBool(_cacheServiceableKey, serviceable);
    await prefs.setInt(_cacheTimestampKey, _validatedAt!.millisecondsSinceEpoch);

    if (FirebaseAuth.instance.currentUser == null &&
        _address.isNotEmpty &&
        _address != 'Loading...') {
      final point = latLng;
      await GuestAddressStore.save(
        prefs,
        addressText: _address,
        pinCode: _pinCode,
        latitude: point?.latitude,
        longitude: point?.longitude,
        area: areaController.text.trim().isNotEmpty
            ? areaController.text.trim()
            : null,
      );
    }

    notifyListeners();
    unawaited(_syncProfileAddress());
  }

  /// Persists a guest delivery snapshot to the signed-in user's address book.
  Future<void> persistGuestAddressSnapshot(
    Map<String, dynamic> pending,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final addressText = (pending['address'] ?? '').toString().trim();
    if (addressText.isEmpty) return;

    final area = (pending['area'] ?? '').toString().trim();
    final lat = (pending['latitude'] as num?)?.toDouble();
    final lng = (pending['longitude'] as num?)?.toDouble();

    final docRef = await _firestore.collection('address').add({
      'id': '',
      'name': (pending['name'] ?? '').toString().trim(),
      'mobile': (pending['mobile'] ?? '').toString().trim().isNotEmpty
          ? (pending['mobile'] ?? '').toString().trim()
          : _verifiedMobileDigits(),
      'address': addressText,
      'area': area,
      'type': 'HOME',
      'createdAt': FieldValue.serverTimestamp(),
      'lastEdited': FieldValue.serverTimestamp(),
      'user_id': uid,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
    });
    await docRef.update({'id': docRef.id});
    _selectedAddressId = docRef.id;
    _address = area.isEmpty ? addressText : '$addressText, $area';
    if (lat != null && lng != null) {
      latLng = LatLng(lat, lng);
    }
    _pinCode = DeliveryZoneLookup.resolvePin(
          addressText: _address,
          storedPin: pending['pinCode']?.toString(),
        ) ??
        _pinCode;
    await getAddress();
    notifyListeners();
  }

  Future<void> invalidateAddressValidation({bool notify = true}) async {
    final mutation = ++_validationMutation;
    _isAddressValidated = false;
    _cachedServiceable = false;
    _validatedAt = null;
    _sessionServiceCheckBypass = false;
    final prefs = await SharedPreferences.getInstance();
    if (mutation != _validationMutation) return;
    await prefs.setBool(_cacheServiceableKey, false);
    await prefs.remove(_cacheTimestampKey);
    if (notify) notifyListeners();
  }

  String? get _currentAddressId {
    final list = addresses;
    if (list == null || list.isEmpty) return null;
    final i = _selectedIndex.clamp(0, list.length - 1);
    return list[i].id;
  }

  void _applyCachedSelection() {
    _normalizeSelection(preferCachedId: true);
  }

  void _normalizeSelection({bool preferCachedId = false}) {
    final list = addresses;
    if (list == null || list.isEmpty) {
      _selectedIndex = 0;
      if (list?.isEmpty ?? true) {
        _selectedAddressId = null;
      }
      return;
    }

    if (preferCachedId) {
      final selectedId = _selectedAddressId;
      if (selectedId != null && selectedId.isNotEmpty) {
        final byId = list.indexWhere((a) => a.id == selectedId);
        if (byId >= 0) {
          _selectedIndex = byId;
          _applySelectedAddressFields(list[byId]);
          return;
        }
      }
    }

    _selectedIndex = _selectedIndex.clamp(0, list.length - 1);
    final selected = list[_selectedIndex];
    _selectedAddressId = selected.id;
    _applySelectedAddressFields(selected);
  }

  void _applySelectedAddressFields(AddressModel selected) {
    _address = '${selected.address}, ${selected.area}';
    _pinCode = _extractPinCodeFromAddress('${selected.address} ${selected.area}') ??
        _pinCode;
  }

  Future<void> _syncProfileAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final list = addresses;
    if (list == null || list.isEmpty) return;

    final idx = _selectedIndex.clamp(0, list.length - 1);
    final selected = list[idx];
    final full = '${selected.address}, ${selected.area}';
    final pin = _extractPinCodeFromAddress(full) ?? _pinCode;
    final point = latLng;

    final saved = list
        .map(
          (a) => {
            'id': a.id,
            'type': a.type,
            'address': a.address,
            'area': a.area,
            'name': a.name,
            'mobile': a.mobile,
          },
        )
        .toList();

    try {
      await _profileRepo.syncDefaultAddress(
        uid: uid,
        addressId: selected.id,
        fullAddress: full,
        area: selected.area,
        addressType: selected.type,
        pincode: pin,
        latitude: point?.latitude,
        longitude: point?.longitude,
        savedAddresses: saved,
      );
    } catch (e) {
      debugPrint('AddressService: profile sync failed: $e');
    }
  }

  /// Wipes in-memory address state after logout (prefs cleared separately).
  void resetSessionForLogout() {
    addresses = null;
    latLng = null;
    _address = 'Loading...';
    _pinCode = null;
    _selectedAddressId = null;
    _selectedIndex = 0;
    _isAddressValidated = false;
    _cachedServiceable = false;
    _validatedAt = null;
    _sessionServiceCheckBypass = false;
    _cacheRestored = false;
    _validationMutation++;
    nameController.clear();
    mobileController.clear();
    addressController.clear();
    areaController.clear();
    _editingAddressId = null;
    _addresstype = 'HOME';
    notifyListeners();
  }
}
