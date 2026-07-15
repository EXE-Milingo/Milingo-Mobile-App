# Payment QR Centering, Bank Name, and VietQR Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Center the native PayOS QR, display the configured full legal receiving-bank name, and identify the transfer as VietQR over NAPAS 247.

**Architecture:** The backend remains the source of truth for payment metadata. It reads the legal bank name from the single PayOS channel configuration, returns and persists it with native QR orders, and supplies that configured value for legacy pending orders. Flutter parses the added field and makes only presentation changes; no new runtime API request is introduced.

**Tech Stack:** ASP.NET Core 8, Firestore, xUnit v3, Flutter, Riverpod, `qr_flutter`, Flutter widget tests.

## Global Constraints

- Keep QR contents, PayOS webhooks, polling, reconciliation, expiration, activation, and order-reuse behavior unchanged.
- Keep the QR at 250 logical pixels and preserve its existing white `RepaintBoundary` and padding.
- Use the full legal name `Ngân hàng Thương mại Cổ phần Quân đội (MB)` for the current PayOS channel.
- Display `VietQR • Chuyển nhanh NAPAS 247` as text; do not create unofficial logo artwork.
- Do not add a VietQR directory call, mobile BIN table, banking deep link, or new package.
- Preserve unrelated mobile changes in `android/app/build.gradle.kts`, `lib/core/constants/app_constants.dart`, and the remaining unstaged `pubspec.lock` hunks.
- Preserve the backend's unrelated `.hatch-pet-runs/` directory.

---

### Task 1: Add backend legal-bank metadata to native PayOS orders

**Files:**
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Models/PaymentModels.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/PayOSProtocol.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/PaymentOrderPolicy.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/PaymentService.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/appsettings.json`
- Test: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/PayOSProtocolTests.cs`
- Test: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/PaymentOrderPolicyTests.cs`

**Interfaces:**
- Consumes: `PayOS:BankName` configuration and PayOS response field `bin`.
- Produces: JSON field `bankName` on `CreatePayOSOrderResponse`; Firestore field `bankName`; `PaymentOrderPolicy.ResolveBankName(string? storedBankName, string configuredBankName)`.

- [ ] **Step 1: Write failing backend contract and fallback tests**

Update the protocol test to pass and assert the configured legal name:

```csharp
const string bankName = "Ngân hàng Thương mại Cổ phần Quân đội (MB)";
var result = PayOSProtocol.ParseCreateOrder(json, expiresAt, bankName);
Assert.Equal(bankName, result.BankName);
```

Add policy tests for stored and legacy orders:

```csharp
[Fact]
public void ResolveBankName_keeps_persisted_legal_name()
{
    Assert.Equal(
        "Persisted Legal Bank",
        PaymentOrderPolicy.ResolveBankName(
            "Persisted Legal Bank",
            "Configured Legal Bank"));
}

[Fact]
public void ResolveBankName_uses_configuration_for_legacy_order()
{
    Assert.Equal(
        "Configured Legal Bank",
        PaymentOrderPolicy.ResolveBankName(null, "Configured Legal Bank"));
}
```

- [ ] **Step 2: Run backend tests to verify RED**

Run from the backend root:

```powershell
dotnet test Milingo-Backend.sln --no-restore
```

Expected: compilation fails because the new `ParseCreateOrder` argument, `BankName`, and `ResolveBankName` do not exist.

- [ ] **Step 3: Extend the response contract and pure fallback policy**

Add to `CreatePayOSOrderResponse`:

```csharp
[JsonPropertyName("bankName")]
public string BankName { get; set; } = string.Empty;
```

Change the parser signature and response construction:

```csharp
internal static CreatePayOSOrderResponse ParseCreateOrder(
    string responseBody,
    DateTime expiresAtUtc,
    string bankName)
{
    // existing PayOS parsing remains unchanged
    return new CreatePayOSOrderResponse
    {
        Bin = ReadString(data, "bin"),
        BankName = bankName,
        // existing fields remain unchanged
    };
}
```

Add the legacy-order fallback helper:

```csharp
internal static string ResolveBankName(
    string? storedBankName,
    string configuredBankName)
{
    return string.IsNullOrWhiteSpace(storedBankName)
        ? configuredBankName
        : storedBankName;
}
```

- [ ] **Step 4: Wire configuration, persistence, and recovery**

Add the PayOS configuration value:

```json
"BankName": "Ngân hàng Thương mại Cổ phần Quân đội (MB)"
```

In `CreatePayOSOrderAsync`, read it with `GetRequiredConfig("PayOS:BankName")` and pass it to `ParseCreateOrder`. Persist it in `SavePayOSOrderAsync`:

```csharp
{ "bankName", payment.BankName },
```

Add `BankName` after `Bin` in `PaymentOrderDocument`, map it with:

```csharp
GetString(data, "bankName", string.Empty),
```

Make `ToCreateOrderResponse` an instance method and resolve legacy values:

```csharp
BankName = PaymentOrderPolicy.ResolveBankName(
    order.BankName,
    GetRequiredConfig("PayOS:BankName")),
