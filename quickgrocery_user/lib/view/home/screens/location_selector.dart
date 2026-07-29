import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_geo/quick_grocery_geo.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/core/permissions/app_permission_coordinator.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:shimmer/shimmer.dart';

class _SearchHit {
  const _SearchHit({
    required this.label,
    required this.point,
  });
  final String label;
  final LatLng point;
}

enum _LocationGate {
  none,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// Map location picker.
///
/// Important: this screen must **not** `watch` [AddressService] while the map
/// is panning. Notifying listeners on every camera frame rebuilds [FlutterMap],
/// which causes duplicate layer keys, a bogus ~100kpx RenderFlex overflow, and
/// `_dependents.isEmpty` / wrong build-scope assertions.
class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  static const _defaultCenter = LatLng(12.9352, 77.6147);
  static const _nominatimUa =
      'QuickGroceryLocationPicker/1.0 (support@quickgrocery.app)';

  final GlobalKey<_LocationMapPaneState> _mapKey =
      GlobalKey<_LocationMapPaneState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _geoDebounce;
  Timer? _searchDebounce;

  late LatLng _selected;
  String _previewAddress = '';
  bool _geocoding = false;
  List<_SearchHit> _suggestions = [];
  bool _suggestLoading = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    final addr = context.read<AddressService>();
    _selected = _sanitize(addr.latLng);
    _previewAddress = addr.address;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  LatLng _sanitize(LatLng? point) {
    if (point != null &&
        GpsPoint.isValidCoord(point.latitude, point.longitude)) {
      return point;
    }
    return _defaultCenter;
  }

  Future<void> _bootstrap() async {
    final addr = context.read<AddressService>();
    // Seed silently — never notify during map bootstrap.
    addr.onLatlongChanged(_selected, notify: false);
    await _reverseGeocode(_selected, immediate: true);
    if (!mounted) return;

    if (addr.hasSavedAddresses && addr.latLng != null) return;

    if (await AppPermissionCoordinator.isLocationGranted()) {
      await _mapKey.currentState?.locateMe(silent: true);
      return;
    }

    final status = await Permission.locationWhenInUse.status;
    if (!status.isPermanentlyDenied) {
      await _mapKey.currentState?.locateMe(silent: true);
    }
  }

