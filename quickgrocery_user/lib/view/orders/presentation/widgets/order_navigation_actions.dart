import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_geo/quick_grocery_geo.dart';

import '../../domain/order_models.dart';

class OrderNavigationActions extends StatelessWidget {
  const OrderNavigationActions({
    super.key,
    required this.order,
    this.rider,
  });

  final LiveOrder order;
  final RiderLocation? rider;

  Future<void> _open({
    required BuildContext context,
    double? lat,
    double? lng,
    String? label,
  }) async {
    final ok = await ExternalNavigation.open(
      lat: lat,
      lng: lng,
      coordinatesOnly: true,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            label == null
                ? 'Location coordinates are unavailable.'
                : '$label coordinates are unavailable.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final drop = order.dropLatLng;
    final store = order.storeLatLng;
    final riderPos = rider?.position;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (order.hasStoreCoordinates)
          OutlinedButton.icon(
            onPressed: () => _open(
              context: context,
              lat: store!.latitude,
              lng: store.longitude,
              label: 'Store',
            ),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Navigate to Store'),
          ),
        if (GpsPoint.isValidCoord(drop.latitude, drop.longitude))
          OutlinedButton.icon(
            onPressed: () => _open(
              context: context,
              lat: drop.latitude,
              lng: drop.longitude,
              label: 'Delivery address',
            ),
            icon: const Icon(Icons.home_outlined, size: 18),
            label: const Text('My Location'),
          ),
        if (riderPos != null &&
            GpsPoint.isValidCoord(riderPos.latitude, riderPos.longitude))
          OutlinedButton.icon(
            onPressed: () => _open(
              context: context,
              lat: riderPos.latitude,
              lng: riderPos.longitude,
              label: 'Delivery partner',
            ),
            icon: const Icon(Icons.delivery_dining_outlined, size: 18),
            label: Text(
              'Partner',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
