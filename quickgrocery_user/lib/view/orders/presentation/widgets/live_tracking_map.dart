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
  static const _fallbackCenter = LatLng(12.9352, 77.6147);

  final MapController _mapController = MapController();
  final OsrmRouteService _routeService = OsrmRouteService();
  LatLng? _lastRiderPosition;
  List<LatLng> _routePoints = const [];
  double? _routeDistanceKm;
  int? _routeEtaMinutes;
  bool _loadingRoute = false;
  bool _mapReady = false;

  static bool _isValid(LatLng? p) =>
      p != null && GpsPoint.isValidCoord(p.latitude, p.longitude);

  LatLng get _safeDrop =>
      _isValid(widget.dropLocation) ? widget.dropLocation : _fallbackCenter;

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
    if (_isValid(riderPos) && riderPos != _lastRiderPosition) {
      _lastRiderPosition = riderPos;
      _fitBounds();
      _refreshRoute();
    }
  }

  Future<void> _refreshRoute() async {
    final riderPos = widget.rider?.position;
    if (!_isValid(riderPos) || !_isValid(_safeDrop)) return;
    setState(() => _loadingRoute = true);
    final from = GpsPoint(riderPos!.latitude, riderPos.longitude);
    final to = GpsPoint(_safeDrop.latitude, _safeDrop.longitude);
    final route = await _routeService.route(from: from, to: to);
    if (!mounted) return;
    setState(() {
      _loadingRoute = false;
      if (route != null) {
        _routePoints = route.points
            .where((p) => GpsPoint.isValidCoord(p.latitude, p.longitude))
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(growable: false);
        _routeDistanceKm = route.distanceKm;
        _routeEtaMinutes = route.etaMinutes;
      } else {
        _routePoints = [riderPos, _safeDrop];
        _routeDistanceKm = null;
        _routeEtaMinutes = null;
      }
    });
  }

  void _fitBounds() {
    if (!_mapReady || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      try {
        final size = _mapController.camera.nonRotatedSize;
        if (size.width <= 0 || size.height <= 0) return;

        final points = <LatLng>[_safeDrop];
        final riderPos = widget.rider?.position;
        if (_isValid(riderPos)) points.add(riderPos!);
        final store = widget.storeLocation;
        if (_isValid(store)) points.add(store!);

        if (points.length == 1) {
          _mapController.move(points.first, 15.5);
          return;
        }

        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(48),
            maxZoom: 16,
          ),
        );

        final c = _mapController.camera.center;
        if (!GpsPoint.isValidCoord(c.latitude, c.longitude)) {
          _mapController.move(_safeDrop, 14);
        }
      } catch (_) {
        try {
          _mapController.move(_safeDrop, 14);
        } catch (_) {}
      }
    });
  }

  double? _distanceKm() {
    if (_routeDistanceKm != null && _routeDistanceKm! > 0) {
      return _routeDistanceKm;
    }
    final riderPos = widget.rider?.position;
    if (!_isValid(riderPos)) return null;
    return RouteMath.haversineKm(
      riderPos!.latitude,
      riderPos.longitude,
      _safeDrop.latitude,
      _safeDrop.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final riderPos = widget.rider?.position;
    final hasRider = _isValid(riderPos);
    final drop = _safeDrop;
    final center = hasRider
        ? LatLng(
            (riderPos!.latitude + drop.latitude) / 2,
            (riderPos.longitude + drop.longitude) / 2,
          )
        : drop;
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
                onMapReady: () {
                  _mapReady = true;
                  _fitBounds();
                  _refreshRoute();
                },
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
                    if (_isValid(widget.storeLocation))
                      Marker(
                        point: widget.storeLocation!,
                        width: 44,
                        height: 44,
                        child: const _StorePin(),
                      ),
                    Marker(
                      point: drop,
                      width: 44,
                      height: 44,
                      child: const _DropPin(),
                    ),
                    if (hasRider)
                      Marker(
                        point: riderPos!,
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
