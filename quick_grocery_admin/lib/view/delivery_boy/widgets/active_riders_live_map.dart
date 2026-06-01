import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/delivery_boy_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';

/// Admin live map — all online riders with GPS (updates every ~5s from rider app).
class ActiveRidersLiveMap extends StatefulWidget {
  const ActiveRidersLiveMap({super.key, this.height = 320});

  final double height;

  @override
  State<ActiveRidersLiveMap> createState() => _ActiveRidersLiveMapState();
}

class _ActiveRidersLiveMapState extends State<ActiveRidersLiveMap> {
  final MapController _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DeliveryPersonModel> _activeRiders(List<DeliveryPersonModel>? all) {
    if (all == null) return const [];
    return all
        .where((r) => r.isActive && r.isOnline && r.hasLiveLocation)
        .toList(growable: false);
  }

  void _fitRiders(List<DeliveryPersonModel> riders) {
    if (riders.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final points = riders.map((r) => LatLng(r.lat, r.lng)).toList();
      if (points.length == 1) {
        _controller.move(points.first, 14);
        return;
      }
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryBoyService>(
      builder: (context, svc, _) {
        final riders = _activeRiders(svc.deliveryBoys);
        _fitRiders(riders);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.map_outlined, color: AppColor.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Active riders live',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${riders.length} online',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: widget.height,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: riders.isEmpty
                      ? Center(
                          child: Text(
                            'No riders with live GPS right now',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : FlutterMap(
                          mapController: _controller,
                          options: MapOptions(
                            initialCenter: LatLng(riders.first.lat, riders.first.lng),
                            initialZoom: 13,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.quickgrocery.admin',
                            ),
                            MarkerLayer(
                              markers: [
                                for (final r in riders)
                                  Marker(
                                    point: LatLng(r.lat, r.lng),
                                    width: 120,
                                    height: 56,
                                    child: _RiderMarkerLabel(rider: r),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RiderMarkerLabel extends StatelessWidget {
  const _RiderMarkerLabel({required this.rider});

  final DeliveryPersonModel rider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rider.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColor.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.delivery_dining,
            color: Colors.white,
            size: 16,
          ),
        ),
      ],
    );
  }
}
