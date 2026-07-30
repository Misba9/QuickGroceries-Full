import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import {
  getOpsSettings,
  sendPushToToken,
  str,
  writeActivityLog,
} from "./ops_notify";

const db = admin.firestore();

/** Hourly scan for inactive carts → reminder push. */
export const abandonedCartReminder = onSchedule(
  {
    schedule: "every 60 minutes",
    region: "us-central1",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const settings = await getOpsSettings();
    if (!settings.abandonedCartEnabled) return;

    const delayHours = Number(settings.abandonedCartDelayHours) || 24;
    const cutoff = admin.firestore.Timestamp.fromMillis(
      Date.now() - delayHours * 60 * 60 * 1000
    );

    const carts = await db.collection("cart").limit(200).get();
    for (const doc of carts.docs) {
      const uid = doc.id;
      const data = doc.data();
      const items = (data.items as unknown[]) || [];
      if (items.length === 0) continue;

      const updatedAt = data.updatedAt as admin.firestore.Timestamp | undefined;
      if (updatedAt && updatedAt.toMillis() > cutoff.toMillis()) continue;

      const alertId = `${uid}_${delayHours}h`;
      const existing = await db.collection("abandoned_carts").doc(alertId).get();
      if (existing.exists) continue;

      const cust = await db.collection("customers").doc(uid).get();
      const token = str(cust.data()?.fcmToken || cust.data()?.fcm_token);
      const first = items[0] as Record<string, unknown>;
      const productName = str(first.name || first.productName) || "items";

      const title = "Your cart is waiting";
      const body = `You left ${productName} in your cart. Complete checkout before offers expire!`;

      if (token) {
        await sendPushToToken({
          token,
          title,
          body,
          soundType: "offers",
          deepLink: "/cart",
          redirectType: "cart_page",
          eventId: `abandoned_cart:${uid}:${alertId}`,
          data: {
            type: "abandoned_cart",
            notificationType: "abandoned_cart",
            targetScreen: "cart_page",
            title,
            message: body,
            deepLink: "/cart",
            redirectType: "cart_page",
            soundType: "offers",
          },
        });
      }

      await db.collection("abandoned_carts").doc(alertId).set({
        userId: uid,
        itemCount: items.length,
        productHint: productName,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        delayHours,
      });

      await writeActivityLog({
        action: "abandoned_cart_reminder",
        entityType: "cart",
        entityId: uid,
        summary: body,
        metadata: { itemCount: items.length },
      });
    }
  }
);
