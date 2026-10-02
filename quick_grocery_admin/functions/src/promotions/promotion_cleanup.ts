import { onSchedule } from "firebase-functions/v2/scheduler";
import { REGION } from "../https_callable_options";
import { deactivateExpiredPromotions } from "./promotion_engine";

/**
 * Deactivates expired product promotions every 5 minutes and dual-writes
 * cleared flags / restored prices onto product documents.
 */
export const promotionExpiryCleanup = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "Asia/Kolkata",
    region: REGION,
  },
  async () => {
    const result = await deactivateExpiredPromotions();
    console.log(
      `[promotionExpiryCleanup] deactivated=${result.deactivated} products=${result.productIds.length}`
    );
  }
);
