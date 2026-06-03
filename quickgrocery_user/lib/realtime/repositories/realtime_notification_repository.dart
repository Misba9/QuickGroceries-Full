import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/realtime/models/notification_item.dart';
import 'package:quickgrocery/realtime/services/realtime_notification_service.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';

class RealtimeNotificationRepository {
  RealtimeNotificationRepository(this._service);
  final RealtimeNotificationService _service;

  Stream<List<NotificationItem>> watch(String uid, {int limit = 50}) {
    if (uid.isEmpty) return Stream.value(const []);
    return _service.watch(uid, limit: limit).map(_mapList).handleError(
          _throwHomeFailure('Failed to watch notifications.'),
        );
  }

  /// Unread count derived from the same feed stream so badge matches the list.
  Stream<int> watchUnreadCount(String uid) {
    if (uid.isEmpty) return Stream.value(0);
    return watch(uid).map((items) => items.where((e) => !e.read).length).handleError(
          _throwHomeFailure('Failed to watch unread notifications.'),
        );
  }

  Future<void> markAsRead(String uid, String id) =>
      _service.markAsRead(uid, id);

  Future<void> markAllAsRead(String uid) => _service.markAllAsRead(uid);

  // ── helpers ────────────────────────────────────────────────────────

  List<NotificationItem> _mapList(QuerySnapshot<Map<String, dynamic>> snap) {
    final out = <NotificationItem>[];
    for (final d in snap.docs) {
      try {
        out.add(NotificationItem.fromFirestore(d.data(), d.id));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[RealtimeNotifRepo] parse fail ${d.id}: $e');
        }
      }
    }
    return out;
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
