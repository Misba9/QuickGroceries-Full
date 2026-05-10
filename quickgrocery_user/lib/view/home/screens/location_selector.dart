import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPicker extends StatefulWidget {
  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locateMe();
    });
  }

  Future<void> _searchLocation(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'FlutterMapApp/1.0 (test@email.com)'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        final newPoint = LatLng(lat, lon);
        final provider = Provider.of<AddressService>(context, listen: false);
        provider.onLatlongChanged(newPoint);
        _mapController.move(newPoint, 17);
        _updateAddress(newPoint);
      }
    }
  }

  Future<void> _locateMe() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check location service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services disabled.')),
      );
      return;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Permission denied')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission permanently denied')),
      );
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return; // widget may have been disposed after await

    final currentLatLng = LatLng(position.latitude, position.longitude);

    // Update provider
    final provider = Provider.of<AddressService>(context, listen: false);
    provider.onLatlongChanged(currentLatLng);

    // Move map and update address
    _mapController.move(currentLatLng, 17);
    _updateAddress(currentLatLng);
  }

  Future<void> _updateAddress(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        final address =
            "${p.name}, ${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}";
        final addressService = Provider.of<AddressService>(
          context,
          listen: false,
        );
        addressService.updateAddress(address);
        // Also update pin code directly from placemark
        if (p.postalCode != null && p.postalCode!.isNotEmpty) {
          // The updateAddress method will extract it, but we can also set it directly
          // by accessing the private field through a method if needed
        }
      }
    } catch (e) {
      log("Address lookup failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AddressService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Location"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search delivery location',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.black),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: provider.latLng ?? LatLng(12.9352, 77.6147),
              onTap: (tapPosition, point) {
                provider.onLatlongChanged(point);
                _updateAddress(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                tileProvider: NetworkTileProvider(
                  headers: {
                    'User-Agent': 'MyFlutterApp/1.0 (contact@yourapp.com)',
                    'Referer': 'https://yourapp.com',
                  },
                ),
              ),
              if (provider.latLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: provider.latLng!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Locate Me Button
          Positioned(
            bottom: 140,
            left: MediaQuery.of(context).size.width / 2 - 60,
            child: ElevatedButton.icon(
              onPressed: _locateMe,
              icon: Icon(Icons.my_location, color: AppColor.primary),
              label: Text(
                "LOCATE ME",
                style: TextStyle(color: AppColor.primary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: AppColor.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Address Display Box
          // Bottom fixed bar with address and confirm button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Address tile
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.navigation, color: AppColor.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.address.isEmpty
                              ? "Select a delivery location"
                              : provider.address,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Confirm button
                  ElevatedButton(
                    onPressed: () async {
                      final selectedLatLng = provider.latLng;
                      if (selectedLatLng != null) {
                        await provider.onLatLongUpdatedinHome(
                          context,
                          selectedLatLng,
                        );
                        // The address and pin code will be updated,
                        // and the home screen will recheck serviceability
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please select a location.")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Confirm",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
