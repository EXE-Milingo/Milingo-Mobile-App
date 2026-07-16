# Additive Premium Renewal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Make every paid Plus, Pro, or Ultra PayOS order add its full duration to existing Premium time exactly once, while clearly presenting renewals in Flutter.

**Architecture:** New PayOS orders persist purchased duration. A unit-tested policy calculates additive expiration, and one Firestore transaction updates both the user and order. Flutter treats packages as duration bundles, derives renewal copy from subscription state, and keeps every package selectable.

**Tech Stack:** .NET 8, ASP.NET Core, Google.Cloud.Firestore 4.2.0, xUnit v3, Flutter, Dart, Riverpod, GoRouter, Dio, flutter_test.

## Global Constraints

- Plus adds 7 days, Pro 30 days, and Ultra 365 days; backend configuration is authoritative.
- Packages have identical benefits. Do not add proration, feature-tier logic, or scheduled plan changes.
- Renewal equals max(confirmation UTC, current future expiry UTC) plus duration days.
- One PayOS order grants at most once; distinct valid paid orders each grant once.
- Preserve signature, amount, ownership, and pending-order validation.
- Mobile never sends or decides price or duration.
- Preserve Google Play behavior and add no dependencies.
- Commit backend and mobile changes in their respective repositories.

## File Map

Backend root: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend

- Create Services/PremiumRenewalPolicy.cs.
- Create Milingo.Backend.Tests/PremiumRenewalPolicyTests.cs.
- Modify Services/PaymentService.cs.

Mobile root: C:/FPTUniversity/MILINGO/PROJECT/APP/Milingo-Mobile-App

- Create lib/features/premium/models/premium_renewal_info.dart.
- Modify premium selection, payment method, and subscription management UI.
- Add focused model, contract, widget, and source tests under test/.

---

### Task 1: Define and Persist the Backend Renewal Contract

**Files:**
- Create: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/PremiumRenewalPolicy.cs
- Create: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/PremiumRenewalPolicyTests.cs
- Modify: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/PaymentService.cs:63
- Modify: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/PaymentService.cs:758

**Interfaces:**
- Produces: PremiumRenewalPolicy.Decide(string, DateTime, DateTime?, int).
- Produces PayOS order field durationDays.
- Consumes configured Subscriptions:{Plan}:DurationDays.

- [ ] **Step 1: Write failing policy tests**

Create PremiumRenewalPolicyTests.cs:

~~~csharp
using Milingo.Backend.Services;
using Xunit;

namespace Milingo.Backend.Tests;

public class PremiumRenewalPolicyTests
{
    private static readonly DateTime NowUtc =
        new(2026, 7, 16, 3, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Expired_user_starts_from_confirmation_time()
    {
        var result = PremiumRenewalPolicy.Decide(
            "PENDING", NowUtc, NowUtc.AddDays(-1), 30);
        Assert.True(result.ShouldApply);
        Assert.Equal(NowUtc.AddDays(30), result.NewExpiryUtc);
    }

    [Fact]
    public void Active_user_keeps_remaining_time()
    {
        var expiry = NowUtc.AddDays(12);
        var result = PremiumRenewalPolicy.Decide(
            "PENDING", NowUtc, expiry, 30);
        Assert.Equal(expiry.AddDays(30), result.NewExpiryUtc);
    }

    [Theory]
    [InlineData("PAID")]
    [InlineData("SUCCESS")]
    [InlineData("COMPLETED")]
    public void Paid_order_is_not_reapplied(string status)
    {
        var result = PremiumRenewalPolicy.Decide(
            status, NowUtc, NowUtc.AddDays(12), 30);
        Assert.False(result.ShouldApply);
        Assert.Null(result.NewExpiryUtc);
    }

    [Theory]
    [InlineData(7)]
    [InlineData(30)]
    [InlineData(365)]
    public void Every_package_adds_its_duration(int durationDays)
    {
        var expiry = NowUtc.AddDays(20);
        var result = PremiumRenewalPolicy.Decide(
            "PENDING", NowUtc, expiry, durationDays);
        Assert.Equal(expiry.AddDays(durationDays), result.NewExpiryUtc);
    }

    [Fact]
    public void Distinct_orders_stack_after_transaction_serialization()
    {
        var first = PremiumRenewalPolicy.Decide(
            "PENDING", NowUtc, NowUtc.AddDays(10), 30);
        var second = PremiumRenewalPolicy.Decide(
            "PENDING", NowUtc, first.NewExpiryUtc, 7);
        Assert.Equal(NowUtc.AddDays(47), second.NewExpiryUtc);
    }

    [Fact]
    public void Non_positive_duration_is_rejected()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            PremiumRenewalPolicy.Decide("PENDING", NowUtc, null, 0));
    }
}
~~~

