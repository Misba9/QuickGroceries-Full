import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Publishes rider GPS every [interval] to Firestore for live tracking.
///
/// Writes:
/// - `delivery_boys/{id}` — profile + latest coords
/// - `delivery_boys/{id}/live/current` — fast live read path
/// - `driver_locations/{id}` — live rider position for admin map
/// - `orders/{activeOrderId}/live/rider` — order-scoped mirror for user/admin
class DriverLocationPublisher {
  DriverLocationPublisher({FirebaseFirestore? db, this.interval = const Duration(seconds: 5)})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final Duration interval;

  Timer? _timer;
  String? _riderId;
  String? _activeOrderId;
  bool _publishing = false;

  String? get activeOrderId => _activeOrderId;

  void setActiveOrderId(String? orderId) {
    _activeOrderId = orderId?.trim().isEmpty == true ? null : orderId?.trim();
  }

  Future<void> start() async {
    await stop();
    final pref = await SharedPreferences.getInstance();
    _riderId = pref.getString('deliveryBoyId') ?? '';
    if (_riderId == null || _riderId!.isEmpty) return;

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    await _tick();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  Future<void> _tick() async {
    if (_publishing) return;
    _publishing = true;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _publish(pos);
    } catch (e) {
      if (kDebugMode) debugPrint('[DriverLocationPublisher] tick $e');
    } finally {
      _publishing = false;
    }
  }

  void Function(double lat, double lng)? onPosition;

  Future<void> _publish(Position pos) async {
    final id = _riderId;
    if (id == null || id.isEmpty) return;

    onPosition?.call(pos.latitude, pos.longitude);

    final orderId = _activeOrderId;
    final payload = <String, dynamic>{
      'lat': pos.latitude,
      'lng': pos.longitude,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'heading': pos.heading,
      'speed': pos.speed,
      'accuracy': pos.accuracy,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'locationIntervalSec': interval.inSeconds,
      if (orderId != null) 'activeOrderId': orderId,
    };

    try {
      final batch = _db.batch();
      final riderRef = _db.collection('delivery_boys').doc(id);
      batch.set(riderRef, payload, SetOptions(merge: true));
      batch.set(
        riderRef.collection('live').doc('current'),
        payload,
        SetOptions(merge: true),
      );
      batch.set(
        _db.collection('driver_locations').doc(id),
        {
          ...payload,
          'riderId': id,
          'deliveryBoyId': id,
        },
        SetOptions(merge: true),
      );
      if (orderId != null) {
        batch.set(
          _db.collection('orders').doc(orderId).collection('live').doc('rider'),
          {
            ...payload,
            'deliveryBoyId': id,
            'riderId': id,
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) debugPrint('[DriverLocationPublisher] write $e');
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    await stop();
  }
}
