# Native PayOS QR Payment Design

## Goal

Replace the external PayOS checkout website with a native MiLingo bank-QR flow, make PayOS webhooks activate Premium without a browser redirect, and keep payment/profile state correct across backgrounding, process restarts, and cleared local app state.

## Scope

This change spans:

- Flutter mobile app: `C:/FPTUniversity/MILINGO/PROJECT/APP/Milingo-Mobile-App`
- ASP.NET Core backend: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend`

Only `QR Ngân hàng` remains available. Apple Pay, Visa/Mastercard, MoMo, and the unused "add payment method" control are removed until real integrations exist.

## Root Causes

1. Flutter launches PayOS `checkoutUrl` with `LaunchMode.externalApplication`, so checkout leaves the app.
2. PayOS sends the webhook signature in the JSON `signature` field, but the backend reads only an `x-payos-signature` header.
3. The backend requires webhook `data.status == PAID`, while the PayOS payment webhook contract reports success through top-level `code == "00"`, `success == true`, and transaction `data.code == "00"`; the documented transaction payload does not contain `status`.
4. The mobile deep-link parser returns only the route path and drops PayOS query parameters such as `orderCode`.
5. `userProfileProvider` and `subscriptionOverviewProvider` are not refreshed after payment reconciliation or app resume.

## Architecture

```text
Flutter creates/resumes order
          |
          v
Backend creates or reuses a 30-minute PayOS order
          |
          v
Flutter renders PayOS qrCode as native VietQR
          |
          +------------------------------+
          |                              |
          v                              v
PayOS webhook                    Flutter polling/resume check
          |                              |
          +--------------+---------------+
                         v
             Backend verifies ownership/status
                         |
                         v
              Firestore Premium is updated
                         |
                         v
        Flutter refreshes profile/subscription state
