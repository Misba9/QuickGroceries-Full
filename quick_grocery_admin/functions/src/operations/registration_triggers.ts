import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { notifyAdmins, str } from "./ops_notify";

export const onCustomerCreated = onDocumentCreated(
  { document: "customers/{uid}", region: "us-central1" },
  async (event) => {
    const data = event.data?.data() as Record<string, unknown> | undefined;
    if (!data) return;
    const uid = event.params.uid;
    const name = str(data.name) || "Customer";
    const phone = str(data.phone);
    await notifyAdmins({
      title: "New customer",
      message: `${name}${phone ? ` · ${phone}` : ""} registered.`,
      type: "user_registered",
      category: "users",
      metadata: { userId: uid, role: "customer", name, phone },
    });
  }
);

export const onVendorCreated = onDocumentCreated(
  { document: "vendors/{vendorId}", region: "us-central1" },
  async (event) => {
    const data = event.data?.data() as Record<string, unknown> | undefined;
    if (!data) return;
    const vendorId = event.params.vendorId;
    const name = str(data.name || data.shopName) || "Vendor";
    await notifyAdmins({
      title: "New vendor",
      message: `${name} joined the platform.`,
      type: "vendor_registered",
      category: "vendors",
      metadata: { vendorId, name },
    });
  }
);

export const onDeliveryBoyCreated = onDocumentCreated(
  { document: "delivery_boys/{riderId}", region: "us-central1" },
  async (event) => {
    const data = event.data?.data() as Record<string, unknown> | undefined;
    if (!data) return;
    const riderId = event.params.riderId;
    const name = str(data.name) || "Rider";
    await notifyAdmins({
      title: "New delivery partner",
      message: `${name} registered as a rider.`,
      type: "delivery_registered",
      category: "delivery",
      metadata: { riderId, name },
    });
  }
);
