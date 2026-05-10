import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:quickgrocery/constants/app_color.dart';

import '../../domain/order_models.dart';

/// Live tracking map for the order tracking screen.
///
/// Today this widget is backed by `flutter_map` (OpenStreetMap) so it works
/// out-of-the-box with no API key. The whole module is intentionally narrow
/// (drop pin, optional rider pin, polyline-ready, auto-fit bounds) so you
/// can swap in `google_maps_flutter` by replacing the body of [build] —
/// see `ORDERS_INFRA.md` for the step-by-step migration.
class LiveTrackingMap extends StatelessWidget {
  const LiveTrackingMap({
    super.key,
    required this.dropLocation,
    required this.rider,
    this.height = 260,
  });

  final LatLng dropLocation;
  final RiderLocation? rider;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasRider = rider?.position != null;
    final center = hasRider
        ? LatLng(
            (rider!.position!.latitude + dropLocation.latitude) / 2,
            (rider!.position!.longitude + dropLocation.longitude) / 2,
          )
        : dropLocation;

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: hasRider ? 14 : 15.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.quickgrocery.io',
              maxZoom: 19,
            ),
            if (hasRider)
              PolylineLayer(polylines: [
                Polyline(
                  points: [rider!.position!, dropLocation],
                  strokeWidth: 4,
                  color: AppColor.primary,
                ),
              ]),
            MarkerLayer(
              markers: [
                Marker(
                  point: dropLocation,
                  width: 44,
                  height: 44,
                  child: const _DropPin(),
                ),
                if (hasRider)
                  Marker(
                    point: rider!.position!,
                    width: 56,
                    height: 56,
                    child: const _RiderPin(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropPin extends StatelessWidget {
  const _DropPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
    );
  }
}

class _RiderPin extends StatefulWidget {
  const _RiderPin();

  @override
  State<_RiderPin> createState() => _RiderPinState();
}

class _RiderPinState extends State<_RiderPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            return Container(
              width: 56 * (0.6 + 0.4 * t),
              height: 56 * (0.6 + 0.4 * t),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.primary.withOpacity(0.25 * (1 - t)),
              ),
            );
          },
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: AppColor.primary, width: 3),
          ),
          child: const Icon(
            Icons.delivery_dining,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }
}
