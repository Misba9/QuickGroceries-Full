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

function boolField(
  data: FirebaseFirestore.DocumentData,
  keys: string[],
  fallback: boolean,
): boolean {
  for (const key of keys) {
    if (typeof data[key] === "boolean") return data[key] as boolean;
  }
  return fallback;
}

function vendorIsActive(data: FirebaseFirestore.DocumentData): boolean {
  const status = str(data.status).toLowerCase();
  if (data.isBlocked === true || data.is_blocked === true) return false;
  if (status === "suspended" || status === "rejected") return false;
  if (status === "inactive" || status === "pending") return false;
  if (data.is_active === false || data.isActive === false) return false;
  return true;
}

function vendorIsApproved(data: FirebaseFirestore.DocumentData): boolean {
  const status = str(data.status).toLowerCase();
  if (typeof data.isApproved === "boolean") return data.isApproved;
  if (typeof data.is_approved === "boolean") return data.is_approved;
  return status !== "pending" && status !== "rejected";
}

function vendorIsOpen(data: FirebaseFirestore.DocumentData): boolean {
  if (data.isOpen === false) return false;
  if (data.is_open === false) return false;
  if (data.storeOpen === false) return false;
  if (data.store_open === false) return false;
  if (data.shopOpen === false) return false;
  return true;
}

function effectiveMax(stock: number, maxOrder: number): number {
  if (stock <= 0) return 0;
  if (maxOrder <= 0) return stock;
  return maxOrder < stock ? maxOrder : stock;
}

