import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/realtime/models/rider_live_location.dart';
import 'package:quickgrocery/realtime/services/realtime_delivery_service.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';

class RealtimeDeliveryRepository {
  RealtimeDeliveryRepository(this._service);
  final RealtimeDeliveryService _service;

  Stream<RiderLiveLocation?> watchRider(String id) {
    if (id.isEmpty) return Stream.value(null);
    return _service.watchRider(id).map((doc) {
      if (!doc.exists) return null;
      try {
        return RiderLiveLocation.fromFirestore(doc.data()!, doc.id);
      } catch (e) {
        if (kDebugMode) debugPrint('[RealtimeDeliveryRepo] parse fail: $e');
        return null;
      }
    }).handleError(_throwHomeFailure('Failed to watch rider.'));
  }

  void Function(Object, StackTrace) _throwHomeFailure(String message) {
    return (Object error, StackTrace stackTrace) {
      throw HomeFailure(message, code: _codeOf(error), cause: error);
    };
  }

  String? _codeOf(Object error) {
    if (error is FirebaseException) return error.code;
    return null;
  }
}
