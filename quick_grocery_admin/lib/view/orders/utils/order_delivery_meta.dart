import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDeliverySlot {
  const OrderDeliverySlot({
    required this.slotId,
    required this.slotName,
    required this.startTime,
    required this.endTime,
    required this.slotType,
  });

  final String slotId;
  final String slotName;
  final DateTime? startTime;
  final DateTime? endTime;
  final String slotType;

  bool get isExpress =>
      slotType.toLowerCase() == 'express' ||
      slotName.toLowerCase().contains('express');

  static OrderDeliverySlot? fromFirestore(Map<String, dynamic> data) {
    final raw = data['deliverySlot'] ?? data['delivery_slot'];
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    return OrderDeliverySlot(
      slotId: (m['slotId'] ?? m['id'] ?? '').toString(),
      slotName: (m['slotName'] ?? m['label'] ?? '').toString(),
      startTime: _readTime(m['startTime'] ?? m['start']),
      endTime: _readTime(m['endTime'] ?? m['end']),
      slotType: (m['slotType'] ??
              (m['isExpress'] == true ? 'Express' : 'Scheduled'))
          .toString(),
    );
  }
}

class OrderDeliveryInstructions {
  const OrderDeliveryInstructions({
    this.instructionText = '',
    this.leaveAtDoor = false,
    this.gateCode = '',
    this.landmark = '',
    this.notes = '',
  });

  final String instructionText;
  final bool leaveAtDoor;
  final String gateCode;
  final String landmark;
  final String notes;

  bool get isEmpty =>
      instructionText.isEmpty &&
      !leaveAtDoor &&
      gateCode.isEmpty &&
      landmark.isEmpty &&
      notes.isEmpty;

  static OrderDeliveryInstructions fromFirestore(Map<String, dynamic> data) {
    final raw =
        data['deliveryInstructions'] ?? data['delivery_instructions'];
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return OrderDeliveryInstructions(
        instructionText:
            (m['instructionText'] ?? m['text'] ?? '').toString(),
        leaveAtDoor: m['leaveAtDoor'] == true || m['leave_at_door'] == true,
        gateCode: (m['gateCode'] ?? m['gate_code'] ?? '').toString(),
        landmark: (m['landmark'] ?? '').toString(),
        notes: (m['notes'] ?? '').toString(),
      );
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return OrderDeliveryInstructions(instructionText: raw.trim());
    }
    return const OrderDeliveryInstructions();
  }

  List<String> displayLines() {
    final lines = <String>[];
    if (gateCode.isNotEmpty) lines.add('Gate code: $gateCode');
    if (landmark.isNotEmpty) lines.add('Landmark: $landmark');
    if (leaveAtDoor) lines.add('Leave at door: Yes');
    if (notes.isNotEmpty) lines.add('Notes: $notes');
    if (lines.isEmpty && instructionText.isNotEmpty) {
      lines.add(instructionText);
    }
    return lines;
  }
}

String formatDeliverySlotLabel(OrderDeliverySlot? slot) {
  if (slot == null || slot.slotName.isEmpty) return '—';
  if (slot.isExpress) {
    final name =
        slot.slotName.replaceAll(RegExp(r'^Express\s*[·•\-]\s*'), '');
    return 'Express • $name';
  }
  if (slot.slotName.contains('Today') || slot.slotName.contains('Tomorrow')) {
    return slot.slotName;
  }
  final start = slot.startTime;
  final end = slot.endTime;
  if (start == null) return slot.slotName;
  final day = _dayLabel(start);
  final range = end != null ? _timeRange(start, end) : _fmtTime(start);
  return '$day • $range';
}

String _dayLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  if (day == today) return 'Today';
  if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
  return DateFormat('EEE, MMM d').format(dt);
}

String _timeRange(DateTime start, DateTime end) =>
    '${_fmtTime(start)} - ${_fmtTime(end)}';

String _fmtTime(DateTime t) {
  final h = t.hour;
  final period = h >= 12 ? 'PM' : 'AM';
  final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$hour12 $period';
}

DateTime? _readTime(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
