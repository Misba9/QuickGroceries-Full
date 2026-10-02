import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";

const db = admin.firestore();

function str(v: unknown): string {
  return (v ?? "").toString().trim();
}

/** Always-present device profile fields for API responses. */
export function deviceProfileFromData(
  data: admin.firestore.DocumentData | undefined | null,
): {
  platform: string;
  appVersion: string;
  buildNumber: string;
  deviceModel: string;
  osVersion: string;
  lastSeen: string | null;
  lastLogin: string | null;
} {
  const d = data ?? {};
  const pick = (...keys: string[]) => {
    for (const k of keys) {
      const v = str(d[k]);
      if (v) return v;
    }
    return "";
  };

  const appVersion = pick("appVersion", "app_version", "version");
  const buildNumber = pick("buildNumber", "build_number");
  const displayVersion =
    !appVersion
      ? buildNumber
      : !buildNumber || appVersion.includes(buildNumber) || appVersion.includes("+")
        ? appVersion
        : `${appVersion}+${buildNumber}`;

  const ts = (raw: unknown): string | null => {
    if (raw && typeof (raw as admin.firestore.Timestamp).toDate === "function") {
      return (raw as admin.firestore.Timestamp).toDate().toISOString();
    }
    if (typeof raw === "string" && raw.trim()) return raw.trim();
    return null;
  };

  return {
    platform: pick("platform", "fcmPlatform", "device_type"),
    appVersion: displayVersion,
    buildNumber,
    deviceModel: pick("deviceModel", "device_model"),
    osVersion: pick("osVersion", "os_version"),
    lastSeen: ts(d.lastSeen ?? d.last_seen ?? d.last_active_at ?? d.lastActiveAt),
    lastLogin: ts(d.lastLogin ?? d.last_login),
  };
}

/**
 * GET customer profile for admin — merge-safe read that always returns
 * platform / appVersion / buildNumber / deviceModel / osVersion / lastSeen / lastLogin.
 */
export const getCustomerProfileCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const userId = str(request.data?.userId ?? request.data?.id);
    if (!userId) {
      throw new HttpsError("invalid-argument", "userId is required.");
    }

    const snap = await db.collection("customers").doc(userId).get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Customer not found.");
    }

    const data = snap.data() ?? {};
    const device = deviceProfileFromData(data);

    return {
      userId,
      id: snap.id,
      name: str(data.name),
      email: str(data.email),
      phone: str(data.phone ?? data.phoneNumber),
      ...device,
      profile: {
        ...data,
        ...device,
      },
    };
  },
);

/**
 * Merge-only device profile update (client or admin). Never clears existing
 * values with empty strings.
 */
export const syncCustomerDeviceProfileCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const targetId = str(request.data?.userId) || uid;
    if (targetId !== uid) {
      await assertNotificationAdmin(uid);
    }

    const body = (request.data ?? {}) as Record<string, unknown>;
    const write: Record<string, unknown> = {
      uid: targetId,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      lastSeen: admin.firestore.FieldValue.serverTimestamp(),
      last_seen: admin.firestore.FieldValue.serverTimestamp(),
      last_active_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    const put = (key: string, value: unknown) => {
      const v = str(value);
      if (v) write[key] = v;
    };

    put("platform", body.platform);
    put("fcmPlatform", body.platform);
    put("device_type", body.platform);
    put("appVersion", body.appVersion);
    put("app_version", body.appVersion);
    put("buildNumber", body.buildNumber);
    put("build_number", body.buildNumber);
    put("deviceModel", body.deviceModel);
    put("device_model", body.deviceModel);
    put("osVersion", body.osVersion);
    put("os_version", body.osVersion);

    if (body.isLogin === true) {
      write.lastLogin = admin.firestore.FieldValue.serverTimestamp();
      write.last_login = admin.firestore.FieldValue.serverTimestamp();
    }

    await db.collection("customers").doc(targetId).set(write, { merge: true });
    await db.collection("users").doc(targetId).set(write, { merge: true });

    const snap = await db.collection("customers").doc(targetId).get();
    return {
      userId: targetId,
      ...deviceProfileFromData(snap.data()),
    };
  },
);