- [ ] **Step 2: Run RED**

~~~powershell
dotnet test .\Milingo.Backend.Tests\Milingo.Backend.Tests.csproj --filter PremiumRenewalPolicyTests
~~~

Expected: FAIL because the policy types do not exist.

- [ ] **Step 3: Implement the policy**

Create Services/PremiumRenewalPolicy.cs:

~~~csharp
namespace Milingo.Backend.Services;

internal sealed record PremiumRenewalDecision(
    bool ShouldApply,
    DateTime? NewExpiryUtc);

internal static class PremiumRenewalPolicy
{
    internal static PremiumRenewalDecision Decide(
        string orderStatus,
        DateTime nowUtc,
        DateTime? currentExpiryUtc,
        int durationDays)
    {
        if (durationDays <= 0)
            throw new ArgumentOutOfRangeException(nameof(durationDays));

        if (IsPaid(orderStatus))
            return new PremiumRenewalDecision(false, null);

        var now = nowUtc.ToUniversalTime();
        var current = currentExpiryUtc?.ToUniversalTime();
        var baseDate = current.HasValue && current.Value > now
            ? current.Value
            : now;
        return new PremiumRenewalDecision(
            true,
            baseDate.AddDays(durationDays));
    }

    private static bool IsPaid(string? status) =>
        string.Equals(status, "PAID", StringComparison.OrdinalIgnoreCase)
        || string.Equals(status, "SUCCESS", StringComparison.OrdinalIgnoreCase)
        || string.Equals(status, "COMPLETED", StringComparison.OrdinalIgnoreCase);
}
~~~

- [ ] **Step 4: Persist purchased duration**

In CreatePayOSOrderAsync replace the precomputed Premium expiration with:

~~~csharp
var durationDays = GetConfiguredPlanDurationDays(
    GetPaymentPlan(normalizedPlanId));
~~~

Change SavePayOSOrderAsync to accept int durationDays. Pass it from order creation, remove the new-order premiumExpiresAt write, and add:

~~~csharp
{ "durationDays", durationDays },
~~~

Keep legacy reads until Task 2 supplies their fallback.

- [ ] **Step 5: Verify and commit Task 1**

~~~powershell
dotnet test .\Milingo.Backend.Tests\Milingo.Backend.Tests.csproj --filter PremiumRenewalPolicyTests
dotnet build .\Milingo.Backend.csproj
git add -- Services/PremiumRenewalPolicy.cs Services/PaymentService.cs Milingo.Backend.Tests/PremiumRenewalPolicyTests.cs
git commit -m "feat: define additive premium renewal policy"
~~~

Expected: tests pass and build has zero errors.

---

### Task 2: Apply Paid PayOS Orders Atomically

**Files:**
- Modify: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/PaymentService.cs:270
- Modify: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/PaymentService.cs:315

**Interfaces:**
- Consumes PremiumRenewalPolicy.Decide.
- Produces ApplyPaidPayOSOrderAsync(long, string?, int, DateTime, CancellationToken).
- Produces entitlementAppliedAt and grantedPremiumExpiresAt audit fields.

