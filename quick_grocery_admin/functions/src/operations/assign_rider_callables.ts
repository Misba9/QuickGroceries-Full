import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import {
  assignRiderToOrder,
  autoAssignNearestRider,
  haversineKm,
} from "./rider_assignment";
import { OrderStatus, resolveStatus } from "./order_lifecycle";
import { getOpsSettings, num, str } from "./ops_notify";

const db = admin.firestore();

function orderNeedsRider(data: Record<string, unknown>): boolean {
  if (data.isCancelled === true || data.isDelivered === true) return false;
  if (str(data.deliveryBoyId)) return false;
  const status = resolveStatus(data);
  return status === OrderStatus.ORDER_PLACED;
}

/** Admin manually assigns a rider → status = rider_assigned. */
export const assignRiderCallable = onCall(callableBaseOptions(), async (request) => {
  await assertNotificationAdmin(request.auth?.uid);
  const orderId = str(request.data?.orderId);
  const riderId = str(request.data?.riderId);
  if (!orderId || !riderId) {
    throw new HttpsError("invalid-argument", "orderId and riderId are required");
  }

  try {
    await assignRiderToOrder(orderId, riderId, {
      assignedBy: "admin",
      riderName: str(request.data?.riderName),
      riderPhone: str(request.data?.riderPhone),
    });
    return { ok: true, orderId, riderId };
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Assignment failed";
    throw new HttpsError("failed-precondition", msg);
  }
});

/** Admin auto-assigns nearest online rider within radius (lowest workload). */
export const autoAssignRiderCallable = onCall(callableBaseOptions(), async (request) => {
  await assertNotificationAdmin(request.auth?.uid);
  const orderId = str(request.data?.orderId);
  if (!orderId) {
    throw new HttpsError("invalid-argument", "orderId is required");
  }

  try {
    const result = await autoAssignNearestRider(orderId);
    if (!result) {
      throw new HttpsError(
        "not-found",
        "No eligible rider online within radius",
      );
    }
    return { ok: true, orderId, ...result };
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    const msg = e instanceof Error ? e.message : "Auto-assign failed";
    throw new HttpsError("failed-precondition", msg);
  }
});

/** Batch auto-assign all unassigned orders ready for dispatch. */
export const autoAssignAllUnassignedCallable = onCall(
  callableBaseOptions(),
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const limit = Math.min(num(request.data?.limit) || 25, 50);

    const snap = await db
      .collection("orders")
      .where("isDelivered", "==", false)
      .limit(200)
      .get();

    const pending = snap.docs.filter((d) =>
      orderNeedsRider(d.data() as Record<string, unknown>),
    );

    let assigned = 0;
    const failures: string[] = [];

    for (const doc of pending.slice(0, limit)) {
      try {
        const result = await autoAssignNearestRider(doc.id);
        if (result) assigned++;
        else failures.push(`${doc.id}: no rider in range`);
      } catch (e) {
        failures.push(
          `${doc.id}: ${e instanceof Error ? e.message : "error"}`,
        );
      }
    }

    return {
      ok: true,
      assigned,
      attempted: Math.min(pending.length, limit),
      failures,
    };
  },
);

/** Preview ranked riders for an order (admin assign dialog). */
export const rankRidersForOrderCallable = onCall(
  callableBaseOptions(),
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const orderId = str(request.data?.orderId);
    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required");
    }

    const orderSnap = await db.collection("orders").doc(orderId).get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found");
    }
    const order = orderSnap.data() as Record<string, unknown>;
    const lat = num(order.lat);
    const lng = num(order.lng);
    if (!lat || !lng) {
      throw new HttpsError("failed-precondition", "Order has no coordinates");
    }

    const settings = await getOpsSettings();
    const radiusKm = num(settings.assignRadiusKm) || 8;

    const ridersSnap = await db.collection("delivery_boys").limit(100).get();
    const ranked: Array<{
      id: string;
      name: string;
      phone: string;
      distanceKm: number;
      workload: number;
      score: number;
      online: boolean;
      active: boolean;
      eligible: boolean;
    }> = [];

    for (const doc of ridersSnap.docs) {
      const r = doc.data() as Record<string, unknown>;
      const online = r.isOnline === true || r.online_status === true;
      const active =
        r.isActive !== false &&
        r.is_active !== false &&
        str(r.status).toLowerCase() !== "inactive";
      const rLat = num(r.lat ?? r.latitude);
      const rLng = num(r.lng ?? r.longitude);
      const workload = num(r.activeOrders ?? r.active_orders ?? 0);
      let distanceKm = 9999;
      if (rLat && rLng) {
        distanceKm = haversineKm(lat, lng, rLat, rLng);
      }
      const eligible = online && active && distanceKm <= radiusKm;
      const score = distanceKm * 1000 + workload * 100;
      ranked.push({
        id: doc.id,
        name:
          str(r.name) ||
          `${str(r.first_name)} ${str(r.last_name)}`.trim() ||
          "Rider",
        phone: str(r.phone),
        distanceKm: Math.round(distanceKm * 10) / 10,
        workload,
        score,
        online,
        active,
        eligible,
      });
    }

    ranked.sort((a, b) => {
      if (a.eligible !== b.eligible) return a.eligible ? -1 : 1;
      return a.score - b.score;
    });

    return { riders: ranked, radiusKm };
  },
);
