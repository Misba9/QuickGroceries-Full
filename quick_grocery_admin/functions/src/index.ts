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
