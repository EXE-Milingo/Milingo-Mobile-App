# Native PayOS QR Payment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Replace external PayOS checkout with a recoverable native VietQR flow, correct automatic webhook activation, and reconcile Premium/profile state on payment, startup, and resume.

**Architecture:** The backend owns PayOS credentials, creates or reuses 30-minute orders, persists QR recovery fields, validates body-signed webhooks, and exposes authenticated pending/verify operations. Flutter renders the PayOS QR payload locally, polls while active, reconciles at authenticated startup/resume, and refreshes profile/subscription providers after payment.

**Tech Stack:** Flutter/Dart, Riverpod 2, GoRouter, Dio, qr_flutter 4.1.0, gal 2.3.2, ASP.NET Core 8, Firestore, xUnit v3 3.2.2.

## Global Constraints

- Preserve Riverpod, GoRouter, Dio, Firebase Auth, Firestore, and feature-first patterns.
- Backend communication stays in MilingoApiService; PayOS secrets remain backend-only.
- Screen payment state is autoDispose; auth reconciliation watches authStateProvider.
- QR expiry is 30 minutes.
- Same user + same plan + valid PENDING order returns the same QR.
- Changing tier cancels valid pending orders before creating the replacement.
- Preserve existing user changes in android/app/build.gradle.kts, pubspec.lock, and backend .hatch-pet-runs/.
- Add packages only after explicit package-install approval.
- Backend edits require filesystem approval because that repository is outside the writable mobile root.

---

## File Structure

Backend:
- Modify Models/PaymentModels.cs for native QR, webhook, and status DTOs.
- Create Services/PayOSProtocol.cs for pure response parsing and HMAC rules.
- Modify Services/IPaymentService.cs and Services/PaymentService.cs for UID-scoped reuse, expiry, cancel, pending lookup, webhook, and verification.
- Modify Controller/PaymentController.cs and appsettings.json for the simplified API.
- Create Properties/AssemblyInfo.cs and Milingo.Backend.Tests for protocol/policy tests.
- Modify Milingo-Backend.sln to include tests.

Flutter:
- Modify pubspec.yaml and ios/Runner/Info.plist for QR rendering/gallery saving.
- Modify app constants, API service, and models for the native contract.
- Create features/premium/providers/payment_provider.dart.
- Create payment_qr_screen.dart and payment_qr_view.dart.
- Simplify payment_method_screen.dart and payment_method_view.dart to bank QR only.
- Modify routing, main lifecycle/deep links, and payment result refresh.
- Add model, provider, widget, lifecycle, and routing tests.

---

### Task 1: Backend PayOS Protocol Contract

**Files:**
- Create: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/Milingo.Backend.Tests.csproj
- Create: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/PayOSProtocolTests.cs
- Create: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Properties/AssemblyInfo.cs
- Create: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/PayOSProtocol.cs
- Modify: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Models/PaymentModels.cs
- Modify: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo-Backend.sln

**Interfaces:**
- Produces: PayOSProtocol.ParseCreateOrder(string, DateTime) -> CreatePayOSOrderResponse
- Produces: PayOSProtocol.VerifyWebhook(PayOSWebhookPayload, string) -> bool
- Produces: PayOSProtocol.IsPaidWebhook(PayOSWebhookPayload) -> bool

- [ ] **Step 1: Add the failing test project and protocol tests**

Use this test project:

~~~xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="xunit.v3" Version="3.2.2" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\Milingo.Backend.csproj" />
  </ItemGroup>
</Project>
~~~

Tests parse the official create-order sample and assert Bin, AccountNumber, AccountName, Amount, Description, OrderCode, PaymentLinkId, QrCode, Status, CheckoutUrl, and supplied ExpiresAt. Webhook tests compute a signature across every data field and assert: valid documented body is paid; missing signature is rejected; changed amount invalidates HMAC; success false is not paid.

