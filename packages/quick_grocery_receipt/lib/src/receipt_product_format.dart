/// Build `Qty: 1 | 500 gm` from neutral product fields.
String receiptQtyLine({
  required int quantity,
  String variantName = '',
  num? weightAmount,
  String packUnit = '',
  String unit = '',
}) {
  final variant = variantName.trim();

  if (variant.isNotEmpty && RegExp(r'\d').hasMatch(variant)) {
    return 'Qty: $quantity | $variant';
  }

  final size = _packSizeText(weightAmount, packUnit);
  if (size.isNotEmpty) {
    return 'Qty: $quantity | $size';
  }

  final u = packUnit.isNotEmpty ? packUnit : unit.trim();
  if (u.isNotEmpty && _isCountOnlyUnit(u)) {
    return 'Qty: $quantity | ${_normalizeUnit(u)}';
  }

  return 'Qty: $quantity';
}

String _packSizeText(num? weight, String unit) {
  if (weight != null && unit.isNotEmpty) {
    final n = weight;
    final s = n == n.roundToDouble() ? n.round().toString() : n.toString();
    return '$s ${_normalizeUnit(unit)}';
  }
  return '';
}

bool _isCountOnlyUnit(String u) {
  final x = u.toLowerCase();
  return x == 'pcs' || x == 'pc' || x == 'pack' || x == 'bottle' || x == 'bunch';
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
