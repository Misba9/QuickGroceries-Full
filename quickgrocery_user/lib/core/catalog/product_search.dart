/// Client-side product catalog search: case-insensitive partial match.
bool productMatchesSearchQuery(
  String query, {
  required String name,
  String category = '',
  String subcategory = '',
  String brand = '',
  String sku = '',
  String barcode = '',
  String description = '',
  String shopName = '',
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;

  bool hit(String value) => value.trim().toLowerCase().contains(q);

  return hit(name) ||
      hit(sku) ||
      hit(barcode) ||
      hit(brand) ||
      hit(category) ||
      hit(subcategory) ||
      hit(shopName) ||
      hit(description);
}

String firstNonEmptyField(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final v = data[key]?.toString().trim() ?? '';
    if (v.isNotEmpty) return v;
  }
  return '';
}
