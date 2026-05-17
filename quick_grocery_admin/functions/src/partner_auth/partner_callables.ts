import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import {
  writeAdminNotification,
  writeActivityLog,
} from "../operations/ops_notify";
import {
  generateOtp,
  hashOtp,
  hashPassword,
  verifyPassword,
  validatePasswordRules,
} from "./partner_crypto";
import { sendPasswordResetOtpEmail } from "./partner_email";
import {
  PartnerRole,
  OTP_EXPIRY_MS,
  RESEND_COOLDOWN_MS,
  MAX_OTP_ATTEMPTS,
  MAX_LOGIN_ATTEMPTS,
  LOCK_DURATION_MS,
  RESET_VERIFIED_MS,
  appNameForRole,
  collectionForRole,
  db,
  findPartnerByEmail,
  getPartnerDoc,
  isAccountActive,
  isLocked,
} from "./partner_store";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function parseRole(v: unknown): PartnerRole {
  const r = str(v).toLowerCase();
  if (r === "vendor" || r === "delivery") return r;
  throw new HttpsError("invalid-argument", "role must be vendor or delivery");
}

async function verifyPartnerPassword(
  data: admin.firestore.DocumentData,
  password: string
): Promise<boolean> {
  const hash = str(data.password_hash);
  if (hash) {
    return verifyPassword(password, hash);
  }
  const plain = str(data.password);
  return plain.length > 0 && plain === password;
}

function publicProfile(
  role: PartnerRole,
  id: string,
  data: admin.firestore.DocumentData
): Record<string, unknown> {
  if (role === "vendor") {
    return {
      id,
      first_name: data.first_name ?? "",
      last_name: data.last_name ?? "",
      phone: data.phone ?? "",
      email: data.email ?? "",
      shop_name: data.shop_name ?? "",
      shop_address: data.shop_address ?? "",
      vendor_image: data.vendor_image ?? "",
      shop_image: data.shop_image ?? "",
      is_active: data.is_active !== false,
    };
  }
  return {
    id,
    first_name: data.first_name ?? "",
    last_name: data.last_name ?? "",
    name: data.name ?? `${data.first_name ?? ""} ${data.last_name ?? ""}`.trim(),
    phone: data.phone ?? "",
    email: data.email ?? "",
    address: data.address ?? "",
    image: data.image ?? "",
    licence_number: data.licence_number ?? data.licence ?? "",
    is_active: data.is_active !== false,
  };
}

async function issueOtpAndNotify(
  role: PartnerRole,
  partnerId: string,
  email: string,
  data: admin.firestore.DocumentData,
  notifyAdmin: boolean
): Promise<void> {
  const now = Date.now();
  const lastSent = (data.last_otp_sent_at as Timestamp | undefined)?.toMillis() ?? 0;
  if (lastSent && now - lastSent < RESEND_COOLDOWN_MS) {
    const waitSec = Math.ceil((RESEND_COOLDOWN_MS - (now - lastSent)) / 1000);
    throw new HttpsError(
      "resource-exhausted",
      `Please wait ${waitSec} seconds before requesting another code.`
    );
  }

  const otp = generateOtp();
  const otpHash = hashOtp(otp);
  const expiry = Timestamp.fromMillis(now + OTP_EXPIRY_MS);

  await db.collection(collectionForRole(role)).doc(partnerId).update({
    reset_otp: otpHash,
    otp_expiry: expiry,
    otp_attempts: 0,
    last_otp_sent_at: FieldValue.serverTimestamp(),
    password_reset_verified: false,
    password_reset_verified_expiry: FieldValue.delete(),
  });

  if (process.env.FUNCTIONS_EMULATOR === "true") {
    logger.info(`[partner_auth] OTP for ${email}: ${otp}`);
  }

  await sendPasswordResetOtpEmail({
    to: email,
    otp,
    appName: appNameForRole(role),
  });

  if (notifyAdmin) {
    const label = role === "vendor" ? "Vendor" : "Delivery partner";
    await writeAdminNotification({
      title: "Password reset requested",
      message: `${label} ${email} requested a password reset OTP.`,
      type: "password_reset_requested",
      category: role === "vendor" ? "vendors" : "delivery",
      soundAlert: true,
      metadata: { role, partnerId, email },
    });
  }
}

