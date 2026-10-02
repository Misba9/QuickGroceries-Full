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

/// Splits [text] into spans with [highlightStyle] on case-insensitive [query] matches.
List<({String text, bool highlight})> splitHighlightedSegments(
  String text,
  String query,
) {
  final q = query.trim();
  if (q.isEmpty || text.isEmpty) {
    return [(text: text, highlight: false)];
  }

  final lowerText = text.toLowerCase();
  final lowerQuery = q.toLowerCase();
  final out = <({String text, bool highlight})>[];
  var start = 0;

  while (true) {
    final index = lowerText.indexOf(lowerQuery, start);
    if (index < 0) {
      if (start < text.length) {
        out.add((text: text.substring(start), highlight: false));
      }
      break;
    }
    if (index > start) {
      out.add((text: text.substring(start, index), highlight: false));
    }
    out.add((
      text: text.substring(index, index + q.length),
      highlight: true,
    ));
    start = index + q.length;
  }

  return out.isEmpty ? [(text: text, highlight: false)] : out;
}
