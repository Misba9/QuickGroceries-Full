import * as nodemailer from "nodemailer";
import { logger } from "firebase-functions";

function smtpConfig() {
  const host = process.env.SMTP_HOST?.trim();
  const user = process.env.SMTP_USER?.trim();
  const pass = process.env.SMTP_PASS?.trim();
  const from = process.env.SMTP_FROM?.trim() || user;
  if (!host || !user || !pass || !from) return null;
  const port = Number(process.env.SMTP_PORT || "587");
  return { host, port, user, pass, from };
}

export function buildPasswordResetOtpHtml(opts: {
  otp: string;
  appName: string;
  minutesValid: number;
  logoUrl?: string;
}): string {
  const logoBlock = opts.logoUrl?.trim()
    ? `<img src="${opts.logoUrl}" alt="${opts.appName}" width="72" height="72" style="border-radius:12px;margin-bottom:16px;" />`
    : `<p style="margin:0;font-size:28px;font-weight:700;">${opts.appName}</p>`;

  return `<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/></head>
<body style="margin:0;padding:0;background:#f4f6f8;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:32px 16px;">
    <tr><td align="center">
      <table width="100%" style="max-width:480px;background:#fff;border-radius:16px;box-shadow:0 4px 24px rgba(0,0,0,.08);overflow:hidden;">
        <tr><td style="padding:32px 28px;text-align:center;background:linear-gradient(135deg,#1a7f37 0%,#2ecc71 100%);color:#fff;">
          ${logoBlock}
          <h1 style="margin:8px 0 0;font-size:22px;font-weight:700;">Password Reset OTP</h1>
        </td></tr>
        <tr><td style="padding:28px;">
          <p style="margin:0 0 16px;color:#334155;font-size:15px;line-height:1.5;">Use this one-time code to reset your password:</p>
          <div style="text-align:center;margin:24px 0;">
            <span style="display:inline-block;letter-spacing:8px;font-size:32px;font-weight:700;color:#1a7f37;background:#ecfdf5;padding:16px 24px;border-radius:12px;">${opts.otp}</span>
          </div>
          <p style="margin:0 0 12px;color:#64748b;font-size:14px;">This code expires in <strong>${opts.minutesValid} minutes</strong>.</p>
          <p style="margin:0;color:#94a3b8;font-size:13px;line-height:1.5;">If you did not request a password reset, ignore this email. Never share your OTP with anyone — our team will never ask for it.</p>
        </td></tr>
        <tr><td style="padding:16px 28px;background:#f8fafc;text-align:center;color:#94a3b8;font-size:12px;">
          &copy; ${new Date().getFullYear()} ${opts.appName}. All rights reserved.
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

export async function sendPasswordResetOtpEmail(opts: {
  to: string;
  otp: string;
  appName: string;
}): Promise<void> {
  const cfg = smtpConfig();
  if (!cfg) {
    logger.warn("partner_auth: SMTP not configured — OTP email skipped");
    return;
  }

  const transporter = nodemailer.createTransport({
    host: cfg.host,
    port: cfg.port,
    secure: cfg.port === 465,
    auth: { user: cfg.user, pass: cfg.pass },
  });

  const logoUrl = process.env.APP_LOGO_URL?.trim();
  const html = buildPasswordResetOtpHtml({
    otp: opts.otp,
    appName: opts.appName,
    minutesValid: 5,
    logoUrl,
  });

  await transporter.sendMail({
    from: cfg.from,
    to: opts.to,
    subject: "Password Reset OTP",
    html,
    text: `Your ${opts.appName} password reset code is ${opts.otp}. It expires in 5 minutes. If you did not request this, ignore this email.`,
  });
}
