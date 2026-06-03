/**
 * Simplified quick-commerce order lifecycle (4 customer-visible steps).
 * Both `status` (snake_case id) and `order_status` (legacy display) stay in sync.
 */
export const OrderStatus = {
  ORDER_PLACED: "order_placed",
  DELIVERY_ASSIGNED: "delivery_assigned",
  OUT_FOR_DELIVERY: "out_for_delivery",
  DELIVERED: "delivered",
  CANCELLED: "cancelled",
  CANCELLED_BY_CUSTOMER: "cancelled_by_customer",
  CANCELLED_BY_VENDOR: "cancelled_by_vendor",
  CANCELLED_BY_RIDER: "cancelled_by_rider",
} as const;

export type OrderStatusId = (typeof OrderStatus)[keyof typeof OrderStatus];

const CANONICAL = new Set<string>(Object.values(OrderStatus));

/** Map legacy / granular statuses to the simplified model when reading Firestore. */
export function normalizeStatus(status: string): string {
  const s = str(status).toLowerCase();
  if (!s) return OrderStatus.ORDER_PLACED;

  if (CANONICAL.has(s)) return s;

  if (
    s === "cancelled_by_customer" ||
    s === "cancelled_by_vendor" ||
    s === "cancelled_by_rider" ||
    s === "cancelled" ||
    s === "vendor_rejected"
  ) {
    return cancellationStatusFromId(s);
  }

  if (s === "delivered") return OrderStatus.DELIVERED;
  if (s === "out_for_delivery" || s === "picked_up") {
    return OrderStatus.OUT_FOR_DELIVERY;
  }
  if (
    s === "delivery_assigned" ||
    s === "rider_assigned" ||
    s === "rider_accepted" ||
    s === "reached_store" ||
    s === "heading_to_store"
  ) {
    return OrderStatus.DELIVERY_ASSIGNED;
  }

  return OrderStatus.ORDER_PLACED;
}

/** Legacy display string written to `order_status`. */
export function statusToLegacy(status: string): string {
  switch (normalizeStatus(status)) {
    case OrderStatus.ORDER_PLACED:
      return "Order Placed";
    case OrderStatus.DELIVERY_ASSIGNED:
      return "Delivery Partner Assigned";
    case OrderStatus.OUT_FOR_DELIVERY:
      return "Out For Delivery";
    case OrderStatus.DELIVERED:
      return "Order Delivered";
    case OrderStatus.CANCELLED_BY_CUSTOMER:
      return "Cancelled by Customer";
    case OrderStatus.CANCELLED_BY_VENDOR:
      return "Cancelled by Vendor";
    case OrderStatus.CANCELLED_BY_RIDER:
      return "Cancelled by Rider";
    case OrderStatus.CANCELLED:
      return "cancelled";
    default:
      return status;
  }
}

function cancellationStatusFromId(s: string): string {
  if (s === OrderStatus.CANCELLED_BY_CUSTOMER) return s;
  if (s === OrderStatus.CANCELLED_BY_VENDOR || s === "vendor_rejected") {
    return OrderStatus.CANCELLED_BY_VENDOR;
  }
  if (s === OrderStatus.CANCELLED_BY_RIDER) return s;
  return OrderStatus.CANCELLED;
}

