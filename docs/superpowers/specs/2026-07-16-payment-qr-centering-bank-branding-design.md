# Payment QR Centering, Bank Name, and VietQR Branding Design

## Goal

Improve the native PayOS payment screen without changing payment behavior:

- horizontally center the generated QR code inside its existing white save boundary;
- show the receiving bank's full legal name;
- identify the QR visibly as a VietQR transfer over NAPAS 247.

## Scope

This is a targeted extension of the existing native PayOS QR flow. It spans:

- Flutter mobile app: `C:/FPTUniversity/MILINGO/PROJECT/APP/Milingo-Mobile-App`
- ASP.NET Core backend: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend`

It does not change order creation, QR contents, webhook processing, polling,
reconciliation, subscription activation, expiration, or pending-order reuse.

## UX Design

### QR alignment

The existing full-width white QR container remains the `RepaintBoundary` used
when saving the image. Its child alignment becomes `Alignment.center`. The QR
remains 250 logical pixels and the surrounding padding remains unchanged.

### VietQR and NAPAS identification

A compact text branding row appears directly below the QR image and above the
save button:

`VietQR • Chuyển nhanh NAPAS 247`

The current repository does not contain official VietQR or NAPAS trademark
assets. This change therefore uses a restrained text badge rather than an
unofficially reconstructed logo. Official supplied logo assets can replace the
text treatment later without changing the payment data contract.

### Transfer information

The information section displays these rows in order:

1. Số tiền
2. Ngân hàng
3. Tên tài khoản
4. Số tài khoản
5. Nội dung chuyển khoản

The bank value is the full legal name, for example:

`Ngân hàng Thương mại Cổ phần Quân đội (MB)`

The bank row is informational and does not need a copy action because the bank
account number remains the transfer identifier users may need to copy.

## Backend Data Contract

The backend owns the receiving-bank display name because it already owns the
single configured PayOS payment channel. Runtime mobile calls to VietQR and a
mobile-maintained bank BIN dictionary are intentionally avoided.

Backend configuration adds:

```json
"PayOS": {
  "BankName": "Ngân hàng Thương mại Cổ phần Quân đội (MB)"
}
```

`CreatePayOSOrderResponse` adds:

```json
{
  "bin": "970422",
  "bankName": "Ngân hàng Thương mại Cổ phần Quân đội (MB)"
}
```

The backend persists `bankName` with new payment orders so a reused or recovered
QR displays the same information. When reading a legacy pending order that does
not contain `bankName`, the backend supplies the configured value and may merge
it into the stored document. Order recovery must not fail solely because the
legacy field is absent.

`PayOS:BankName` is required for new order creation. This prevents a successful
payment screen from silently displaying a blank or guessed bank name.

## Flutter Data Flow

`CreatePayOSOrderResponse` parses the required `bankName` response field. The
existing payment route passes the same typed order into `PaymentQrScreen`, and
`PaymentQrView` renders `order.bankName` in the new bank row.

No extra HTTP call is introduced. The QR screen continues polling only for
payment status; bank metadata arrives with the create/recovery response.

## Error and Compatibility Behavior

- A newly created backend order fails clearly if the configured legal bank name
  is missing.
- Legacy stored pending orders use the configured legal bank name.
- Flutter treats a missing `bankName` from an outdated backend as empty data,
  but the payment screen falls back to `Ngân hàng (BIN: <bin>)` so checkout is
  still usable during a staggered deployment.
- QR saving still captures only the existing white QR boundary. The branding
  row and transfer details remain outside the saved QR image.

## Testing

Backend tests cover:

- `bankName` in the create-order response contract;
- persisted/recovered orders retaining the configured bank name;
- legacy pending orders receiving the configured fallback.

Flutter tests cover:

- parsing `bankName`;
- rendering the full legal bank name and VietQR/NAPAS text;
- matching the horizontal center of the QR widget to its white container;
- preserving existing copy, save, expiry, and status behavior.

## Non-Goals

- Fetching the VietQR bank directory at runtime.
- Adding bank deep links or launching a mobile banking application.
- Changing the encoded PayOS QR payload.
- Redesigning the payment screen outside the requested alignment and metadata.
- Replacing text branding with unofficial logo artwork.
