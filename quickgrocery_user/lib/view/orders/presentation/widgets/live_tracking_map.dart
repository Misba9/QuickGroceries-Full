import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quick_grocery_geo/quick_grocery_geo.dart';

import '../../domain/order_models.dart';

/// Live tracking map backed by OpenStreetMap tiles and OSRM road routing.
class LiveTrackingMap extends StatefulWidget {
  const LiveTrackingMap({
    super.key,
    required this.dropLocation,
    required this.rider,
    this.storeLocation,
    this.eta = Duration.zero,
    this.height = 260,
  });

  final LatLng dropLocation;
  final RiderLocation? rider;
  final LatLng? storeLocation;
  final Duration eta;
  final double height;

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  final MapController _mapController = MapController();
  final OsrmRouteService _routeService = OsrmRouteService();
  LatLng? _lastRiderPosition;
  List<LatLng> _routePoints = const [];
  double? _routeDistanceKm;
  int? _routeEtaMinutes;
  bool _loadingRoute = false;

  @override
  void dispose() {
    _mapController.dispose();
    _routeService.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final riderPos = widget.rider?.position;
    if (riderPos != null && riderPos != _lastRiderPosition) {
      _lastRiderPosition = riderPos;
      _fitBounds();
      _refreshRoute();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
      _refreshRoute();
    });
  }

  Future<void> _refreshRoute() async {
    final riderPos = widget.rider?.position;
    if (riderPos == null || !GpsPoint.isValidCoord(riderPos.latitude, riderPos.longitude)) {
      return;
    }
    setState(() => _loadingRoute = true);
    final from = GpsPoint(riderPos.latitude, riderPos.longitude);
    final to = GpsPoint(widget.dropLocation.latitude, widget.dropLocation.longitude);
    final route = await _routeService.route(from: from, to: to);
    if (!mounted) return;
    setState(() {
      _loadingRoute = false;
      if (route != null) {
        _routePoints = route.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(growable: false);
        _routeDistanceKm = route.distanceKm;
        _routeEtaMinutes = route.etaMinutes;
      } else {
        _routePoints = [riderPos, widget.dropLocation];
        _routeDistanceKm = null;
        _routeEtaMinutes = null;
      }
    });
  }

  void _fitBounds() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final points = <LatLng>[widget.dropLocation];
      final riderPos = widget.rider?.position;
      if (riderPos != null) points.add(riderPos);
      final store = widget.storeLocation;
      if (store != null) points.add(store);
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  double? _distanceKm() {
    if (_routeDistanceKm != null && _routeDistanceKm! > 0) {
      return _routeDistanceKm;
    }
    final riderPos = widget.rider?.position;
    if (riderPos == null) return null;
    return RouteMath.haversineKm(
      riderPos.latitude,
      riderPos.longitude,
      widget.dropLocation.latitude,
      widget.dropLocation.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRider = widget.rider?.position != null;
    final center = hasRider
        ? LatLng(
            (widget.rider!.position!.latitude + widget.dropLocation.latitude) / 2,
            (widget.rider!.position!.longitude + widget.dropLocation.longitude) /
                2,
          )
        : widget.dropLocation;
    final distanceKm = _distanceKm();
    final etaMinutes = _routeEtaMinutes ??
        (widget.eta.inSeconds > 0 ? (widget.eta.inSeconds / 60).round() : null);

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
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
                if (_routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4,
                        color: AppColor.primary,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (widget.storeLocation != null)
                      Marker(
                        point: widget.storeLocation!,
                        width: 44,
                        height: 44,
                        child: const _StorePin(),
                      ),
                    Marker(
                      point: widget.dropLocation,
                      width: 44,
                      height: 44,
                      child: const _DropPin(),
                    ),
                    if (hasRider)
                      Marker(
                        point: widget.rider!.position!,
                        width: 56,
                        height: 56,
                        child: const _RiderPin(),
                      ),
                  ],
                ),
              ],
            ),
            if (_loadingRoute)
              const Positioned(
                top: 12,
                right: 12,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (hasRider && (distanceKm != null || etaMinutes != null))
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _MapStatsBar(
                  distanceKm: distanceKm,
                  etaMinutes: etaMinutes,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapStatsBar extends StatelessWidget {
  const _MapStatsBar({
    required this.distanceKm,
    required this.etaMinutes,
  });

  final double? distanceKm;
  final int? etaMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadow.dim,
      ),
      child: Row(
        children: [
          if (distanceKm != null) ...[
            const Icon(Icons.route_rounded, color: AppColor.primary, size: 18),
            const SizedBox(width: 6),
            Text(
              RouteMath.formatDistance(distanceKm),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
          const Spacer(),
          if (etaMinutes != null) ...[
            const Icon(Icons.schedule_rounded, color: AppColor.primary, size: 18),
            const SizedBox(width: 6),
            Text(
              'ETA ${RouteMath.formatDuration(etaMinutes)}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StorePin extends StatelessWidget {
  const _StorePin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
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
            color: Colors.black.withValues(alpha: 0.25),
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
                color: AppColor.primary.withValues(alpha: 0.25 * (1 - t)),
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
