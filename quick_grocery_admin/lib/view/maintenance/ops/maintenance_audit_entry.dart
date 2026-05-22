import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceAuditEntry {
  MaintenanceAuditEntry({
    required this.id,
    required this.action,
    required this.adminUid,
    required this.createdAt,
  });

  final String id;
  final String action;
  final String? adminUid;
  final DateTime? createdAt;

  factory MaintenanceAuditEntry.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    DateTime? at;
    final raw = d['createdAt'];
    if (raw is Timestamp) at = raw.toDate();
    return MaintenanceAuditEntry(
      id: doc.id,
      action: d['action']?.toString() ?? 'update',
      adminUid: d['adminUid']?.toString(),
      createdAt: at,
    );
  }

  String get displayAction {
    switch (action) {
      case 'admin_save':
        return 'Published maintenance settings';
      case 'emergency_update':
        return 'Updated emergency controls';
      case 'force_maintenance':
        return 'Forced maintenance mode';
      case 'stop_orders':
        return 'Stopped all orders';
      case 'discard_draft':
        return 'Discarded unsaved changes';
      default:
        return action.replaceAll('_', ' ');
    }
  }
}
