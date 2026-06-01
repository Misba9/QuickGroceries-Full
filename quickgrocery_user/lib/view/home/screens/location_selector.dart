import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_color.dart';
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

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  static const _defaultCenter = LatLng(12.9352, 77.6147);
  static const _nominatimUa =
      'QuickGroceryLocationPicker/1.0 (support@quickgrocery.app)';

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _geoDebounce;
  Timer? _searchDebounce;

  bool _mapReady = false;
  bool _showMapShimmer = true;
  bool _geocoding = false;
  double _mapRotationDeg = 0;
  _LocationGate _gate = _LocationGate.none;
  LatLng? _gpsFix;
  List<_SearchHit> _suggestions = [];
  bool _suggestLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final addr = context.read<AddressService>();
    final start = addr.latLng ?? _defaultCenter;
    addr.onLatlongChanged(start);
    await _reverseGeocode(start, immediate: true);
    if (!mounted) return;
    await _locateMe(silent: true);
  }

  @override
  void dispose() {
    _geoDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _scheduleReverseGeocode(LatLng center) {
    _geoDebounce?.cancel();
    _geoDebounce = Timer(const Duration(milliseconds: 480), () {
      _reverseGeocode(center);
    });
  }

  Future<void> _reverseGeocode(LatLng point, {bool immediate = false}) async {
    if (!immediate) {
      await Future<void>.delayed(Duration.zero);
    }
    if (!mounted) return;
    setState(() => _geocoding = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        context.read<AddressService>().applyMapGeocode(placemarks.first);
      }
    } catch (e) {
      log('Reverse geocode failed: $e');
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  void _syncCenterToSelection() {
    if (!_mapReady) return;
    try {
      final c = _mapController.camera.center;
      context.read<AddressService>().onLatlongChanged(c);
      _scheduleReverseGeocode(c);
    } catch (_) {}
  }

  Future<void> _locateMe({bool silent = false}) async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      if (!silent && mounted) {
        setState(() => _gate = _LocationGate.servicesDisabled);
      }
      return;
    }

    var ph = await Permission.locationWhenInUse.status;
    if (ph.isDenied) {
      ph = await Permission.locationWhenInUse.request();
    }
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
    if (gp == LocationPermission.denied) {
      gp = await Geolocator.requestPermission();
    }
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
      if (!mounted) return;
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _gate = _LocationGate.none;
        _gpsFix = here;
      });
      context.read<AddressService>().onLatlongChanged(here);
      _mapController.move(here, 16.5);
      await _reverseGeocode(here, immediate: true);
    } catch (e) {
      log('locateMe: $e');
      if (!silent && mounted) {
        setState(() => _gate = _LocationGate.servicesDisabled);
      }
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
        if (lat != null && lon != null && name != null) {
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
    });
    context.read<AddressService>().onLatlongChanged(hit.point);
    _mapController.move(hit.point, 17);
    _reverseGeocode(hit.point, immediate: true);
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    try {
      final cam = _mapController.camera;
      final z = (cam.zoom + delta).clamp(3.0, 19.0);
      _mapController.move(cam.center, z);
    } catch (_) {}
  }

  void _resetNorth() {
    if (!_mapReady) return;
    try {
      _mapController.rotate(0);
    } catch (_) {}
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  String get _tileUrl => _isDark
      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  Widget build(BuildContext context) {
    final addr = context.watch<AddressService>();
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
                    'select_delivery_location'.tr(),
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
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: addr.latLng ?? _defaultCenter,
                        initialZoom: 15,
                        initialRotation: 0,
                        minZoom: 3,
                        maxZoom: 19,
                        onMapReady: () {
                          setState(() => _mapReady = true);
                          Future.delayed(const Duration(milliseconds: 220), () {
                            if (mounted) {
                              setState(() => _showMapShimmer = false);
                            }
                          });
                          _syncCenterToSelection();
                        },
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                        onPositionChanged: (camera, hasGesture) {
                          final r = camera.rotation;
                          if ((r - _mapRotationDeg).abs() > 0.4) {
                            setState(() => _mapRotationDeg = r);
                          }
                          if (hasGesture) {
                            context.read<AddressService>().onLatlongChanged(
                                  camera.center,
                                );
                            _scheduleReverseGeocode(camera.center);
                          }
                        },
                        onMapEvent: (ev) {
                          if (ev is MapEventMoveEnd ||
                              ev is MapEventFlingAnimationEnd ||
                              ev is MapEventRotateEnd) {
                            if (_mapReady) {
                              try {
                                setState(
                                  () => _mapRotationDeg =
                                      _mapController.camera.rotation,
                                );
                              } catch (_) {}
                            }
                            _syncCenterToSelection();
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _tileUrl,
                          userAgentPackageName: 'com.quickgrocery.io',
                          maxZoom: 19,
                          subdomains: _isDark
                              ? const ['a', 'b', 'c', 'd']
                              : const [],
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
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.22),
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
                    if (_showMapShimmer)
                      Positioned.fill(
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(color: Colors.white),
                        ),
                      ),
                    IgnorePointer(
                      child: Center(
                        child: Transform.translate(
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
                        ),
                      ),
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
                                .withValues(alpha: _isDark ? 0.42 : 0.72),
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
                                    hintText:
                                        'search_delivery_location_hint'.tr(),
                                    prefixIcon: const Icon(Icons.search_rounded),
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
                    Positioned(
                      right: 12,
                      bottom: 160,
                      child: Column(
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
                          if (_mapRotationDeg.abs() > 1) ...[
                            const SizedBox(height: 10),
                            _RoundMapFab(
                              icon: Icons.explore_rounded,
                              onTap: _resetNorth,
                            ),
                          ],
                          const SizedBox(height: 10),
                          _RoundMapFab(
                            icon: Icons.my_location_rounded,
                            onTap: () => _locateMe(silent: false),
                            iconColor: primary,
                          ),
                        ],
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
                                        _gate ==
                                                _LocationGate.servicesDisabled
                                            ? Icons.location_off_rounded
                                            : Icons.privacy_tip_outlined,
                                        size: 40,
                                        color: primary,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _gate ==
                                                _LocationGate.servicesDisabled
                                            ? 'location_services_off'.tr()
                                            : 'location_permission_needed'
                                                .tr(),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _gate ==
                                                _LocationGate.servicesDisabled
                                            ? 'location_services_off_body'.tr()
                                            : 'location_permission_body'.tr(),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: 18),
                                      if (_gate ==
                                          _LocationGate.servicesDisabled)
                                        FilledButton.icon(
                                          onPressed: () async {
                                            await Geolocator
                                                .openLocationSettings();
                                            if (mounted) {
                                              setState(
                                                () => _gate =
                                                    _LocationGate.none,
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.settings_rounded,
                                            size: 20,
                                          ),
                                          label: Text(
                                            'open_location_settings'.tr(),
                                          ),
                                        )
                                      else if (_gate ==
                                          _LocationGate
                                              .permissionDeniedForever)
                                        FilledButton.icon(
                                          onPressed: () async {
                                            await openAppSettings();
                                            if (mounted) {
                                              setState(
                                                () => _gate =
                                                    _LocationGate.none,
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.app_settings_alt_outlined,
                                            size: 20,
                                          ),
                                          label: Text('open_app_settings'.tr()),
                                        )
                                      else
                                        FilledButton.icon(
                                          onPressed: () async {
                                            setState(
                                              () => _gate = _LocationGate.none,
                                            );
                                            await _locateMe(silent: false);
                                          },
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                            size: 20,
                                          ),
                                          label: Text('retry_location'.tr()),
                                        ),
                                      const SizedBox(height: 10),
                                      TextButton(
                                        onPressed: () {
                                          setState(
                                            () => _gate = _LocationGate.none,
                                          );
                                        },
                                        child: Text('cancel'.tr()),
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
                                      key: const ValueKey('g'),
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
                                            'updating_address'.tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      addr.address.isEmpty
                                          ? 'move_map_hint'.tr()
                                          : addr.address,
                                      key: ValueKey(addr.address),
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
                        onPressed: addr.latLng == null || _geocoding
                            ? null
                            : () async {
                                await addr.onLatLongUpdatedinHome(
                                  context,
                                  addr.latLng!,
                                );
                              },
                        child: Text(
                          'confirm_location'.tr(),
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
