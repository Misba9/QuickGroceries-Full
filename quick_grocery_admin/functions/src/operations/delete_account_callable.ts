import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";

/**
 * Customer-initiated permanent account deletion (App Store 5.1.1v).
 *
 * UID is taken only from the callable auth context — never from client payload.
 *
 * Orders and payment identifiers are retained for legal / Razorpay reconciliation.
 * Personal fields are stripped on completed/cancelled orders. In-progress orders
 * keep address/phone so fulfillment can finish, and are flagged accountDeleted.
 */
const REGION_OPTIONS = {
  ...callableBaseOptions(),
  invoker: "public" as const,
  timeoutSeconds: 120,
  memory: "512MiB" as const,
};

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function isActiveOrder(data: FirebaseFirestore.DocumentData): boolean {
  if (data.isCancelled === true) return false;
  if (data.isDelivered === true) return false;
  const status = str(data.status || data.order_status).toLowerCase();
  if (status.includes("cancel") || status.includes("deliver")) return false;
  return true;
}

async function commitInChunks(
  refs: FirebaseFirestore.DocumentReference[],
  mutate: (
    batch: FirebaseFirestore.WriteBatch,
    ref: FirebaseFirestore.DocumentReference,
  ) => void,
): Promise<void> {
  const db = admin.firestore();
  for (let i = 0; i < refs.length; i += 400) {
    const batch = db.batch();
    for (const ref of refs.slice(i, i + 400)) mutate(batch, ref);
    await batch.commit();
  }
}

async function deleteQuery(
  query: FirebaseFirestore.Query,
): Promise<number> {
  let deleted = 0;
  for (;;) {
    const snap = await query.limit(400).get();
    if (snap.empty) break;
    await commitInChunks(
      snap.docs.map((d) => d.ref),
      (batch, ref) => batch.delete(ref),
    );
    deleted += snap.size;
  }
  return deleted;
}

async function deleteSubcollection(
  parent: FirebaseFirestore.DocumentReference,
  name: string,
): Promise<void> {
  await deleteQuery(parent.collection(name));
}

async function stripProfileImage(url: string): Promise<void> {
  if (!url.includes("firebasestorage.googleapis.com")) return;
  try {
    const marker = "/o/";
    const idx = url.indexOf(marker);
    if (idx < 0) return;
    const encoded = url.slice(idx + marker.length).split("?")[0];
    const path = decodeURIComponent(encoded);
    if (!path) return;
    await admin.storage().bucket().file(path).delete({ ignoreNotFound: true });
  } catch (e) {
    console.warn("deleteMyAccountCallable storage cleanup skipped", e);
  }
}