/** Resolve canonical `status` from legacy `order_status` or modern field. */
export function resolveStatus(data: Record<string, unknown>): string {
  if (data.isCancelled === true) {
    return cancellationStatusFromMeta(data);
  }
  if (data.isDelivered === true) return OrderStatus.DELIVERED;

  const modern = str(data.status);
  if (modern) return normalizeStatus(modern);

  const legacy = str(data.order_status).toLowerCase();
  if (legacy.includes("cancel")) return OrderStatus.CANCELLED;
  if (legacy.includes("deliver")) return OrderStatus.DELIVERED;
  if (legacy.includes("way") || legacy.includes("out for")) {
    return OrderStatus.OUT_FOR_DELIVERY;
  }
  if (legacy.includes("picked")) return OrderStatus.OUT_FOR_DELIVERY;
  if (legacy.includes("rider") || legacy.includes("assign") || legacy.includes("delivery partner")) {
    return OrderStatus.DELIVERY_ASSIGNED;
  }
  if (legacy.includes("reject")) return OrderStatus.CANCELLED_BY_VENDOR;
  if (legacy.includes("prepar") || legacy.includes("pack") || legacy.includes("confirm") || legacy.includes("accept")) {
    return OrderStatus.ORDER_PLACED;
  }
  if (legacy.includes("pending") || legacy.includes("waiting") || legacy.includes("placed")) {
    return OrderStatus.ORDER_PLACED;
  }
  return OrderStatus.ORDER_PLACED;
}

export function cancellationStatusFromMeta(data: Record<string, unknown>): string {
  const modern = str(data.status);
  if (modern) return normalizeStatus(modern);
  const by = str(data.cancelledBy).toLowerCase();
  if (by === "customer") return OrderStatus.CANCELLED_BY_CUSTOMER;
  if (by === "vendor") return OrderStatus.CANCELLED_BY_VENDOR;
  if (by === "rider" || by === "driver") return OrderStatus.CANCELLED_BY_RIDER;
  if (by === "admin") return OrderStatus.CANCELLED;
  return OrderStatus.CANCELLED;
}

export function isCancellationStatus(status: string): boolean {
  const s = normalizeStatus(status);
  return (
    s === OrderStatus.CANCELLED ||
    s === OrderStatus.CANCELLED_BY_CUSTOMER ||
    s === OrderStatus.CANCELLED_BY_VENDOR ||
    s === OrderStatus.CANCELLED_BY_RIDER
  );
}

export function isBeforePickup(status: string): boolean {
  const s = normalizeStatus(status);
  return s === OrderStatus.ORDER_PLACED || s === OrderStatus.DELIVERY_ASSIGNED;
}

export function isActiveStatus(status: string): boolean {
  return normalizeStatus(status) !== OrderStatus.DELIVERED && !isCancellationStatus(status);
}

export function isPendingVendorAction(status: string): boolean {
  return normalizeStatus(status) === OrderStatus.ORDER_PLACED;
}

export function isVendorRejected(status: string): boolean {
  return normalizeStatus(status) === OrderStatus.CANCELLED_BY_VENDOR;
}

/** @deprecated Use [isPendingVendorAction] — vendor assigns rider from order_placed. */
export function isReadyForDispatch(status: string): boolean {
  return normalizeStatus(status) === OrderStatus.ORDER_PLACED;
}

export function needsRiderAcceptance(status: string): boolean {
  return normalizeStatus(status) === OrderStatus.DELIVERY_ASSIGNED;
}

export function isInTransit(status: string): boolean {
  return normalizeStatus(status) === OrderStatus.OUT_FOR_DELIVERY;
}

export function isPickupPhase(status: string): boolean {
  return false;
}

export function isRiderAccepted(status: string): boolean {
  const s = normalizeStatus(status);
  return s === OrderStatus.DELIVERY_ASSIGNED || s === OrderStatus.OUT_FOR_DELIVERY;
}

export function isLiveTracking(status: string): boolean {
  return normalizeStatus(status) === OrderStatus.OUT_FOR_DELIVERY;
}

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

/** Fields to mirror into vendor_orders on every order update. */
export function vendorMirrorPatch(data: Record<string, unknown>): Record<string, unknown> {
  const status = resolveStatus(data);
  return {
    status,
    order_status: statusToLegacy(status),
    deliveryBoyId: str(data.deliveryBoyId),
    isDelivered: Boolean(data.isDelivered),
    isCancelled: Boolean(data.isCancelled),
    updatedAt: data.updatedAt,
  };
}