  @override
  void dispose() {
    assert(() {
      debugPrint(
        '[LocationPicker] dispose geoTimer=${_geoDebounce?.isActive} '
        'searchTimer=${_searchDebounce?.isActive}',
      );
      return true;
    }());
    _geoDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onCenterSettled(LatLng center) {
    final safe = _sanitize(center);
    _selected = safe;
    // Keep AddressService in sync without rebuilding this route / FlutterMap.
    context.read<AddressService>().onLatlongChanged(safe, notify: false);
    _scheduleReverseGeocode(safe);
  }

  void _scheduleReverseGeocode(LatLng center) {
    _geoDebounce?.cancel();
    _geoDebounce = Timer(const Duration(milliseconds: 480), () {
      _reverseGeocode(center);
    });
  }

  Future<void> _reverseGeocode(LatLng point, {bool immediate = false}) async {
    final safe = _sanitize(point);
    if (!immediate) {
      await Future<void>.delayed(Duration.zero);
    }
    if (!mounted) return;
    setState(() => _geocoding = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        safe.latitude,
        safe.longitude,
      );
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Update service quietly; UI uses local preview string.
        context.read<AddressService>().applyMapGeocode(p, notify: false);
        final parts = <String>[
          if ((p.name ?? '').trim().isNotEmpty) p.name!.trim(),
          if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
          if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
          if ((p.postalCode ?? '').trim().isNotEmpty) p.postalCode!.trim(),
          if ((p.administrativeArea ?? '').trim().isNotEmpty)
            p.administrativeArea!.trim(),
        ];
        setState(() {
          _previewAddress =
              parts.isEmpty ? 'Address not found' : parts.join(', ');
        });
      }
    } catch (e) {
      log('Reverse geocode failed: $e');
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  Future<void> _fetchSuggestions(String raw) async {
    final q = raw.trim();
    if (q.length < 2) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    setState(() => _suggestLoading = true);
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(q)}&format=json&limit=6',
    );
    try {
      final res = await http.get(
        uri,
        headers: {'User-Agent': _nominatimUa},
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() {
          _suggestions = [];
          _suggestLoading = false;
        });
        return;
      }
      final data = json.decode(res.body) as List<dynamic>;
      final hits = <_SearchHit>[];
      for (final row in data) {
        final m = row as Map<String, dynamic>;
        final lat = double.tryParse(m['lat']?.toString() ?? '');
        final lon = double.tryParse(m['lon']?.toString() ?? '');
        final name = m['display_name']?.toString();
        if (lat != null &&
            lon != null &&
            name != null &&
            GpsPoint.isValidCoord(lat, lon)) {
          hits.add(_SearchHit(label: name, point: LatLng(lat, lon)));
        }
      }
      setState(() {
        _suggestions = hits;
        _suggestLoading = false;
      });
    } catch (e) {
      log('search: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _suggestLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 380), () {
      _fetchSuggestions(v);
    });
  }

  void _applySearchHit(_SearchHit hit) {
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = [];
      _searchController.text = hit.label.split(',').first.trim();
      _selected = hit.point;
    });
    context.read<AddressService>().onLatlongChanged(hit.point, notify: false);
    _mapKey.currentState?.moveTo(hit.point, 17);
    _reverseGeocode(hit.point, immediate: true);
  }

  Future<void> _confirm() async {
    if (_confirming || _geocoding) return;
    setState(() => _confirming = true);
    try {
      await context.read<AddressService>().onLatLongUpdatedinHome(
            context,
            _selected,
          );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.padding.bottom;
    final primary = AppColor.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, mq.padding.top + 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.6),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.l10n.select_delivery_location,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Isolated map pane — survives parent setState for address UI.
                    _LocationMapPane(
                      key: _mapKey,
                      initialCenter: _selected,
                      onCenterSettled: _onCenterSettled,
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Material(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(
                                  alpha: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 0.42
                                      : 0.72,
                                ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocus,
                                  onChanged: _onSearchChanged,
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: (v) {
                                    if (_suggestions.isNotEmpty) {
                                      _applySearchHit(_suggestions.first);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: context
                                        .l10n.search_delivery_location_hint,
                                    prefixIcon:
                                        const Icon(Icons.search_rounded),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                                if (_suggestLoading)
                                  const LinearProgressIndicator(minHeight: 2),
                                if (_suggestions.isNotEmpty)
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 220,
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount: _suggestions.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (ctx, i) {
                                        final h = _suggestions[i];
                                        return ListTile(
                                          key: ValueKey(
                                            'suggest-$i-${h.point.latitude}-'
                                            '${h.point.longitude}',
                                          ),
                                          dense: true,
                                          title: Text(
                                            h.label,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          onTap: () => _applySearchHit(h),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? 6 : 12),
              child: Material(
                elevation: 12,
                shadowColor: Colors.black26,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.place_rounded, color: primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _geocoding
                                  ? Row(
                                      key: const ValueKey('loc-geocoding'),
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: primary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            context.l10n.updating_address,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      _previewAddress.isEmpty
                                          ? context.l10n.move_map_hint
                                          : _previewAddress,
                                      key: ValueKey(
                                        'loc-addr-$_previewAddress',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(height: 1.35),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _geocoding || _confirming
                            ? null
                            : _confirm,
                        child: Text(
                          context.l10n.confirm_location,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns [FlutterMap] + [MapController] so parent address UI rebuilds cannot
/// recreate map layers mid-gesture.
class _LocationMapPane extends StatefulWidget {
  const _LocationMapPane({
    super.key,
    required this.initialCenter,
    required this.onCenterSettled,
  });

  final LatLng initialCenter;
  final ValueChanged<LatLng> onCenterSettled;

  @override
  State<_LocationMapPane> createState() => _LocationMapPaneState();
}

class _LocationMapPaneState extends State<_LocationMapPane> {
  static const _defaultCenter = LatLng(12.9352, 77.6147);
  static const _logName = 'LocationMap';

  final MapController _mapController = MapController();
  final ValueNotifier<double> _rotationDeg = ValueNotifier<double>(0);

  /// Stable for the lifetime of this State. Recreating [MapOptions] each build
  /// changes callback identity → FlutterMap calls `controller.options=` →
  /// ValueNotifier notify → MapInheritedModel rebuilds during route pop →
  /// `_dependents.isEmpty`.
  late final MapOptions _mapOptions;

  bool _alive = true;
  bool _mapReady = false;
  bool _showMapShimmer = true;
  _LocationGate _gate = _LocationGate.none;
  LatLng? _gpsFix;

  void _log(String message) {
    assert(() {
      debugPrint('[$_logName] $message');
      return true;
    }());
  }

  @override
  void initState() {
    super.initState();
    _mapOptions = MapOptions(
      initialCenter: _sanitize(widget.initialCenter),
      initialZoom: 15,
      initialRotation: 0,
      minZoom: 3,
      maxZoom: 19,
      onMapReady: _onMapReady,
      onPositionChanged: _onPositionChanged,
      onMapEvent: _onMapEvent,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all,
      ),
    );
    _log(
      'initState mapController=#${identityHashCode(_mapController)} '
      'options=#${identityHashCode(_mapOptions)}',
    );
  }

  LatLng _sanitize(LatLng? point) {
    if (point != null &&
        GpsPoint.isValidCoord(point.latitude, point.longitude)) {
      return point;
    }
    return _defaultCenter;
  }

  void moveTo(LatLng point, double zoom) {
    if (!_alive || !_mapReady) return;
    final target = _sanitize(point);
    try {
      final size = _mapController.camera.nonRotatedSize;
      if (size.width <= 0 || size.height <= 0) return;
      _mapController.move(target, zoom);
    } catch (e) {
      _log('moveTo failed: $e');
    }
  }

  void _emitSettled() {
    if (!_alive || !_mapReady) return;
    try {
      final c = _mapController.camera.center;
      if (!GpsPoint.isValidCoord(c.latitude, c.longitude)) return;
      widget.onCenterSettled(c);
    } catch (e) {
      _log('emitSettled failed: $e');
    }
  }

  void _onMapReady() {
    _log('onMapReady alive=$_alive mounted=$mounted');
    if (!_alive || !mounted) return;
    _mapReady = true;
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!_alive || !mounted) return;
      setState(() => _showMapShimmer = false);
    });
    _emitSettled();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!_alive) return;
    final r = camera.rotation;
    if ((r - _rotationDeg.value).abs() > 0.4) {
      _rotationDeg.value = r;
    }
  }

  void _onMapEvent(MapEvent ev) {
    if (!_alive) return;
    if (ev is MapEventMoveEnd ||
        ev is MapEventFlingAnimationEnd ||
        ev is MapEventRotateEnd) {
      try {
        _rotationDeg.value = _mapController.camera.rotation;
      } catch (_) {}
      _emitSettled();
    }
  }

  Future<void> locateMe({bool silent = false}) async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!_alive) return;
    if (!serviceOn) {
      if (!silent && mounted) {
        setState(() => _gate = _LocationGate.servicesDisabled);
      }
      return;
    }

    var ph = await Permission.locationWhenInUse.status;
    if (!_alive) return;
    if (!ph.isGranted) {
      if (silent) return;
      ph = await Permission.locationWhenInUse.request();
    }
    if (!_alive) return;
    if (ph.isPermanentlyDenied) {
      if (!silent && mounted) {
        setState(() => _gate = _LocationGate.permissionDeniedForever);
      }
      return;
    }
    if (!ph.isGranted) {
      if (!silent && mounted) {
        setState(() => _gate = _LocationGate.permissionDenied);
      }
      return;
    }

    LocationPermission gp = await Geolocator.checkPermission();
    if (!_alive) return;
    if (gp == LocationPermission.denied && !silent) {
      gp = await Geolocator.requestPermission();
    } else if (gp == LocationPermission.denied && silent) {
      return;
    }
    if (!_alive) return;
    if (gp == LocationPermission.deniedForever) {
      if (!silent && mounted) {
        setState(() => _gate = _LocationGate.permissionDeniedForever);
      }
      return;
    }
    if (gp == LocationPermission.denied) {
      if (!silent && mounted) {
        setState(() => _gate = _LocationGate.permissionDenied);
      }
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!_alive || !mounted) return;
      if (!GpsPoint.isValidCoord(pos.latitude, pos.longitude)) return;
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _gate = _LocationGate.none;
        _gpsFix = here;
      });
      moveTo(here, 16.5);
      widget.onCenterSettled(here);
    } catch (e) {
      log('locateMe: $e');
      if (!silent && _alive && mounted) {
        setState(() => _gate = _LocationGate.servicesDisabled);
      }
    }
  }

  void _zoomBy(double delta) {
    if (!_alive || !_mapReady) return;
    try {
      final cam = _mapController.camera;
      if (!GpsPoint.isValidCoord(cam.center.latitude, cam.center.longitude)) {
        return;
      }
      final z = (cam.zoom + delta).clamp(3.0, 19.0);
      moveTo(cam.center, z);
    } catch (_) {}
  }

  void _resetNorth() {
    if (!_alive || !_mapReady) return;
    try {
      _mapController.rotate(0);
      _rotationDeg.value = 0;
    } catch (_) {}
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  String get _tileUrl => _isDark
      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  void dispose() {
    _log(
      'dispose BEGIN mapController=#${identityHashCode(_mapController)} '
      'mapReady=$_mapReady',
    );
    _alive = false;
    // Children (FlutterMap → MapInteractiveViewer → MapInheritedModel) are
    // already unmounted before State.dispose. Safe to dispose the external
    // controller now that listeners were removed in InteractiveViewer.dispose.
    _rotationDeg.dispose();
    _mapController.dispose();
    _log('dispose END controller disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColor.primary;
    _log(
      'build options=#${identityHashCode(_mapOptions)} '
      'mapReady=$_mapReady gate=$_gate',
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: _mapOptions,
            children: [
              TileLayer(
                key: ValueKey('tiles-$_isDark'),
                urlTemplate: _tileUrl,
                userAgentPackageName: 'com.quickgrocery.io',
                maxZoom: 19,
                subdomains: _isDark ? const ['a', 'b', 'c', 'd'] : const [],
              ),
              if (_gpsFix != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _gpsFix!,
                      width: 22,
                      height: 22,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (_showMapShimmer)
          Positioned.fill(
            child: IgnorePointer(
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(color: Colors.white),
              ),
            ),
          ),
        const IgnorePointer(
          child: Center(
            child: _MapPin(),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 24,
          child: ValueListenableBuilder<double>(
            valueListenable: _rotationDeg,
            builder: (context, rotation, _) {
              return Column(
                children: [
                  _RoundMapFab(
                    icon: Icons.add_rounded,
                    onTap: () => _zoomBy(1),
                  ),
                  const SizedBox(height: 10),
                  _RoundMapFab(
                    icon: Icons.remove_rounded,
                    onTap: () => _zoomBy(-1),
                  ),
                  if (rotation.abs() > 1) ...[
                    const SizedBox(height: 10),
                    _RoundMapFab(
                      icon: Icons.explore_rounded,
                      onTap: _resetNorth,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _RoundMapFab(
                    icon: Icons.my_location_rounded,
                    onTap: () => locateMe(silent: false),
                    iconColor: primary,
                  ),
                ],
              );
            },
          ),
        ),
        if (_gate != _LocationGate.none)
          Positioned.fill(
            child: Material(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _gate == _LocationGate.servicesDisabled
                                ? Icons.location_off_rounded
                                : Icons.privacy_tip_outlined,
                            size: 40,
                            color: primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _gate == _LocationGate.servicesDisabled
                                ? context.l10n.location_services_off
                                : context.l10n.location_permission_needed,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _gate == _LocationGate.servicesDisabled
                                ? context.l10n.location_services_off_body
                                : context.l10n.location_permission_body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 18),
                          if (_gate == _LocationGate.servicesDisabled)
                            FilledButton.icon(
                              onPressed: () async {
                                await Geolocator.openLocationSettings();
                                if (_alive && mounted) {
                                  setState(() => _gate = _LocationGate.none);
                                }
                              },
                              icon: const Icon(Icons.settings_rounded, size: 20),
                              label: Text(context.l10n.open_location_settings),
                            )
                          else if (_gate ==
                              _LocationGate.permissionDeniedForever)
                            FilledButton.icon(
                              onPressed: () async {
                                await openAppSettings();
                                if (_alive && mounted) {
                                  setState(() => _gate = _LocationGate.none);
                                }
                              },
                              icon: const Icon(
                                Icons.app_settings_alt_outlined,
                                size: 20,
                              ),
                              label: Text(context.l10n.open_app_settings),
                            )
                          else
                            FilledButton.icon(
                              onPressed: () async {
                                setState(() => _gate = _LocationGate.none);
                                await locateMe(silent: false);
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              label: Text(context.l10n.retry_location),
                            ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              setState(() => _gate = _LocationGate.none);
                            },
                            child: Text(context.l10n.cancel),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}


class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -26),
      child: Icon(
        Icons.location_on_rounded,
        size: 52,
        color: Colors.redAccent.shade700,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _RoundMapFab extends StatelessWidget {
  const _RoundMapFab({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black38,
      shape: const CircleBorder(),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: iconColor ??
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
