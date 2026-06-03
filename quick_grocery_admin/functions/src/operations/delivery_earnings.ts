import { num } from "./ops_notify";

/** Tip amount stored on the order (100% to delivery partner). */
export function orderTipAmount(data: Record<string, unknown>): number {
  const direct = num(data.tipAmount);
  if (direct > 0) return direct;
  const bill = data.bill as Record<string, unknown> | undefined;
  return num(bill?.deliveryPartnerTip ?? bill?.tipAmount);
}

/** Rider commission for a completed delivery (delivery fee or % of subtotal). */
export function orderDeliveryFee(data: Record<string, unknown>): number {
  const deliveryCharge = num(data.deliveryCharge ?? data.delivery_charge);
  if (deliveryCharge > 0) return deliveryCharge;

  const bill = data.bill as Record<string, unknown> | undefined;
  if (bill?.deliveryFee != null) return num(bill.deliveryFee);

  const products = (data.products as unknown[]) || [];
  let subtotal = 0;
  for (const raw of products) {
    const p = raw as Record<string, unknown>;
    subtotal +=
      num(p.price) * num(p.itemCount ?? p.quantity ?? p.item_count ?? 1);
  }
  return subtotal * 0.05;
}

/** Delivery fee + customer tip for rider earnings display. */
export function orderEarning(data: Record<string, unknown>): number {
  return orderDeliveryFee(data) + orderTipAmount(data);
}
