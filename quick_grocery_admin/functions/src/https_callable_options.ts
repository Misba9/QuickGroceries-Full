import cors from "cors";

/** Same region as Flutter `FirebaseFunctions.instanceFor(region: ...)`. */
export const REGION = "us-central1";

/**
 * Express-style CORS middleware from the `cors` package.
 * Use only with raw `onRequest` / Express routers — **not** used by `onCall`.
 * Callable CORS is configured via `callableBaseOptions().cors` below.
 */
export const expressOpenCors = cors({
  origin: true,
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: [
    "Authorization",
    "Content-Type",
    "X-Firebase-AppCheck",
    "X-Firebase-GMPID",
    "X-Client-Version",
    "X-Requested-With",
    "Accept",
  ],
  maxAge: 3600,
});

/**
 * Shared options for **2nd gen** `onCall` handlers.
 *
 * Gen2 callables run on Cloud Run; browsers send a CORS preflight. Without an
 * explicit `cors` setting, Flutter Web (localhost + hosting) can fail.
 *
 * - Default: `cors: true` (allow any origin) — best for dev + mixed staging URLs.
 * - Production: set `CALLABLE_CORS_ORIGINS` to a comma-separated list of exact
 *   origins, e.g. `https://my-admin.web.app,https://admin.example.com`
 */
export function callableBaseOptions(): {
  region: string;
  cors: boolean | (string | RegExp)[];
} {
  const originsEnv = process.env.CALLABLE_CORS_ORIGINS?.trim();
  if (originsEnv) {
    const list = originsEnv.split(",").map((s) => s.trim()).filter(Boolean);
    if (list.length) {
      return { region: REGION, cors: list };
    }
  }
  if (process.env.CALLABLE_CORS_MODE === "strict") {
    return {
      region: REGION,
      cors: [
        /^https?:\/\/localhost(:\d+)?$/,
        /^https?:\/\/127\.0\.0\.1(:\d+)?$/,
        /^https:\/\/[\w-]+\.web\.app$/,
        /^https:\/\/[\w-]+\.firebaseapp\.com$/,
      ],
    };
  }
  return { region: REGION, cors: true };
}
