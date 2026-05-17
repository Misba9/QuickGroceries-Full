import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import { seedTestAdminNotification } from "./ops_notify";

/** Writes a test document to `admin_notifications` (verify real-time UI). */
export const seedAdminTestNotification = onCall(
  callableBaseOptions(),
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const id = await seedTestAdminNotification();
    return { ok: true, id };
  }
);
