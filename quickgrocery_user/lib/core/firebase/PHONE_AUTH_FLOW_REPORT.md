# Phone Auth flow improvements — report

Date: 2026-07-31  
App: `quickgrocery_user` (Flutter — Android + iOS shared Dart code)  
Scope: Authentication UX / reliability only. No Firebase Console / iOS native / UI redesign.

## Files changed

### New
| File | Role |
|------|------|
| `lib/core/firebase/phone_auth_user_messages.dart` | Friendly title + message for all Auth error codes |
| `lib/core/firebase/phone_auth_request_guard.dart` | OTP throttle, 60s cooldown, 3min too-many-requests cooldown, SharedPreferences persistence |
| `lib/core/firebase/phone_auth_network.dart` | Connectivity check before OTP send / verify |
| `lib/core/firebase/phone_auth_debug_test_numbers.dart` | Debug-only test-number helpers (no-op in release) |

### Updated
| File | Role |
|------|------|
| `lib/view/auth/services/auth_provider.dart` | Full flow: validation, network, cooldown, logging, friendly errors, duplicate-tap guard |
| `lib/view/auth/screens/login_screen.dart` | Title/body error banner, Retry, Continue cooldown label, lifecycle restore |
| `lib/view/auth/screens/otp_screen.dart` | Shared 60s cooldown, watch AuthService, lifecycle restore |
| `lib/view/auth/widgets/primary_button.dart` | Disable when `onTap == null` (cooldown) |

## Firebase errors handled

| Code | Title (user-facing) |
|------|---------------------|
| `too-many-requests` | Too Many Attempts |
| `quota-exceeded` | SMS Limit Reached |
| `invalid-phone-number` | Invalid Phone Number |
| `captcha-check-failed` | Verification Failed |
| `network-request-failed` | No Internet |
| `session-expired` | Code Expired |
| `invalid-verification-code` | Incorrect OTP |
| `invalid-verification-id` | Session Expired |
| `credential-already-in-use` | Number Already Linked |
| `app-not-authorized` | App Not Authorized |
| `operation-not-allowed` | Phone Login Disabled |
| `missing-client-identifier` | Phone Login Unavailable |
| `invalid-app-credential` / `invalid-cert-hash` | App Verification Failed |
| `user-disabled` | Account Disabled |
| `internal-error` | Something Went Wrong |
| *(default)* | Sign-In Failed |

Also local/synthetic: invalid local phone, no internet, cooldown, timeout, OTP session empty.

## Behavior summary

1. **Friendly errors** — banner shows title + body (e.g. Too Many Attempts).
2. **60s OTP cooldown** — Continue / Resend disabled; label `Resend OTP in N`. Persisted across recreate/resume.
3. **Too-many-requests** — 3 minute cooldown after Firebase rate limit.
4. **Duplicate taps** — ignored while `isLoading` / in-flight; button shows spinner.
5. **Network** — pre-check; Retry on network / captcha / timeout errors.
6. **Logging** — `PhoneAuth` logs: started, otp_sent, otp_verified, exception code/message.
7. **Test numbers** — debug-only helper map; release never special-cases.
8. **Platform** — Dart-only; Android & iOS share the same flow. No `ios/` edits.

## How to verify

1. Hot restart / full restart the app.
2. Request OTP → Continue shows countdown 60→0.
3. Trigger rate limit → see “Too Many Attempts” + longer wait.
4. Airplane mode → “No Internet” + Retry.
5. OTP screen Resend respects the same cooldown.
