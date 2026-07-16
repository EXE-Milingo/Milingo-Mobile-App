# Additive Premium Renewal Design

**Date:** 2026-07-16

**Status:** Approved behavior; awaiting written-spec review

## Objective

Treat Plus, Pro, and Ultra as Premium duration packages rather than feature
tiers. All packages grant the same Premium benefits:

- Plus adds 7 days.
- Pro adds 30 days.
- Ultra adds 365 days.

An authenticated user may buy any package while Premium is active, including
the same package again. Every successfully paid order adds its full duration
without discarding time the user already owns.

## Current Risk

The mobile Premium screen does not read the active subscription and allows all
packages to proceed to checkout. That UI is acceptable for additive renewal,
but it does not explain the renewal result.

The backend currently calculates an order's `premiumExpiresAt` as
`DateTime.UtcNow + durationDays` when the PayOS order is created. When payment
is confirmed, `SetPremiumAsync` replaces the user's existing expiration with
that stored date. A user with substantial time remaining can therefore lose
time by making another purchase.

## Renewal Semantics

Entitlement is applied when a valid payment is confirmed, not when its order
is created.

For each newly paid order:

```text
currentExpiry = the user's stored Premium expiration, if it is in the future
baseDate = max(paymentConfirmationTimeUtc, currentExpiry)
newExpiry = baseDate + purchasedDurationDays
```

Examples:

- An expired user buying Pro receives 30 days from payment confirmation.
- A user with 12 days remaining who buys Pro receives approximately 42 days
  remaining.
- A user with 200 days remaining who buys Plus receives approximately 207 days
  remaining.

The latest purchased package may be displayed as the last purchase, but it is
not a persistent feature tier. Premium access and its combined expiration are
the authoritative subscription state.

## Backend Design

Backend repository:
`C:\FPTUniversity\MILINGO\PROJECT\BACKEND\Milingo-Backend`

### Order creation

`PaymentService.CreatePayOSOrderAsync` continues to validate `planId`, derive
the price from backend configuration, and reuse or replace pending PayOS orders
under the existing order policy.

New PayOS order documents store the purchased duration as `durationDays`.
They must not store a precomputed final user entitlement as the authority for
renewal. Existing `premiumExpiresAt` data may remain readable for backward
compatibility, but new entitlement calculations do not overwrite a future user
expiration with it.

For a legacy pending order without `durationDays`, the backend derives the
duration from its validated `planId` using the configured plan definition.
Already-paid legacy orders remain applied and must never be extended again by
the migration.

### Atomic entitlement application

Both PayOS webhook handling and direct order verification call one shared
backend operation for applying a paid order. That operation runs in a Firestore
transaction and:

1. Reads the payment order and owning user.
2. Confirms the order belongs to the expected user where an authenticated UID
   is available.
3. Treats an already-paid/applied order as a successful no-op.
4. Reads `durationDays`, with the legacy `planId` fallback described above.
5. Calculates `newExpiry` from the later of the current UTC time and the user's
   future Premium expiration.
6. Updates the user to `isPremium: true`, the calculated
   `premiumExpiresAt`, and `premiumSource: payos`.
7. Updates the order to `PAID` and records `paidAt`, `entitlementAppliedAt`,
   and the resulting `grantedPremiumExpiresAt` for auditability.

The user and order updates commit together. If two different valid orders are
confirmed concurrently, Firestore transaction retries serialize their writes,
so both durations are added once. Duplicate webhook or verification processing
for the same order is a no-op and never adds time twice.

PayOS signature validation, amount comparison, UID ownership checks, and order
status reconciliation remain mandatory before entitlement is applied.

### Subscription overview

`GetSubscriptionOverviewAsync` continues returning the user's combined
expiration and remaining days. `planId` and `planName` describe the most recent
paid package only; they do not limit or reset previously accumulated time.

Automatic-renewal wording is removed for PayOS duration packages because PayOS
orders are user-initiated, one-time purchases. `nextPaymentAmount` must not be
presented as a scheduled charge unless a separate automatic-renewal product is
implemented later.

## Mobile Design

### Premium package selection

`PremiumScreen` loads the plan catalog and `subscriptionOverviewProvider`.

- Free users retain the existing default selection.
- Active users default to the most recently purchased package when its
  `planId` exists in the current catalog.
- Every package remains selectable, including the most recent package.
- The matching card uses wording such as `Gói mua gần nhất`, not `Gói hiện tại`
  or a disabled state.
- If subscription loading fails, checkout remains available because the
  backend is authoritative; the UI falls back to generic purchase wording.

The primary action reflects the selected duration:

- Free user: `Bắt đầu ngay`.
- Active user selecting the most recent package: `Gia hạn thêm 30 ngày`.
- Active user selecting another package: `Mua thêm 365 ngày`.

The exact number comes from the backend-provided `durationDays`, not a
hard-coded mapping.

### Checkout confirmation

The payment-method screen states that the purchase adds the selected duration
and does not replace remaining time. When the active expiration is available,
it shows an estimated resulting date calculated as:

```text
max(current local view of expiration, current time) + durationDays
```

The estimate is informational. The backend result after payment remains
authoritative. The payment success and subscription management screens refresh
the existing profile and subscription providers and display the confirmed
expiration returned by the backend.

### Pending orders

Existing pending-order behavior is unchanged:

- Re-entering the same package restores its valid pending QR.
- Selecting another package cancels the previous valid pending order before
  creating a replacement.
- Discovering that a pending order has already been paid refreshes entitlement
  instead of creating another order automatically.

## Error Handling

- If entitlement application fails after PayOS confirms payment, leave the
  order recoverable and retry through webhook, verification, or pending-order
  reconciliation. Never create a second entitlement grant as recovery.
- Reject unknown plan IDs or non-positive configured durations.
- Never trust a duration or amount supplied by the mobile application.
- If the mobile subscription view is stale, allow checkout but use the backend
  user's expiration when applying payment.
- If a transaction conflicts with another renewal, retry through Firestore's
  transaction mechanism rather than using a last-write-wins update.

## Testing

### Backend

Add focused tests proving:

- An expired user receives `now + durationDays`.
- An active user receives `currentExpiry + durationDays`.
- Buying the same package adds its duration.
- Buying a different package adds that package's duration.
- A duplicate webhook for one order does not extend twice.
- Direct verification followed by a webhook does not extend twice.
- Two different concurrently paid orders each extend exactly once.
- A legacy pending order without `durationDays` uses its validated `planId`.
- An already-paid legacy order is not reapplied.
- Invalid signatures, amount mismatches, and cross-user verification never
  modify entitlement.
- The subscription overview reports the combined expiration and latest
  purchased package consistently.

### Flutter

Add provider/widget tests proving:

- Active subscription data preselects the latest purchased package.
- The latest package remains selectable.
- Same-package action text says `Gia hạn` and displays the correct duration.
- Another-package action text says `Mua thêm` and displays its duration.
- Checkout explains that remaining time is preserved.
- Subscription-load failure falls back safely without blocking checkout.
- Payment success refreshes profile and subscription state and displays the
  backend-confirmed expiration.

## Non-goals

- Different feature entitlements for Plus, Pro, and Ultra.
- Proration, refunds, credits, or currency conversion.
- Scheduled downgrades or upgrades.
- PayOS automatic recurring billing.
- Changing Google Play subscription renewal semantics.
- Migrating or reapplying already-paid historical orders.
