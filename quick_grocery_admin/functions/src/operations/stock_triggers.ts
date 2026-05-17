import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {
  getOpsSettings,
  notifyAdmins,
  notifyVendor,
  str,
  writeActivityLog,
} from "./ops_notify";

const db = admin.firestore();

export const onProductStockUpdated = onDocumentUpdated(
  { document: "products/{productId}", region: "us-central1" },
  async (event) => {
    const before = event.data?.before.data() as Record<string, unknown> | undefined;
    const after = event.data?.after.data() as Record<string, unknown> | undefined;
    if (!before || !after) return;
    const productId = event.params.productId;
    const prevStock = Number(before.stock ?? before.quantity ?? 0);
    const nextStock = Number(after.stock ?? after.quantity ?? 0);
    if (prevStock === nextStock) return;

    const settings = await getOpsSettings();
    const threshold = Number(settings.lowStockThreshold) || 10;
    const name = str(after.name) || productId;
    const vendorId = str(after.vendor_id || after.vendorId);

    const wasLow = prevStock > 0 && prevStock <= threshold;
    const isLow = nextStock > 0 && nextStock <= threshold;
    const wasOut = prevStock <= 0;
    const isOut = nextStock <= 0;

    if (isOut && !wasOut) {
      await db.collection("stock_alerts").add({
        productId,
        vendorId,
        productName: name,
        stock: nextStock,
        alertType: "out_of_stock",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await notifyAdmins({
        title: "Out of stock",
        message: `${name} is out of stock.`,
        type: "out_of_stock",
        category: "stock",
        metadata: { productId, vendorId, stock: nextStock },
      });
      if (vendorId) {
        await notifyVendor(vendorId, {
          title: "Out of stock",
          message: `${name} is out of stock. Restock soon.`,
          type: "out_of_stock",
          metadata: { productId },
        });
      }
      if (settings.autoDisableOutOfStock) {
        await db.collection("products").doc(productId).update({
          isAvailable: false,
          stockStatus: "out_of_stock",
        });
      }
    } else if (isLow && !wasLow && !isOut) {
      await db.collection("stock_alerts").add({
        productId,
        vendorId,
        productName: name,
        stock: nextStock,
        alertType: "low_stock",
        threshold,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await notifyAdmins({
        title: "Low stock",
        message: `${name} has only ${nextStock} left (threshold ${threshold}).`,
        type: "low_stock",
        category: "stock",
        metadata: { productId, vendorId, stock: nextStock, threshold },
      });
      if (vendorId) {
        await notifyVendor(vendorId, {
          title: "Low stock",
          message: `${name}: ${nextStock} units left.`,
          type: "low_stock",
          metadata: { productId, stock: nextStock },
        });
      }
    }

    const prevStatus = str(before.stockStatus);
    const newStatus = isOut
      ? "out_of_stock"
      : isLow
        ? "low_stock"
        : "in_stock";
    if (newStatus !== prevStatus) {
      await db.collection("products").doc(productId).set(
        { stockStatus: newStatus },
        { merge: true }
      );
    }

    await writeActivityLog({
      action: "stock_update",
      entityType: "product",
      entityId: productId,
      summary: `${name} stock ${prevStock} → ${nextStock}`,
      metadata: { vendorId, prevStock, nextStock },
    });
  }
);
