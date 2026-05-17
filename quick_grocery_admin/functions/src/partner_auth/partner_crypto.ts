import * as crypto from "crypto";
import * as bcrypt from "bcryptjs";

const BCRYPT_ROUNDS = 12;

export function generateOtp(): string {
  return crypto.randomInt(0, 1_000_000).toString().padStart(6, "0");
}

export function otpPepper(): string {
  const secret = process.env.PARTNER_OTP_SECRET?.trim();
  if (!secret) {
    throw new Error("PARTNER_OTP_SECRET is not configured");
  }
  return secret;
}

/** Stored in Firestore field `reset_otp` (hash only, never plain OTP). */
export function hashOtp(otp: string): string {
  return crypto
    .createHmac("sha256", otpPepper())
    .update(otp.trim())
    .digest("hex");
}

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, BCRYPT_ROUNDS);
}

export async function verifyPassword(
  plain: string,
  hash: string | undefined
): Promise<boolean> {
  if (!hash || !hash.startsWith("$2")) return false;
  return bcrypt.compare(plain, hash);
}

export function validatePasswordRules(password: string): string | null {
  if (password.length < 8) {
    return "Password must be at least 8 characters";
  }
  if (!/[A-Z]/.test(password)) {
    return "Password must include at least one uppercase letter";
  }
  if (!/[0-9]/.test(password)) {
    return "Password must include at least one number";
  }
  return null;
}