```

Do not add `BankName` to `HasRecoverableQr`; legacy orders must remain recoverable.

- [ ] **Step 5: Run backend tests and build to verify GREEN**

```powershell
dotnet test Milingo-Backend.sln --no-restore
dotnet build Milingo-Backend.sln --no-restore
```

Expected: all tests pass; build reports 0 errors.

- [ ] **Step 6: Commit backend metadata support**

Stage only the files listed in Task 1 and commit:

```powershell
git commit -m "feat: include receiving bank name in PayOS orders"
```

---

### Task 2: Render centered QR, bank name, and VietQR/NAPAS label in Flutter

**Files:**
- Modify: `lib/core/network/milingo_models.dart`
- Modify: `lib/features/premium/widgets/payment_qr_view.dart`
- Test: `test/payos_order_model_test.dart`
- Test: `test/payment_provider_test.dart`
- Test: `test/payment_qr_view_test.dart`

**Interfaces:**
- Consumes: backend JSON field `bankName` and existing `bin`.
- Produces: `CreatePayOSOrderResponse.bankName`; widget key `payment-qr-boundary`; centered key `payos-qr-code`; visible bank and VietQR/NAPAS labels.

- [ ] **Step 1: Write failing Flutter model and layout tests**

Add `'bankName': 'Ngân hàng Thương mại Cổ phần Quân đội (MB)'` to the model fixture and:

```dart
expect(
  order.bankName,
  'Ngân hàng Thương mại Cổ phần Quân đội (MB)',
);
```

Update the direct `_order()` fixtures in `payment_provider_test.dart` and
`payment_qr_view_test.dart` with the same `bankName`. Add UI assertions:

```dart
expect(
  find.text('Ngân hàng Thương mại Cổ phần Quân đội (MB)'),
  findsOneWidget,
);
expect(find.text('VietQR • Chuyển nhanh NAPAS 247'), findsOneWidget);

final boundaryCenter = tester.getCenter(
  find.byKey(const Key('payment-qr-boundary')),
);
final qrCenter = tester.getCenter(find.byKey(const Key('payos-qr-code')));
expect(qrCenter.dx, closeTo(boundaryCenter.dx, 0.1));
```

- [ ] **Step 2: Run focused Flutter tests to verify RED**

```powershell
flutter test test/payos_order_model_test.dart test/payment_qr_view_test.dart
```

Expected: compilation/assertion failures for missing `bankName`, boundary key, and labels.

- [ ] **Step 3: Extend the Flutter order model with staggered-deploy fallback**

Add the constructor parameter and field:

```dart
required this.bankName,
final String bankName;
```

Parse the backend field without breaking an older deployed backend:

```dart
bankName: (json['bankName'] ?? '').toString(),
```

Update all direct `CreatePayOSOrderResponse` test fixtures with `bankName`.

- [ ] **Step 4: Center and label the native QR**

Give the existing white container a test key and explicit alignment:

```dart
child: Container(
  key: const Key('payment-qr-boundary'),
  alignment: Alignment.center,
  color: Colors.white,
  padding: const EdgeInsets.all(20),
  child: QrImageView(
    key: const Key('payos-qr-code'),
    // existing QR properties remain unchanged
  ),
),
```

Immediately after the `RepaintBoundary`, render:

```dart
const SizedBox(height: 10),
const Text(
  'VietQR • Chuyển nhanh NAPAS 247',
  textAlign: TextAlign.center,
  style: TextStyle(
    color: Color(0xFF0B7A75),
    fontSize: 12,
    fontWeight: FontWeight.w700,
  ),
),
```

Add the bank detail between amount and account name:

```dart
_TransferDetail(
  label: 'Ngân hàng',
  value: order.bankName.trim().isNotEmpty
      ? order.bankName
      : 'Ngân hàng (BIN: ${order.bin})',
),
```

- [ ] **Step 5: Run focused Flutter tests to verify GREEN**

```powershell
flutter test test/payos_order_model_test.dart test/payment_qr_view_test.dart
```

Expected: all focused tests pass.

- [ ] **Step 6: Commit Flutter presentation changes**

Stage only the Task 2 files and commit:

```powershell
git commit -m "feat: polish native VietQR payment details"
```

---

### Task 3: Verify both repositories without absorbing unrelated changes

**Files:**
- Verify only; no planned source changes.

**Interfaces:**
- Consumes: Tasks 1 and 2.
- Produces: evidence that formatting, analysis, tests, and Android native integration remain healthy.

- [ ] **Step 1: Verify Flutter formatting**

```powershell
dart format --output=none --set-exit-if-changed lib test
```

Expected: `Formatted ... files (0 changed)`.

- [ ] **Step 2: Verify Flutter analysis**

```powershell
flutter analyze --no-fatal-infos --no-fatal-warnings
```

Expected: exit code 0 and no analyzer errors; existing repository warnings may remain.

- [ ] **Step 3: Run the complete Flutter suite**

```powershell
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Build the Android debug APK**

```powershell
flutter build apk --debug
```

Expected: `Built build\app\outputs\flutter-apk\app-debug.apk`.

- [ ] **Step 5: Re-run backend verification**

```powershell
dotnet test Milingo-Backend.sln --no-restore
dotnet build Milingo-Backend.sln --no-restore
```

Expected: all backend tests pass; build reports 0 warnings and 0 errors.

- [ ] **Step 6: Audit final repository state**

Confirm the mobile repository still leaves only the user's unrelated working-tree changes unstaged and the backend still leaves `.hatch-pet-runs/` untouched. Report the exact commits and verification results.
