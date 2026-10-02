import {
  CatalogOffer,
  CatalogProduct,
  fetchActiveOffers,
  fetchRecentOrdersSummary,
  searchCatalogProducts,
} from "./grocery_context";
import { readGeminiApiKey } from "./gemini_config";

export type ChatTurn = { role: "user" | "assistant"; text: string };

export type AssistantPayload = {
  reply: string;
  productIds: string[];
  quickReplies: string[];
  intent:
    | "product_search"
    | "offers"
    | "order_status"
    | "delivery"
    | "payment"
    | "coupon"
    | "general";
  source: "gemini" | "catalog";
};

const SYSTEM = `You are QuickGrocery's in-app shopping assistant for a grocery delivery app in India.
Be concise, friendly, and accurate. Use Indian Rupees (₹).

RULES:
- Only recommend products that appear in CATALOG_RESULTS. Never invent products, prices, or stock.
- If nothing matches, say you couldn't find it and suggest refining the search or browsing categories.
- For order status, use ORDER_CONTEXT only — never invent tracking updates.
- For offers, use OFFERS_CONTEXT when present.
- Answer delivery/payment/coupon/refund questions with general grocery-app guidance and suggest Support if account-specific.
- Prefer short paragraphs. Use markdown sparingly (bold for product names).
- Respond ONLY with valid JSON (no markdown fences):
{
  "reply": "string",
  "productIds": ["id1","id2"],
  "quickReplies": ["short chip 1","short chip 2","short chip 3"],
  "intent": "product_search|offers|order_status|delivery|payment|coupon|general"
}
productIds must be a subset of CATALOG_RESULTS ids (max 4).`;

function looksLikeOrderQuestion(msg: string): boolean {
  const m = msg.toLowerCase();
  return (
    m.includes("order") ||
    m.includes("track") ||
    m.includes("delivery status") ||
    m.includes("where is my") ||
    m.includes("arrived")
  );
}

function looksLikeOfferQuestion(msg: string): boolean {
  const m = msg.toLowerCase();
  return (
    m.includes("offer") ||
    m.includes("discount") ||
    m.includes("deal") ||
    m.includes("coupon") ||
    m.includes("promo")
  );
}

function catalogFallback(
  message: string,
  products: CatalogProduct[],
  offers: CatalogOffer[],
): AssistantPayload {
  if (looksLikeOfferQuestion(message) && offers.length) {
    const lines = offers
      .slice(0, 4)
      .map((o) => `• **${o.title}**${o.subtitle ? ` — ${o.subtitle}` : ""}`)
      .join("\n");
    return {
      reply: `Here are offers running right now:\n\n${lines}\n\nOpen the Offers tab for full details.`,
      productIds: products.filter((p) => p.isAvailable).slice(0, 3).map((p) => p.id),
      quickReplies: ["Show fruits", "Any milk offers?", "Browse snacks"],
      intent: "offers",
      source: "catalog",
    };
  }

  if (looksLikeOrderQuestion(message)) {
    return {
      reply:
        "I can see your recent orders when signed in. Open **Orders** in the bottom tab for live tracking, invoices, and help — or tell me an order concern and I'll guide you.",
      productIds: [],
      quickReplies: ["Open orders help", "Delivery timings", "Refund policy"],
      intent: "order_status",
      source: "catalog",
    };
  }

  if (products.length === 0) {
    return {
      reply:
        "I couldn't find matching items in our catalog yet. Try a product name (e.g. *Amul Milk*), a category (*fruits*), or ask about today's offers.",
      productIds: [],
      quickReplies: ["Today's offers", "Fresh vegetables", "Breakfast ideas"],
      intent: "product_search",
      source: "catalog",
    };
  }

  const available = products.filter((p) => p.isAvailable);
  const list = (available.length ? available : products).slice(0, 4);
  const lines = list
    .map((p) => {
      const price =
        p.discountPrice < p.price
          ? `₹${p.discountPrice} (was ₹${p.price})`
          : `₹${p.price}`;
      const stock = p.isAvailable ? "In stock" : "Out of stock";
      return `• **${p.name}** — ${price} · ${stock}`;
    })
    .join("\n");

  return {
    reply: `Here's what I found related to your question:\n\n${lines}\n\nTap a card below to open details or add to cart.`,
    productIds: list.map((p) => p.id),
    quickReplies: ["Any discounts?", "Suggest breakfast", "Show more"],
    intent: "product_search",
    source: "catalog",
  };
}