- [ ] **Step 2: Verify RED**

Run: dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj

Expected: compile failure because PayOSProtocol and the new DTO fields do not exist.

- [ ] **Step 3: Implement minimal DTO/protocol code**

CreatePayOSOrderResponse exposes the fields above. PayOSWebhookPayload adds JSON success/signature. PayOSWebhookData adds code/desc while retaining JsonExtensionData. VerifyWebhook sorts explicit and extension data keys ordinally, serializes null as an empty string, hashes the key=value sequence with HMAC-SHA256, and compares fixed-time. IsPaidWebhook requires top code 00, success true, and data code 00.

- [ ] **Step 4: Verify GREEN**

Run: dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj

Expected: all PayOSProtocolTests pass.

- [ ] **Step 5: Commit the protocol contract**

Stage only the Task 1 files and commit with message: test: define native PayOS protocol contract.

---

### Task 2: Backend Recoverable Order Lifecycle

**Files:**
- Create: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/PaymentOrderPolicyTests.cs
- Modify: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/IPaymentService.cs
- Modify: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/PaymentService.cs
- Modify: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Controller/PaymentController.cs
- Modify: C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/appsettings.json

**Interfaces:**
- Produces: CreatePayOSOrderAsync(string uid, string planId, CancellationToken)
- Produces: GetPendingPayOSOrderAsync(string uid, CancellationToken)
- Produces: VerifyPayOSOrderAsync(string uid, long orderCode, CancellationToken)
- Produces: CancelPayOSOrderAsync(string uid, long orderCode, CancellationToken)

- [ ] **Step 1: Write failing policy tests**

Extract internal PaymentOrderPolicy.Decide(requestedPlan, existingPlan, status, expiresAt, nowUtc). Assert Reuse for same-plan valid PENDING; Replace for expired/cancelled; CancelAndReplace for different-plan valid PENDING; RefreshEntitlement for PAID.

- [ ] **Step 2: Verify RED**

Run: dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --filter PaymentOrderPolicyTests

Expected: compile failure for missing policy types.

- [ ] **Step 3: Implement policy and order creation**

Set expiredAt to now + configured 30 minutes and send its Unix seconds to PayOS. Store every QR recovery field and expiresAt in payment_orders. Before creation, reconcile user pending orders. Reuse complete same-plan PENDING data. Cancel different-plan orders using POST /v2/payment-requests/{orderCode}/cancel. Reconcile and replace incomplete legacy records only when unpaid.

- [ ] **Step 4: Implement UID-scoped verification and pending recovery**

Verify loads Firestore first and rejects snapshot.uid != authenticated uid. It returns PayOSOrderStatusResponse with OrderCode, Status, IsPaid, and ExpiresAt. Pending lookup returns only the authenticated user's latest recoverable order.

- [ ] **Step 5: Correct webhook processing**

Controller uses payload.Signature with header fallback. Service verifies HMAC before mutation, requires the success codes from Task 1, checks stored amount, grants Premium, and marks PAID. Duplicate PAID webhook returns success without extending entitlement twice. Invalid signatures return non-2xx.

- [ ] **Step 6: Expose endpoints and backend configuration**

Endpoints:
- POST /api/v1/payments/payos/create-order with body { planId }
- GET /api/v1/payments/payos/pending-order
- POST /api/v1/payments/payos/verify-order/{orderCode}
- POST /api/v1/payments/payos/cancel-order/{orderCode}

Configuration:

~~~json
"PayOS": {
  "ClientId": "",
  "ApiKey": "",
  "ChecksumKey": "",
  "ReturnUrl": "https://api.milingo.vn/api/v1/payments/payos/redirect?status=success",
  "CancelUrl": "https://api.milingo.vn/api/v1/payments/payos/redirect?status=cancel",
  "OrderExpiryMinutes": 30
}
~~~

- [ ] **Step 7: Verify backend**

