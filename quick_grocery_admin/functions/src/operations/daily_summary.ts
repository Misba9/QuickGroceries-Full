import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { notifyAdmins, num, str } from "./ops_notify";

const db = admin.firestore();

/** Daily ops summary at 11:30 PM IST. */
export const dailySalesSummary = onSchedule(
  {
    schedule: "30 23 * * *",
    region: "us-central1",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const startTs = admin.firestore.Timestamp.fromDate(start);

    const ordersSnap = await db
      .collection("orders")
      .where("createdAt", ">=", startTs)
      .get();

    let revenue = 0;
    let failedPayments = 0;
    const productCounts: Record<string, number> = {};

    for (const doc of ordersSnap.docs) {
      const d = doc.data();
      if (d.isCancelled) continue;
      const bill = d.bill as Record<string, unknown> | undefined;
      revenue += num(bill?.total) || 0;
      if (str(d.paymentStatus) === "failed") failedPayments++;
      const products = (d.products as unknown[]) || [];
      for (const p of products) {
        const row = p as Record<string, unknown>;
        const name = str(row.name) || "item";
        productCounts[name] =
          (productCounts[name] || 0) + num(row.itemCount || 1);
      }
    }

    const customersSnap = await db
      .collection("customers")
      .where("createdAt", ">=", startTs)
      .get()
      .catch(() => null);

    const newUsers = customersSnap?.size ?? 0;
    const topProducts = Object.entries(productCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([name, count]) => `${name} (${count})`)
      .join(", ");

    const summary = {
      date: start.toISOString().slice(0, 10),
      totalOrders: ordersSnap.size,
      revenue,
      newUsers,
      failedPayments,
      topProducts,
    };

    await db.collection("daily_summaries").add({
      ...summary,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await notifyAdmins({
      title: "Daily summary",
      message: `${summary.totalOrders} orders · ₹${revenue.toFixed(0)} revenue · ${newUsers} new users`,
      type: "daily_summary",
      category: "system",
      metadata: summary,
    });
  }
);
