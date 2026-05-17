import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { containsBlockedContent, sanitizeText } from "./review_moderation";
import { writeAdminNotification } from "../operations/ops_notify";

const db = admin.firestore();

const EDIT_WINDOW_MS = 24 * 60 * 60 * 1000;
const LOW_RATING_THRESHOLD = 3.5;
const LOW_RATING_MIN_REVIEWS = 3;

export type ReviewStatus = "pending" | "approved" | "rejected" | "hidden";

export interface CategoryRatings {
  product_quality: number;
  freshness: number;
  packaging: number;
  delivery_experience: number;
  value_for_money: number;
}

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function num(v: unknown, fallback = 0): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

function clamp15(n: number): number {
  return Math.min(5, Math.max(1, n));
}

function parseCategoryRatings(raw: unknown): CategoryRatings {
  const m = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  return {
    product_quality: clamp15(num(m.product_quality, 5)),
    freshness: clamp15(num(m.freshness, 5)),
    packaging: clamp15(num(m.packaging, 5)),
    delivery_experience: clamp15(num(m.delivery_experience, 5)),
    value_for_money: clamp15(num(m.value_for_money, 5)),
  };
}

function overallFromCategories(c: CategoryRatings): number {
  const sum =
    c.product_quality +
    c.freshness +
    c.packaging +
    c.delivery_experience +
    c.value_for_money;
  return Math.round((sum / 5) * 10) / 10;
}

function isVisibleReview(data: admin.firestore.DocumentData): boolean {
  if (data.hidden === true || data.status === "hidden" || data.status === "rejected") {
    return false;
  }
  if (data.admin_approved === false) return false;
  if (data.status === "pending" || data.status === "rejected") return false;
  return true;
}

export async function findDeliveredOrderWithProduct(
  userId: string,
  productId: string,
  productName: string
): Promise<{ orderId: string; vendorId: string } | null> {
  const snap = await db
    .collection("orders")
    .where("uuid", "==", userId)
    .limit(40)
    .get();

  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.isCancelled === true) continue;
    const delivered =
      data.isDelivered === true ||
      str(data.status).toLowerCase() === "delivered" ||
      str(data.order_status).toLowerCase().includes("deliver");
    if (!delivered) continue;

    const products = (data.products as unknown[]) ?? [];
    for (const p of products) {
      if (!p || typeof p !== "object") continue;
      const item = p as Record<string, unknown>;
      const pid = str(item.productId ?? item.product_id ?? item.id);
      if (pid === productId) {
        return {
          orderId: doc.id,
          vendorId: str(item.vendor_id ?? item.vendorId ?? data.vendor_id),
        };
      }
      if (productName && str(item.name).toLowerCase() === productName.toLowerCase()) {
        return {
          orderId: doc.id,
          vendorId: str(item.vendor_id ?? item.vendorId ?? data.vendor_id),
        };
      }
    }
  }
  return null;
}

export async function hasExistingReview(
  userId: string,
  productId: string,
  orderId: string
): Promise<boolean> {
  const snap = await db
    .collection("ratings")
    .where("product_id", "==", productId)
    .where("user_id", "==", userId)
    .where("order_id", "==", orderId)
    .limit(1)
    .get();
  return !snap.empty;
}

export async function recalculateProductQuality(productId: string): Promise<void> {
  const snap = await db
    .collection("ratings")
    .where("product_id", "==", productId)
    .get();

  const approved = snap.docs.filter((d) => isVisibleReview(d.data()));
  let sum = 0;
  for (const d of approved) {
    sum += num(d.data().rating ?? d.data().overall_rating);
  }
  const count = approved.length;
  const average = count > 0 ? sum / count : 0;
  const autoQuality = Math.round((average / 5) * 100);

  const productRef = db.collection("products").doc(productId);
  const productSnap = await productRef.get();
  if (!productSnap.exists) return;

  const pdata = productSnap.data() ?? {};
  const override = num(pdata.quality_score_override);
  const qualityScore = override > 0 ? override : autoQuality;

  await productRef.set(
    {
      rating: Math.round(average * 10) / 10,
      totalReviews: count,
      quality_score: qualityScore,
      review_count: count,
    },
    { merge: true }
  );

  if (count >= LOW_RATING_MIN_REVIEWS && average < LOW_RATING_THRESHOLD) {
    const already = pdata.low_quality_alert_sent === true;
    if (!already) {
      await writeAdminNotification({
        title: "Low product quality alert",
        message: `${str(pdata.name)} dropped to ${average.toFixed(1)}/5 (${count} reviews).`,
        type: "low_stock",
        category: "stock",
        soundAlert: true,
        metadata: { productId, average, count },
      });
      await productRef.update({ low_quality_alert_sent: true });
    }
  }
}

