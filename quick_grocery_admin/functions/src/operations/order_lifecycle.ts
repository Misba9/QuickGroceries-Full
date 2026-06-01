/**
 * Canonical quick-commerce order lifecycle (Zepto / Blinkit model).
 * Both `status` (snake_case id) and `order_status` (legacy display) are kept in sync.
 */
export const OrderStatus = {
  PENDING: "pending",
  VENDOR_ACCEPTED: "vendor_accepted",
  VENDOR_REJECTED: "vendor_rejected",
  ACCEPTED: "accepted",
  PACKING: "packing",
  READY_FOR_PICKUP: "ready_for_pickup",
  RIDER_ASSIGNED: "rider_assigned",
  RIDER_ACCEPTED: "rider_accepted",
  REACHED_STORE: "reached_store",
  HEADING_TO_STORE: "heading_to_store",
  PICKED_UP: "picked_up",
  OUT_FOR_DELIVERY: "out_for_delivery",
  DELIVERED: "delivered",
  CANCELLED: "cancelled",
  CANCELLED_BY_CUSTOMER: "cancelled_by_customer",
  CANCELLED_BY_VENDOR: "cancelled_by_vendor",
  CANCELLED_BY_RIDER: "cancelled_by_rider",
} as const;

export type OrderStatusId = (typeof OrderStatus)[keyof typeof OrderStatus];

/** Legacy display string written to `order_status`. */
export function statusToLegacy(status: string): string {
  switch (status.toLowerCase()) {
    case OrderStatus.PENDING:
      return "Pending";
    case OrderStatus.VENDOR_ACCEPTED:
      return "Vendor Accepted";
    case OrderStatus.VENDOR_REJECTED:
      return "Vendor Rejected";
    case OrderStatus.ACCEPTED:
      return "Order Confirm";
    case OrderStatus.PACKING:
      return "Preparing";
    case OrderStatus.READY_FOR_PICKUP:
      return "Ready for Pickup";
    case OrderStatus.RIDER_ASSIGNED:
      return "Rider Assigned";
    case OrderStatus.RIDER_ACCEPTED:
      return "Rider Accepted";
    case OrderStatus.REACHED_STORE:
      return "Reached Store";
    case OrderStatus.HEADING_TO_STORE:
      return "Going to Shop";
    case OrderStatus.PICKED_UP:
      return "Order Picked";
    case OrderStatus.OUT_FOR_DELIVERY:
      return "On the Way";
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

/** Resolve canonical `status` from legacy `order_status` or modern field. */
export function resolveStatus(data: Record<string, unknown>): string {
  const modern = str(data.status);
  if (modern && isKnownStatus(modern)) return modern;

  if (data.isCancelled === true) {
    return cancellationStatusFromMeta(data);
  }
  if (data.isDelivered === true) return OrderStatus.DELIVERED;

  const legacy = str(data.order_status).toLowerCase();
  if (legacy.includes("cancel")) return OrderStatus.CANCELLED;
  if (legacy.includes("deliver")) return OrderStatus.DELIVERED;
  if (legacy.includes("way")) return OrderStatus.OUT_FOR_DELIVERY;
  if (legacy.includes("picked")) return OrderStatus.PICKED_UP;
  if (legacy.includes("reached") && legacy.includes("store")) return OrderStatus.REACHED_STORE;
  if (legacy.includes("going") || legacy.includes("shop")) return OrderStatus.HEADING_TO_STORE;
  if (legacy.includes("rider") && legacy.includes("accept")) return OrderStatus.RIDER_ACCEPTED;
  if (legacy.includes("rider") && legacy.includes("assign")) return OrderStatus.RIDER_ASSIGNED;
  if (legacy.includes("ready")) return OrderStatus.READY_FOR_PICKUP;
  if (legacy.includes("reject")) return OrderStatus.VENDOR_REJECTED;
  if (legacy.includes("vendor") && legacy.includes("accept")) return OrderStatus.VENDOR_ACCEPTED;
  if (legacy.includes("prepar") || legacy.includes("pack")) return OrderStatus.PACKING;
  if (legacy.includes("confirm") || legacy.includes("accept")) {
    return OrderStatus.VENDOR_ACCEPTED;
  }
  if (legacy.includes("pending") || legacy.includes("waiting")) return OrderStatus.PENDING;
  return OrderStatus.PENDING;
}

export function cancellationStatusFromMeta(data: Record<string, unknown>): string {
  const modern = str(data.status);
  if (isCancellationStatus(modern)) return modern;
  const by = str(data.cancelledBy).toLowerCase();
  if (by === "customer") return OrderStatus.CANCELLED_BY_CUSTOMER;
  if (by === "vendor") return OrderStatus.CANCELLED_BY_VENDOR;
  if (by === "rider" || by === "driver") return OrderStatus.CANCELLED_BY_RIDER;
  if (by === "admin") return OrderStatus.CANCELLED;
  return OrderStatus.CANCELLED;
}

export function isCancellationStatus(status: string): boolean {
  return (
    status === OrderStatus.CANCELLED ||
    status === OrderStatus.CANCELLED_BY_CUSTOMER ||
    status === OrderStatus.CANCELLED_BY_VENDOR ||
    status === OrderStatus.CANCELLED_BY_RIDER ||
    status === OrderStatus.VENDOR_REJECTED
  );
}

export function isBeforePickup(status: string): boolean {
  return (
    status !== OrderStatus.PICKED_UP &&
    status !== OrderStatus.OUT_FOR_DELIVERY &&
    status !== OrderStatus.DELIVERED &&
    !isCancellationStatus(status)
  );
}

function isKnownStatus(s: string): boolean {
  return Object.values(OrderStatus).includes(s as OrderStatusId);
}

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

export function isActiveStatus(status: string): boolean {
  return status !== OrderStatus.DELIVERED && !isCancellationStatus(status);
}

export function isPendingVendorAction(status: string): boolean {
  return status === OrderStatus.PENDING;
}

export function isVendorRejected(status: string): boolean {
  return status === OrderStatus.VENDOR_REJECTED;
}

export function isReadyForDispatch(status: string): boolean {
  return status === OrderStatus.READY_FOR_PICKUP;
}

export function needsRiderAcceptance(status: string): boolean {
  return status === OrderStatus.RIDER_ASSIGNED;
}

export function isInTransit(status: string): boolean {
  return (
    status === OrderStatus.REACHED_STORE ||
    status === OrderStatus.HEADING_TO_STORE ||
    status === OrderStatus.PICKED_UP ||
    status === OrderStatus.OUT_FOR_DELIVERY
  );
}

export function isPickupPhase(status: string): boolean {
  return (
    status === OrderStatus.RIDER_ACCEPTED ||
    status === OrderStatus.REACHED_STORE ||
    status === OrderStatus.HEADING_TO_STORE
  );
}

export function isRiderAccepted(status: string): boolean {
  return status === OrderStatus.RIDER_ACCEPTED;
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
