import { FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import {
  OrderStatus,
  statusToLegacy,
} from "./order_lifecycle";
import { getOpsSettings, num, str } from "./ops_notify";

const db = admin.firestore();

export type RiderCandidate = {
  id: string;
  name: string;
  phone: string;
  lat: number;
  lng: number;
  distanceKm: number;
  workload: number;
  score: number;
};

/** Haversine distance in km between two lat/lng points. */
export function haversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function riderCanReceiveAssignments(data: Record<string, unknown>): boolean {
  if (!riderIsActive(data)) return false;
  const availability = str(data.availability_status).toLowerCase();
  if (availability === "online") return true;
  if (availability === "offline" || availability === "paused") return false;
  if (data.pause_deliveries === true) return false;
  return data.isOnline === true || data.online_status === true;
}

function riderIsActive(data: Record<string, unknown>): boolean {
  if (data.isActive === false || data.is_active === false) return false;
  const status = str(data.status).toLowerCase();
  if (status === "inactive" || status === "blocked" || status === "suspended") {
    return false;
  }
  return true;
}

function riderName(data: Record<string, unknown>): string {
  const direct = str(data.name);
  if (direct) return direct;
  return `${str(data.first_name)} ${str(data.last_name)}`.trim() || "Rider";
}

function riderPhone(data: Record<string, unknown>): string {
  return str(data.phone);
}

function riderCoords(data: Record<string, unknown>): { lat: number; lng: number } {
  const lat = num(data.lat ?? data.latitude);
  const lng = num(data.lng ?? data.longitude);
  return { lat, lng };
}

function riderWorkload(data: Record<string, unknown>): number {
  return num(
    data.activeOrders ??
      data.active_orders ??
      data.activeOrderCount ??
      0,
  );
}

/** Score eligible riders: online + active + within radius → lowest distance + workload wins. */
export async function findBestRiderForOrder(
  orderLat: number,
  orderLng: number,
  radiusKm?: number,
): Promise<RiderCandidate | null> {
  const settings = await getOpsSettings();
  const maxRadius =
    radiusKm ?? (num(settings.assignRadiusKm) || 8);

  const ridersSnap = await db.collection("delivery_boys").limit(100).get();
  if (ridersSnap.empty) return null;

  let best: RiderCandidate | null = null;

  for (const doc of ridersSnap.docs) {
    const r = doc.data() as Record<string, unknown>;
    if (!riderCanReceiveAssignments(r)) continue;

    const { lat, lng } = riderCoords(r);
    if (!lat || !lng || !orderLat || !orderLng) continue;

    const distanceKm = haversineKm(orderLat, orderLng, lat, lng);
    if (distanceKm > maxRadius) continue;

    const workload = riderWorkload(r);
    const score = distanceKm * 1000 + workload * 100;

    const candidate: RiderCandidate = {
      id: doc.id,
      name: riderName(r),
      phone: riderPhone(r),
      lat,
      lng,
      distanceKm,
      workload,
      score,
    };

    if (!best || candidate.score < best.score) {
      best = candidate;
    }
  }

  return best;
}

/** Assign rider to order — sets status = rider_assigned and sync fields. */
export async function assignRiderToOrder(
  orderId: string,
  riderId: string,
  opts: {
    autoAssigned?: boolean;
    assignedBy?: string;
    riderName?: string;
    riderPhone?: string;
  } = {},
): Promise<void> {
  if (!orderId || !riderId) {
    throw new Error("orderId and riderId are required");
  }

  const orderRef = db.collection("orders").doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) throw new Error("Order not found");

  const order = orderSnap.data() as Record<string, unknown>;
  if (order.isCancelled === true) throw new Error("Order is cancelled");
  if (order.isDelivered === true) throw new Error("Order already delivered");
  if (str(order.deliveryBoyId)) throw new Error("Order already has a rider");

  let name = opts.riderName ?? "";
  let phone = opts.riderPhone ?? "";
  if (!name || !phone) {
    const riderSnap = await db.collection("delivery_boys").doc(riderId).get();
    if (riderSnap.exists) {
      const r = riderSnap.data() as Record<string, unknown>;
      if (!name) name = riderName(r);
      if (!phone) phone = riderPhone(r);
    }
  }

  await orderRef.update({
    deliveryBoyId: riderId,
    delivery_boy_id: riderId,
    riderName: name,
    riderPhone: phone,
    status: OrderStatus.RIDER_ASSIGNED,
    order_status: statusToLegacy(OrderStatus.RIDER_ASSIGNED),
    assignedAt: FieldValue.serverTimestamp(),
    assignedBy: opts.assignedBy ?? (opts.autoAssigned ? "auto" : "admin"),
    autoAssigned: opts.autoAssigned === true,
    updatedAt: FieldValue.serverTimestamp(),
  });

  await db
    .collection("delivery_boys")
    .doc(riderId)
    .set(
      {
        activeOrders: FieldValue.increment(1),
        active_orders: FieldValue.increment(1),
        lastAssignedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
}

/** Auto-assign nearest eligible rider for one order. Returns rider id or null. */
export async function autoAssignNearestRider(
  orderId: string,
): Promise<{ riderId: string; riderName: string; distanceKm: number } | null> {
  const orderSnap = await db.collection("orders").doc(orderId).get();
  if (!orderSnap.exists) throw new Error("Order not found");

  const order = orderSnap.data() as Record<string, unknown>;
  if (str(order.deliveryBoyId)) throw new Error("Order already assigned");

  const lat = num(order.lat);
  const lng = num(order.lng);
  if (!lat || !lng) throw new Error("Order has no delivery coordinates");

  const best = await findBestRiderForOrder(lat, lng);
  if (!best) return null;

  await assignRiderToOrder(orderId, best.id, {
    autoAssigned: true,
    assignedBy: "auto",
    riderName: best.name,
    riderPhone: best.phone,
  });

  return {
    riderId: best.id,
    riderName: best.name,
    distanceKm: best.distanceKm,
  };
}