Run:
- dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj
- dotnet build Milingo-Backend.sln

Expected: zero failures and build exit 0.

- [ ] **Step 8: Commit recoverable order lifecycle**

Stage only the Task 2 files and commit with message: feat: add recoverable native PayOS orders.

---

### Task 3: Flutter Native Contracts

**Files:**
- Create: test/payos_order_model_test.dart
- Modify: lib/core/network/milingo_models.dart
- Modify: lib/core/network/milingo_api_service.dart
- Modify: lib/core/constants/app_constants.dart

**Interfaces:**
- Produces: CreatePayOSOrderResponse.fromJson
- Produces: PayOSOrderStatusResponse.fromJson
- Produces: createPayOSOrder(planId), getPendingPayOSOrder(), verifyPayOSOrder(orderCode)

- [ ] **Step 1: Write failing model tests**

Parse the backend samples and assert every native field, UTC expiry, typed status, and terminal-state helpers.

- [ ] **Step 2: Verify RED**

Run: flutter test test/payos_order_model_test.dart

Expected: compile failure for missing fields/status model.

- [ ] **Step 3: Implement models/API**

Create-order sends only planId. Pending parses nullable data. Verify returns typed status. Remove PayOS credentials/API/return/cancel getters from AppConstants; keep only constants required for backend/deep-link routing.

- [ ] **Step 4: Verify GREEN**

Run: flutter test test/payos_order_model_test.dart

Expected: all tests pass.

- [ ] **Step 5: Commit mobile contracts**

Stage only the Task 3 files and commit with message: feat: add native PayOS mobile contract.

---

### Task 4: Riverpod Polling and Reconciliation

**Files:**
- Create: lib/features/premium/providers/payment_provider.dart
- Create: test/payment_provider_test.dart
- Modify: lib/features/premium/providers/subscription_provider.dart

**Interfaces:**
- Produces: PaymentQrState
- Produces: paymentQrProvider.autoDispose.family
- Produces: auth-scoped paymentReconciliationProvider
- Produces: reconcileNow() and handleAppResumed()

- [ ] **Step 1: Write failing provider tests**

Override a narrow payment gateway provider. Assert immediate verification, five-second PENDING polling, no overlap, terminal cancellation, disposal cancellation, backend pending recovery without SharedPreferences, auth reset, and one profile/subscription refresh on paid.

- [ ] **Step 2: Verify RED**

Run: flutter test test/payment_provider_test.dart

Expected: compile failure for missing provider/state.

- [ ] **Step 3: Implement minimal provider logic**

Use Timer.periodic(Duration(seconds: 5)), an in-flight guard, and ref.onDispose. Auth reconciliation watches authStateProvider. Paid refresh calls userProfileProvider.notifier.refresh and invalidates subscriptionOverviewProvider.

- [ ] **Step 4: Verify GREEN**

Run: flutter test test/payment_provider_test.dart

Expected: tests pass with no pending timers.

- [ ] **Step 5: Commit reconciliation providers**

Stage only the Task 4 files and commit with message: feat: reconcile PayOS payments with Riverpod.

---

### Task 5: Native QR UI, Copy, and Save

**Files:**
- Modify: pubspec.yaml
- Modify: pubspec.lock
- Modify: ios/Runner/Info.plist
- Create: lib/features/premium/widgets/payment_qr_view.dart
- Create: lib/features/premium/screens/payment_qr_screen.dart
- Create: test/payment_qr_view_test.dart
- Modify: lib/features/premium/screens/payment_method_screen.dart
- Modify: lib/features/premium/widgets/payment_method_view.dart
- Modify: lib/core/routing/app_router.dart
- Modify: test/payment_method_screen_source_test.dart

**Interfaces:**
- Produces: AppConstants.paymentQrRoute = /premium/payment-qr
- Produces: PaymentQrView callbacks for copy, save, retry, and fresh-order creation