- [ ] **Step 1: Add the atomic result and method**

Add the result record:

~~~csharp
private sealed record PayOSEntitlementApplication(
    bool Applied,
    DateTime? ExpiresAtUtc);
~~~

Implement ApplyPaidPayOSOrderAsync with this exact transaction sequence:

1. Read payment_orders/{orderCode} inside Firestore RunTransactionAsync.
2. Require the order to exist, have an owner, match expectedUid when supplied, and match expectedAmount.
3. If status is PAID, SUCCESS, or COMPLETED, return Applied=false and the stored grantedPremiumExpiresAt.
4. Read durationDays; if absent or non-positive, resolve the validated planId through GetConfiguredPlanDurationDays.
5. Read users/{ownerUid} in the same transaction.
6. Call PremiumRenewalPolicy.Decide with the stored user premiumExpiresAt.
7. In that transaction set the user fields isPremium=true, premiumExpiresAt, premiumSource=payos, and updatedAt.
8. In that transaction set order fields status=PAID, durationDays, paidAt, entitlementAppliedAt, grantedPremiumExpiresAt, and updatedAt.
9. Return Applied=true and the calculated expiration.

Use existing GetString, GetInt, GetDateTime, IsPaidStatus, and SetOptions.MergeAll helpers. Use Timestamp.FromDateTime after normalizing the calculated DateTime to UTC.

- [ ] **Step 2: Replace both non-atomic paid paths**

In HandlePayOSWebhookAsync, retain signature and amount validation, then replace SetPremiumAsync plus MarkPayOSOrderStatusAsync with:

~~~csharp
await ApplyPaidPayOSOrderAsync(
    payload.Data.OrderCode,
    order.Uid,
    payload.Data.Amount,
    DateTime.UtcNow,
    cancellationToken);
~~~

In the paid branch of VerifyPayOSOrderAsync use:

~~~csharp
await ApplyPaidPayOSOrderAsync(
    orderCode,
    uid,
    snapshot.GetValue<int>("amount"),
    DateTime.UtcNow,
    cancellationToken);
return BuildOrderStatus(orderCode, "PAID", orderExpiresAt);
~~~

Delete PremiumExpiresAt from PayOSOrderRecord and its mapper. Keep SetPremiumAsync for Google Play. A paid legacy order is a no-op; a pending legacy order derives duration from planId.

- [ ] **Step 3: Verify and commit Task 2**

~~~powershell
dotnet test .\Milingo.Backend.Tests\Milingo.Backend.Tests.csproj
dotnet build .\Milingo.Backend.csproj
rg -n "SetPremiumAsync|ApplyPaidPayOSOrderAsync|durationDays|entitlementAppliedAt" Services/PaymentService.cs
git add -- Services/PaymentService.cs
git commit -m "feat: apply PayOS renewals atomically"
~~~

Expected: PayOS paid paths use the transaction; only Google Play uses SetPremiumAsync.
The policy suite's distinct-order test models Firestore retry serialization;
the paid-status test models webhook-after-verification and duplicate-webhook
idempotency. Do not claim an emulator or live concurrency test unless one was
actually run.

---

### Task 3: Add the Flutter Renewal Presentation Model

**Files:**
- Create: lib/features/premium/models/premium_renewal_info.dart
- Create: test/premium_renewal_info_test.dart
- Modify: lib/features/premium/widgets/premium_upgrade_view.dart:5
- Modify: test/payment_plan_contract_test.dart

**Interfaces:**
- Consumes SubscriptionOverviewResponse.
- Produces PremiumRenewalInfo action copy, estimated expiry, and preferred package.
- Produces PremiumPlan.durationDays.

- [ ] **Step 1: Write failing model tests**

Create test/premium_renewal_info_test.dart with assertions for:

~~~dart
const free = PremiumRenewalInfo.free();
expect(
  free.actionLabel(planId: 'pro', durationDays: 30),
  'Bắt đầu ngay',
);

