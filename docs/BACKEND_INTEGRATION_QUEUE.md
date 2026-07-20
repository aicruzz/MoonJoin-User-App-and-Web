# Backend Integration Queue

**Single source of truth** for every frontend feature that is completed and approved but waiting for backend
(API / config / database / admin) implementation. Backend development MUST check this file before creating
APIs, models, or admin settings, and must adapt to the approved frontend contract — **never redesign the
frontend when backend starts.**

---

## MoonJoin Frontend Completion Status

- **User App:** ✅ Completed frontend migration (shared storefront foundation + Parcel).
- **Frozen foundation:** ✅ Shared Storefront Home ✅ Shared Store Page ✅ MoonJoin Store Card
  ✅ Store Hero Header ✅ Store Map Card ✅ Shared Quantity System ✅ Food Product Details
  ✅ Shared Product Details.
- **Modules completed (User App):** ✅ Food ✅ Grocery (incl. Market, Fuel & Gas, Drink Distributor,
  Solar & Power — all Grocery business-module type) ✅ Pharmacy ✅ Fashion / Ecommerce ✅ Parcel.
- **Pending:**
  - Backend integration queue only (the items below).
  - Vendor App frontend.
  - Delivery Man App frontend.
  - Rental frontend redesign (Car Rental + Short Apartment Rental — not started).

---

## Status Definition

**Frontend Complete — Waiting for Backend Integration**

Meaning:
- UI/UX is completed and approved.
- Frontend logic / state handling is prepared.
- Backend API / config / database / admin implementation is pending.
- Do **not** redesign the frontend when backend starts.
- Backend should adapt to the approved frontend contract.

---

## Feature Entry Template

```
Feature Name:   e.g. Parcel Package Protection
Module:         Food | Grocery | Pharmacy | Ecommerce | Parcel | Rental
App:            User App | Vendor App | Delivery Man App
Status:         Frontend Complete — Waiting for Backend Integration

Frontend Completed:      what already works
Frontend Files:          files changed
Required Backend Work:   API endpoints / DB fields / config fields / admin panel location /
                         validation rules / order/payment implications
Backend Integration Notes: exactly how backend connects without changing the frontend
```

---

## Features — Frontend Complete, Waiting for Backend

### 1. Parcel Package Protection

- **Module:** Parcel
- **App:** User App
- **Status:** Frontend Complete — Waiting for Backend Integration
- **Location:** User App → Parcel Request page → between **Delivery Man Tips** and **Charge Pay By**

**Frontend Completed**
- Package Protection section (premium card) with **Select / Unselect**.
- Expand/collapse animation; declared **package value** input (numeric, auto-focus + numeric keypad).
- **Protection fee** calculation (dynamic, never hardcoded in UI): `package_value × (percentage / 100)`.
- **Order Summary** integration (adds a "Package Protection" line) + **Total** update — instant, using the
  existing shared Order Summary calculation (no new total system).
- Validation: when selected, package value is required and must be > 0.
- Payment-flow compatible: uses the shared **Choose Payment Method** card; nothing about payment changed.
- Config-driven & gated on `packageProtectionEnabled` (shows/hides automatically).

**Frontend Files**
- `lib/common/models/config_model.dart` — nullable `packageProtectionStatus`, `packageProtectionPercentage`
  (parsed from `package_protection_status` / `package_protection_percentage`; null until backend sends them).
- `lib/features/parcel/controllers/parcel_controller.dart` — `packageProtectionEnabled`,
  `packageProtectionPercentage`, `packageProtectionSelected`, `packageValue`, `protectionFee`,
  `togglePackageProtection`, `setPackageValue`, `resetPackageProtection`; single isolated dev fallback
  (`TODO(BACKEND)`).
- `lib/features/parcel/screens/parcel_request_screen.dart` — the UI section + Order Summary line +
  Total addend + the `PACKAGE PROTECTION — BACKEND INTEGRATION POINT` marker at the place-order.
- `assets/language/{en,ar,es,bn}.json` — i18n keys.

**Required Backend Work**
- **Admin Panel:** Business Settings → Order Settings → **Package Protection** (place it before the Free
  Delivery Option).
- **Config fields** (returned in the config API, read by `ConfigModel`):
  - `package_protection_status` → 1/0 (enable/disable the whole section)
  - `package_protection_percentage` → **percent number**, e.g. `1.5` means **1.5%**
