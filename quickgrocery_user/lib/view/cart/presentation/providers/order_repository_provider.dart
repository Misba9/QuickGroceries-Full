import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/order_inventory_validator.dart';
import '../../data/order_placement_client.dart';
import '../../data/order_repository.dart';
import 'cart_notifier.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(firebaseFirestoreProvider));
});

final orderPlacementClientProvider = Provider<OrderPlacementClient>((ref) {
  return OrderPlacementClient();
});

final orderInventoryValidatorProvider =
    Provider<OrderInventoryValidator>((ref) {
  return OrderInventoryValidator(ref.watch(firebaseFirestoreProvider));
});
