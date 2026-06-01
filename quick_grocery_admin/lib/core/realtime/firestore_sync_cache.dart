import 'package:cloud_firestore/cloud_firestore.dart';

/// In-memory index updated from Firestore [docChanges] (incremental sync).
class FirestoreSyncCache<T> {
  final Map<String, T> _byId = {};

  bool get isEmpty => _byId.isEmpty;
  int get length => _byId.length;
  Iterable<T> get values => _byId.values;
  Map<String, T> get snapshot => Map.unmodifiable(_byId);

  void clear() => _byId.clear();

  void applySnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
    T Function(Map<String, dynamic> data, String id) parse, {
    void Function(DocumentChangeType type, String id)? onChange,
  }) {
    if (snap.docChanges.isEmpty && snap.docs.isNotEmpty) {
      for (final doc in snap.docs) {
        _byId[doc.id] = parse(doc.data(), doc.id);
      }
      return;
    }

    for (final change in snap.docChanges) {
      final id = change.doc.id;
      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          _byId[id] = parse(change.doc.data() ?? <String, dynamic>{}, id);
          onChange?.call(change.type, id);
        case DocumentChangeType.removed:
          _byId.remove(id);
          onChange?.call(change.type, id);
      }
    }
  }

  List<T> sorted(int Function(T a, T b) compare) {
    final list = _byId.values.toList();
    list.sort(compare);
    return list;
  }
}
