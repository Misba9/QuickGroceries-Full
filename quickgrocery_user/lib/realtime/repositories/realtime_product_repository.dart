import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/realtime/models/inventory_snapshot.dart';
import 'package:quickgrocery/realtime/services/realtime_product_service.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';

/// Realtime product repository — wraps [RealtimeProductService] and
/// returns parsed, error-enveloped streams.
///
/// Robustness:
/// * Per-document try/catch — one bad doc never empties a list.
/// * `FirebaseException` → [HomeFailure] with code (so UI rails can
///   show a typed error chip).
class RealtimeProductRepository {
  RealtimeProductRepository(this._service);
  final RealtimeProductService _service;

  /// Stream of one product. Emits `null` if the doc is removed; rethrows
  /// on permission errors.
  Stream<ProductModel?> watchProduct(String id) {
    return _service.watchProduct(id).map((doc) {
      if (!doc.exists) return null;
      try {
        return ProductModel.fromFirestore(doc.data()!, doc.id);
      } catch (e) {
        if (kDebugMode) debugPrint('[RealtimeProductRepo] parse fail: $e');
        return null;
      }
    }).handleError(_throwHomeFailure('Failed to watch product.'));
  }

  Stream<List<ProductModel>> watchByCategory(
    String categoryId, {
    int? limit,
  }) {
    return _service
        .watchByCategory(categoryId, limit: limit)
        .map(_mapList)
        .handleError(_throwHomeFailure('Failed to watch category.'));
  }

  /// Live inventory map for an arbitrary list of ids — sharded under
  /// the hood (Firestore `whereIn` cap = 30) and merged back into a
  /// single `Map<id, snapshot>`.
  ///
  /// Cart / wishlist screens call this with their current product ids,
  /// then patch line items as inventory ticks change. The merge runs
  /// `.combineLatest` over the shards so any shard tick re-emits the
  /// whole map.
  Stream<Map<String, InventorySnapshot>> watchInventoryFor(List<String> ids) {
    if (ids.isEmpty) {
      return Stream.value(const <String, InventorySnapshot>{});
    }

    final shards = _service.watchByIdsSharded(ids).toList();
    if (shards.length == 1) return shards.first.map(_inventoryFromSnap);

    return Rx.combineLatestList<QuerySnapshot<Map<String, dynamic>>>(shards)
        .map((snaps) {
      final out = <String, InventorySnapshot>{};
      for (final s in snaps) {
        out.addAll(_inventoryFromSnap(s));
      }
      return out;
    }).handleError(_throwHomeFailure('Failed to watch inventory.'));
  }

  Stream<List<ProductModel>> watchLowStock({int threshold = 5, int limit = 50}) {
    return _service
        .watchLowStock(threshold: threshold, limit: limit)
        .map(_mapList)
        .handleError(_throwHomeFailure('Failed to watch low stock.'));
  }

  // ── helpers ────────────────────────────────────────────────────────

  List<ProductModel> _mapList(QuerySnapshot<Map<String, dynamic>> snap) {
    final out = <ProductModel>[];
    for (final d in snap.docs) {
      try {
        out.add(ProductModel.fromFirestore(d.data(), d.id));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[RealtimeProductRepo] parse fail id=${d.id} err=$e');
        }
      }
    }
    return out;
  }

  Map<String, InventorySnapshot> _inventoryFromSnap(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final out = <String, InventorySnapshot>{};
    for (final d in snap.docs) {
      try {
        final p = ProductModel.fromFirestore(d.data(), d.id);
        out[d.id] = InventorySnapshot(
          id: p.id,
          price: p.price,
          slashedPrice: p.slashedPrice,
          stock: p.stock,
          isAvailable: p.isAvailable,
          maxOrder: p.maxOrder,
          minOrderQuantity: p.minOrderQuantity,
          stockStatus: p.stockStatus,
        );
      } catch (_) {
        // single-doc parse failures are silent — see watchProduct for
        // verbose mode.
      }
    }
    return out;
  }

  void Function(Object, StackTrace) _throwHomeFailure(String message) {
    return (Object error, StackTrace stackTrace) {
      throw HomeFailure(message, code: _codeOf(error), cause: error);
    };
  }

  String? _codeOf(Object error) {
    if (error is FirebaseException) return error.code;
    return null;
  }
}
