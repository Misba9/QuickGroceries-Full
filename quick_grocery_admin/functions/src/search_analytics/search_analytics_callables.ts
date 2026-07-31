import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";

const db = admin.firestore();
const COL = "search_logs";

function str(v: unknown, max = 200): string {
  const s = (v ?? "").toString().trim();
  return s.length > max ? s.slice(0, max) : s;
}

function asStringList(v: unknown, maxItems = 5): string[] {
  if (!Array.isArray(v)) return [];
  return v
    .map((x) => str(x, 120))
    .filter(Boolean)
    .slice(0, maxItems);
}

function tsIso(raw: unknown): string | null {
  if (raw && typeof (raw as admin.firestore.Timestamp).toDate === "function") {
    return (raw as admin.firestore.Timestamp).toDate().toISOString();
  }
  if (typeof raw === "string" && raw.trim()) return raw.trim();
  return null;
}

/**
 * User-app search telemetry. Uses Admin SDK so writes succeed even when
 * client Firestore rules block `search_logs`.
 */
export const logSearchEventCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required to log search.");
    }

    const query = str(request.data?.query, 120);
    if (query.length < 2) {
      throw new HttpsError("invalid-argument", "query must be at least 2 characters.");
    }

    const normalized =
      str(request.data?.queryNormalized || query, 120).toLowerCase().replace(/\s+/g, " ");
    const resultCountRaw = request.data?.resultCount;
    const resultCount =
      typeof resultCountRaw === "number" && Number.isFinite(resultCountRaw)
        ? Math.max(0, Math.floor(resultCountRaw))
        : parseInt(str(resultCountRaw, 12), 10) || 0;

    const payload = {
      query,
      queryNormalized: normalized,
      userId: uid,
      userName: str(request.data?.userName, 80),
      userPhone: str(request.data?.userPhone, 32),
      userEmail: str(request.data?.userEmail, 120),
      resultCount,
      hasResults: resultCount > 0,
      source: str(request.data?.source || "typed", 32) || "typed",
      platform: str(request.data?.platform, 32),
      appVersion: str(request.data?.appVersion, 40),
      catalogSampleSize:
        typeof request.data?.catalogSampleSize === "number"
          ? Math.max(0, Math.floor(request.data.catalogSampleSize))
          : 0,
      topResultIds: asStringList(request.data?.topResultIds),
      topResultNames: asStringList(request.data?.topResultNames),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      clientAt: admin.firestore.Timestamp.now(),
      loggedVia: "callable",
    };

    const ref = await db.collection(COL).add(payload);
    return { ok: true, id: ref.id };
  },
);

/**
 * Admin Search Analytics — list recent search events (rules-safe).
 */
export const listSearchLogsCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);

    const limitRaw = request.data?.limit;
    const limit =
      typeof limitRaw === "number" && Number.isFinite(limitRaw)
        ? Math.min(1000, Math.max(1, Math.floor(limitRaw)))
        : 500;

    let docs: admin.firestore.QueryDocumentSnapshot[] = [];
    try {
      const snap = await db
        .collection(COL)
        .orderBy("createdAt", "desc")
        .limit(limit)
        .get();
      docs = snap.docs;
    } catch {
      const snap = await db.collection(COL).limit(limit).get();
      docs = [...snap.docs].sort((a, b) => {
        const at =
          (a.data().createdAt as admin.firestore.Timestamp | undefined)?.toMillis?.() ??
          0;
        const bt =
          (b.data().createdAt as admin.firestore.Timestamp | undefined)?.toMillis?.() ??
          0;
        return bt - at;
      });
    }

    const logs = docs.map((d) => {
      const data = d.data();
      return {
        id: d.id,
        query: str(data.query),
        queryNormalized: str(data.queryNormalized || data.query).toLowerCase(),
        userId: str(data.userId),
        userName: str(data.userName),
        userPhone: str(data.userPhone),
        userEmail: str(data.userEmail),
        resultCount:
          typeof data.resultCount === "number" ? data.resultCount : 0,
        hasResults: data.hasResults === true || (data.resultCount as number) > 0,
        source: str(data.source),
        platform: str(data.platform || data.fcmPlatform),
        appVersion: str(data.appVersion || data.app_version),
        catalogSampleSize:
          typeof data.catalogSampleSize === "number" ? data.catalogSampleSize : 0,
        topResultIds: asStringList(data.topResultIds),
        topResultNames: asStringList(data.topResultNames),
        createdAt: tsIso(data.createdAt ?? data.clientAt),
      };
    });

    return { logs, count: logs.length };
  },
);