- [ ] **Step 1: Write failing widget/source tests**

Assert only QR Ngân hàng exists; Apple Pay, Visa/Mastercard, MoMo, add-method, url_launcher, and launchUrl do not. Pump sample QR data and assert amount, account name/number, description, QR widget, copy controls, Lưu mã QR, pending, expired, and retry states.

- [ ] **Step 2: Verify RED**

Run:
- flutter test test/payment_method_screen_source_test.dart
- flutter test test/payment_qr_view_test.dart

Expected: source assertion failure and missing QR view compile failure.

- [ ] **Step 3: Add approved dependencies**

Add qr_flutter ^4.1.0 and gal ^2.3.2, run flutter pub get, and add NSPhotoLibraryAddUsageDescription in Vietnamese. Add no unnecessary Android storage permission.

- [ ] **Step 4: Implement native screen**

Render QrImageView from order.qrCode inside RepaintBoundary. Capture PNG bytes and call Gal.putImageBytes(bytes, album: MiLingo). Copy with Clipboard.setData. Use SingleChildScrollView. Confirming creates the order and context.pushes the QR route with the response. QR lifecycle resumes provider reconciliation and paid state transitions to PaymentResultScreen.

- [ ] **Step 5: Verify GREEN**

Run both tests from Step 2. Expected: pass.

- [ ] **Step 6: Commit native QR UI**

Stage only the Task 5 files and commit with message: feat: show PayOS VietQR inside the app.

---

### Task 6: Startup, Resume, Profile, and Legacy Links

**Files:**
- Modify: lib/main.dart
- Modify: lib/features/premium/screens/payment_result_screen.dart
- Create: test/payment_link_routing_test.dart
- Modify: test/profile_screen_source_test.dart

**Interfaces:**
- Consumes: paymentReconciliationProvider.notifier.reconcileNow()
- Produces: query-preserving paymentRouteFor(Uri)

- [ ] **Step 1: Write failing lifecycle/link tests**

Assert milingo://payment/payment/success?orderCode=42 becomes /payment/success?orderCode=42. Assert startup/resume reconciliation and paid legacy refresh of userProfileProvider plus subscriptionOverviewProvider.

- [ ] **Step 2: Verify RED**

Run: flutter test test/payment_link_routing_test.dart test/profile_screen_source_test.dart

Expected: current route drops orderCode and refresh assertions fail.

- [ ] **Step 3: Implement lifecycle wiring**

Make MiLingoApp observe WidgetsBinding, reconcile after authenticated startup and on resumed, and remove the observer on dispose. Preserve query parameters. Legacy success uses typed verification and shared refresh.

- [ ] **Step 4: Verify GREEN**

Run the Step 2 command. Expected: pass.

- [ ] **Step 5: Commit lifecycle refresh**

Stage only the Task 6 files and commit with message: fix: refresh Premium state after PayOS payment.

---

### Task 7: Full Verification and Audit

- [ ] **Step 1: Backend verification**

Run dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj and dotnet build Milingo-Backend.sln. Expected: exit 0.

- [ ] **Step 2: Flutter formatting**

Run dart format --output=none --set-exit-if-changed lib test. If needed, format, inspect, and rerun.

- [ ] **Step 3: Flutter verification**

Run flutter analyze and flutter test. Expected: exit 0 and zero failures.

- [ ] **Step 4: Requirement audit**

Confirm:
1. No external PayOS page; native QR has copy/save.
2. Body-signed webhook grants Premium; poll/startup/resume is fallback.
3. Paid reconciliation refreshes Profile/subscription.
4. Same tier reuses valid QR; different tier cancels; expiry is 30 minutes.
5. All order operations enforce UID ownership.
6. Legacy deep links preserve orderCode.

- [ ] **Step 5: Diff safety**

Run git diff --check and git status --short in both repos. Confirm pre-existing mobile Gradle work and backend .hatch-pet-runs remain untouched.