final info = PremiumRenewalInfo(
  isPremium: true,
  latestPlanId: 'pro',
  currentExpiresAt: DateTime.utc(2026, 7, 28),
);
expect(
  info.actionLabel(planId: 'pro', durationDays: 30),
  'Gia hạn thêm 30 ngày',
);
expect(
  info.actionLabel(planId: 'ultra', durationDays: 365),
  'Mua thêm 365 ngày',
);
expect(
  info.estimatedExpiry(
    now: DateTime.utc(2026, 7, 16),
    durationDays: 30,
  ),
  DateTime.utc(2026, 8, 27),
);
expect(
  info.preferredPlanId({'plus', 'pro', 'ultra'}, 'pro'),
  'pro',
);
expect(
  PremiumRenewalInfo.fromOverview(null).isPremium,
  isFalse,
);
~~~

- [ ] **Step 2: Run RED**

~~~powershell
flutter test test/premium_renewal_info_test.dart
~~~

Expected: FAIL because PremiumRenewalInfo does not exist.

- [ ] **Step 3: Implement the presentation model**

Create a value object with:

~~~dart
class PremiumRenewalInfo {
  const PremiumRenewalInfo({
    required this.isPremium,
    required this.latestPlanId,
    required this.currentExpiresAt,
  });

  const PremiumRenewalInfo.free()
      : isPremium = false,
        latestPlanId = null,
        currentExpiresAt = null;

  factory PremiumRenewalInfo.fromOverview(
    SubscriptionOverviewResponse? overview,
  ) {
    if (overview == null || !overview.isPremium) {
      return const PremiumRenewalInfo.free();
    }
    return PremiumRenewalInfo(
      isPremium: true,
      latestPlanId: overview.planId,
      currentExpiresAt: overview.expiresAt,
    );
  }

  final bool isPremium;
  final String? latestPlanId;
  final DateTime? currentExpiresAt;

  String preferredPlanId(Set<String> ids, String fallback) {
    final latest = latestPlanId;
    return latest != null && ids.contains(latest) ? latest : fallback;
  }

  String actionLabel({required String planId, required int durationDays}) {
    if (!isPremium) return 'Bắt đầu ngay';
    final prefix = planId == latestPlanId ? 'Gia hạn thêm' : 'Mua thêm';
    return '$prefix $durationDays ngày';
  }

  DateTime estimatedExpiry({required DateTime now, required int durationDays}) {
    final nowUtc = now.toUtc();
    final expiry = currentExpiresAt?.toUtc();
    final base = expiry != null && expiry.isAfter(nowUtc) ? expiry : nowUtc;
    return base.add(Duration(days: durationDays));
  }
}
~~~

Also add checkoutNotice using intl DateFormat dd/MM/yyyy. Free copy says the package activates N Premium days. Active copy says remaining time is preserved, N days are added, and shows the estimated date.

- [ ] **Step 4: Retain duration in PremiumPlan**

Add required durationDays to PremiumPlan, map plan.durationDays in fromApi, and set fallback plans to 7, 30, 365. Extend payment_plan_contract_test.dart:

~~~dart
expect(plans.map((plan) => plan.durationDays), [7, 30, 365]);
~~~

- [ ] **Step 5: Verify and commit Task 3**

~~~powershell
dart format lib/features/premium/models/premium_renewal_info.dart lib/features/premium/widgets/premium_upgrade_view.dart test/premium_renewal_info_test.dart test/payment_plan_contract_test.dart
flutter test test/premium_renewal_info_test.dart test/payment_plan_contract_test.dart
git add -- lib/features/premium/models/premium_renewal_info.dart lib/features/premium/widgets/premium_upgrade_view.dart test/premium_renewal_info_test.dart test/payment_plan_contract_test.dart
git commit -m "feat: model premium renewal presentation"
~~~

---

### Task 4: Present Renewals on the Premium Selection Screen