export const deleteMyAccountCallable = onCall(REGION_OPTIONS, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in to delete your account.");
  }

  const db = admin.firestore();
  const customerRef = db.collection("customers").doc(uid);
  const userRef = db.collection("users").doc(uid);

  const customerSnap = await customerRef.get();
  const profileImage = str(
    customerSnap.data()?.profile_image || customerSnap.data()?.image,
  );
  const referralCode = str(customerSnap.data()?.referral_code).toUpperCase();

  await deleteSubcollection(customerRef, "notification_inbox");

  const addressSnap = await db
    .collection("address")
    .where("user_id", "==", uid)
    .get();
  await commitInChunks(
    addressSnap.docs.map((d) => d.ref),
    (batch, ref) => batch.delete(ref),
  );

  await db.collection("cart").doc(uid).delete().catch(() => undefined);

  const idemSnap = await db
    .collection("order_idempotency")
    .where("uid", "==", uid)
    .get();
  await commitInChunks(
    idemSnap.docs.map((d) => d.ref),
    (batch, ref) => batch.delete(ref),
  );

  const ratingsSnap = await db
    .collection("ratings")
    .where("user_id", "==", uid)
    .get();
  await commitInChunks(
    ratingsSnap.docs.map((d) => d.ref),
    (batch, ref) => batch.delete(ref),
  );

  const couponSnap = await db
    .collection("coupon_usages")
    .where("userId", "==", uid)
    .get();
  await commitInChunks(
    couponSnap.docs.map((d) => d.ref),
    (batch, ref) => batch.delete(ref),
  );

  const tipByUser = await db
    .collection("tip_transactions")
    .where("userId", "==", uid)
    .get();
  const tipByCustomer = await db
    .collection("tip_transactions")
    .where("customerId", "==", uid)
    .get();
  const tipRefs = [
    ...tipByUser.docs.map((d) => d.ref),
    ...tipByCustomer.docs.map((d) => d.ref),
  ];
  const seenTips = new Set<string>();
  const uniqueTips = tipRefs.filter((ref) => {
    if (seenTips.has(ref.path)) return false;
    seenTips.add(ref.path);
    return true;
  });
  await commitInChunks(uniqueTips, (batch, ref) => batch.delete(ref));

  const abandonedSnap = await db
    .collection("abandoned_carts")
    .where("userId", "==", uid)
    .get();
  await commitInChunks(
    abandonedSnap.docs.map((d) => d.ref),
    (batch, ref) => batch.delete(ref),
  );

  const referredSnap = await db
    .collection("referrals")
    .where("referred_user_id", "==", uid)
    .get();
  await commitInChunks(
    referredSnap.docs.map((d) => d.ref),
    (batch, ref) => {
      batch.update(ref, {
        referred_user_name: "Deleted account",
        referred_user_phone: admin.firestore.FieldValue.delete(),
      });
    },
  );

  if (referralCode) {
    await db.collection("referral_codes").doc(referralCode).delete().catch(() => undefined);
  }

  const favQueries = [
    db.collection("products").where("is_favorite", "array-contains", uid),
    db.collection("products").where("favorites", "array-contains", uid),
  ];
  for (const q of favQueries) {
    const snap = await q.get();
    await commitInChunks(
      snap.docs.map((d) => d.ref),
      (batch, ref) =>
        batch.update(ref, {
          is_favorite: admin.firestore.FieldValue.arrayRemove(uid),
          favorites: admin.firestore.FieldValue.arrayRemove(uid),
        }),
    );
  }

  const ordersSnap = await db.collection("orders").where("uuid", "==", uid).get();
  const vendorPatches: Array<{
    vendorId: string;
    orderId: string;
    payload: Record<string, unknown>;
  }> = [];

  await commitInChunks(
    ordersSnap.docs.map((d) => d.ref),
    (batch, ref) => {
      const doc = ordersSnap.docs.find((d) => d.ref.path === ref.path);
      const data = doc?.data() ?? {};
      const keepFulfillment = isActiveOrder(data);
      const payload: Record<string, unknown> = {
        accountDeleted: true,
        accountDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
        customer_name: "Deleted account",
        fcmToken: admin.firestore.FieldValue.delete(),
        fcm_token: admin.firestore.FieldValue.delete(),
      };
      if (!keepFulfillment) {
        payload.phone = "";
        payload.customerPhone = "";
        payload.phoneNumber = "";
        payload.address = "";
        payload.currentLocation = "";
        payload.lat = 0;
        payload.lng = 0;
        payload.address_snapshot = {};
      }
      batch.update(ref, payload);
      const vendorIds = [
        ...new Set(
          [
            ...(Array.isArray(data.vendorIds) ? data.vendorIds : []),
            data.vendorId,
            data.vendor_id,
          ]
            .map((id) => str(id))
            .filter(Boolean),
        ),
      ];
      for (const vendorId of vendorIds) {
        vendorPatches.push({ vendorId, orderId: ref.id, payload });
      }
    },
  );

  await commitInChunks(
    vendorPatches.map((p) =>
      db.collection("vendor_orders").doc(p.vendorId).collection("orders").doc(p.orderId),
    ),
    (batch, ref) => {
      const patch = vendorPatches.find(
        (p) =>
          ref.path ===
          `vendor_orders/${p.vendorId}/orders/${p.orderId}`,
      );
      if (patch) batch.set(ref, patch.payload, { merge: true });
    },
  );

  if (profileImage) await stripProfileImage(profileImage);

  await customerRef.delete().catch(() => undefined);
  await userRef.delete().catch(() => undefined);

  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    const code = (e as { code?: string }).code;
    if (code !== "auth/user-not-found") {
      console.error("deleteMyAccountCallable auth delete failed", e);
      throw new HttpsError(
        "internal",
        "Account data was removed but sign-in could not be closed. Contact support.",
      );
    }
  }

  return { ok: true };
});
