import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function intInRange(v: unknown, min: number, max: number): number | null {
  const n = typeof v === "number" ? v : Number(v);
  if (!Number.isFinite(n)) return null;
  const i = Math.round(n);
  if (i < min || i > max) return null;
  return i;
}

/**
 * POST-style callable for order-experience reviews ("Rate Your Order").
 *
 * Stores:
 *   order_reviews/{autoId}
 * And mirrors:
 *   orders/{orderId}.experience_rating / experience_review / experience_rated
 *
 * Payload:
 * {
 *   orderId, userId?, rating, review?, platform?, appVersion?, createdAt?,
 *   screenshotUrls?
 * }
 */
export const submitOrderExperienceReview = onCall(
  callableBaseOptions(),
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const orderId = str(req.data?.orderId);
    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required.");
    }

    const rating = intInRange(req.data?.rating, 1, 5);
    if (rating == null) {
      throw new HttpsError("invalid-argument", "rating must be 1–5.");
    }

    const claimedUserId = str(req.data?.userId) || uid;
    if (claimedUserId !== uid) {
      throw new HttpsError(
        "permission-denied",
        "userId must match the signed-in user."
      );
    }

    const review = str(req.data?.review).slice(0, 2000);
    const platform = str(req.data?.platform).slice(0, 32) || "unknown";
    const appVersion = str(req.data?.appVersion).slice(0, 32);
    const buildNumber = str(req.data?.buildNumber).slice(0, 32);
    const screenshotUrls = Array.isArray(req.data?.screenshotUrls)
      ? (req.data.screenshotUrls as unknown[])
          .map((x) => str(x))
          .filter(Boolean)
          .slice(0, 5)
      : [];

    const db = admin.firestore();
    const orderRef = db.collection("orders").doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const order = orderSnap.data() || {};
    const orderUid = str(order.uuid || order.userId || order.user_id);
    if (orderUid && orderUid !== uid) {
      throw new HttpsError(
        "permission-denied",
        "You can only review your own orders."
      );
    }

    const isDelivered =
      order.isDelivered === true ||
      str(order.status) === "delivered" ||
      str(order.order_status).toLowerCase().includes("deliver");
    if (!isDelivered) {
      throw new HttpsError(
        "failed-precondition",
        "Order must be delivered before reviewing."
      );
    }

    if (order.experience_rated === true) {
      throw new HttpsError(
        "already-exists",
        "You already submitted an experience review for this order."
      );
    }

    // Duplicate guard via query (covers races / older docs without the flag).
    const existing = await db
      .collection("order_reviews")
      .where("orderId", "==", orderId)
      .where("userId", "==", uid)
      .limit(1)
      .get();
    if (!existing.empty) {
      throw new HttpsError(
        "already-exists",
        "You already submitted an experience review for this order."
      );
    }

    const createdAtRaw = str(req.data?.createdAt);
    let createdAt: admin.firestore.Timestamp | admin.firestore.FieldValue =
      admin.firestore.FieldValue.serverTimestamp();
    if (createdAtRaw) {
      const parsed = Date.parse(createdAtRaw);
      if (!Number.isNaN(parsed)) {
        createdAt = admin.firestore.Timestamp.fromDate(new Date(parsed));
      }
    }

    const doc = {
      orderId,
      userId: uid,
      rating,
      review,
      feedback: review,
      platform,
      appVersion,
      buildNumber,
      screenshotUrls,
      createdAt,
      source: "order_experience",
    };

    const reviewRef = db.collection("order_reviews").doc();
    const batch = db.batch();
    batch.set(reviewRef, doc);
    batch.set(
      orderRef,
      {
        experience_rating: rating,
        experience_review: review,
        experience_rated: true,
        experience_rated_at: admin.firestore.FieldValue.serverTimestamp(),
        experience_platform: platform,
        // Keep legacy `star` / `is_rated` in sync for older admin UIs.
        star: rating,
        is_rated: true,
      },
      { merge: true }
    );
    await batch.commit();

    return {
      success: true,
      reviewId: reviewRef.id,
      message: "Thanks for your feedback.",
    };
  }
);
