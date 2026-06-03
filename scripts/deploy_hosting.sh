#!/usr/bin/env bash
# Build and deploy all Flutter web apps to Firebase Hosting (project: quikgroceries).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Building admin web..."
(cd quick_grocery_admin && flutter pub get && flutter build web --release)

echo "==> Building user web..."
(cd quickgrocery_user && flutter pub get && flutter build web --release)

echo "==> Building vendor web..."
(cd quickgrocery_vendor && flutter pub get && flutter build web --release)

echo "==> Building delivery web..."
(cd quick_grocery_delivery && flutter pub get && flutter build web --release)

echo "==> Deploying Firebase Hosting (admin, user, vendor, delivery)..."
firebase deploy --only hosting:admin,hosting:user,hosting:vendor,hosting:delivery --project quikgroceries

echo ""
echo "Deployed:"
echo "  Admin:    https://quikgroceries.web.app"
echo "  User:     https://quikgroceries-user.web.app"
echo "  Vendor:   https://quikgroceries-vendor.web.app"
echo "  Delivery: https://quikgroceries-delivery.web.app"