/** Step 1 — request OTP for registered email. */
export const partnerRequestPasswordReset = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const role = parseRole(req.data?.role);
    const email = str(req.data?.email).toLowerCase();
    if (!email || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "Valid email is required.");
    }

    const found = await findPartnerByEmail(role, email);
    if (!found) {
      return { success: true, message: "If this email is registered, you will receive a code shortly." };
    }
    if (!isAccountActive(found.data)) {
      throw new HttpsError("permission-denied", "This account is disabled.");
    }

    await issueOtpAndNotify(role, found.id, email, found.data, true);
    return { success: true, message: "If this email is registered, you will receive a code shortly." };
  }
);

/** Step 2 — verify 6-digit OTP (max 3 attempts). */
export const partnerVerifyResetOtp = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const role = parseRole(req.data?.role);
    const email = str(req.data?.email).toLowerCase();
    const otp = str(req.data?.otp);
    if (!email || otp.length !== 6) {
      throw new HttpsError("invalid-argument", "Email and 6-digit OTP are required.");
    }

    const found = await findPartnerByEmail(role, email);
    if (!found) {
      throw new HttpsError("not-found", "Invalid or expired code.");
    }

    const data = found.data;
    const expiry = data.otp_expiry as Timestamp | undefined;
    if (!expiry || expiry.toMillis() < Date.now()) {
      throw new HttpsError("deadline-exceeded", "This code has expired. Request a new one.");
    }

    const attempts = Number(data.otp_attempts ?? 0);
    if (attempts >= MAX_OTP_ATTEMPTS) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many incorrect attempts. Request a new code."
      );
    }

    const expectedHash = str(data.reset_otp);
    const providedHash = hashOtp(otp);
    if (!expectedHash || expectedHash !== providedHash) {
      const nextAttempts = attempts + 1;
      await db.collection(collectionForRole(role)).doc(found.id).update({
        otp_attempts: nextAttempts,
      });
      const remaining = MAX_OTP_ATTEMPTS - nextAttempts;
      if (remaining <= 0) {
        throw new HttpsError(
          "resource-exhausted",
          "Too many incorrect attempts. Request a new code."
        );
      }
      throw new HttpsError(
        "invalid-argument",
        `Invalid code. ${remaining} attempt(s) remaining.`
      );
    }

    await db.collection(collectionForRole(role)).doc(found.id).update({
      password_reset_verified: true,
      password_reset_verified_expiry: Timestamp.fromMillis(
        Date.now() + RESET_VERIFIED_MS
      ),
    });

    return { success: true, verified: true };
  }
);

/** Step 3 — set new password after OTP verified. */
export const partnerCompletePasswordReset = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const role = parseRole(req.data?.role);
    const email = str(req.data?.email).toLowerCase();
    const newPassword = str(req.data?.newPassword);
    const ruleErr = validatePasswordRules(newPassword);
    if (ruleErr) throw new HttpsError("invalid-argument", ruleErr);

    const found = await findPartnerByEmail(role, email);
    if (!found) {
      throw new HttpsError("not-found", "Account not found.");
    }

    const data = found.data;
    if (!data.password_reset_verified) {
      throw new HttpsError("failed-precondition", "Verify your OTP first.");
    }
    const verifiedExpiry = data.password_reset_verified_expiry as Timestamp | undefined;
    if (!verifiedExpiry || verifiedExpiry.toMillis() < Date.now()) {
      throw new HttpsError("deadline-exceeded", "Verification expired. Start again.");
    }

    const passwordHash = await hashPassword(newPassword);
    await db.collection(collectionForRole(role)).doc(found.id).update({
      password_hash: passwordHash,
      password: FieldValue.delete(),
      reset_otp: FieldValue.delete(),
      otp_expiry: FieldValue.delete(),
      otp_attempts: FieldValue.delete(),
      last_otp_sent_at: FieldValue.delete(),
      password_reset_verified: FieldValue.delete(),
      password_reset_verified_expiry: FieldValue.delete(),
      password_changed_at: FieldValue.serverTimestamp(),
      force_password_change: false,
      failed_attempts: 0,
      locked_until: FieldValue.delete(),
      session_version: FieldValue.increment(1),
    });

    const label = role === "vendor" ? "Vendor" : "Delivery partner";
    await writeAdminNotification({
      title: "Password reset completed",
      message: `${label} ${email} reset their password.`,
      type: "password_reset_completed",
      category: role === "vendor" ? "vendors" : "delivery",
      metadata: { role, partnerId: found.id, email },
    });

    return { success: true };
  }
);

