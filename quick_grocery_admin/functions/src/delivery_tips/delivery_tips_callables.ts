import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import { num, str } from "../operations/ops_notify";
import {
  getDeliveryTipSettings,
  settingsToFirestore,
} from "./delivery_tips_settings";
import {
  DEFAULT_DELIVERY_TIP_SETTINGS,
  DELIVERY_TIPS_SETTINGS_PATH,
} from "./delivery_tips_types";
import {
  currentTipAmount,
  updateOrderTipAmount,
  validateTipAmount,
} from "./delivery_tips_engine";

const db = admin.firestore();

/** Public settings for checkout and tracking UI. */
export const getDeliveryTipSettingsCallable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async () => {
    const settings = await getDeliveryTipSettings();
    return { settings };
  },
);

/** Customer increases tip on an active or delivered order. */
export const updateOrderTipCallable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in to update tip.");
    }
    const orderId = str(req.data?.orderId);
    const tipAmount = Math.round(num(req.data?.tipAmount));
    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required.");
    }
    if (tipAmount <= 0) {
      throw new HttpsError("invalid-argument", "tipAmount must be positive.");
    }
    return updateOrderTipAmount(orderId, uid, tipAmount, {
      allowAfterDelivered: req.data?.allowAfterDelivered === true,
    });
  },
);

type AdminTipAction = "save_settings" | "aggregate_stats" | "list_tip_orders";

/** Admin: configure tips and fetch reports. */
export const adminDeliveryTipsCallable = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const action = str(req.data?.action) as AdminTipAction;

    switch (action) {
      case "save_settings": {
        const settings = await getDeliveryTipSettings();
        const enabled = req.data?.enabled;
        const maxTipRaw = num(req.data?.maxTipAmount);
        const maxTip = maxTipRaw > 0 ? maxTipRaw : settings.maxTipAmount;
        const rawTips = req.data?.suggestedTips;
        const suggestedTips = Array.isArray(rawTips)
          ? rawTips.map((t) => Math.round(num(t))).filter((t) => t > 0)
          : settings.suggestedTips;
        const next = {
          enabled: enabled === undefined ? settings.enabled : enabled === true,
          suggestedTips:
            suggestedTips.length > 0
              ? suggestedTips
              : DEFAULT_DELIVERY_TIP_SETTINGS.suggestedTips,
          maxTipAmount: Math.max(1, maxTip),
        };
        await db
          .doc(DELIVERY_TIPS_SETTINGS_PATH)
          .set(settingsToFirestore(next), { merge: true });
        return { ok: true, settings: next };
      }

      case "aggregate_stats": {
        const daysRaw = num(req.data?.days);
        const days = Math.min(90, Math.max(1, Math.floor(daysRaw > 0 ? daysRaw : 30)));
        const since = new Date();
        since.setDate(since.getDate() - days);

        const snap = await db
          .collection("orders")
          .where("tipAmount", ">", 0)
          .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(since))
          .orderBy("createdAt", "desc")
          .limit(500)
          .get()
          .catch(async () => {
            const fallback = await db
              .collection("orders")
              .orderBy("createdAt", "desc")
              .limit(800)
              .get();
            return {
              docs: fallback.docs.filter((d) => currentTipAmount(d.data()) > 0),
            } as typeof fallback;
          });

        let totalTips = 0;
        const byDate = new Map<string, number>();
        const byRider = new Map<
          string,
          { name: string; tips: number; orders: number }
        >();

        for (const doc of snap.docs) {
          const data = doc.data();
          const tip = currentTipAmount(data);
          if (tip <= 0) continue;
          totalTips += tip;

          const created = data.createdAt;
          let dateKey = "unknown";
          if (created && typeof (created as admin.firestore.Timestamp).toDate === "function") {
            const d = (created as admin.firestore.Timestamp).toDate();
            dateKey = d.toISOString().slice(0, 10);
          }
          byDate.set(dateKey, (byDate.get(dateKey) ?? 0) + tip);

          const riderId = str(data.deliveryBoyId ?? data.delivery_boy_id);
          if (riderId) {
            const prev = byRider.get(riderId) ?? {
              name: str(data.deliveryBoyName ?? data.rider_name) || riderId,
              tips: 0,
              orders: 0,
            };
            byRider.set(riderId, {
              name: prev.name,
              tips: prev.tips + tip,
              orders: prev.orders + 1,
            });
          }
        }

        const topRiders = [...byRider.entries()]
          .map(([id, v]) => ({
            riderId: id,
            riderName: v.name,
            totalTips: v.tips,
            orderCount: v.orders,
          }))
          .sort((a, b) => b.totalTips - a.totalTips)
          .slice(0, 20);

        const tipsByDate = [...byDate.entries()]
          .map(([date, amount]) => ({ date, amount }))
          .sort((a, b) => b.date.localeCompare(a.date));

        return {
          totalTipsCollected: totalTips,
          tipsByDate,
          topRiders,
          orderCount: snap.docs.length,
        };
      }

      case "list_tip_orders": {
        const limitRaw = num(req.data?.limit);
        const limit = Math.min(
          200,
          Math.max(10, Math.floor(limitRaw > 0 ? limitRaw : 100)),
        );
        const snap = await db
          .collection("orders")
          .orderBy("createdAt", "desc")
          .limit(400)
          .get();
        const rows = [];
        for (const doc of snap.docs) {
          const data = doc.data();
          const tip = currentTipAmount(data);
          if (tip <= 0) continue;
          rows.push({
            orderId: doc.id,
            customerName: str(data.customer_name ?? data.customerName),
            deliveryPartnerId: str(data.deliveryBoyId ?? data.delivery_boy_id),
            deliveryPartnerName: str(
              data.deliveryBoyName ?? data.rider_name ?? data.riderName,
            ),
            tipAmount: tip,
            tipStatus: str(data.tipStatus) || "pending",
            createdAt: data.createdAt ?? data.created_date,
          });
          if (rows.length >= limit) break;
        }
        return { rows };
      }

      default:
        throw new HttpsError("invalid-argument", "Unknown action.");
    }
  },
);
