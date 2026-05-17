import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import {
  deleteUserReview,
  findDeliveredOrderWithProduct,
  hasExistingReview,
  markHelpful,
  moderateReview,
  parseCategoriesInput,
  reportReview,
  submitReview,
  updateUserReview,
  vendorReplyReview,
} from "./review_engine";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function strList(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return v.map((x) => str(x)).filter(Boolean);
}

/** User submits a verified-purchase review. */
export const submitProductReview = onCall(callableBaseOptions(), async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const productId = str(req.data?.productId);
  const productName = str(req.data?.productName);
  const orderId = str(req.data?.orderId);
  if (!productId) {
    throw new HttpsError("invalid-argument", "productId is required.");
  }

  let resolvedOrderId = orderId;
  let vendorId = str(req.data?.vendorId);
  if (!resolvedOrderId) {
    const found = await findDeliveredOrderWithProduct(uid, productId, productName);
    if (!found) {
      throw new HttpsError(
        "failed-precondition",
        "Only verified buyers who received this product can review."
      );
    }
    resolvedOrderId = found.orderId;
    vendorId = vendorId || found.vendorId;
  }

  if (await hasExistingReview(uid, productId, resolvedOrderId)) {
    throw new HttpsError(
      "already-exists",
      "You already reviewed this product for this order."
    );
  }

  const result = await submitReview({
    userId: uid,
    userName: str(req.data?.userName) || "Customer",
    productId,
    productName,
    vendorId,
    orderId: resolvedOrderId,
    reviewText: str(req.data?.reviewText),
    reviewImages: strList(req.data?.reviewImages),
    reviewVideo: str(req.data?.reviewVideo),
    categoryRatings: parseCategoriesInput(req.data?.categoryRatings),
    autoApprove: false,
  });

  return {
    success: true,
    reviewId: result.reviewId,
    status: result.status,
    message: "Review submitted and pending approval.",
  };
});

export const updateProductReview = onCall(callableBaseOptions(), async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const reviewId = str(req.data?.reviewId);
  if (!reviewId) throw new HttpsError("invalid-argument", "reviewId required.");

  try {
    await updateUserReview(reviewId, uid, {
      reviewText: req.data?.reviewText != null ? str(req.data.reviewText) : undefined,
      categoryRatings:
        req.data?.categoryRatings != null
          ? parseCategoriesInput(req.data.categoryRatings)
          : undefined,
      reviewImages:
        req.data?.reviewImages != null ? strList(req.data.reviewImages) : undefined,
      reviewVideo:
        req.data?.reviewVideo != null ? str(req.data.reviewVideo) : undefined,
    });
    return { success: true, message: "Review updated." };
  } catch (e) {
    throw new HttpsError("failed-precondition", str(e));
  }
});

export const deleteProductReview = onCall(callableBaseOptions(), async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const reviewId = str(req.data?.reviewId);
  if (!reviewId) throw new HttpsError("invalid-argument", "reviewId required.");
  await deleteUserReview(reviewId, uid);
  return { success: true };
});

export const moderateProductReview = onCall(callableBaseOptions(), async (req) => {
  await assertNotificationAdmin(req.auth?.uid);
  const reviewId = str(req.data?.reviewId);
  const action = str(req.data?.action) as
    | "approve"
    | "reject"
    | "hide"
    | "feature"
    | "unfeature";
  if (!reviewId || !action) {
    throw new HttpsError("invalid-argument", "reviewId and action required.");
  }
  await moderateReview(reviewId, action, str(req.data?.adminReply));
  return { success: true };
});

export const vendorReplyProductReview = onCall(callableBaseOptions(), async (req) => {
  const reviewId = str(req.data?.reviewId);
  const vendorId = str(req.data?.vendorId);
  const text = str(req.data?.text);
  if (!reviewId || !vendorId || !text) {
    throw new HttpsError("invalid-argument", "reviewId, vendorId, text required.");
  }
  await vendorReplyReview(reviewId, vendorId, text);
  return { success: true };
});

export const markReviewHelpful = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const reviewId = str(req.data?.reviewId);
    if (!reviewId) throw new HttpsError("invalid-argument", "reviewId required.");
    await markHelpful(reviewId);
    return { success: true };
  }
);

export const reportProductReview = onCall(callableBaseOptions(), async (req) => {
  const reviewId = str(req.data?.reviewId);
  if (!reviewId) throw new HttpsError("invalid-argument", "reviewId required.");
  await reportReview(reviewId);
  return { success: true };
});

/** Check if user can review (delivered order exists). */
export const canReviewProduct = onCall(callableBaseOptions(), async (req) => {
  const uid = req.auth?.uid;
  if (!uid) return { canReview: false };
  const productId = str(req.data?.productId);
  const productName = str(req.data?.productName);
  const found = await findDeliveredOrderWithProduct(uid, productId, productName);
  if (!found) return { canReview: false, reason: "no_purchase" };
  const exists = await hasExistingReview(uid, productId, found.orderId);
  return {
    canReview: !exists,
    orderId: found.orderId,
    reason: exists ? "already_reviewed" : "",
  };
});