/** Secure login with lockout, last_login, and session version. */
export const partnerLogin = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const role = parseRole(req.data?.role);
    const email = str(req.data?.email).toLowerCase();
    const password = str(req.data?.password);
    const deviceInfo = (req.data?.deviceInfo ?? {}) as Record<string, unknown>;

    if (!email || !password) {
      throw new HttpsError("invalid-argument", "Email and password are required.");
    }

    const found = await findPartnerByEmail(role, email);
    if (!found) {
      return { success: false, error: "Invalid email or password." };
    }

    const ref = db.collection(collectionForRole(role)).doc(found.id);
    const data = found.data;

    if (!isAccountActive(data)) {
      throw new HttpsError("permission-denied", "This account is disabled.");
    }

    if (isLocked(data)) {
      const until = (data.locked_until as Timestamp).toDate().toLocaleString();
      throw new HttpsError(
        "resource-exhausted",
        `Account temporarily locked. Try again after ${until}.`
      );
    }

    const valid = await verifyPartnerPassword(data, password);
    if (!valid) {
      const failed = Number(data.failed_attempts ?? 0) + 1;
      const updates: Record<string, unknown> = {
        failed_attempts: failed,
        last_failed_login: FieldValue.serverTimestamp(),
      };
      if (failed >= MAX_LOGIN_ATTEMPTS) {
        updates.locked_until = Timestamp.fromMillis(Date.now() + LOCK_DURATION_MS);
        await writeAdminNotification({
          title: "Multiple failed logins",
          message: `${appNameForRole(role)}: ${email} had ${failed} failed login attempts.`,
          type: "failed_login_spike",
          category: role === "vendor" ? "vendors" : "delivery",
          soundAlert: true,
          metadata: { role, partnerId: found.id, email, failed_attempts: failed },
        });
      }
      await ref.update(updates);
      return { success: false, error: "Invalid email or password." };
    }

    const sessionVersion = Number(data.session_version ?? 0);
    await ref.update({
      failed_attempts: 0,
      locked_until: FieldValue.delete(),
      last_login: {
        at: FieldValue.serverTimestamp(),
        platform: str(deviceInfo.platform),
        deviceId: str(deviceInfo.deviceId),
        appVersion: str(deviceInfo.appVersion),
      },
    });

    return {
      success: true,
      partnerId: found.id,
      sessionVersion,
      forcePasswordChange: data.force_password_change === true,
      profile: publicProfile(role, found.id, data),
    };
  }
);

type AdminAction =
  | "reset_password_manual"
  | "send_password_reset_email"
  | "force_logout"
  | "set_enabled"
  | "set_force_password_change";

