import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/view/home/data/home_product_debug.dart';

/// Ensures every `products` document has a numeric [product_index] so
/// explore can consistently `orderBy('product_index')` without falling
/// back to documentId (which skips the admin sort order).
///
/// Runs once per process after first paint. Soft-fails when security rules
/// deny client writes — admin/vendor should still write the field on create.
abstract final class ProductIndexBackfill {
  static bool _started = false;

  static Future<void> ensureIndexes({
    FirebaseFirestore? firestore,
    int batchSize = 400,
  }) async {
    if (_started) return;
    _started = true;

    final db = firestore ?? FirebaseFirestore.instance;
    final col = db.collection('products');

    try {
      // Documents missing the field are excluded from orderBy(product_index).
      // Pull by documentId and assign contiguous indexes where absent.
      final snap = await col.orderBy(FieldPath.documentId).limit(batchSize).get();
      if (snap.docs.isEmpty) return;

      var nextIndex = 0;
      try {
        final maxSnap = await col
            .orderBy('product_index', descending: true)
            .limit(1)
            .get();
        if (maxSnap.docs.isNotEmpty) {
          final raw = maxSnap.docs.first.data()['product_index'];
          if (raw is num) nextIndex = raw.toInt() + 1;
        }
      } catch (_) {
        // No indexed docs yet — start at 0.
      }

      var writes = 0;
      var batch = db.batch();
      var opsInBatch = 0;

      Future<void> commit() async {
        if (opsInBatch == 0) return;
        await batch.commit();
        writes += opsInBatch;
        batch = db.batch();
        opsInBatch = 0;
      }

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data.containsKey('product_index') && data['product_index'] is num) {
          continue;
        }
        batch.set(
          doc.reference,
          {'product_index': nextIndex++},
          SetOptions(merge: true),
        );
        opsInBatch++;
        if (opsInBatch >= 400) await commit();
      }
      await commit();

      logHomeProducts(
        'product_index backfill: scanned=${snap.docs.length} wrote=$writes '
        'nextIndex=$nextIndex',
      );
    } catch (e, st) {
      // Expected when customers cannot write `products` — explore still
      // synthesizes indexes in-memory for the session.
      logHomeProducts('product_index backfill skipped/failed: $e', error: true);
      if (kDebugMode) debugPrintStack(stackTrace: st);
    }
  }
}