- **Calculation (must match frontend):** `package_value × (percentage / 100)`.
- **Order fields** (parcel place-order API — reuse the existing parcel order flow, no new order/payment
  system): `package_protection_selected` (bool), `package_value`, `package_protection_fee`; the backend
  should add the fee into the order total. `PlaceOrderBodyModel.extraPackagingAmount` (currently unused for
  parcel) is an available channel if preferred, otherwise add a dedicated field.
- **Validation rules:** if `package_protection_selected` is true, `package_value` must be > 0 and
  `package_protection_fee = package_value × percentage / 100`.

**Backend Integration Notes**
- Provide `package_protection_status` + `package_protection_percentage` in config → the frontend
  automatically shows/hides the section and computes the fee. **No UI / controller / calculation / widget
  change is required.** Then wire the three order fields at the documented place-order marker.

---

### 2. Parcel — "Why Choose Us" & "Get Service" (Video Content)

- **Module:** Parcel
- **App:** User App
- **Status:** Frontend Complete — Waiting for **Admin Configuration** (APIs already exist, return empty)
- **Location:** User App → Parcel Home / Category page → "Experience the best with us" & "Easiest way to get
  services".

**Frontend Completed** — both sections are redesigned/frozen and wrap the live backend responses; they render
automatically once data exists and collapse gracefully while empty.

**Required Backend Work** — no new API. Admin must configure the existing endpoints so they return data:
- `GET /api/v1/other-banners/why-choose` → `WhyChooseModel.banners[]` (image / title / short_description).
- `GET /api/v1/other-banners/video-content` → `VideoContentModel` (banner_type, banner_image_full_url /
  banner_video, banner_contents value pairs).
- Admin panel: the Parcel module's "Why Choose Us" and "Video Content / Get Service" sections.

**Backend Integration Notes** — populate the admin data; the frontend needs no changes.

---

## MoonJoin Development Rule (permanent)

**Before implementing backend, complete all frontend applications first:**
1. User App
2. Vendor App
3. Delivery Man App

- Any missing backend functionality must be documented here as **Frontend Complete — Waiting for Backend
  Integration**.
- Do **not** create temporary backend hacks unless approved.
- Do **not** redesign approved frontend when backend becomes available — backend adapts to the frontend
  contract.
- Reuse approved components.

---

## Reference — Admin/Config-Controlled Features (already backend-integrated)

These User-App features are **already wired to the backend** and are driven by config flags / admin settings.
They are **not pending** — listed only as a map so future backend/admin work knows where each is controlled.
Do not re-implement; configure via admin.

**Payment** — Cash on Delivery (`cash_on_delivery`), Wallet (`customer_wallet_status`, `add_fund_status`),
Digital payment + gateways (`digital_payment`, `active_payment_method_list`), **9PSB Virtual Account**
(`/api/v1/wallet/virtual-account`), Offline payment (`offline_payment_status` + offline methods), Partial
payment (`partial_payment_status`/`partial_payment_method`), COD max limit (`max_cod_order_amount`). Shared
"Choose Payment Method" card is the single implementation across all modules.

**Orders** — Delivery fees (per-km / minimum, incl. parcel `parcel_per_km_shipping_charge` /
`parcel_minimum_shipping_charge`), Free delivery, Taxes (`tax`, `tax_included`), Additional charge
(`additional_charge_status`/`name`/amount), Delivery-man tips (`dm_tips_status`), Home delivery / Takeaway
(`home_delivery_status`/`takeaway_status`), Refund/Cancellation/Shipping policies, Guest checkout
(`guest_checkout_status`).

**Admin-controlled content** — Banners (admin banner feed + store-wise + parcel-other banners), Categories,
Brands, Popular/Reviewed/Discounted product sections, Flash sale, Promotional cards.

**User features** — Loyalty points (`loyalty_point_status` + exchange rate), Referral earnings
(`ref_earning_status`), Coupons (`/api/v1/coupon/list`), Notifications, Profile verification
(`customer_verification`, `email_verification_status`, `phone_verification_status`), Prescription
(`prescription_status`).

**Module-specific**
- **Parcel:** Package Protection → **Waiting for Backend Integration** (see item 1 above). Why Choose Us /
  Get Service steps → **Waiting for Admin Configuration** (see item 2 above). Parcel categories, delivery
  instructions, cancellation reasons, distance/fee calc → already integrated.
- **Rental (Car Rental + Short Apartment Rental):** frontend **not yet redesigned** (existing `rental_module`
  = "taxi"). Short Apartment Rental will be built with mock repositories where the backend is missing; those
  mock/placeholder points will be added to THIS queue when Rental frontend work begins. Nothing to integrate
  yet.