/** Admin-only partner account controls. */
export const adminPartnerAccountAction = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const role = parseRole(req.data?.role);
    const partnerId = str(req.data?.partnerId);
    const action = str(req.data?.action) as AdminAction;
    if (!partnerId) {
      throw new HttpsError("invalid-argument", "partnerId is required.");
    }

    const snap = await getPartnerDoc(role, partnerId);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Partner not found.");
    }
    const data = snap.data()!;
    const ref = db.collection(collectionForRole(role)).doc(partnerId);
    const email = str(data.email);

    switch (action) {
      case "reset_password_manual": {
        const tempPassword = str(req.data?.newPassword);
        if (!tempPassword) {
          throw new HttpsError("invalid-argument", "newPassword is required.");
        }
        const ruleErr = validatePasswordRules(tempPassword);
        if (ruleErr) throw new HttpsError("invalid-argument", ruleErr);
        const passwordHash = await hashPassword(tempPassword);
        await ref.update({
          password_hash: passwordHash,
          password: FieldValue.delete(),
          password_changed_at: FieldValue.serverTimestamp(),
          force_password_change: true,
          session_version: FieldValue.increment(1),
          reset_otp: FieldValue.delete(),
          otp_expiry: FieldValue.delete(),
        });
        await writeActivityLog({
          action: "admin_reset_password",
          entityType: role,
          entityId: partnerId,
          summary: `Admin set temporary password for ${email}`,
        });
        return { success: true, message: "Password updated. User must change it on next login." };
      }
      case "send_password_reset_email": {
        if (!email) throw new HttpsError("failed-precondition", "Partner has no email.");
        await issueOtpAndNotify(role, partnerId, email, data, false);
        return { success: true, message: "Password reset email sent." };
      }
      case "force_logout": {
        await ref.update({ session_version: FieldValue.increment(1) });
        await writeActivityLog({
          action: "admin_force_logout",
          entityType: role,
          entityId: partnerId,
          summary: `Admin forced logout for ${email}`,
        });
        return { success: true, message: "User signed out on all devices." };
      }
      case "set_enabled": {
        const enabled = req.data?.enabled === true;
        await ref.update({ is_active: enabled });
        return { success: true, message: enabled ? "Account enabled." : "Account disabled." };
      }
      case "set_force_password_change": {
        const force = req.data?.force === true;
        await ref.update({ force_password_change: force });
        return { success: true, message: force ? "Must change password on next login." : "Cleared." };
      }
      default:
        throw new HttpsError("invalid-argument", "Unknown action.");
    }
  }
);

/** Change password when `force_password_change` is set (after admin reset). */
export const partnerUpdatePassword = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const role = parseRole(req.data?.role);
    const partnerId = str(req.data?.partnerId);
    const newPassword = str(req.data?.newPassword);
    const currentPassword = str(req.data?.currentPassword);

    const ruleErr = validatePasswordRules(newPassword);
    if (ruleErr) throw new HttpsError("invalid-argument", ruleErr);

    if (!partnerId) {
      throw new HttpsError("invalid-argument", "partnerId is required.");
    }

    const snap = await getPartnerDoc(role, partnerId);
    if (!snap.exists) throw new HttpsError("not-found", "Account not found.");
    const data = snap.data()!;

    if (!isAccountActive(data)) {
      throw new HttpsError("permission-denied", "Account disabled.");
    }

    const mustChange = data.force_password_change === true;
    if (!mustChange) {
      if (!currentPassword) {
        throw new HttpsError("invalid-argument", "Current password is required.");
      }
      const valid = await verifyPartnerPassword(data, currentPassword);
      if (!valid) {
        throw new HttpsError("permission-denied", "Current password is incorrect.");
      }
    }

    const passwordHash = await hashPassword(newPassword);
    const currentVersion = Number(data.session_version ?? 0);
    const newVersion = currentVersion + 1;
    await db.collection(collectionForRole(role)).doc(partnerId).update({
      password_hash: passwordHash,
      password: FieldValue.delete(),
      password_changed_at: FieldValue.serverTimestamp(),
      force_password_change: false,
      session_version: newVersion,
    });

    return { success: true, sessionVersion: newVersion };
  }
);

/** Client checks session is still valid (force logout). */
export const partnerCheckSession = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const role = parseRole(req.data?.role);
    const partnerId = str(req.data?.partnerId);
    const sessionVersion = Number(req.data?.sessionVersion ?? -1);
    if (!partnerId) {
      throw new HttpsError("invalid-argument", "partnerId is required.");
    }
    const snap = await getPartnerDoc(role, partnerId);
    if (!snap.exists) {
      return { valid: false, reason: "not_found" };
    }
    const data = snap.data()!;
    if (!isAccountActive(data)) {
      return { valid: false, reason: "disabled" };
    }
    const current = Number(data.session_version ?? 0);
    if (current !== sessionVersion) {
      return { valid: false, reason: "session_revoked" };
    }
    return {
      valid: true,
      forcePasswordChange: data.force_password_change === true,
      sessionVersion: current,
    };
  }
);
