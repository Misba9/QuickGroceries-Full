import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { str, writeAdminNotification } from "./ops_notify";

/** Vendor signup via direct Firestore create (vendor app) → admin alert. */
export const onVendorRequestCreated = onDocumentCreated(
  { document: "vendor_requests/{requestId}", region: "us-central1" },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const requestId = event.params.requestId;
    const data = snap.data() as Record<string, unknown>;
    const firstName = str(data.firstName);
    const lastName = str(data.lastName);
    const shopName = str(data.shopName);
    const email = str(data.email);

    await writeAdminNotification({
      title: "New vendor signup request",
      message: `${firstName} ${lastName} (${shopName}) requested vendor access.`,
      type: "vendor_request",
      category: "vendors",
      sourceApp: "vendor_app",
      soundAlert: true,
      metadata: { requestId, email, shopName },
    });
  }
);