export async function submitReview(opts: {
  userId: string;
  userName: string;
  productId: string;
  productName: string;
  vendorId: string;
  orderId: string;
  reviewText: string;
  reviewImages: string[];
  reviewVideo: string;
  categoryRatings: CategoryRatings;
  autoApprove?: boolean;
}): Promise<{ reviewId: string; status: ReviewStatus }> {
  const text = sanitizeText(opts.reviewText);
  if (containsBlockedContent(text)) {
    throw new Error("Review contains inappropriate content.");
  }

  const overall = overallFromCategories(opts.categoryRatings);
  const status: ReviewStatus = opts.autoApprove ? "approved" : "pending";

  const ref = await db.collection("ratings").add({
    product_id: opts.productId,
    product_name: opts.productName,
    vendor_id: opts.vendorId,
    order_id: opts.orderId,
    user_id: opts.userId,
    user_name: opts.userName,
    rating: overall,
    overall_rating: overall,
    review: text,
    review_text: text,
    review_images: opts.reviewImages.slice(0, 6),
    review_video: opts.reviewVideo,
    category_ratings: opts.categoryRatings,
    verified_purchase: true,
    admin_approved: status === "approved",
    status,
    hidden: false,
    is_featured: false,
    helpful_count: 0,
    reported_count: 0,
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  });

  if (status === "approved") {
    await recalculateProductQuality(opts.productId);
  }

  return { reviewId: ref.id, status };
}

export async function moderateReview(
  reviewId: string,
  action: "approve" | "reject" | "hide" | "feature" | "unfeature",
  adminReply?: string
): Promise<void> {
  const ref = db.collection("ratings").doc(reviewId);
  const snap = await ref.get();
  if (!snap.exists) throw new Error("Review not found.");
  const data = snap.data()!;
  const productId = str(data.product_id);

  const updates: Record<string, unknown> = {
    updated_at: FieldValue.serverTimestamp(),
  };

  switch (action) {
    case "approve":
      updates.status = "approved";
      updates.admin_approved = true;
      updates.hidden = false;
      break;
    case "reject":
      updates.status = "rejected";
      updates.admin_approved = false;
      break;
    case "hide":
      updates.status = "hidden";
      updates.hidden = true;
      break;
    case "feature":
      updates.is_featured = true;
      break;
    case "unfeature":
      updates.is_featured = false;
      break;
  }

  if (adminReply != null && adminReply.trim()) {
    updates.vendor_reply = {
      text: sanitizeText(adminReply, 1000),
      repliedAt: FieldValue.serverTimestamp(),
      by: "admin",
    };
  }

  await ref.update(updates);
  await recalculateProductQuality(productId);
}

export async function vendorReplyReview(
  reviewId: string,
  vendorId: string,
  text: string
): Promise<void> {
  const ref = db.collection("ratings").doc(reviewId);
  const snap = await ref.get();
  if (!snap.exists) throw new Error("Review not found.");
  if (str(snap.data()?.vendor_id) !== vendorId) {
    throw new Error("Not allowed to reply to this review.");
  }
  await ref.update({
    vendor_reply: {
      text: sanitizeText(text, 1000),
      repliedAt: FieldValue.serverTimestamp(),
      vendorId,
      by: "vendor",
    },
    updated_at: FieldValue.serverTimestamp(),
  });
}

export async function updateUserReview(
  reviewId: string,
  userId: string,
  patch: {
    reviewText?: string;
    categoryRatings?: CategoryRatings;
    reviewImages?: string[];
    reviewVideo?: string;
  }
): Promise<void> {
  const ref = db.collection("ratings").doc(reviewId);
  const snap = await ref.get();
  if (!snap.exists) throw new Error("Review not found.");
  const data = snap.data()!;
  if (str(data.user_id) !== userId) throw new Error("Not your review.");

  const created = (data.created_at as Timestamp)?.toMillis() ?? 0;
  if (Date.now() - created > EDIT_WINDOW_MS) {
    throw new Error("Edit window expired (24 hours).");
  }

  const updates: Record<string, unknown> = {
    updated_at: FieldValue.serverTimestamp(),
    status: "pending",
    admin_approved: false,
  };

  if (patch.reviewText != null) {
    const text = sanitizeText(patch.reviewText);
    if (containsBlockedContent(text)) throw new Error("Inappropriate content.");
    updates.review = text;
    updates.review_text = text;
  }
  if (patch.categoryRatings) {
    updates.category_ratings = patch.categoryRatings;
    const overall = overallFromCategories(patch.categoryRatings);
    updates.rating = overall;
    updates.overall_rating = overall;
  }
  if (patch.reviewImages) updates.review_images = patch.reviewImages.slice(0, 6);
  if (patch.reviewVideo != null) updates.review_video = patch.reviewVideo;

  await ref.update(updates);
}

export async function deleteUserReview(reviewId: string, userId: string): Promise<void> {
  const ref = db.collection("ratings").doc(reviewId);
  const snap = await ref.get();
  if (!snap.exists) return;
  if (str(snap.data()?.user_id) !== userId) throw new Error("Not your review.");
  const productId = str(snap.data()?.product_id);
  await ref.delete();
  await recalculateProductQuality(productId);
}

export async function markHelpful(reviewId: string): Promise<void> {
  await db.collection("ratings").doc(reviewId).update({
    helpful_count: FieldValue.increment(1),
  });
}

export async function reportReview(reviewId: string): Promise<void> {
  const ref = db.collection("ratings").doc(reviewId);
  await ref.update({ reported_count: FieldValue.increment(1) });
  const snap = await ref.get();
  const data = snap.data();
  if (data && num(data.reported_count) >= 3) {
    await ref.update({ status: "hidden", hidden: true });
    await writeAdminNotification({
      title: "Review reported multiple times",
      message: `Review on ${str(data.product_name)} was auto-hidden.`,
      type: "low_stock",
      category: "system",
      metadata: { reviewId },
    });
  }
}

export function parseCategoriesInput(raw: unknown): CategoryRatings {
  return parseCategoryRatings(raw);
}

export { overallFromCategories, isVisibleReview, EDIT_WINDOW_MS };