```

The backend is the source of truth. No payment recovery depends solely on SharedPreferences, route extras, or a browser return.

## Backend Design

### Create-order contract

The authenticated mobile request sends only:

```json
{ "planId": "pro" }
```

PayOS return/cancel URLs and credentials remain backend configuration. Flutter no longer contains PayOS client IDs, API keys, PayOS API base URLs, or redirect URL construction.

The authenticated response contains the native-payment data returned by PayOS:

```json
{
  "bin": "970422",
  "accountNumber": "113366668888",
  "accountName": "MERCHANT NAME",
  "amount": 139000,
  "description": "Milingo pro",
  "orderCode": 123456789012,
  "paymentLinkId": "...",
  "qrCode": "000201...",
  "status": "PENDING",
  "expiresAt": "2026-07-15T10:30:00Z"
}
```

`checkoutUrl` may remain stored server-side for transaction history/backward compatibility, but it is not launched by the app.

### Expiry and idempotency

- New orders set PayOS `expiredAt` to 30 minutes after creation and persist the same timestamp in Firestore.
- Before creating an order, the backend loads the authenticated user's pending PayOS orders and reconciles them against PayOS.
- If the same plan already has a valid `PENDING` order, return its stored QR/payment data. The identical QR reappears.
- If the pending order is paid, grant Premium and return paid state instead of creating another order.
- If it is expired or cancelled, mark it accordingly and create a new order.
- If the user changes plan, cancel valid pending orders for other plans through PayOS, mark them `CANCELLED`, then create the new plan order.
- Legacy pending records without recoverable QR fields are reconciled, then replaced only when still unpaid.

### Pending-order recovery

Add an authenticated endpoint that returns the current user's latest recoverable pending order or `null`. This makes recovery work after Flutter cache/preferences are lost, after a process restart, or after reinstall followed by sign-in.

The endpoint never returns another user's order. Verification/cancellation methods receive the authenticated UID and reject ownership mismatches.

### Webhook correction

The webhook DTO includes top-level `success` and `signature`, plus the documented transaction fields. Verification uses the JSON body signature, with header fallback only for backward compatibility.

A payment is accepted only when all conditions hold:

- HMAC signature is valid over the complete PayOS `data` payload.
- Top-level `code` equals `00`.
- Top-level `success` is true.
- Transaction `data.code` equals `00`.
- The order exists.
- The received amount exactly equals the stored amount.

The handler then calls the existing Premium grant path and marks the order `PAID`. Invalid signatures or malformed payloads return a non-2xx response; valid duplicate webhooks are idempotent and return success.

### Reconciliation response

The authenticated verify/status operation returns a typed result rather than encoding an unpaid order as an API-envelope error:

```json
{
  "orderCode": 123456789012,
  "status": "PAID",
  "isPaid": true,
  "expiresAt": "2026-07-15T10:30:00Z"
}
```

It queries PayOS when the stored status is pending, updates Firestore, and grants Premium when PayOS reports `PAID`.

## Flutter Design

### Payment selection

The payment-method screen shows the chosen plan and a single `QR Ngân hàng` method. Confirming calls the backend and navigates to a native QR screen; it never calls `launchUrl`.

### Native QR screen

The screen is vertically scrollable and shows:

- A locally rendered QR image from PayOS `qrCode`.
- Amount.
- Transfer description.
- Bank BIN/identifier.
- Account name.
- Account number.
- Copy actions for amount, description, and account number.
- `Lưu mã QR` to save a PNG to the device gallery.
- Waiting, paid, expired, cancelled, and recoverable-error states.
- A manual `Kiểm tra lại` action when automatic checking encounters a transient error.

The QR image is produced on-device. Saving captures only the QR/payment card, not the whole screen. Flutter package versions and platform permission behavior must be verified against current official package documentation before dependencies are added.

### Polling and lifecycle

- Poll every five seconds only while the QR screen is mounted and the app is active.
- Pause polling in the background.
- Reconcile immediately when the app resumes.
- Stop permanently for `PAID`, `CANCELLED`, or `EXPIRED`.
- Dispose timers/subscriptions through an `autoDispose` Riverpod screen provider.
- A separate authentication-scoped reconciliation provider checks the backend on authenticated startup/resume, so recovery does not depend on local pending-order storage.

No automatic navigation occurs merely because a pending order exists. Re-entering payment for the same plan restores the same QR. A paid reconciliation refreshes state immediately.

### Provider refresh

When payment becomes paid through webhook reconciliation or direct verification:

- Refresh `userProfileProvider` so `isPremium` changes on Profile.
- Invalidate `subscriptionOverviewProvider` so plan/expiry details refetch.
- Refresh any Premium status state used by payment screens.
- Clear pending payment UI state.

The root app lifecycle forwards `resumed` events to the reconciliation provider. Provider logic remains outside UI widgets and watches authentication state to prevent cross-account leakage.

### Legacy return links

External checkout is removed from the active flow, but existing return links remain backward compatible. The deep-link parser preserves `orderCode` and other query parameters and triggers the same reconciliation/provider refresh path.

## Error Handling

- Order creation failure: remain on payment selection and show the backend's user-safe message.
- Invalid/missing QR fields: do not show a broken QR; offer retry and record a diagnostic log without secrets.
- Poll timeout/network error: keep the QR visible, pause aggressive retries, and provide manual retry.
- HTTP 429 from PayOS: apply a longer retry interval; never create a replacement order solely because status polling was throttled.
- Save-to-gallery failure or denied permission: keep payment active and show instructions; payment state is unaffected.
- Copy action failure: show a non-blocking message.
- Expired/cancelled order: disable payment checking and offer creation of a fresh order.
- Duplicate webhook/poll success: Premium grant and order updates are idempotent.

## Security

- PayOS credentials and checksum key remain backend-only.
- Mobile sends no amount; the backend derives amount/duration from its plan configuration.
- Every authenticated order read, verify, resume, or cancel operation enforces UID ownership.
- Webhook HMAC verification occurs before any order or Premium mutation.
- Amount equality is checked before Premium is granted.
- Logs exclude credentials, full QR payloads, Firebase tokens, and account-sensitive content.

## Testing

### Backend

Add a dedicated .NET test project and test before implementation:

- Create-response parsing includes every native QR field.
- Same user + same plan + valid pending order returns the same QR/order code.
- Expired/cancelled orders create a replacement.
- Selecting another tier cancels the old pending order before creation.
- Body-signature webhook with documented PayOS fields is accepted.
- Missing/invalid signature is rejected.
- Successful webhook grants Premium and marks `PAID`.
- Amount mismatch never grants Premium.
- Duplicate webhook is idempotent.
- Verify/pending endpoints reject cross-user order access.

### Flutter

Add model, provider, and widget tests before implementation:

- PayOS native order JSON parses all required fields.
- Payment confirmation no longer launches an external URL.
- Only bank QR is displayed.
- QR screen shows amount/account/description and copy/save actions.
- Polling stops after paid/expired/cancelled.
- Resume triggers immediate reconciliation.
- Paid state refreshes profile and subscription providers.
- Existing pending order is restored from backend without local preferences.
- Deep links preserve `orderCode` for backward compatibility.

Run Flutter formatting, analysis, and the full Flutter test suite, plus backend build and test commands before completion.

## Non-goals

- Apple Pay, Visa/Mastercard, MoMo, or Google Play purchase implementation.
- Push notifications for payment completion.
- Opening or embedding PayOS checkout in a browser/WebView.
- Refactoring unrelated Premium, profile, networking, or routing code.

## Deployment Requirement

The deployed PayOS channel must configure its webhook URL as the public backend endpoint `/api/v1/payments/payos/webhook`. The backend deployment must precede or accompany the mobile release because the mobile create-order response contract changes.
