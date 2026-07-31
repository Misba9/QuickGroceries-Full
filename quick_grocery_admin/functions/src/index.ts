/**
 * Quick Grocery Admin — Cloud Functions
 *
 * Push notifications (FCM) + admin claim helpers.
 * Configure Firebase secrets / env as needed for `setAdminClaims` bootstrap.
 */
import * as admin from "firebase-admin";

admin.initializeApp();

export { setAdminClaims } from "./set_admin_claims";
export { syncAdminClaimsFromAdmins } from "./sync_admin_claims_from_admins";

export {
  sendTopicNotification,
  sendSingleNotification,
  scheduleNotification,
  notificationCampaignWorker,
  recordNotificationOpen,
} from "./fcm_notifications";

/** CORS-enabled HTTP endpoints for Flutter Web admin (localhost + hosting). */
export {
  sendTopicNotificationHttp,
  sendSingleNotificationHttp,
} from "./fcm_http_handlers";

/** Real-time operations: admin alerts, vendor/driver pushes, stock, carts. */
export {
  onOrderCreated,
  onOrderUpdated,
} from "./operations/order_triggers";
export {
  onCustomerCreated,
  onVendorCreated,
  onDeliveryBoyCreated,
} from "./operations/registration_triggers";
export { onProductStockUpdated } from "./operations/stock_triggers";
export { abandonedCartReminder } from "./operations/abandoned_cart";
export { dailySalesSummary } from "./operations/daily_summary";
export { seedAdminTestNotification } from "./operations/ops_callables";
export { placeOrderCallable } from "./operations/place_order_callable";
export {
  getDeliveryTipSettingsCallable,
  updateOrderTipCallable,
  adminDeliveryTipsCallable,
} from "./delivery_tips/delivery_tips_callables";
export {
  getPaymentSettingsCallable,
  updatePaymentSettingsCallable,
  previewCodFeeCallable,
} from "./cod_fee/cod_fee_callables";
export {
  getCustomerPaymentRestrictionsCallable,
  updateCustomerPaymentRestrictionsCallable,
  deleteCustomerPaymentRestrictionsCallable,
  listCodRestrictedCustomersCallable,
} from "./cod_restrictions/cod_restriction_callables";
export {
  assignRiderCallable,
  autoAssignRiderCallable,
  autoAssignAllUnassignedCallable,
  rankRidersForOrderCallable,
} from "./operations/assign_rider_callables";
export {
  confirmDelivery,
  reportCustomerNotReachable,
} from "./operations/delivery_callables";
export { recordDeliveryPaymentCallable } from "./operations/delivery_payment_callables";
export {
  cancelOrderByCustomer,
  cancelOrderByVendor,
  cancelOrderByRider,
} from "./operations/cancel_order_callables";
export { onDeliveryBoyStatusUpdated } from "./operations/delivery_status_triggers";
export { onVendorRequestCreated } from "./operations/vendor_request_triggers";
export { onMaintenanceConfigChange } from "./operations/maintenance_triggers";

/** Vendor & delivery partner auth: login, OTP password reset, admin controls. */
export {
  partnerRequestPasswordReset,
  partnerVerifyResetOtp,
  partnerCompletePasswordReset,
  partnerLogin,
  partnerUpdatePassword,
  partnerCheckSession,
  adminPartnerAccountAction,
} from "./partner_auth/partner_callables";
export { adminCreateVendorAccount, adminRollbackVendorAuth, adminSyncVendorAuthPassword, adminMigrateVendorAuth, adminRestoreVendorAuth } from "./partner_auth/admin_create_vendor";
export { adminCreateDeliveryAccount, adminRollbackDeliveryAuth } from "./partner_auth/admin_create_delivery";
export {
  adminCreateDeliveryAccountHttp,
  createDeliveryBoy,
} from "./partner_auth/delivery_http_handlers";
export {
  adminMigrateVendorAuthHttp,
  adminRestoreVendorAuthHttp,
  adminApproveVendorRequestHttp,
  adminRejectVendorRequestHttp,
} from "./partner_auth/vendor_http_handlers";
export {
  vendorCheckAuthForPasswordReset,
  vendorDiagnoseLogin,
} from "./partner_auth/vendor_auth_callables";
export {
  submitVendorRequest,
  uploadVendorSignupImage,
  adminApproveVendorRequest,
  adminRejectVendorRequest,
  adminBlockVendorFromRequest,
} from "./partner_auth/vendor_requests";

/** Advanced coupon validation, redemption, and checkout listing. */
export {
  validateCouponCallable,
  redeemCouponCallable,
  listActiveCouponsCallable,
} from "./coupons/coupon_callables";

/** Refer & Earn: referral codes, rewards, admin actions. */
export {
  applyReferralCodeCallable,
  getReferEarnStatsCallable,
  getReferralDashboard,
  ensureReferralCodeCallable,
  generateReferralCode,
  getReferralHistory,
  shareReferralInvite,
  adminReferEarnActionCallable,
} from "./refer_earn/refer_earn_callables";
export { onCustomerCreatedReferralCode } from "./refer_earn/refer_earn_triggers";

/** Product reviews: verified purchase, moderation, quality score. */
export {
  submitProductReview,
  updateProductReview,
  deleteProductReview,
  moderateProductReview,
  vendorReplyProductReview,
  markReviewHelpful,
  reportProductReview,
  canReviewProduct,
} from "./reviews/review_callables";

/** Order-experience review ("Rate Your Order" after delivery). */
export { submitOrderExperienceReview } from "./reviews/order_experience_review_callable";

/** Razorpay: create Orders API checkout sessions (secret stays on server). */
export { createRazorpayOrderCallable } from "./payments/create_razorpay_order_callable";
export { confirmRazorpayTipPaymentCallable } from "./payments/confirm_razorpay_tip_callable";

/** Admin-controlled product promotions. */
export {
  adminListPromotionsCallable,
  adminCreatePromotionCallable,
  adminUpdatePromotionCallable,
  adminDeletePromotionCallable,
  listProductPromotionsCallable,
  patchProductPromotionsCallable,
  getPromotionCallable,
  vendorRequestPromotionCallable,
  adminListPromotionRequestsCallable,
  adminResolvePromotionRequestCallable,
} from "./promotions/promotion_callables";
export { productPromotionsHttp } from "./promotions/promotion_http_handlers";
export { promotionExpiryCleanup } from "./promotions/promotion_cleanup";

/** Grocery AI shopping assistant (Gemini + catalog grounding). */
export { aiGroceryAssistant } from "./ai/ai_assistant_callable";
export {
  listAiChatSessionsCallable,
  listAiChatMessagesCallable,
} from "./ai/ai_chat_admin_callables";
