# Pearl Nest Mobile: Finance API and Page Handoff

This is a mobile-focused implementation guide for the booking, payment, refund,
landlord wallet, withdrawal, and account-activity work. It describes the API
currently present in the adjacent backend repository and the Flutter screens
that should use it.

## API connection and authentication

The mobile app's API base URL is configured in
[`lib/apis/app_config.dart`](lib/apis/app_config.dart). It defaults to
`https://admin.pearlnestestates.com`; development URLs can be supplied through
environment variables.

Authenticated API calls are made through `ApiClient` in
[`lib/apis/api_client.dart`](lib/apis/api_client.dart), which attaches the
stored bearer token. Unless noted otherwise, the routes below require a signed
in user:

```http
Authorization: Bearer <accessToken>
Content-Type: application/json
```

The backend typically returns `{ "success": true, "data": ... }`, but some
older payment endpoints return raw data or inconsistent error envelopes.
Handle response shapes explicitly rather than assuming every endpoint matches.
Backend controllers are in the sibling `../pearl_nest_backend/src/` directory.

## Pages and mobile files affected

| Mobile page / flow | File(s) | API responsibilities |
|---|---|---|
| Tenant booking and quote | `lib/screens/tenant/booking_screen.dart`, `lib/blocs/booking/booking_bloc.dart`, `lib/apis/booking_service.dart` | Fetch authoritative quote, create booking, then start payment and open provider checkout. |
| Booking history and balances | `lib/screens/tenant/bookings_list_screen.dart`, `lib/models/booking.dart` | Show booking/payment statuses and paid/outstanding amounts; allow retrying an unpaid balance; link completed payments to refund request. |
| Tenant refund request and history | `lib/screens/tenant/refund_request_screen.dart`, `lib/apis/refund_service.dart` | Submit a refund against a completed payment and show the request's current review/payout status. |
| Landlord refund review | `lib/screens/landlord/landlord_refunds_screen.dart`, `lib/apis/refund_service.dart` | View refund requests for the landlord's properties and send a recommendation to the administrator. |
| Landlord wallet and withdrawals | `lib/screens/landlord/landlord_wallet_screen.dart`, `lib/apis/payment_service.dart`, `lib/apis/withdrawal_service.dart` | Show earnings, commission, refunds, reserved funds, wallet history; submit a withdrawal request and show its status. |
| Payment return/deep link | `lib/services/deep_link_service.dart`, `lib/apis/payment_service.dart` | Verify final payment state with the backend after returning from the provider. This path currently does not match the backend route; see integration issues below. |
| User profile (context only) | `lib/screens/tenant/profile_screen.dart`, `lib/screens/tenant/edit_profile_screen.dart`, `lib/apis/auth_service.dart` | Fetch or update the signed-in user's profile. There is no mobile admin user-activity page at present. |

