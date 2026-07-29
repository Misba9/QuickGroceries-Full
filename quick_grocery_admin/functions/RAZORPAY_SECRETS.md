# Razorpay server secrets (Cloud Functions)

Set these as Firebase Secret Manager secrets before deploying payment functions:

```bash
firebase functions:secrets:set RAZORPAY_KEY_ID
firebase functions:secrets:set RAZORPAY_KEY_SECRET
```

Then deploy:

```bash
cd quick_grocery_admin/functions
npm run build
firebase deploy --only functions:createRazorpayOrderCallable,functions:placeOrderCallable,functions:confirmRazorpayTipPaymentCallable
```

- `RAZORPAY_KEY_ID` — public key id (`rzp_live_…` / `rzp_test_…`)
- `RAZORPAY_KEY_SECRET` — **Key Secret only** (never the key id, never commit to git)

The Flutter app never stores the secret.
