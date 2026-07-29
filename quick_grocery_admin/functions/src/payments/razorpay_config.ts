import { defineSecret } from "firebase-functions/params";
import { HttpsError } from "firebase-functions/v2/https";

/** Firebase Secret Manager bindings (never ship in the Flutter app). */
export const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
export const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

export function razorpaySecretBindings() {
  return [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET];
}

export function readRazorpayKeys(): { keyId: string; keySecret: string } {
  // Gen2 injects defineSecret values into process.env under the secret name.
  const keyId = (process.env.RAZORPAY_KEY_ID || "").trim();
  const keySecret = (process.env.RAZORPAY_KEY_SECRET || "").trim();
  if (!keyId || !keySecret) {
    throw new HttpsError(
      "failed-precondition",
      "Razorpay is not configured on the server. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.",
    );
  }
  if (keySecret.startsWith("rzp_test_") || keySecret.startsWith("rzp_live_")) {
    throw new HttpsError(
      "failed-precondition",
      "RAZORPAY_KEY_SECRET looks like a key id. Use the Key Secret from the Razorpay dashboard.",
    );
  }
  return { keyId, keySecret };
}
