/**
 * Env `BOOTSTRAP_ADMIN_EMAILS` = comma-separated emails allowed as full admins
 * even without a Firestore `admins` row. Default keeps primary owner unblocked.
 */
export function isBootstrapPanelEmail(email: string | undefined): boolean {
  if (!email) return false;
  const raw =
    process.env.BOOTSTRAP_ADMIN_EMAILS ||
    "admin@quickgroceries.in";
  const set = new Set(
    raw
      .split(",")
      .map((s) => s.trim().toLowerCase())
      .filter(Boolean)
  );
  return set.has(email.trim().toLowerCase());
}