The most recent mobile repository change is `4b08a38` ("Update Pearl Nest mobile
app"); the backend changes include dynamic booking configuration and finance
work. The notes below describe current checked-in code, not a proposed API
contract.

## Booking and payment lifecycle

Expected tenant flow:

1. Select the property and dates/payment option.
2. Call `GET /booking/quote` and render the returned amounts.
3. Call `POST /booking/create`. The backend recalculates and stores its own
   quote; do not treat a client-supplied amount as authoritative.
4. Read the created booking ID and call `POST /payments/create` with the quoted
   due-now amount and payment type `MOBILE_MONEY`.
5. Open the returned Pesapal `redirect_url`.
6. On return, ask the backend for verified payment state, refresh the booking,
   and show paid and remaining balances.

### Booking endpoints

| Method and path | Access | Purpose and response |
|---|---|---|
| `GET /booking/quote?propertyId=...&checkInDate=YYYY-MM-DD&checkOutDate=YYYY-MM-DD&paymentOption=FULL` | Signed in | Returns a quote under `data`: `bookingPurpose`, `paymentOption`, `nights`, `baseAmount`, `bookingFeeAmount`, `transactionFeeAmount`, `totalAmount`, `amountDueNow`, `transactionFeePercent`, and `paymentOptions`. Date parameters are needed for short stays. Supported options are `DEPOSIT`, `HALF`, and `FULL`. |
| `POST /booking/create` | Signed in | Creates a booking for the authenticated user. Request body: `propertyId`, optional `checkInDate`, `checkOutDate`, optional `amount`/`deposit`, and optional `paymentOption`. The backend derives the final amount from its quote. Response is `{ success, data: booking }`. |
| `GET /booking/list` | Signed in | Lists the current user's bookings, including property and `Payments`. |
| `GET /booking/landlord/list` | Signed in landlord | Lists bookings associated with the landlord's properties. |
| `DELETE /booking/cancel/:bookingId` | Booking tenant, property owner, or admin | Cancels a booking; for rentals, the current service makes the property available again. |
| `PATCH /booking/status/update/:bookingId/:status` | Property landlord or admin | Changes booking status. The service sends tenant notification/email for approval or rejection. |

Backend source: `../pearl_nest_backend/src/booking/booking.controller.ts` and
`booking/booking.service.ts`.

### Payment endpoints

| Method and path | Access | Purpose and response |
|---|---|---|
| `POST /payments/create` | Signed-in booking owner | Request body: `{ "propertyId": "...", "bookingId": "...", "amount": 12345, "paymentType": "MOBILE_MONEY", "sendEmail": true }`. `userId` is derived from the access token; do not send it as authority. The backend checks ownership and outstanding amount, creates a Pesapal order, and returns nested provider data, including `data.paymentInfo.redirect_url` and `data.paymentInfo.order_tracking_id`. |
| `GET /payments/list?page=1&limit=20` | Signed in | Lists the caller's payment records. |
| `GET /payments/paymentsPerBookingPerUser` | Signed in | Returns that user's payment totals grouped by booking. |
| `GET /payments/booking/:bookingId` | Booking tenant, property landlord, or admin | Returns payment records for a booking. |
| `GET /payments/transactionStatus/:orderTrackingId` | Authenticated by `AuthGuard` | Queries Pesapal transaction status. Backend code calls the provider and returns `{ success, data }`; verify authorization/ownership before using it as a tenant-facing status API. |

Payment states include `PENDING`, `BOOKED`, `APPROVED`, `CANCELLED`, and
`REJECTED`. The booking flow treats `BOOKED` and `APPROVED` payment records as
paid.

### Current mobile checkout gap

`BookingScreen._submitBooking()` dispatches `BookingCreateRequested`, which
creates a booking, but does not dispatch the existing `CreatePayment` event.
The success dialog then says "Proceed to Payment" but currently navigates to
the bookings list. This does not start provider checkout. The bookings list
also has no clear action to pay the remaining booking balance.

Implement checkout using the quote's `amountDueNow` and created booking ID.
After a user returns from Pesapal, refresh booking/payment data rather than
assuming the redirect means payment succeeded.

## Refunds

Refunds are a **manual payout workflow**. The API records review decisions and
the transfer reference; it does not transfer money automatically.

| Method and path | Access | Purpose and required data |
|---|---|---|
| `POST /refunds` | Tenant who made the payment | Submit `{ paymentId, amount, reason, destinationMethod, destinationName, destinationAccount, destinationProvider? }`. Amount must be a positive whole number. `reason` must be 5–2000 characters. Destination method is `MOBILE_MONEY` or `BANK`; bank destination requires a provider/bank name. Only a completed payment owned by the tenant is eligible. The server enforces the remaining refundable balance. |
| `GET /refunds/mine` | Signed-in tenant | Lists the current tenant's refund requests. |
| `GET /refunds/landlord` | Landlord (admin is also allowed by the controller) | Lists refund requests for properties owned by the caller. |
| `POST /refunds/:id/landlord-review` | Owning landlord | Submit `{ decision: "APPROVE" | "REJECT", note? }`. A rejection recommendation requires a note. This is a recommendation, not the final decision. |
| `GET /refunds/admin` | Admin | Lists all refund requests. This is for the admin dashboard, not the mobile landlord/tenant app. |
| `PATCH /refunds/:id/admin-review` | Admin | Submit `{ decision: "APPROVE" | "REJECT", note? }`. Rejection requires a reason. Admin can make the final decision before or after a landlord recommendation. |
| `PATCH /refunds/:id/complete` | Admin | Submit `{ reference: "manual transfer receipt/reference" }` after paying. Only an approved refund can be completed. |

Normal status path:

```text
PENDING_LANDLORD
  -> PENDING_ADMIN
  -> APPROVED or REJECTED
  -> COMPLETED (only approved requests; admin records the manual payout)
```

Even a landlord's `REJECT` recommendation moves the request to
`PENDING_ADMIN`; the administrator makes the final decision. The tenant and
landlord receive email updates at key transitions. Completed refunds affect
wallet earnings and commission reconciliation.

Backend source: `../pearl_nest_backend/src/refunds/refunds.controller.ts` and
`refunds/refunds.service.ts`.

## Landlord wallet and withdrawals

### Wallet summary

`GET /payments/landlord/wallet` is available to an authenticated landlord (and
admin). It returns `{ success, data }`, where `data` contains:

- `summary.grossPayments`: confirmed payments for the landlord's properties.
- `summary.commission`: commission after commission returned for completed
  refunds.
- `summary.refunds`: completed refund amounts.
- `summary.availableEarnings`: gross payments less commission and completed
  refunds, with the refunded commission added back.
- `summary.reservedWithdrawals`: requests in `PENDING` or `APPROVED`.
- `summary.paidWithdrawals`: withdrawals marked `PAID`.
- `summary.availableForWithdrawal`: amount the landlord can currently request.
- `withdrawals`: the landlord's withdrawal requests.
- `monthly`: per-month gross payments, commission, refunds, commission
  reversals, and net earnings.
- `activity`: recent payment, completed refund, and withdrawal entries.

The service computes the available amount approximately as:

```text
confirmed payments
- commission
- completed refunds
+ commission reversed for refunded amounts
- pending/approved withdrawal reservations
- already-paid withdrawals
```

This is a computed wallet view, not a separate stored account balance.

### Withdrawal endpoints

| Method and path | Access | Purpose and required data |
|---|---|---|
| `POST /payments/landlord/withdrawals` | Landlord | Submit `{ amount, destinationMethod, destinationName, destinationAccount, destinationProvider? }`. Amount must be a positive integer within `availableForWithdrawal`. Destination is `MOBILE_MONEY` or `BANK`; bank requires a provider name. The API reserves the amount while it is pending or approved. |
| `GET /payments/admin/withdrawals/summary` | Admin | Counts pending and approved requests. |
| `GET /payments/admin/withdrawals` | Admin | Lists requests with landlord profile details. |
| `PATCH /payments/admin/withdrawals/:id/review` | Admin | Submit `{ decision: "APPROVE" | "REJECT", note? }`. Rejection requires a note. |
| `PATCH /payments/admin/withdrawals/:id/paid` | Admin | Submit `{ reference: "transfer receipt/reference" }` after manual payment. Only an approved withdrawal can be marked paid. |

Withdrawal statuses are `PENDING`, `APPROVED`, `REJECTED`, and `PAID`.
Approval is **not** a payment: an administrator must transfer the funds
manually, then record the transfer reference. Admin routes are documented for
context; the mobile landlord app must not call them.

Backend source: `../pearl_nest_backend/src/payments/payments.controller.ts` and
`payments/payments.service.ts`.

## Configuration used by booking quotes

| Method and path | Access | Purpose |
|---|---|---|
| `GET /configuration/booking-settings` | Public | Returns `generalBookingFee`, `saleVisitFee`, `adminCommissionPercent`, and `transactionFeePercent`. |
| `GET /configuration/property-types` | Public | Returns active property types and their `bookingMode` (`STANDARD` or `SHORT_STAY`). Mobile `PropertyService` caches this response for 10 minutes. |
| `PATCH /configuration/booking-settings` | Admin | Changes fees and commission; not a mobile user action. |
| `POST /configuration/property-types` | Admin | Adds a property type; not a mobile user action. |
| `DELETE /configuration/property-types/:id` | Admin | Deactivates a property type; not a mobile user action. |

Backend source: `../pearl_nest_backend/src/configuration/configuration.controller.ts`.

## User activity and account data

There is **no mobile endpoint for an admin activity feed** in the tenant or
landlord app. The backend route `GET /user/admin/:userId/activity` is restricted
to administrators and is used by the web dashboard. It returns user profile
data, counts, and up to five recent properties, bookings, payments, favorites,
views, shares, reviews, and notifications; up to three landlord registration
records are included. It is not a full audit log and currently does not include
refunds or withdrawals.

Mobile account/profile operations use these routes:

- `GET /user/userProfile/fetch` — fetch the signed-in user's profile.
- `PATCH /user/userProfile/update` — update the signed-in user's profile.

Do not expose the admin activity endpoint on tenant or landlord screens. If
support/admin needs financial activity later, extend the admin API deliberately
to include refund and withdrawal records and appropriate audit history.

## Integration gaps to resolve

1. **Start payment from mobile booking.** Quote and create the booking, then
   call `/payments/create` with the created booking ID and quote amount. Open
   `redirect_url`; do not just show a "Proceed to Payment" button that returns
   to bookings.
2. **Use a backend route that exists for payment status.** The current mobile
   `PaymentService.checkPaymentStatus()` calls
   `/payments/status/:orderTrackingId`, which is not present in the backend
   controller. The existing provider lookup route is
   `/payments/transactionStatus/:orderTrackingId`; decide whether to use that
   route or add a secure, ownership-checked app endpoint that returns the
   stored payment and booking state.
3. **Do not trust a provider redirect as proof of payment.** Confirm status
   server-side and refresh the booking. The backend also has
   `POST /notifications/ipn` for provider notification. Treat provider callbacks
   as untrusted until the backend verifies the transaction with the provider.
4. **Align callback routes and return URLs.** Mobile
   [`deep_link_service.dart`](lib/services/deep_link_service.dart) expects
   `pearlnest://payment` with a `payment_id`, while backend payment creation
   currently returns users to the dashboard website. Set up a supported mobile
   return/deep-link flow and pass the Pesapal `order_tracking_id` expected by
   the status-check route.
5. **Replace stale mobile payment APIs.** `PaymentService.getUserPayments()`
   calls `/payments/user/:userId`, which does not exist in the backend.
   `/payments/list` or `/payments/paymentsPerBookingPerUser` are the current
   user-scoped alternatives. Prefer `/booking/list` when the screen needs
   bookings with their associated payments.
6. **Keep the booking total and wallet math consistent.** The backend has
   `totalAmount`, partial payment options, booking fees, and transaction fees.
   Display the server quote, use successful payments only when computing the
   paid amount, and do not assume every booking total is the property's deposit.
7. **Surface manual finance states.** Show refund review progress and withdrawal
   reservation/approval/payment progress. Explain that admin approval does not
   itself initiate a payout.
8. **Add mobile finance tests.** Cover quote display, payment initiation and
   cancellation/return, partial balance retry, each refund status, withdrawal
   validation, and server-side balance rejection. Keep provider credentials out
   of the app; all provider operations belong on the backend.

## Related API implementation files

- Booking: `../pearl_nest_backend/src/booking/booking.controller.ts`,
  `booking/booking.service.ts`
- Payments and wallet: `../pearl_nest_backend/src/payments/payments.controller.ts`,
  `payments/payments.service.ts`
- Refunds: `../pearl_nest_backend/src/refunds/refunds.controller.ts`,
  `refunds/refunds.service.ts`
- Booking configuration: `../pearl_nest_backend/src/configuration/configuration.controller.ts`,
  `configuration/configuration.service.ts`
- Admin activity: `../pearl_nest_backend/src/user/user.controller.ts`,
  `user/user.service.ts`
- Provider callback: `../pearl_nest_backend/src/notifications/notifications.controller.ts`,
  `notifications/notifications.service.ts`
