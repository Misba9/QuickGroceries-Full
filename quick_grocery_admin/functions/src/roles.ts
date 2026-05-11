/**
 * Custom-claim helpers for admin / SMS / notifications.
 */
export function hasSmsPanelAccess(
  c: Record<string, unknown> | undefined | null
): boolean {
  if (!c) return false;
  if (c.superAdmin === true) return true;
  if (c.admin === true) return true;
  if (c.smsAdmin === true) return true;
  if (c.notificationsAdmin === true) return true;
  const r = c.role;
  if (r === "admin" || r === "superAdmin" || r === "smsAdmin") return true;
  return false;
}

/** Can assign claims to other users (not bootstrap). */
export function hasElevatedAdmin(
  c: Record<string, unknown> | undefined | null
): boolean {
  if (!c) return false;
  if (c.superAdmin === true) return true;
  if (c.admin === true) return true;
  const r = c.role;
  if (r === "superAdmin" || r === "admin") return true;
  return false;
}
