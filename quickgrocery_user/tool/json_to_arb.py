#!/usr/bin/env python3
"""Convert easy_localization JSON files to Flutter gen_l10n ARB files."""

import json
import re
import sys
from pathlib import Path

# Reserved / awkward Dart identifiers → safe ARB keys.
KEY_RENAMES = {
    "continue": "continueAction",
}

PLACEHOLDER_KEYS = {
    "resend_otp_in": [("seconds", "int")],
    "sorry_minimum_order": [("amount", "String")],
    "items_in_category": [("count", "int")],
    "support_number": [("number", "String")],
    "coupons_available": [("count", "int")],
    "coupon_copied": [("code", "String")],
    "coupon_applied_checkout": [("code", "String")],
    "onlyNItemsAvailable": [("count", "int")],
}


def convert_value(value: str) -> str:
    return value.replace("\n", "\\n")


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    translations = root / "assets" / "translations"
    out_dir = root / "lib" / "l10n"
    out_dir.mkdir(parents=True, exist_ok=True)

    mapping = {
        "en-US.json": "app_en.arb",
        "hi-IN.json": "app_hi.arb",
        "te-IN.json": "app_te.arb",
        "ur-IN.json": "app_ur.arb",
    }

    en_path = translations / "en-US.json"
    en_data = json.loads(en_path.read_text(encoding="utf-8"))

    # Extra keys for hardcoded strings not yet in JSON.
    extras = {
        "editAddress": "Edit address",
        "wishlistEmpty": "No items in wishlist",
        "logoutTitle": "Logout",
        "logoutConfirm": "Are you sure you want to logout?",
        "errorPartCouldNotBeShown": "This part of the app couldn't be shown.",
        "errorGoBackOrRestart": "Go back or restart the app.",
        "outOfStock": "OUT OF STOCK",
        "itemLabel": "{count, plural, =1{1 Item} other{{count} Items}}",
        "billDetails": "Bill details",
        "toPay": "To pay",
        "itemTotalLabel": "Item total",
        "deliveryFeeLabel": "Delivery fee",
        "freeUpper": "FREE",
        "noOrdersFound": "No Orders Found!",
        "totalItemsLabel": "Total Items:",
        "statusLabel": "Status:",
        "cancelOrderTitle": "Cancel order?",
        "keepOrder": "Keep order",
        "callDeliveryPartner": "Call delivery partner",
        "signInToFavorite": "Sign in required to favorite items.",
        "writeReview": "Write review",
        "deleteReviewTitle": "Delete review?",
        "ratingsAndReviews": "Ratings & Reviews",
        "customerPhotos": "Customer photos",
        "couponsAndOffers": "Coupons & Offers",
        "couponAppliedSuccess": "Coupon applied successfully",
        "remove": "Remove",
        "chooseDeliverySlot": "Choose a delivery slot",
        "someItemsOutOfStock": "Some items are out of stock",
        "storeClosed": "Store is closed",
        "cartEmptyMessage": "Your cart is empty",
        "deliveryUnavailable": "Delivery unavailable for your location",
        "maxOrderLimitReached": "Maximum order limit reached",
        "onlyNItemsAvailable": "Only {count} items available",
        "updateRequiredTitle": "Update Required",
        "updateRequiredBody": "A new version of the app is available. Please update to continue.",
        "updateNow": "Update Now",
        "enableLocationTitle": "Enable Location",
        "leaveReviewTitle": "Leave a Review",
        "orderCancelledByYou": "Order Cancelled by you!",
        "nameRequired": "Name is required",
        "enterValidMobile": "Enter valid mobile number",
        "pleaseEnterName": "Please enter name",
        "pleaseSelectGender": "Please select gender",
        "copyCode": "Copy Code",
        "shareInvite": "Share Invite",
        "referralCodeCopied": "Referral code copied",
        "goBack": "Go Back",
        "addDeliveryTip": "Add delivery tip",
        "customTip": "Custom tip",
        "addExtraTip": "Add extra tip",
        "rateDelivery": "Rate Delivery",
        "submit": "Submit",
        "retryBanners": "Retry banners",
        "qtyLabel": "Qty:",
        "pcs": "pcs",
        "mrpTotal": "MRP Total",
        "productDiscount": "Product Discount",
        "taxLabel": "Tax",
        "thankYou": "Thank you!",
        "quickGrocery": "QUICK GROCERY",
        "totalUpper": "TOTAL",
        "cashOnDeliveryLabel": "Cash on Delivery",
        "onlinePaymentLabel": "Online Payment",
        "upiLabel": "UPI",
        "pendingStatus": "Pending",
        "joinedStatus": "Joined",
        "rewardGranted": "Reward Granted",
        "failedToLoadCart": "Failed to load your cart",
        "cartSyncFailed": "Cart sync failed",
        "cartClearedLocally": "Cart cleared locally",
        "cartUnavailable": "Cart unavailable",
        "emailRequired": "Please enter an email address.",
        "emailInvalid": "Please enter a valid email address.",
        "passwordRequired": "Password is required",
        "passwordMinLength": "At least 8 characters required",
        "phoneRequired": "Phone number is required",
        "addressRequired": "Address is required",
        "areaRequired": "Area or road name is required",
        "itemOutOfStock": "This item is out of stock",
        "onlyOneItemAvailable": "Only 1 item available",
        "onlyNItemsAvailable": "Only {count} items available",
        "thisItemOutOfStock": "This item is out of stock",
    }
    en_data.update(extras)

    for json_name, arb_name in mapping.items():
        path = translations / json_name
        if not path.exists():
            print(f"skip missing {path}", file=sys.stderr)
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        if json_name == "en-US.json":
            data = en_data
        else:
            for k, v in extras.items():
                if k not in data and k in en_data:
                    data[k] = en_data[k]

        arb: dict = {"@@locale": arb_name.replace("app_", "").replace(".arb", "")}
        if arb_name == "app_en.arb":
            arb["@@locale"] = "en"

        meta: dict = {}
        for key, value in sorted(data.items()):
            arb_key = KEY_RENAMES.get(key, key)
            if not isinstance(value, str):
                continue
            arb[arb_key] = convert_value(value)
            if key in PLACEHOLDER_KEYS and arb_name == "app_en.arb":
                placeholders = {}
                for ph_name, ph_type in PLACEHOLDER_KEYS[key]:
                    placeholders[ph_name] = {"type": ph_type}
                meta[f"@{arb_key}"] = {"placeholders": placeholders}

        arb.update(meta)
        out_path = out_dir / arb_name
        out_path.write_text(
            json.dumps(arb, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"wrote {out_path} ({len(data)} keys)")


if __name__ == "__main__":
    main()
