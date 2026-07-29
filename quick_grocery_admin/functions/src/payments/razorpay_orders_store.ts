import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

const COLLECTION = "razorpay_checkout_orders";

export type RazorpayCheckoutPurpose = "grocery_order" | "delivery_tip";

export interface RazorpayCheckoutOrderDoc {
  uid: string;
  razorpayOrderId: string;
  amountPaise: number;
  currency: string;
  purpose: RazorpayCheckoutPurpose;
  status: "created" | "consumed" | "failed";
  idempotencyKey?: string;
  groceryIdempotencyKey?: string;
  tipOrderId?: string;
  paymentId?: string;
  createdAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  consumedAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
}

export async function saveRazorpayCheckoutOrder(
  data: Omit<RazorpayCheckoutOrderDoc, "createdAt" | "status"> & {
    status?: RazorpayCheckoutOrderDoc["status"];
  },
): Promise<void> {
  const db = admin.firestore();
  await db.collection(COLLECTION).doc(data.razorpayOrderId).set({
    ...data,
    status: data.status ?? "created",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Validates ownership + amount, prevents replay, and marks the Razorpay order consumed.
 * Returns existing grocery order id when the same payment was already applied.
 */
export async function consumeRazorpayCheckoutOrder(params: {
  uid: string;
  razorpayOrderId: string;
  paymentId: string;
  expectedAmountPaise: number;
  purpose: RazorpayCheckoutPurpose;
}): Promise<{ alreadyConsumed: boolean; linkedOrderId?: string }> {
  const db = admin.firestore();
  const ref = db.collection(COLLECTION).doc(params.razorpayOrderId);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Unknown Razorpay order. Create a payment order first.",
      );
    }
    const data = snap.data() as RazorpayCheckoutOrderDoc;
    if (data.uid !== params.uid) {
      throw new HttpsError(
        "permission-denied",
        "This payment does not belong to the signed-in user.",
      );
    }
    if (data.purpose !== params.purpose) {
      throw new HttpsError(
        "failed-precondition",
        "Payment purpose mismatch.",
      );
    }
    if (Math.round(data.amountPaise) !== Math.round(params.expectedAmountPaise)) {
      throw new HttpsError(
        "failed-precondition",
        "Paid amount does not match the order total.",
      );
    }

    if (data.status === "consumed") {
      if (data.paymentId && data.paymentId !== params.paymentId) {
        throw new HttpsError(
          "already-exists",
          "This Razorpay order was already used with a different payment.",
        );
      }
      const linked = (data as { linkedGroceryOrderId?: string })
        .linkedGroceryOrderId;
      return { alreadyConsumed: true, linkedOrderId: linked };
    }

    // Replay guard: same payment id already linked elsewhere.
    const paySnap = await tx.get(
      db.collection("razorpay_payments").doc(params.paymentId),
    );
    if (paySnap.exists) {
      const existing = paySnap.data() as {
        uid?: string;
        linkedGroceryOrderId?: string;
      };
      if (existing.uid === params.uid && existing.linkedGroceryOrderId) {
        return {
          alreadyConsumed: true,
          linkedOrderId: existing.linkedGroceryOrderId,
        };
      }
      throw new HttpsError(
        "already-exists",
        "This payment was already processed.",
      );
    }

    tx.update(ref, {
      status: "consumed",
      paymentId: params.paymentId,
      consumedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(db.collection("razorpay_payments").doc(params.paymentId), {
      uid: params.uid,
      razorpayOrderId: params.razorpayOrderId,
      purpose: params.purpose,
      amountPaise: params.expectedAmountPaise,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { alreadyConsumed: false };
  });
}

export async function linkConsumedPaymentToGroceryOrder(params: {
  razorpayOrderId: string;
  paymentId: string;
  groceryOrderId: string;
}): Promise<void> {
  const db = admin.firestore();
  const batch = db.batch();
  batch.set(
    db.collection(COLLECTION).doc(params.razorpayOrderId),
    { linkedGroceryOrderId: params.groceryOrderId },
    { merge: true },
  );
  batch.set(
    db.collection("razorpay_payments").doc(params.paymentId),
    { linkedGroceryOrderId: params.groceryOrderId },
    { merge: true },
  );
  await batch.commit();
}