**Files:**
- Modify: lib/features/premium/screens/premium_screen.dart
- Modify: lib/features/premium/widgets/premium_upgrade_view.dart
- Create: test/premium_upgrade_view_test.dart

**Interfaces:**
- Consumes PremiumRenewalInfo and subscriptionOverviewProvider.
- Produces PremiumUpgradeView.latestPurchasedPlanId and actionLabel.

- [ ] **Step 1: Write the failing widget test**

Pump PremiumUpgradeView with Pro selected, latestPurchasedPlanId=pro, and actionLabel=Gia hạn thêm 30 ngày. Assert:

~~~dart
expect(find.text('GÓI MUA GẦN NHẤT'), findsOneWidget);
expect(find.text('Gia hạn thêm 30 ngày'), findsOneWidget);
await tester.tap(find.text('Gói Pro').first);
expect(selected?.id, 'pro');
await tester.tap(find.text('Gia hạn thêm 30 ngày'));
expect(started, isTrue);
~~~

- [ ] **Step 2: Run RED**

~~~powershell
flutter test test/premium_upgrade_view_test.dart
~~~

Expected: FAIL because the view lacks renewal inputs.

- [ ] **Step 3: Implement renewal view inputs**

Add required latestPurchasedPlanId and actionLabel fields to PremiumUpgradeView. Thread the latest ID into cards and render GÓI MUA GẦN NHẤT on the match. Thread actionLabel to _PremiumActionArea:

~~~dart
label: Text(isStartingPayment ? 'Đang mở PayOS' : actionLabel),
~~~

Do not disable or intercept the matching card.

- [ ] **Step 4: Load subscription context in PremiumScreen**

Add PremiumRenewalInfo state. In initState load subscriptionOverviewProvider.future. On success, build PremiumRenewalInfo and select latestPlanId only if it exists in the loaded plan catalog. On error, retain the current free/generic presentation and allow checkout. Reapply preferredPlanId after the remote catalog loads to avoid races.

Pass:

~~~dart
latestPurchasedPlanId:
    _renewalInfo.isPremium ? _renewalInfo.latestPlanId : null,
actionLabel: _renewalInfo.actionLabel(
  planId: _selectedPlan.id,
  durationDays: _selectedPlan.durationDays,
),
~~~

- [ ] **Step 5: Verify and commit Task 4**

~~~powershell
dart format lib/features/premium/screens/premium_screen.dart lib/features/premium/widgets/premium_upgrade_view.dart test/premium_upgrade_view_test.dart
flutter test test/premium_upgrade_view_test.dart test/premium_renewal_info_test.dart test/payment_plan_contract_test.dart
git add -- lib/features/premium/screens/premium_screen.dart lib/features/premium/widgets/premium_upgrade_view.dart test/premium_upgrade_view_test.dart
git commit -m "feat: present additive premium renewals"
~~~

---

### Task 5: Explain Added Time at Checkout and Remove PayOS Recurring Copy

**Files:**
- Modify: lib/features/premium/screens/payment_method_screen.dart
- Modify: lib/features/premium/widgets/payment_method_view.dart
- Modify: lib/features/premium/screens/subscription_management_screen.dart
- Create: test/premium_payment_method_view_test.dart
- Create: test/subscription_management_payos_source_test.dart

**Interfaces:**
- Consumes PremiumRenewalInfo.checkoutNotice and PremiumPlan.durationDays.
- Produces required PaymentMethodView.renewalNotice.

- [ ] **Step 1: Write failing checkout test**

Pump PaymentMethodView with renewalNotice set to:

~~~dart
const notice =
    'Thời gian còn lại được giữ nguyên. Giao dịch cộng thêm 30 ngày.';
~~~

Assert find.text(notice) finds one widget.

- [ ] **Step 2: Write failing PayOS copy guard**

