/**
 * Quick Grocery Admin — Cloud Functions
 *
 * Push notifications (FCM) + admin claim helpers.
 * Configure Firebase secrets / env as needed for `setAdminClaims` bootstrap.
 */
import * as admin from "firebase-admin";

admin.initializeApp();

export { setAdminClaims } from "./set_admin_claims";
export { syncAdminClaimsFromAdmins } from "./sync_admin_claims_from_admins";

export {
  sendTopicNotification,
  sendSingleNotification,
  scheduleNotification,
  notificationCampaignWorker,
  recordNotificationOpen,
} from "./fcm_notifications";

/** CORS-enabled HTTP endpoints for Flutter Web admin (localhost + hosting). */
export {
  sendTopicNotificationHttp,
  sendSingleNotificationHttp,
} from "./fcm_http_handlers";

/** Real-time operations: admin alerts, vendor/driver pushes, stock, carts. */
export {
  onOrderCreated,
  onOrderUpdated,
} from "./operations/order_triggers";
export {
  onCustomerCreated,
  onVendorCreated,
  onDeliveryBoyCreated,
} from "./operations/registration_triggers";
export { onProductStockUpdated } from "./operations/stock_triggers";
export { abandonedCartReminder } from "./operations/abandoned_cart";
export { dailySalesSummary } from "./operations/daily_summary";
