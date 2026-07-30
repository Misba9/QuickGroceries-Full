import 'package:intl/intl.dart';

/// Consistent order / invoice timestamps across apps.
///
/// Prefers Firestore [createdAt] (UTC stored → local wall clock).
/// Falls back to legacy `created_date` strings only when needed.
abstract final class OrderDateTimeFormat {
  static final DateFormat displayFormat =
      DateFormat('dd MMM yyyy, hh:mm a');

  /// Format for invoices, PDFs, and order detail headers.
  static String format(DateTime? date) {
    if (date == null) return '—';
    return displayFormat.format(date.toLocal());
  }

  /// Prefer server timestamp, then parseable legacy string.
  static DateTime? resolve({
    DateTime? createdAt,
    String? createdDate,
  }) {
    if (createdAt != null) return createdAt;
    final raw = createdDate?.trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String formatOrder({
    DateTime? createdAt,
    String? createdDate,
  }) {
    return format(resolve(createdAt: createdAt, createdDate: createdDate));
  }
}
