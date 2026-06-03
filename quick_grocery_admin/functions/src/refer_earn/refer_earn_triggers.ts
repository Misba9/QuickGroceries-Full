import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { ensureUserReferralCode } from "./refer_earn_engine";

/** Assign a unique referral code when a customer document is created. */
export const onCustomerCreatedReferralCode = onDocumentCreated(
  { document: "customers/{uid}", region: "us-central1" },
  async (event) => {
    const uid = event.params.uid;
    const data = event.data?.data() as Record<string, unknown> | undefined;
    const name = data?.name != null ? String(data.name) : undefined;
    try {
      await ensureUserReferralCode(uid, name);
    } catch (e) {
      console.error("ensureUserReferralCode failed", uid, e);
    }
  }
);