function deliveryInstructionsPayload(data: unknown): {
  legacy: string;
  structured: Record<string, unknown>;
} {
  const empty = {
    instructionText: "",
    leaveAtDoor: false,
    gateCode: "",
    landmark: "",
    notes: "",
  };
  if (data == null) return { legacy: "", structured: empty };
  if (typeof data === "string") {
    const text = data.trim();
    return { legacy: text, structured: { ...empty, instructionText: text } };
  }
  if (typeof data === "object") {
    const m = data as Record<string, unknown>;
    const structured = {
      instructionText: str(m.instructionText || m.text),
      leaveAtDoor: m.leaveAtDoor === true || m.leave_at_door === true,
      gateCode: str(m.gateCode || m.gate_code),
      landmark: str(m.landmark),
      notes: str(m.notes),
    };
    const parts: string[] = [];
    if (structured.gateCode) parts.push(`Gate code: ${structured.gateCode}`);
    if (structured.landmark) parts.push(`Landmark: ${structured.landmark}`);
    if (structured.leaveAtDoor) parts.push("Leave at door");
    if (structured.notes) parts.push(structured.notes);
    const legacy = structured.instructionText || parts.join(" · ");
    return { legacy, structured };
  }
  return { legacy: "", structured: empty };
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
      itemCount: Math.max(
        0,
        Math.floor(num(row.itemCount ?? row.quantity)),
      ),
      selectedWeightInGrams: num(row.selectedWeightInGrams, 1000),
    }));

    if (lines.some((l) => !l.productId || l.itemCount < 1)) {
      throw new HttpsError("invalid-argument", "Invalid cart line.");
    }

    const db = admin.firestore();
    const orderRef = db.collection("orders").doc();

    try {
      await db.runTransaction(async (tx) => {
        const systemSnap = await tx.get(
          db.collection("maintenance").doc("system"),
        );
        const legacyMaintenanceSnap = await tx.get(
          db.collection("app_config").doc("maintenance"),
        );
        const maintenance = systemSnap.exists
          ? systemSnap.data()!
          : legacyMaintenanceSnap.exists
            ? legacyMaintenanceSnap.data()!
            : {};
        const maintenanceMode = boolField(
          maintenance,
          ["maintenanceMode", "enabled", "maintenance"],
          false,
        );
        const affectedApps = maintenance.affectedApps ?? {};
        const affectsUser =
          typeof affectedApps.user === "boolean" ? affectedApps.user : true;
        const storeOpen = boolField(
          maintenance,
          ["storeOpen", "store_open", "legacyStoreActive", "isActive"],
          true,
        );
        const orderingEnabled = boolField(
          maintenance,
          ["orderingEnabled", "ordering_enabled", "allowOrders"],
          true,
        );
        const userAppEnabled = boolField(
          maintenance,
          ["userAppEnabled", "user_app_enabled"],
          true,
        );
        if (maintenanceMode && affectsUser) {
          throw new HttpsError(
            "failed-precondition",
            "Maintenance mode is active",
          );
        }
        if (!storeOpen) {
          throw new HttpsError("failed-precondition", "Store is closed");
        }
        if (!orderingEnabled) {
          throw new HttpsError(
            "failed-precondition",
            "Ordering disabled by admin",
          );
        }
        if (!userAppEnabled) {
          throw new HttpsError(
            "failed-precondition",
            "User app disabled by admin",
          );
        }

        const productSnaps = await Promise.all(
          lines.map((l) => tx.get(db.collection("products").doc(l.productId))),
        );
        const liveVendorIds = [
          ...new Set(
            productSnaps
              .map((snap) => (snap.exists ? str(snap.data()!.vendor_id) : ""))
              .filter((id) => id.length > 0),
          ),
        ];
        const vendorSnaps = await Promise.all(
          liveVendorIds.map((id) => tx.get(db.collection("vendors").doc(id))),
        );
        const vendors = new Map<string, FirebaseFirestore.DocumentData>();
        vendorSnaps.forEach((snap, idx) => {
          if (snap.exists) vendors.set(liveVendorIds[idx], snap.data()!);
        });

        const orderProducts: Record<string, unknown>[] = [];

        const rawLines = rawItems as Record<string, unknown>[];

        for (let i = 0; i < lines.length; i++) {
          const line = lines[i];
          const raw = rawLines[i] ?? {};
          const snap = productSnaps[i];
          if (!snap.exists) {
            throw new HttpsError(
              "failed-precondition",
              "Some items are no longer available",
            );
          }
          const data = snap.data()!;
          const vendorId = str(data.vendor_id);
          if (!vendorId) {
            throw new HttpsError(
              "failed-precondition",
              `Vendor is missing for ${str(data.name) || "this product"}`,
            );
          }
          const vendor = vendors.get(vendorId);
          if (!vendor) {
            throw new HttpsError("failed-precondition", "Vendor not found");
          }
          if (!vendorIsApproved(vendor)) {
            throw new HttpsError(
              "failed-precondition",
              "Vendor is not approved",
            );
          }
          if (!vendorIsActive(vendor)) {
            throw new HttpsError("failed-precondition", "Vendor is inactive");
          }
          if (!vendorIsOpen(vendor)) {
            throw new HttpsError("failed-precondition", "Vendor is closed");
          }

          const stock = num(data.stock ?? data.stock_quantity);
          const maxOrder = num(data.maxOrder ?? data.max_order_quantity);
          const minOrder = num(data.minOrder ?? data.min_order_quantity, 1);
          const available = isAvailable(data);

          if (!available || stock <= 0) {
            throw new HttpsError(
              "failed-precondition",
              "Some items are out of stock",
            );
          }

          const cap = effectiveMax(stock, maxOrder);
          if (line.itemCount > cap) {
            throw new HttpsError(
              "failed-precondition",
              "Some items exceed the maximum order limit",
            );
          }
          if (minOrder > 0 && line.itemCount < minOrder) {
            throw new HttpsError(
              "failed-precondition",
              "Some items do not meet the minimum order quantity",
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

          const rawName = str(raw.name ?? raw.productName) || str(data.name);
          const rawWeight = num(raw.weight);
          const rawUnit = str(raw.unit);
          const rawVariant = str(raw.variantName ?? raw.variant);
          let weight = rawWeight;
          let unit = rawUnit;
          let variantName = rawVariant;
          if (weight <= 0 && rawVariant) {
            const m = rawVariant.match(/^(\d+(?:\.\d+)?)\s*([a-zA-Z]+)$/);
            if (m) {
              weight = num(m[1]);
              unit = m[2];
            }
          }
          if (weight <= 0 && isVeg) {
            if (grams >= 1000) {
              weight = grams / 1000;
              unit = "kg";
              variantName = variantName || `${weight} kg`;
            } else {
              weight = grams;
              unit = "gm";
              variantName = variantName || `${grams} gm`;
            }
          }
          const itemCount = line.itemCount;
          const totalPrice = unitPrice * itemCount;

          orderProducts.push({
            productId: str(raw.productId) || snap.id,
            name: rawName,
            productName: rawName,
            image: str(raw.image) || str(data.image),
            description: str(raw.description || data.description),
            category: str(raw.category) || str(data.category),
            quantity: itemCount,
            itemCount,
            ...(weight > 0 ? { weight } : {}),
            ...(unit ? { unit } : {}),
            ...(variantName ? { variantName } : {}),
            unitPerItem: str(raw.unitPerItem || data.unitPerItem),
            packWeight: str(raw.packWeight || (weight > 0 ? String(weight) : "")),
            selectedWeightInGrams: num(
              raw.selectedWeightInGrams ?? line.selectedWeightInGrams,
              1000,
            ),
            unitType: str(raw.unitType || data.unit),
            price: unitPrice,
            unitPrice,
            totalPrice,
            slashedPrice: unitSlashed,
            vendor_id: vendorId,
            vendorId,
          });
        }

        const address = (req.data?.address ?? {}) as Record<string, unknown>;
        const bill = (req.data?.bill ?? {}) as Record<string, unknown>;
        const paymentMethod = str(req.data?.paymentMethod) || "cod";
        const paymentRef = str(req.data?.paymentRef);
        const isPaid = paymentMethod !== "cod" && paymentRef.length > 0;
        const slotRaw = req.data?.delivery_slot ?? req.data?.deliverySlot;
        const instr = deliveryInstructionsPayload(
          req.data?.delivery_instructions ?? req.data?.deliveryInstructions,
        );

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

        const orderVendorIds = [
          ...new Set(
            orderProducts
              .map((p: { vendor_id?: string }) => str(p.vendor_id))
              .filter((id: string) => id.length > 0),
          ),
        ];

        tx.set(orderRef, {
          ...legacyOrder,
          status: "pending",
          vendorIds: orderVendorIds,
          ...(orderVendorIds.length === 1
            ? { vendorId: orderVendorIds[0], vendor_id: orderVendorIds[0] }
            : {}),
          paymentMethod,
          paymentStatus: isPaid ? "paid" : "pending",
          ...(paymentRef ? { paymentRef } : {}),
          delivery_instructions: instr.legacy,
          deliveryInstructions: instr.structured,
          ...(slotRaw ? { delivery_slot: slotRaw, deliverySlot: slotRaw } : {}),
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

    const orderSnap = await orderRef.get();
    const orderData = orderSnap.data() as Record<string, unknown> | undefined;
    const vendorIds = (orderData?.vendorIds as string[] | undefined) ?? [];
    if (orderData && vendorIds.length > 0) {
      const batch = admin.firestore().batch();
      for (const vendorId of vendorIds) {
        batch.set(
          admin
            .firestore()
            .collection("vendor_orders")
            .doc(vendorId)
            .collection("orders")
            .doc(orderRef.id),
          {
            orderId: orderRef.id,
            vendorId,
            status: orderData.status,
            customer_name: orderData.customer_name,
            phone: orderData.phone,
            address: orderData.address,
            deliverySlot: orderData.deliverySlot ?? orderData.delivery_slot ?? null,
            deliveryInstructions:
              orderData.deliveryInstructions ?? orderData.delivery_instructions ?? null,
            bill: orderData.bill ?? null,
            createdAt: orderData.createdAt ?? admin.firestore.FieldValue.serverTimestamp(),
          },
        );
      }
      await batch.commit();
    }

    return { orderId: orderRef.id };
  },
);
