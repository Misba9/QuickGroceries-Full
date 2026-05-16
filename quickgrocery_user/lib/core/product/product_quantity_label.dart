import 'package:quickgrocery/models/product.dart';

/// Human-readable pack size for product tiles (home, category, search, etc.).
///
/// Uses admin / Firestore fields when present:
/// [ProductModel.packQuantity] (`quantity`), [ProductModel.packWeight] (`weight`),
/// [ProductModel.measurementType] (`measurement_type`), plus legacy
/// [ProductModel.unitPerItem] + [ProductModel.unit].
String productQuantityLabel(ProductModel p) {
  return formatProductQuantityLabel(
    unitPerItem: p.unitPerItem,
    unit: p.unit,
    packQuantity: p.packQuantity,
    packWeight: p.packWeight,
    measurementType: p.measurementType,
  );
}

/// Same logic as [productQuantityLabel] for legacy UIs that only have strings.
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
      case 'ltr':
        return 'L';
      case 'liter':
      case 'litre':
        return 'litre';
      case 'pcs':
      case 'pc':
      case 'gm':
      case 'kg':
      case 'ml':
      case 'g':
        return x == 'g' ? 'gm' : x;
      default:
        return u.trim();
    }
  }

  bool hasLetters(String s) => RegExp(r'[A-Za-z]').hasMatch(s);

  final pq = packQuantity.trim();
  final pw = packWeight.trim();
  final mt = measurementType.trim();
  final uRaw = unit.trim();
  final uDisp = displayUnit(uRaw);
  final upi = unitPerItem.trim();

  if (pq.isNotEmpty && uRaw.isNotEmpty) {
    return '${normNumber(pq)} $uDisp'.trim();
  }
  if (pw.isNotEmpty && uRaw.isNotEmpty) {
    return '${normNumber(pw)} $uDisp'.trim();
  }
  if (pw.isNotEmpty && mt.isNotEmpty && uRaw.isEmpty) {
    return '${normNumber(pw)} ${mt.toLowerCase()}'.trim();
  }

  if (upi.isEmpty && uRaw.isEmpty) return '';

  if (hasLetters(upi)) {
    return upi;
  }

  if (uRaw.isEmpty) return upi;
  if (upi.isEmpty) return uDisp;

  final lower = upi.toLowerCase();
  final ut = uRaw.toLowerCase();
  if (lower == ut || lower.endsWith(' $ut') || lower.endsWith(ut)) {
    return upi;
  }

  return '${normNumber(upi)} $uDisp'.trim();
}
