import 'package:quick_grocery_admin/model/order_model.dart';

/// Paid unit × qty = line total, plus pack size when known.
String productInvoiceQtyLine(ProductItem p) {
  final qty = p.itemCount;
  final unitPaid = _money(p.price);
  final line = _money(p.lineTotal);
  final paid = '$qty × ₹$unitPaid = ₹$line';

  final variant = p.variantName.trim();
  if (variant.isNotEmpty && RegExp(r'\d').hasMatch(variant)) {
    return 'Qty: $paid | $variant';
  }

  final size = _packSizeText(p);
  if (size.isNotEmpty) {
    return 'Qty: $paid | $size';
  }

  final u = p.packUnit.isNotEmpty ? p.packUnit : p.unit.trim();
  if (u.isNotEmpty && _isCountOnlyUnit(u)) {
    return 'Qty: $paid | ${_normalizeUnit(u)}';
  }

  return 'Qty: $paid';
}

String _money(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

String _packSizeText(ProductItem p) {
  if (p.weightAmount != null && p.packUnit.isNotEmpty) {
    final n = p.weightAmount!;
    final s = n == n.roundToDouble() ? n.round().toString() : n.toString();
    return '$s ${_normalizeUnit(p.packUnit)}';
  }
  return '';
}

bool _isCountOnlyUnit(String u) {
  final x = u.toLowerCase();
  return x == 'pcs' ||
      x == 'pc' ||
      x == 'pack' ||
      x == 'bottle' ||
      x == 'bunch';
}

String _normalizeUnit(String u) {
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

double productLineAmount(ProductItem p) => p.lineTotal;
