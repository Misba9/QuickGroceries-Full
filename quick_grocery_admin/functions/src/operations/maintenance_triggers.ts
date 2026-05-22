import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { REGION } from "../https_callable_options";

const db = admin.firestore();

type MaintenanceSnap = Record<string, unknown>;

function wasEnabled(data: MaintenanceSnap | undefined): boolean {
  if (!data) return false;
  return Boolean(data.enabled ?? data.maintenance);
}

function localizedTitle(data: MaintenanceSnap): string {
  const title = data.title;
  if (typeof title === "string") return title;
  if (title && typeof title === "object") {
    const m = title as Record<string, string>;
    return m.en || m["en-US"] || "Quick Groceries";
  }
  return "Quick Groceries";
}

async function notifyTopic(topic: string, title: string, body: string) {
  try {
    await admin.messaging().send({
      topic,
      notification: { title, body },
      data: {
        type: "maintenance",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    });
    await db.collection("notification_logs").add({
      topic,
      title,
      body,
      type: "maintenance_auto",
      provider: "FCM",
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (e) {
    logger.error("maintenance FCM failed", { topic, e });
  }
}

/**
 * Sends push when maintenance is enabled/disabled or emergency close toggles.
 */
export const onMaintenanceConfigChange = onDocumentUpdated(
  {
    document: "app_config/maintenance",
    region: REGION,
  },
  async (event) => {
    const before = event.data?.before.data() as MaintenanceSnap | undefined;
    const after = event.data?.after.data() as MaintenanceSnap | undefined;
    if (!after) return;

    const prevEnabled = wasEnabled(before);
    const nextEnabled = wasEnabled(after);
    const prevEmergency = Boolean(before?.schedule &&
      typeof before.schedule === "object" &&
      (before.schedule as MaintenanceSnap).emergencyClose);
    const scheduleAfter = after.schedule as MaintenanceSnap | undefined;
    const nextEmergency = Boolean(scheduleAfter?.emergencyClose);

    const affected = (after.affectedApps as MaintenanceSnap) || {};
    const title = localizedTitle(after);

    if (!prevEnabled && nextEnabled) {
      let body = "The app is temporarily unavailable.";
      const msg = after.message;
      if (typeof msg === "string") body = msg;
      else if (msg && typeof msg === "object") {
        const m = msg as Record<string, string>;
        body = m.en || m["en-US"] || body;
      }
      if (affected.user) {
        await notifyTopic("user_app", title, String(body));
      }
      if (affected.vendor) {
        await notifyTopic("vendor_app", title, "Vendor app is under maintenance");
      }
      if (affected.driver) {
        await notifyTopic("driver_app", title, "Driver app is under maintenance");
      }
      return;
    }

    if (prevEnabled && !nextEnabled) {
      const reopenMsg = "We're back! Start ordering again.";
      if (affected.user) await notifyTopic("user_app", title, reopenMsg);
      if (affected.vendor) await notifyTopic("vendor_app", title, reopenMsg);
      if (affected.driver) await notifyTopic("driver_app", title, reopenMsg);
      return;
    }

    if (!prevEmergency && nextEmergency) {
      await notifyTopic(
        "user_app",
        title,
        "Emergency closure — ordering paused",
      );
    } else if (prevEmergency && !nextEmergency && nextEnabled) {
      await notifyTopic("user_app", title, "Service resumed — welcome back!");
    }
  },
);
