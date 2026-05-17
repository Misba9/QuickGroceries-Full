import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { notifyAdmins, str } from "./ops_notify";

/** Rider online/offline → admin alert. */
export const onDeliveryBoyStatusUpdated = onDocumentUpdated(
  { document: "delivery_boys/{riderId}", region: "us-central1" },
  async (event) => {
    const before = event.data?.before.data() as Record<string, unknown> | undefined;
    const after = event.data?.after.data() as Record<string, unknown> | undefined;
    if (!before || !after) return;
    const riderId = event.params.riderId;
    const name = str(after.name || after.fullName || riderId);
    const wasOnline = before.isOnline === true;
    const isOnline = after.isOnline === true;
    if (wasOnline === isOnline) return;

    if (!isOnline) {
      await notifyAdmins({
        title: "Driver offline",
        message: `${name} went offline.`,
        type: "driver_offline",
        category: "delivery",
        soundAlert: true,
        metadata: { deliveryBoyId: riderId, riderName: name },
      });
    }
  }
);
