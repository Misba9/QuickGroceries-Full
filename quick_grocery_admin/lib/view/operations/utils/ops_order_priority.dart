import 'package:quick_grocery_admin/view/operations/utils/ops_firestore_helpers.dart';

enum OpsOrderPriority { high, medium, low }

abstract final class OpsOrderPriorityRules {
  static const _slaMinutes = 45;
  static const _codHighAmount = 1500;

  static OpsOrderPriority compute(Map<String, dynamic> d) {
    if (!OpsFirestoreHelpers.isActive(d)) return OpsOrderPriority.low;

    final created = OpsFirestoreHelpers.createdAt(d);
    final delayed = created != null &&
        DateTime.now().difference(created).inMinutes > _slaMinutes;

    final total = OpsFirestoreHelpers.orderTotal(d);
    final codHigh =
        OpsFirestoreHelpers.isCod(d) && total >= _codHighAmount;
    final express = OpsFirestoreHelpers.isExpress(d);

    if (delayed || codHigh || express) return OpsOrderPriority.high;

    if (OpsFirestoreHelpers.riderId(d).isEmpty) {
      return OpsOrderPriority.medium;
    }
    return OpsOrderPriority.low;
  }

  static String label(OpsOrderPriority p) {
    switch (p) {
      case OpsOrderPriority.high:
        return 'High';
      case OpsOrderPriority.medium:
        return 'Medium';
      case OpsOrderPriority.low:
        return 'Low';
    }
  }
}
