import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/order_repository.dart';
import 'cart_notifier.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(firebaseFirestoreProvider));
});