Read subscription_management_screen.dart and assert it contains Gói mua gần nhất, PayOS là giao dịch một lần, and the explicit overview.source == 'payos' branch.

- [ ] **Step 3: Run RED**

~~~powershell
flutter test test/premium_payment_method_view_test.dart test/subscription_management_payos_source_test.dart
~~~

Expected: FAIL because renewal notice and one-time PayOS copy are absent.

- [ ] **Step 4: Add checkout notice**

Add required renewalNotice to PaymentMethodView and show it in a rounded full-width information panel beneath _SelectedPlanCard.

In PaymentMethodScreen.build:

~~~dart
final overview = ref.watch(subscriptionOverviewProvider).valueOrNull;
final renewalInfo = PremiumRenewalInfo.fromOverview(overview);
final renewalNotice = renewalInfo.checkoutNotice(
  durationDays: _selectedPlan.durationDays,
  now: DateTime.now(),
);
~~~

Pass renewalNotice to the view. Loading/error uses generic copy and does not block payment.

- [ ] **Step 5: Replace recurring PayOS language**

Change _buildFooterActions to receive the overview. For active PayOS access return:

~~~dart
if (overview.isPremium && overview.source == 'payos') {
  return const Padding(
    padding: EdgeInsets.symmetric(horizontal: 24),
    child: Text(
      'PayOS là giao dịch một lần và không tự động gia hạn. '
      'Bạn có thể mua thêm thời gian bất cứ lúc nào.',
      textAlign: TextAlign.center,
    ),
  );
}
~~~

For PayOS, label the amount Gói mua gần nhất and use lastPaymentAmount. Preserve existing Google Play labels/actions.

- [ ] **Step 6: Verify and commit Task 5**

~~~powershell
dart format lib/features/premium/screens/payment_method_screen.dart lib/features/premium/widgets/payment_method_view.dart lib/features/premium/screens/subscription_management_screen.dart test/premium_payment_method_view_test.dart test/subscription_management_payos_source_test.dart
flutter test test/premium_payment_method_view_test.dart test/subscription_management_payos_source_test.dart test/payment_method_screen_source_test.dart
git add -- lib/features/premium/screens/payment_method_screen.dart lib/features/premium/widgets/payment_method_view.dart lib/features/premium/screens/subscription_management_screen.dart test/premium_payment_method_view_test.dart test/subscription_management_payos_source_test.dart
git commit -m "feat: explain premium renewal checkout"
~~~

---

### Task 6: Cross-Repository Verification and Audit

**Files:**
- Verify only: files changed in Tasks 1-5.

**Interfaces:**
- Consumes the complete backend and mobile implementation.
- Produces verified changes ready for review.

- [ ] **Step 1: Verify backend**

From the backend root:

~~~powershell
dotnet format .\Milingo.Backend.csproj --verify-no-changes
dotnet test .\Milingo.Backend.Tests\Milingo.Backend.Tests.csproj
dotnet build .\Milingo.Backend.csproj
~~~

Expected: all commands exit 0. If formatting fails, format, inspect touched files, then rerun.

- [ ] **Step 2: Audit paid-order invariants**

~~~powershell
rg -n "SetPremiumAsync|ApplyPaidPayOSOrderAsync|durationDays|entitlementAppliedAt|grantedPremiumExpiresAt" Services/PaymentService.cs
~~~

Expected: PayOS webhook/verification use the transaction; Google Play alone uses SetPremiumAsync; user and order paid updates are in one transaction.

- [ ] **Step 3: Verify Flutter**

From the mobile root:

~~~powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
~~~

Expected: formatting, analysis, and all tests pass.

- [ ] **Step 4: Inspect both worktrees**

Run git status --short and git diff --check in both repositories. Confirm no generated output, secrets, unrelated refactors, or whitespace errors.

- [ ] **Step 5: Hand off results**

Report backend/mobile commit hashes and exact verification outcomes. Report credential- or service-blocked checks honestly; unit tests are not a live PayOS transaction test.
