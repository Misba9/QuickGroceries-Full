import 'package:quickgrocery/core/order/order_line_pricing.dart';
import 'package:quickgrocery/models/order_model.dart';

/// Compact qty line for order UI: `Qty: 1 | 500 gm`
String orderLineQtyDetail(ProductItem p) {
  final size = orderLinePackSize(p);
  if (size.isEmpty) {
    final u = p.packUnit.isNotEmpty ? p.packUnit : p.unit;
    if (u.isNotEmpty) return 'Qty: ${p.itemCount} | $u';
    return 'Qty: ${p.itemCount} | pcs';
  }
  return 'Qty: ${p.itemCount} | $size';
}

/// `1 × ₹169 = ₹169` using snapshot paid prices.
String orderLinePaidQtySummary(ProductItem p) {
  final unit = formatOrderMoney(p.unitPricePaid);
  final line = formatOrderMoney(p.lineTotal);
  return '${p.itemCount} × ₹$unit = ₹$line';
}

String orderLinePackSize(ProductItem p) {
  if (p.variantName.trim().isNotEmpty) return p.variantName.trim();
  if (p.weightAmount != null && p.packUnit.isNotEmpty) {
    final n = p.weightAmount!;
    final s = n == n.roundToDouble() ? n.round().toString() : n.toString();
    return '$s ${p.packUnit}';
  }
  return formatProductQuantityLabel(
    unitPerItem: p.unitPerItem,
    unit: p.unit,
    packQuantity: p.packQuantity,
    packWeight: p.packWeight,
    measurementType: p.measurementType,
  );
}

String formatProductQuantityLabel({
  String unitPerItem = '',
  String unit = '',
  String packQuantity = '',
  String packWeight = '',
  String measurementType = '',
}) {
  String normNumber(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final n = num.tryParse(t);
    if (n == null) return t;
    if (n == n.round()) return n.round().toString();
    final s = n.toString();
    if (s.endsWith('.0')) return s.substring(0, s.length - 2);
    return s;
  }

  String displayUnit(String u) {
    final x = u.trim().toLowerCase();
    switch (x) {
      case 'g':
        return 'gm';
      case 'ltr':
      case 'liter':
      case 'litre':
        return 'L';
      case 'pc':
        return 'pcs';
      default:
        return u.trim();
    }
  }

  bool hasNumber(String s) => RegExp(r'\d').hasMatch(s);

  final pq = packQuantity.trim();
  final pw = packWeight.trim();
  final uRaw = unit.trim();
  final upi = unitPerItem.trim();

  if (pq.isNotEmpty && uRaw.isNotEmpty && hasNumber(pq)) {
    return '${normNumber(pq)} ${displayUnit(uRaw)}';
  }
  if (pw.isNotEmpty && uRaw.isNotEmpty && hasNumber(pw)) {
    return '${normNumber(pw)} ${displayUnit(uRaw)}';
  }
  if (upi.isNotEmpty && hasNumber(upi)) return upi;
  return '';
}
