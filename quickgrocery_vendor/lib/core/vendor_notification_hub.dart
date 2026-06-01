import 'package:flutter/foundation.dart';

import 'vendor_order_notification_controller.dart';

typedef VendorFcmOrderHandler = Future<void> Function(Map<String, dynamic> data);
typedef VendorBannerTrigger = void Function();

/// Global bridge: FCM / push layer → in-app banner + sound.
class VendorNotificationHub {
  VendorNotificationHub._();

  static final VendorNotificationHub instance = VendorNotificationHub._();

  VendorOrderNotificationController? notifications;
  VendorFcmOrderHandler? onFcmNewOrder;
  VendorBannerTrigger? onRequestBannerRefresh;
  String? vendorId;

  void register({
    required String vendorId,
    required VendorOrderNotificationController notifications,
    required VendorFcmOrderHandler onFcmNewOrder,
    VendorBannerTrigger? onRequestBannerRefresh,
  }) {
    this.vendorId = vendorId;
    this.notifications = notifications;
    this.onFcmNewOrder = onFcmNewOrder;
    this.onRequestBannerRefresh = onRequestBannerRefresh;
    if (kDebugMode) {
      debugPrint('[VendorNotify] hub registered vendor=$vendorId');
    }
  }

  void unregister() {
    vendorId = null;
    notifications = null;
    onFcmNewOrder = null;
    onRequestBannerRefresh = null;
  }

  Future<void> handleFcmPayload(Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint('[VendorNotify] FCM received type=${data['type']} orderId=${data['orderId']}');
    }
    final handler = onFcmNewOrder;
    if (handler != null) {
      await handler(data);
      return;
    }
    if (kDebugMode) {
      debugPrint('[VendorNotify] FCM received but hub not registered yet');
    }
  }

  void requestBannerRefresh() {
    onRequestBannerRefresh?.call();
  }

  bool get isReady => vendorId != null && onFcmNewOrder != null;
}
