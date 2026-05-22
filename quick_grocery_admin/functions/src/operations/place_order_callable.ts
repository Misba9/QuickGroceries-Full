import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";

function num(v: unknown, fallback = 0): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function isAvailable(data: FirebaseFirestore.DocumentData): boolean {
  if (data.isAvailable === false) return false;
  if (data.is_active === false) return false;
  if (data.active === false) return false;
  if (data.stockStatus === "out_of_stock") return false;
  return true;
}

function effectiveMax(stock: number, maxOrder: number): number {
  if (stock <= 0) return 0;
  if (maxOrder <= 0) return stock;
  return maxOrder < stock ? maxOrder : stock;
}

interface LineInput {
  productId: string;
  itemCount: number;
  selectedWeightInGrams?: number;
}

/** Validates stock/max-order and places order atomically (decrements inventory). */
export const placeOrderCallable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in to place an order.");
    }

    const rawItems = req.data?.items;
    if (!Array.isArray(rawItems) || rawItems.length === 0) {
      throw new HttpsError("invalid-argument", "Cart items are required.");
    }

    const lines: LineInput[] = rawItems.map((row: Record<string, unknown>) => ({
      productId: str(row.productId),
      itemCount: Math.max(0, Math.floor(num(row.itemCount))),
      selectedWeightInGrams: num(row.selectedWeightInGrams, 1000),
    }));

    if (lines.some((l) => !l.productId || l.itemCount < 1)) {
      throw new HttpsError("invalid-argument", "Invalid cart line.");
    }

    const db = admin.firestore();
    const orderRef = db.collection("orders").doc();

    try {
      await db.runTransaction(async (tx) => {
        const productSnaps = await Promise.all(
          lines.map((l) => tx.get(db.collection("products").doc(l.productId)))
        );

        const orderProducts: Record<string, unknown>[] = [];

        for (let i = 0; i < lines.length; i++) {
          const line = lines[i];
          const snap = productSnaps[i];
          if (!snap.exists) {
            throw new HttpsError(
              "failed-precondition",
              "Some items are no longer available"
            );
          }
          const data = snap.data()!;
          const stock = num(data.stock ?? data.stock_quantity);
          const maxOrder = num(data.maxOrder ?? data.max_order_quantity);
          const minOrder = num(data.minOrder ?? data.min_order_quantity, 1);
          const available = isAvailable(data);

          if (!available || stock <= 0) {
            throw new HttpsError(
              "failed-precondition",
              "Some items are out of stock"
            );
          }

          const cap = effectiveMax(stock, maxOrder);
          if (line.itemCount > cap) {
            throw new HttpsError(
              "failed-precondition",
              "Some items exceed the maximum order limit"
            );
          }
          if (minOrder > 0 && line.itemCount < minOrder) {
            throw new HttpsError(
              "failed-precondition",
              "Some items do not meet the minimum order quantity"
            );
          }

          const nextStock = stock - line.itemCount;
          const patch: Record<string, unknown> = {
            stock: nextStock,
            lastEdited: admin.firestore.FieldValue.serverTimestamp(),
          };
          if (nextStock <= 0) {
            patch.stockStatus = "out_of_stock";
            patch.isAvailable = false;
          } else if (nextStock <= 5) {
            patch.stockStatus = "low_stock";
          } else {
            patch.stockStatus = "in_stock";
          }

          tx.update(snap.ref, patch);

          const price = num(data.price);
          const slashed = num(data.discountPrice ?? data.slashedPrice);
          const isVeg =
            str(data.category).toLowerCase().includes("vegetable") ||
            str(data.subcategory).toLowerCase().includes("vegetable");
          const grams = line.selectedWeightInGrams ?? 1000;
          const unitPrice = isVeg ? (price * grams) / 1000 : price;
          const unitSlashed = isVeg ? (slashed * grams) / 1000 : slashed;

          orderProducts.push({
            productId: snap.id,
            name: str(data.name),
            image: str(data.image),
            description: str(data.description),
            category: str(data.category),
            unit: str(data.unit),
            price: unitPrice,
            slashedPrice: unitSlashed,
            itemCount: line.itemCount,
            vendor_id: str(data.vendor_id),
          });
        }

        const address = (req.data?.address ?? {}) as Record<string, unknown>;
        const bill = (req.data?.bill ?? {}) as Record<string, unknown>;
        const paymentMethod = str(req.data?.paymentMethod) || "cod";
        const paymentRef = str(req.data?.paymentRef);
        const isPaid = paymentMethod !== "cod" && paymentRef.length > 0;

        const legacyOrder = {
          lat: num(req.data?.lat),
          lng: num(req.data?.lng),
          currentLocation: str(req.data?.currentLocation),
          uuid: uid,
          id: orderRef.id,
          products: orderProducts,
          created_date: new Date().toISOString(),
          address: `${str(address.address)} ${str(address.area)}`.trim(),
          customer_name: str(address.name),
          phone: str(address.mobile),
          isPaid,
          order_status: "Pending",
          deliveryBoyId: "",
          isDelivered: false,
          isCancelled: false,
          confrimTime: "",
          driverShop: "",
          onTheWayTime: "",
          pickedTime: "",
          orderDeliveredTime: "",
          delivery_type: "standard",
          deliveryCharge: num(bill.deliveryFee),
          is_rated: false,
          star: 0,
        };

        tx.set(orderRef, {
          ...legacyOrder,
          status: "pending",
          paymentMethod,
          paymentStatus: isPaid ? "paid" : "pending",
          ...(paymentRef ? { paymentRef } : {}),
          delivery_instructions: str(req.data?.delivery_instructions),
          ...(req.data?.delivery_slot
            ? { delivery_slot: req.data.delivery_slot }
            : {}),
          bill,
          ...(req.data?.coupon ? { coupon: req.data.coupon } : {}),
          address_snapshot: address,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      console.error("placeOrderCallable", e);
      throw new HttpsError("internal", "Could not place order");
    }

    return { orderId: orderRef.id };
  }
);