function safeParseModelJson(raw: string): Partial<AssistantPayload> | null {
  const trimmed = raw.trim();
  const start = trimmed.indexOf("{");
  const end = trimmed.lastIndexOf("}");
  if (start < 0 || end <= start) return null;
  try {
    return JSON.parse(trimmed.slice(start, end + 1)) as Partial<AssistantPayload>;
  } catch {
    return null;
  }
}

async function callGemini(opts: {
  apiKey: string;
  userMessage: string;
  history: ChatTurn[];
  products: CatalogProduct[];
  offers: CatalogOffer[];
  orderContext: string;
}): Promise<AssistantPayload | null> {
  const catalogJson = JSON.stringify(
    opts.products.map((p) => ({
      id: p.id,
      name: p.name,
      category: p.category,
      price: p.price,
      discountPrice: p.discountPrice,
      stock: p.stock,
      available: p.isAvailable,
    })),
  );
  const offersJson = JSON.stringify(opts.offers);
  const hist = opts.history
    .slice(-8)
    .map((h) => `${h.role.toUpperCase()}: ${h.text}`)
    .join("\n");

  const userPrompt = `CATALOG_RESULTS: ${catalogJson}
OFFERS_CONTEXT: ${offersJson}
ORDER_CONTEXT:
${opts.orderContext || "(none)"}

RECENT_CHAT:
${hist || "(new session)"}

USER_MESSAGE: ${opts.userMessage}`;

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent` +
    `?key=${encodeURIComponent(opts.apiKey)}`;

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: `${SYSTEM}\n\n${userPrompt}` }] }],
      generationConfig: {
        temperature: 0.4,
        maxOutputTokens: 1024,
        responseMimeType: "application/json",
      },
    }),
  });

  if (!res.ok) {
    const body = await res.text().catch(() => "");
    console.error("[aiGroceryAssistant] gemini http", res.status, body.slice(0, 400));
    return null;
  }

  const json = (await res.json()) as {
    candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
  };
  const text =
    json.candidates?.[0]?.content?.parts?.map((p) => p.text || "").join("") ||
    "";
  const parsed = safeParseModelJson(text);
  if (!parsed?.reply) return null;

  const allowed = new Set(opts.products.map((p) => p.id));
  const productIds = (parsed.productIds || [])
    .map((id) => String(id).trim())
    .filter((id) => allowed.has(id))
    .slice(0, 4);

  const quickReplies = (parsed.quickReplies || [])
    .map((q) => String(q).trim())
    .filter(Boolean)
    .slice(0, 4);

  const intent = (parsed.intent || "general") as AssistantPayload["intent"];

  return {
    reply: String(parsed.reply).trim(),
    productIds,
    quickReplies:
      quickReplies.length > 0
        ? quickReplies
        : ["Today's offers", "Find milk", "Order help"],
    intent,
    source: "gemini",
  };
}

export async function runGroceryAssistant(opts: {
  uid: string;
  message: string;
  history: ChatTurn[];
}): Promise<AssistantPayload> {
  const message = opts.message.trim().slice(0, 2000);
  if (!message) {
    return {
      reply: "Send a short question about products, offers, or your order.",
      productIds: [],
      quickReplies: ["Any discounts?", "Amul milk", "Where is my order?"],
      intent: "general",
      source: "catalog",
    };
  }

  const [products, offers, orderContext] = await Promise.all([
    searchCatalogProducts(message, 8),
    looksLikeOfferQuestion(message) || message.length < 40
      ? fetchActiveOffers(5)
      : Promise.resolve([] as CatalogOffer[]),
    looksLikeOrderQuestion(message)
      ? fetchRecentOrdersSummary(opts.uid, 3)
      : Promise.resolve(""),
  ]);

  const apiKey = readGeminiApiKey();
  if (apiKey) {
    try {
      const llm = await callGemini({
        apiKey,
        userMessage: message,
        history: opts.history,
        products,
        offers,
        orderContext,
      });
      if (llm) {
        // Ensure we never return invent products — ids already filtered.
        if (llm.productIds.length === 0 && products.length > 0 && llm.intent === "product_search") {
          llm.productIds = products.filter((p) => p.isAvailable).slice(0, 3).map((p) => p.id);
        }
        return llm;
      }
    } catch (e) {
      console.error("[aiGroceryAssistant] gemini failed", e);
    }
  }

  return catalogFallback(message, products, offers);
}
