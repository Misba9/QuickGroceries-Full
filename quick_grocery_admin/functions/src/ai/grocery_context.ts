import * as admin from "firebase-admin";

export type CatalogProduct = {
  id: string;
  name: string;
  category: string;
  price: number;
  discountPrice: number;
  stock: number;
  image: string;
  rating: number;
  unit: string;
  isAvailable: boolean;
};

export type CatalogOffer = {
  id: string;
  title: string;
  subtitle: string;
};

function num(v: unknown, fallback = 0): number {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function productFromDoc(
  id: string,
  data: Record<string, unknown>,
): CatalogProduct {
  const price = num(data.price);
  const slash = num(data.slashedPrice ?? data.discountPrice);
  const stock = Math.max(0, Math.floor(num(data.stock)));
  const availableFlag =
    data.isAvailable === false || data.publish === false ? false : true;
  return {
    id,
    name: str(data.name) || "Product",
    category: str(data.category),
    price,
    discountPrice: slash > 0 && slash < price ? slash : price,
    stock,
    image: str(data.image ?? data.imageUrl ?? data.thumbnail),
    rating: num(data.rating),
    unit: str(data.unit || data.unitPerItem),
    isAvailable: availableFlag && stock > 0,
  };
}

/** Extract searchable tokens from a user question (min length 3). */
export function extractSearchTokens(message: string): string[] {
  const stop = new Set([
    "the",
    "and",
    "for",
    "you",
    "have",
    "any",
    "with",
    "from",
    "that",
    "this",
    "what",
    "where",
    "when",
    "how",
    "are",
    "is",
    "do",
    "does",
    "can",
    "please",
    "show",
    "find",
    "want",
    "need",
    "some",
    "about",
    "my",
    "me",
    "a",
    "an",
    "of",
    "to",
    "in",
    "on",
    "at",
    "or",
  ]);
  const raw = message
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .map((t) => t.trim())
    .filter((t) => t.length >= 3 && !stop.has(t));
  return [...new Set(raw)].slice(0, 6);
}

/**
 * Lightweight catalog search — pulls a recent product window and filters
 * in memory (works without composite indexes / Algolia).
 */
export async function searchCatalogProducts(
  message: string,
  limit = 8,
): Promise<CatalogProduct[]> {
  const db = admin.firestore();
  const tokens = extractSearchTokens(message);
  const snap = await db
    .collection("products")
    .orderBy(admin.firestore.FieldPath.documentId())
    .limit(400)
    .get();

  const scored: Array<{ p: CatalogProduct; score: number }> = [];
  for (const doc of snap.docs) {
    const p = productFromDoc(doc.id, doc.data() as Record<string, unknown>);
    const hay = `${p.name} ${p.category} ${p.unit}`.toLowerCase();
    let score = 0;
    if (tokens.length === 0) {
      if (p.isAvailable) score = 1;
    } else {
      for (const t of tokens) {
        if (hay.includes(t)) score += t.length >= 5 ? 3 : 2;
      }
    }
    if (score > 0) scored.push({ p, score });
  }

  scored.sort((a, b) => b.score - a.score || a.p.name.localeCompare(b.p.name));
  return scored.slice(0, limit).map((x) => x.p);
}

export async function fetchActiveOffers(limit = 5): Promise<CatalogOffer[]> {
  const db = admin.firestore();
  try {
    const snap = await db.collection("offer_banners").limit(40).get();
    const now = Date.now();
    const offers: CatalogOffer[] = [];
    for (const doc of snap.docs) {
      const d = doc.data();
      const active = d.active !== false && d.isActive !== false;
      if (!active) continue;
      const end = d.endAt?.toMillis?.() ?? d.endDate?.toMillis?.() ?? null;
      if (end != null && end < now) continue;
      offers.push({
        id: doc.id,
        title: str(d.title) || "Offer",
        subtitle: str(d.subtitle || d.discountBadgeLabel),
      });
      if (offers.length >= limit) break;
    }
    return offers;
  } catch {
    return [];
  }
}

export async function fetchRecentOrdersSummary(
  uid: string,
  limit = 3,
): Promise<string> {
  if (!uid) return "";
  const db = admin.firestore();
  try {
    const snap = await db
      .collection("orders")
      .where("userId", "==", uid)
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();
    if (snap.empty) {
      // Some schemas use customerId
      const alt = await db
        .collection("orders")
        .where("customerId", "==", uid)
        .limit(limit)
        .get();
      if (alt.empty) return "No recent orders found for this user.";
      return alt.docs
        .map((d) => {
          const x = d.data();
          return `- Order ${d.id.slice(0, 8)}… status=${str(x.status || x.orderStatus)}`;
        })
        .join("\n");
    }
    return snap.docs
      .map((d) => {
        const x = d.data();
        return `- Order ${d.id.slice(0, 8)}… status=${str(x.status || x.orderStatus)}`;
      })
      .join("\n");
  } catch {
    return "Order lookup temporarily unavailable.";
  }
}
