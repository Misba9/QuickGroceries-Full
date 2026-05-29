import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:quickgrocery/core/firebase/callable_payload.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/cart/screen/cart_screen.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/orders/presentation/screens/order_tracking_screen.dart';
import 'package:quickgrocery/view/product_view/screens/product_view_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Map<String, String> _stringData(Map<String, dynamic> raw) {
  final out = <String, String>{};
  raw.forEach((k, v) {
    out[k.toString()] = v == null ? '' : v.toString();
  });
  return out;
}

Future<void> recordPushOpenIfNeeded(Map<String, String> data) async {
  final logId = data['logId'] ?? '';
  if (logId.isEmpty) return;
  try {
    final payload = sanitizeCallableData(<String, dynamic>{'logId': logId});
    debugCallableData('recordNotificationOpen', payload);
    await FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('recordNotificationOpen').call(payload);
  } catch (_) {
    /* non-fatal */
  }
  try {
    await FirebaseAnalytics.instance.logEvent(
      name: 'notification_open',
      parameters: {'log_id': logId, 'redirect': data['redirectType'] ?? ''},
    );
  } catch (_) {
    /* analytics optional */
  }
}

String? _parseQuery(String link, String key) {
  try {
    final uri = Uri.parse(link);
    return uri.queryParameters[key];
  } catch (_) {
    return null;
  }
}

String? _lastPathSegment(String link) {
  try {
    final uri = Uri.parse(link);
    if (uri.pathSegments.isEmpty) return null;
    return uri.pathSegments.last;
  } catch (_) {
    return null;
  }
}

Future<void> _openProductById(BuildContext context, String? productId) async {
  if (productId == null || productId.isEmpty) return;
  try {
    final snap = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();
    if (!snap.exists || !context.mounted) return;
    final data = snap.data();
    if (data == null) return;
    final product = ProductModel.fromFirestore(data, snap.id);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductViewScreen(product: product),
      ),
    );
  } catch (_) {
    /* ignore */
  }
}

/// Handles FCM `data` payloads from taps and cold starts.
Future<void> handlePushNavigation(Map<String, dynamic> raw) async {
  final data = _stringData(raw);
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;

  await recordPushOpenIfNeeded(data);
  if (!ctx.mounted) return;

  var redirect = data['redirectType'] ?? '';
  if (redirect.isEmpty) {
    final dl = data['deepLink'] ?? '';
    if (dl.contains('offers')) redirect = 'offers_page';
    if (dl.contains('cart')) redirect = 'cart_page';
    if (dl.contains('order')) redirect = 'order_page';
    if (dl.contains('product')) redirect = 'product_page';
    if (dl.contains('category')) redirect = 'category_page';
  }

  final home = legacy.Provider.of<HomeProvider>(ctx, listen: false);

  switch (redirect) {
    case 'offers_page':
      home.onSelectedChange(2);
      return;
    case 'category_page':
      home.onSelectedChange(1);
      return;
    case 'cart_page':
      home.onSelectedChange(0);
      await Navigator.of(
        ctx,
      ).push(MaterialPageRoute<void>(builder: (_) => const CartScreen()));
      return;
    case 'order_details':
    case 'order_page':
      home.onSelectedChange(3);
      final dl = data['deepLink'] ?? '';
      final id = _parseQuery(dl, 'orderId') ?? _lastPathSegment(dl) ?? '';
      if (id.isNotEmpty) {
        await Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderTrackingScreen(orderId: id),
          ),
        );
      }
      return;
    case 'product_page':
      home.onSelectedChange(0);
      final dl = data['deepLink'] ?? '';
      final pid = _parseQuery(dl, 'productId') ?? _lastPathSegment(dl);
      await _openProductById(ctx, pid);
      return;
    case 'home':
    default:
      home.onSelectedChange(0);
  }
}
