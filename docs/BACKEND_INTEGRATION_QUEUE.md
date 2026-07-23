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
  - Rental frontend redesign: ✅ **Screen 1 Rental Home (FROZEN)** ✅ **Screen 2 All Car Rentals (FROZEN)**
    ✅ **Screen 3 Provider List (ABSORBED INTO SCREEN 2, FROZEN)** ✅ **Screen 4 Provider Details (FROZEN)** ✅ **Vehicle Details (FROZEN)** ✅ **Checkout (FROZEN, MASTER payment implementation)** ✅ **Booking Success (FROZEN)** — **CAR RENTAL FLOW COMPLETE**;
    next → **Short Apartment Rental flow**: ✅ **Apt Screen 1 listing FROZEN** ✅ **Apt Screen 2 Provider
    Details FROZEN (auto-activating)** ✅ **Section scoping FROZEN (item 18)** ✅ **Popular sections FROZEN** ✅ **Apt Details FROZEN** ✅ **Apt Checkout FROZEN (master reuse)** ✅ **Apt Booking Success FROZEN (shared sheet)**;
    next → Apartment Details, then Booking History for both flows.

---

## Status Definition

**Frontend Complete — Waiting for Backend Integration**

Meaning:
- UI/UX is completed and approved.
- Frontend logic / state handling is prepared.
- Backend API / config / database / admin implementation is pending.
- Do **not** redesign the frontend when backend starts.
- Backend should adapt to the approved frontend contract.

**Frontend Complete — Waiting for Backend/Vendor Integration**

Same as above, but the feature ALSO requires Vendor App and/or Admin Panel work before it can function
(e.g. vendors must be able to declare what their provider supports). The User App renders the complete UI and
prepares every integration point; controls that depend on the missing capability stay **inert** — never faked,
never wired to an unrelated flow, never fed placeholder data.

**Permanent rule.** When a feature cannot work because backend or vendor functionality does not exist yet, the
User App must still: render the complete UI · prepare all integration points · avoid fake data · avoid fake
behaviour · document the exact Backend / Vendor / Admin contract here. Backend and Vendor App work then starts
from a precise contract instead of rediscovering requirements.

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

### 3. Rental Home — Hero Images (Car Rental & Apartment Rental)

- **Module:** Rental (Car Rental + Short Apartment Rental)
- **App:** User App
- **Status:** Frontend Complete — Waiting for Backend Integration
- **Location:** User App → Rental Home (Car & Apt Rental) → the two hero cards near the top.

**Frontend Completed**
- The two hero cards render a **dynamic, backend-ready image** (no fixed/hardcoded hero artwork in the
  frontend). Each card has a **dominant, premium image area** (128px tall, full-width, rounded) that supports
  large portrait/landscape promotional images with **`BoxFit.cover` (aspect ratio preserved, no stretching)**.
- Images currently load from **temporary placeholder assets** (`kPlaceholderCarHeroImage`,
  `kPlaceholderAptHeroImage`) via the shared `CustomImage` widget, which already supports remote URLs +
  graceful placeholder fallback — so swapping to admin URLs needs **no widget change**.

**Frontend Files**
- `lib/features/rental_module/apartment_placeholder/apartment_placeholder.dart` — `kPlaceholderCarHeroImage`,
  `kPlaceholderAptHeroImage` (`TODO(BACKEND)`).
- `lib/features/rental_module/home/screens/taxi_home_screen.dart` — `_heroCard` renders the dynamic image.

**Required Backend Work — full Hero Card contract (not just the image)**
- **Admin location:** Car & Apt Rental → Sidebar → **Dashboard** → **Hero Cards**, placed **after Trip
  Management** and **before Promotion Management**.
- Admin manages the **two hero cards separately** (Car Rental, Short Apartment Rental), each supplying:

| Field | Purpose | Frontend param (already exists) |
|---|---|---|
| `image_full_url` | hero image | `image` |
| `title` | card heading | `title` |
| `subtitle` | supporting line | `desc` |
| `cta_text` | button label | `buttonText` |
| `cta_action` | where the button goes | `onExplore` |
| `sort_order` | display order of the cards | list order |
| `status` | enable / disable the card | card shown or omitted |
| `target` | `car_rental` \| `apartment_rental` \| `both` — which home(s) the card appears on | which home renders it |

- The frontend `_heroCard` **already takes the five content inputs** (image, title, subtitle, CTA text, CTA
  action), so the backend response maps 1:1. `sort_order`, `status` and `target` are list-level concerns
  handled where the cards are assembled — a disabled card is omitted, ordering follows `sort_order`, and
  `target` selects which home (Combined / Car Rental / Apartment Rental) renders each card. **No widget change.**
- No production copy is hardcoded: titles/subtitles/CTA labels currently come from the i18n layer and the
  images from the two placeholder constants — all five are single, clearly marked swap points.

**Backend Integration Notes** — return the two hero card objects; bind them to the five existing params.
No layout / widget / UI change required.

---

### 4. Rental Home — Categories (⚠️ ALREADY BACKEND-INTEGRATED — only the car/apartment split is missing)

- **Module:** Rental (Car Rental + Short Apartment Rental)
- **App:** User App
- **Status:** **Backend already exists and is wired** — nothing hardcoded. Only **category type
  (Car vs Apartment)** is missing, which is expected until Apartment Rental has a backend.

**Audit result (existing backend — REUSED, not recreated)**
| Capability | Exists? | Where |
|---|---|---|
| Category list API | ✅ | `GET /api/v1/rental/vehicle/category-list` (`AppConstants.getVehicleCategoriesUri`) |
| Category model (id / name / image_full_url) | ✅ | `VehicleCategoryModel` |
| Controller fetch | ✅ | `TaxiHomeController.getVehicleCategoryList()` |
| Category IDs + selection state | ✅ | `TaxiHomeController.selectedCategoryIds` / `addOrRemoveCategory(id)` |
| Backend filtering by category | ✅ | `getSelectedCars(... categoryIds: _selectedCategoryIds ...)` |
| **Category type (Car vs Apartment)** | ❌ | **missing — see below** |
| **Parent categories** | ❌ | not present (not currently needed) |

**Frontend Completed** — Rental reuses the approved **MoonJoin Category UI/UX** while preserving the Rental
module's **existing backend category filtering behaviour**. The row renders the **real backend categories**
(admin: Car & Apt Rental → Vehicle Management → Categories). Category **names, images and count are 100%
backend-driven** — nothing hardcoded. Uses the shared `MoonjoinCategoryTile`, with a leading **"All"** tile
active by default when nothing is selected, and selection driven by the **existing** controller state.
Creating / renaming / deleting a category in admin needs **no frontend change**.

**Frontend Files**
- `lib/common/widgets/moonjoin/moonjoin_category_tile.dart` — shared MoonJoin category tile.
- `lib/features/rental_module/home/screens/taxi_home_screen.dart` — `_categoryChips` (backend-driven).
- `lib/features/rental_module/home/controllers/taxi_home_controller.dart` — additive
  `clearSelectedCategories()` (the "All" tile); all existing filter logic untouched.

**Required Backend Work (the only gap)**
- Add a **category type** (e.g. `type: car | apartment`) to the Rental category model + list API, so:
  - **Combined Rental Home** → show all categories (current behaviour, already works).
  - **Car Rental Home** → only `car` categories.
  - **Apartment Rental Home** → only `apartment` categories.
- Extend the existing filter endpoints to accept that type. **Do not create a new category system** — extend
  the existing one.

**Backend Integration Notes** — add the type field + an optional `type` query param to the existing
`category-list` endpoint. The frontend then passes the type per home screen; no redesign, no new widget.

---

### 5. Car Rental Listing — Browse-mode filtering (no trip context)

- **Module:** Rental (Car Rental) · **App:** User App
- **Status:** Frontend Complete — Waiting for Backend Integration
- **Location:** User App → Rental Home → Explore Cars / See All → **All Car Rentals** listing.

**Existing backend limitation (audited)**
- `getTopRatedCarList(offset)` — the browse endpoint (`/api/v1/rental/vehicle/top-rated`) accepts **only an
  offset**. No category, brand, sort, price, seating or drive-type parameters.
- `category_ids` (and every other filter) exists **only** on `getSelectedCars(...)`
  (`/api/v1/rental/vehicle/search/`), which **requires `pickupTime` + pickup location** — the controller
  null-asserts `finalTripDateTime!` and `fromAddress!`.
- `getVehicleCategories(offset)` returns the category **list** only; it is not a filtering endpoint.

**Conclusion: there is NO browse-mode filtering in the Rental backend today.**

**Frontend Completed** — the listing renders the approved filter affordances (Filters, Sort, Self Drive, With
Driver, Top Rated, Search, Category) using approved shared components, and **none of them fake filtering**.
Each one routes into the **existing approved trip-context flow** (pickup location → date → time), which
continues to `SelectVehicleScreen` where the existing backend performs the real filtering. This is the single
filtering flow — no second filtering implementation exists.

**Required Backend Enhancement**
- Allow filtering **without trip context** — either add the filter params to the browse endpoint
  (`category_ids`, `brand_ids`, `sort`, `min_price`/`max_price`, `seating_capacity`, `air_condition`,
  drive type) **or** make `pickup_time` / `pickup_location` optional on the search endpoint.
- Once available, the listing can filter in place; the chips simply call the existing controller instead of
  opening the trip flow. **No UI redesign required.**

---

### 6. Rental Brands — missing `vehicles_count`

- **Module:** Rental (Car Rental) · **App:** User App
- **Status:** Frontend Complete — Waiting for Backend Integration
- **Location:** All Car Rentals listing → **Top Brands** section.

**Existing backend limitation** — the rental brand list (`/api/v1/rental/vehicle/brand-list` → `Brands`)
returns `id`, `image`, `name`, `image_full_url` only. There is **no vehicle count**, so the design's
"50+ cars" line cannot be populated.

**Frontend Completed** — reuses the approved shared `TopBrandCard`. Because no count exists, Rental passes
`showCount: false` so the count line is **hidden** rather than showing a fabricated `0+`. `showCount` is a new
**optional, backward-compatible** parameter defaulting to `true`, so Food/Grocery/Pharmacy/Fashion/Parcel
render exactly as before. No duplicate brand card was created.

**Required Backend Enhancement** — expose `vehicles_count` per rental brand.

**Backend Integration Notes** — when the field lands, pass it as `itemCount` and drop `showCount: false`.
**No widget redesign required.**

---

### 7. Rental Category **Type** (Dashboard / Car Rental Home / Apartment Rental Home)

- **Module:** Rental · **App:** User App
- **Status:** Frontend Complete — Waiting for Backend Integration
- **Admin location:** Car & Apt Rental → **Vehicle Management → Categories**

**Existing backend limitation** — Category Management has only **one** category type. `/api/v1/rental/vehicle/category-list`
returns a flat list (`id`, `name`, `image`, `image_full_url`) with **no type/scope field**. Every rental category
therefore appears on **both** Rental Home (Screen 1) and All Car Rentals (Screen 2).

**Required Backend Enhancement** — add a **Type** field when creating a category, so each category belongs to
exactly one surface:

| Type | Shown on | Example |
|---|---|---|
| `dashboard_page` | Rental Home (Screen 1) | Featured |
| `car_rental_home` | Car Rental Listing (Screen 2) | SUV, Luxury |
| `apartment_rental_home` | Apartment Listing (future) | Beach Apartment |

Expose it on the category model and accept an optional `type` filter on `category-list`.

**Frontend Integration Point** — both screens call the same
`TaxiHomeController.getVehicleCategoryList()` and render via the shared `MoonjoinCategoryTile`. When `type`
exists, each screen passes its own type (or filters the returned list by type). **No UI redesign required.**
Until then the current shared-category behaviour is intentionally retained — nothing faked.

---

### 8. Rental Browse — Category filtering of the Popular sections (Screen 1)

- **Module:** Rental · **App:** User App
- **Status:** Frontend Complete — Waiting for Backend Integration

**Desired behaviour** — selecting a Dashboard category on Rental Home updates only the **Popular Car Rentals** /
**Popular Apartment Rentals** sections below the rotating banner; no selection shows everything (current, correct).

**Existing backend limitation** — the browse endpoint `getTopRatedCarList(offset)`
(`/api/v1/rental/vehicle/top-rated`) accepts **only an offset**. It has no `category_ids` parameter, so the
Popular sections cannot be filtered by category. (`category_ids` exists only on `getSelectedCars`, which
requires pickup time + location — see item 5.)

**Required Backend Enhancement** — accept `category_ids` (and ideally a `type`) on the top-rated/browse endpoint.

**Frontend Integration Point** — the selection state already exists (`selectedCategoryIds`,
`addOrRemoveCategory`, `clearSelectedCategories`). When the endpoint accepts the param, pass it and the
sections filter in place. **No UI redesign required.** Default "All" behaviour is preserved meanwhile.

---

### 9. Rental **Provider** listing, filtering & provider banners

- **Module:** Rental · **App:** User App
- **Status:** **Frontend Complete — Waiting for Backend/Vendor Integration**
- **Location:** All Car Rentals → filter chips (Self Drive / With Driver / Top Rated) → provider results.

**Desired behaviour** (mirroring the approved Food All-Restaurants experience): tapping a chip filters the
**provider** list below Top Brands (Self Drive → providers offering self-drive; With Driver → providers offering
driver service; Top Rated → providers sorted by rating); provider banners update; tapping a provider opens that
provider's vehicle listing.

**Existing backend limitation — this has NO backend at all.** Every provider endpoint requires an ID that is
already known:
| Endpoint | Requires |
|---|---|
| `/api/v1/rental/provider/get-provider-details/{id}` | provider id |
| `/api/v1/rental/banners/{id}` (provider banners) | provider id |
| `/api/v1/rental/vehicle/get-provider-vehicles?provider_id=` | provider id |
| `/api/v1/rental/provider/get-provider-reviews/{id}` | provider id |

There is **no provider list / provider search endpoint**, and no self-drive, with-driver or rating filter or
sort. A provider list therefore cannot be rendered or filtered at all — so this was **not** implemented and
**not** faked.

**Current frontend behaviour (production-ready, nothing faked)** — the chips are **fully rendered** and
**inert**: they do NOT navigate to the pickup-location flow (that is not what they mean) and they do NOT fake
filtering. They activate unchanged the moment the endpoints below exist.

**Required BACKEND work**
1. **Provider List endpoint** (paginated), e.g. `GET /api/v1/rental/provider/list?offset=&limit=`, returning per
   provider: `id`, `name`, `logo_full_url`, `cover_banner_full_url`, `rating`, `rating_count`,
   `provider_type`, `self_drive` (bool), `with_driver` (bool), `featured` (bool), `popular` (bool),
   `verified` (bool), `categories[]`, `location`/`zone`, `distance`, `service_availability`.
2. **Filter / sort / search params:** `self_drive`, `with_driver`, `sort=rating|popular|featured`,
   `category_ids`, `location`/`zone`, `search`.

**Required VENDOR APP work** — vendors configure their own provider profile:
`Supports Self Drive` · `Supports Driver Service` · `Provider Categories` · `Featured Provider` ·
`Operating Area` · `Service Availability` · `Cover Banner` · `Logo` · `Gallery` · `Rating settings`.

**Required ADMIN work** — **Car & Apt Rental → Provider Management**:
`Provider List` · `Provider Approval` · `Featured Providers` · `Top Rated Providers` · `Self Drive Providers` ·
`With Driver Providers` · `Provider Categories` · `Provider Banner Management`.

**Frontend Integration Point** — once the list endpoint exists, the provider list slots in below Top Brands,
reusing the **approved MoonJoin store/restaurant card + provider banner components** (Rental data only, no
redesign — see COMPONENTS.md), and the existing chips call it. Provider → vehicle listing navigation already
exists (`get-provider-vehicles`, which already supports `category_ids`). **No UI redesign required.**

---

### 10. Rental Provider Adapter (Temporary Production Adapter) + Provider backend

- **Module:** Rental · **App:** User App
- **Status:** **Frontend Complete — Waiting for Backend/Vendor Integration**
- **Location:** All Car Rentals → Provider banners → Provider page → Vehicle list.

**The adapter (today vs future)**

```
TODAY    Vehicle API → group by provider.id → RentalProviderCard
FUTURE   Provider List API →                  RentalProviderCard
```

Every vehicle returned by the existing vehicle APIs embeds a **real backend `Provider`
object** (`id`, `name`, `logo_full_url`, `cover_photo_full_url`, `avg_rating`, `rating_count`, `discount`).
`RentalProviderAdapter` groups the loaded vehicles by `provider.id` and aggregates each provider's **feature
badges** from real vehicle fields (`air_condition`, `tag`, `fuel_type`, `transmission_type`, `type`,
`seating_capacity`). **Nothing is fabricated — a badge appears only because the backend returned that value.**

**Known limitation** — the derived list contains only providers that have a vehicle in the currently loaded
page, so it is **not a complete provider directory** and paginates by vehicles, not providers.

**When the Provider List endpoint ships, replace ONLY the adapter. `RentalProviderCard` must not change.**

**Required BACKEND work**
- **Provider List endpoint** + **provider pagination** · **provider filtering** · **provider search** ·
  **provider sort**
- Provider fields: **Self Drive** · **With Driver** · **Featured Provider** · **Verified Provider** ·
  **Operating Area** · **Availability** · **Gallery** · **Provider categories** · **Provider vehicle count**

**Required VENDOR APP work** — vendors configure their own provider profile:
**Self Drive toggle** · **Driver Service toggle** · **Featured toggle** · **Category assignment** ·
**Banner upload** · **Gallery upload** · **Availability** · **Operating Area** · **Vehicle Features**

**Required ADMIN work** — **Provider Management**:
**Featured** · **Top Rated** · **Self Drive** · **With Driver** · **Category** · **Banner Management** ·
**Approval** · **Verification** · **Availability** · **Statistics**

**Frontend Files**
- `lib/features/rental_module/provider_adapter/rental_provider_adapter.dart` — the adapter (the ONLY file that
  changes when the endpoint ships).
- `lib/features/rental_module/provider_adapter/rental_provider_card.dart` — permanent provider banner
  (visual clone of `MoonjoinStoreCard`).
- `lib/features/rental_module/home/screens/all_vehicle_screen.dart` — renders the provider list.

---

### 11. All Car Rentals — inert affordances (Filters, Brands, browse category filtering)

- **Module:** Rental · **App:** User App
- **Status:** **Frontend Complete — Production Ready — Waiting for Backend Integration**

**Rule applied:** an affordance whose backend does not exist is rendered but **inert**. It is never wired to an
unrelated screen (previously these opened the Location page, which was wrong) and never fakes filtering.

| Affordance | State today | Why |
|---|---|---|
| **Sort** | ✅ working | client-side sort of loaded vehicles by real price (`day_wise_price`/`hourly_price`) — Food pattern |
| **Top Rated** | ✅ working | client-side sort by real `avg_rating` — Food pattern |
| **Filters** | inert | multi-criteria filtering exists only on `getSelectedCars`, which requires pickup time + location |
| **Self Drive / With Driver** | inert | no such field on any vehicle/provider model, and no provider list endpoint |
| **Category (browse)** | inert | browse endpoint `top-rated` accepts only an offset; `category_ids` requires trip context |
| **Top Brands card** | inert | no brand-filtered browse endpoint |

**Required Backend Enhancement** — accept `category_ids`, `brand_ids`, `sort`, price/seating/AC and drive-type
params on the browse endpoint **without** requiring `pickup_time`/`pickup_location`; add `self_drive` /
`with_driver` to the vehicle/provider models.

**Frontend Integration Point** — each chip already has its handler location; wiring the call is the only change.
**No UI redesign required.**

---

### 12. Rental Provider cover image / logo (Vendor App)

- **Module:** Rental · **App:** User App + **Vendor App**
- **Status:** **Frontend Complete — Waiting for Vendor/Backend Integration**

**Frontend mapping (verified):** `RentalProviderCard` reads `provider.cover_photo_full_url`, falling back to
`provider.meta_image_full_url`, and `provider.logo_full_url` for the logo — the real fields on the backend
`Provider` object embedded in every vehicle. If a provider's cover renders as a neutral placeholder, the
backend supplied **neither** field for that provider; the frontend mapping is correct and needs no change.

**Verified end-to-end chain (Vendor App → Backend → User App):**

| Link | Finding |
|---|---|
| **User App displays** | `cover_photo_full_url` → falls back to `meta_image_full_url`; logo from `logo_full_url` |
| **Backend returns** | the `Provider` object embedded in every vehicle exposes `logo`, `cover_photo`, `logo_full_url`, `cover_photo_full_url`, `meta_image_full_url` — the fields exist on the model |
| **Fallback order** | `cover_photo_full_url` → `meta_image_full_url` → neutral placeholder (never fabricated) |
| **Conclusion** | the **frontend mapping is correct and needs no change**. A placeholder means the backend returned an empty value for that provider. |

**Required VENDOR APP work** — provider **Banner/Cover upload**, **Logo upload**, **Gallery** (confirm the
Vendor App writes to `cover_photo`, i.e. the field the provider payload exposes as `cover_photo_full_url`).
**Required BACKEND work** — return `cover_photo_full_url` / `logo_full_url` on the provider payload (and on the
future Provider List endpoint).

**Expected final behaviour** — once a vendor uploads a banner, the User App displays it automatically with
**no code change**.

---

### 13. Rental Category **Type** (admin enhancement — frontend already prepared)

- **Module:** Rental · **App:** User App · **Status:** **Frontend Complete — Waiting for Backend/Admin**
- **Admin location:** Car & Apt Rental → **Vehicle Management → Category → Add Category**

Add a **Category Type** selector: **Dashboard Page** · **Car Rental Home** · **Apartment Rental Home**.
Return `type` on the category model and accept it as an optional filter on `category-list`.

**Current behaviour is intentional and not a defect:** with a single untyped category list, every Rental page
shows the same categories. **Nothing is faked.** The approved category UI is **frozen**; when the backend sends
`type`, each screen filters by its own type — **no redesign, no widget change**.

---

### 14. Rental Provider Details — **Transmission** filter

- **Module:** Rental · **App:** User App · **Status:** **Frontend Complete — Waiting for Backend**
- **Location:** Provider Details (`VendorDetailScreen`) → filter chip row → **Transmission**.

The approved design (`ui-designs/Car_Rental/car_rental_provider_item_list.png`) shows a **Transmission** chip
alongside Filters · Sort · Price · Seats · More.

**Existing backend capability.** Each vehicle already returns `transmission_type` (Automatic / Manual) — the
Provider Details vehicle card and the provider feature badges both read it. But
`get-provider-vehicles` accepts **no transmission filter parameter**, and the existing rental filter sheet
(`VehicleFilterWidget`) has no transmission section — it filters by price range, brands, vehicle type, seats
and air conditioning only.

**Current frontend behaviour (nothing faked).** The chip is **fully rendered and inert**. It does not navigate
to an unrelated screen and it does not fake client-side filtering. Every other chip in the row is wired to real
backend behaviour: Filters / Price / Seats / More open the existing filter sheet (real backend filtering), and
Sort sorts the loaded real vehicles client-side exactly like the approved Food chips and frozen Screen 2.

**Required BACKEND work** — add `transmission_type` (`automatic` | `manual`, repeatable) as a filter parameter
on `GET /api/v1/rental/vehicle/get-provider-vehicles` and on the vehicle browse/search endpoints.

**Required VENDOR APP work** — none beyond what exists; vendors already set a vehicle's transmission type.

**Required ADMIN work** — expose transmission as a filterable attribute in Vehicle Management (consistent with
seats / vehicle type / air conditioning).

**Frontend Integration Point** — add a Transmission section to the existing `VehicleFilterWidget` and pass the
selected value through the existing `getVendorVehicleList` call. **No UI redesign required** — the chip already
exists in its final position.

---

### 15. ~~Vehicle Details — vehicle location/area line~~ **RESOLVED — not a backend gap**

- **Module:** Rental · **App:** User App · **Status:** ✅ **Resolved (product-owner clarification)**

Initially logged as a missing vehicle-location field. **Incorrect.** The design's location line
("📍 Lekki Phase 1") is the **user's selected browsing location** — the same real source every approved
MoonJoin header uses (`AddressHelper.getUserAddressFromSharedPref()?.address`, cf. the Home header and the
"Ikeja, Lagos" / "Lekki, Lagos" lines across the Rental designs). `VehicleDetailsScreen._header` now renders
it from that source. **No backend, Vendor App or Admin work required.**

---

### 16. Rental Checkout — **Pay Now** at booking (payer/timing + payment method)

- **Module:** Rental (Car + future Short Apt) · **App:** User App · **Status:** **Frontend Complete — Waiting for Backend**
- **Location:** Rental Checkout (`TaxiCheckoutScreen`) → Payment section.

**Frontend Completed** — Parcel-format payer/timing selector: **Pay Now** · **Pay to Driver on Trip**
(default; apt flow will use `pay_to_apartment_provider`). Pay Now reveals the approved shared
**`PaymentSection`** (same component/controller/bottom-sheet as Food/Grocery/Pharmacy/Ecommerce/Parcel),
gated by zone+config digital/wallet/offline flags; cash is deliberately excluded from Pay Now because cash IS
the pay-on-trip option. Nothing faked: Confirm Booking always runs the real `trip-book` flow.

**Backend reality (verified):** `POST trip-book` accepts **no payment fields**, and the production payment
(`makePayment` + `TaxiPaymentBottomSheet`) is only offered once `trip_status == completed`. Pay-at-booking is
therefore architecturally impossible today.

**Required BACKEND work** — accept `payment_timing` (`pay_now` | `pay_on_trip`) and `payment_method` (wallet /
digital gateway / offline) on `trip-book`; for `pay_now`, return the trip id + payment redirect (reuse the
existing `makeTripPayment` contract) so the app can launch the EXISTING payment flow immediately after booking.

**Required ADMIN work** — surface the booking's payment timing/status in trip management.

**Frontend Integration Point** — the marked block in `TaxiCheckoutScreen` (search `PAY-NOW — BACKEND
INTEGRATION POINT`); selector state `_payTimingIndex`, method via the shared `CheckoutController`.
**No UI redesign required.**

---

### 17. Short Apartment Rental — apartment inventory, fields & platform work

- **Module:** Rental (Short Apt) · **App:** User App + **Vendor App** + **Admin** · **Status:** **Frontend In Progress — Waiting for Backend/Vendor/Admin**

**What the User App already does (real data only):** the Short Apartments listing is the SAME unified
`AllVehicleScreen` in `fromApartment` mode; `RentalApartmentAdapter` resolves the REAL "Short Apt Rental"
category (id 2, live) and filters the real browse feed by `category_id`. With zero apartment inventory today
it shows the honest empty state. Top Brands is hidden (brand API has vehicle brands only).

**Required VENDOR APP work** — let providers list APARTMENTS as rental inventory under the Short Apt
category: apartment fields (bedrooms, bathrooms, max guests, amenities, per-night pricing) on top of the
rental item model; photo galleries.
**Required BACKEND work** — apartment fields on the inventory payload (`bedrooms`, `bathrooms`, `guests`,
`amenities[]`, night-rate mapping — today only hourly/distance/day-wise prices exist); category `type`
(items 7/13) and browse/category filter params (items 5/8); apartment brand/platform data if Top Brands is
wanted.
**Required ADMIN work** — create the real apartment categories shown in the approved design (City Center,
Beachside, Budget Stay, Luxury Stay, Family Friendly) under the Short Apt category type; approval flow.

**Frontend Integration Point** — ONLY `rental_apartment_adapter.dart` changes when the endpoints ship; the
listing UI/architecture must not change. The Rental Home "Popular Short Apt Rentals" section is permanent
architecture: it shows the approved empty state while inventory is empty and self-populates from the real
top-rated ranking; if a dedicated popularity metric ("most booked") is wanted, add it backend-side — the
section then only swaps its data source, never its UI. Apartment-specific fields will be consumed by the (upcoming)
Apartment Details phase — its contract will be extended here after its audit.

---

### 18. Rental — banner & category **section classification** (Main / Car / Short Apt)

- **Module:** Rental · **App:** User App + Admin · **Status:** **Frontend Complete — Waiting for Backend/Admin**

**Product-owner architecture:** Main Rental Home shows BOTH sections' banners/categories; the Car listing
shows Car content only; the Short Apartment listing shows Short Apt content only.

**Backend reality:** neither `rental/banners` nor `category-list` carries a section/type field.

**Frontend (adapter, real data only — `RentalApartmentAdapter`):**
- `sectionCategories` — splits the REAL category list by the real apartment-name resolution (apartment-matched
  → Apt section; every other real rental category → Car section). Home passes `all`.
- `filterBanners` — the only real banner signal is `provider_id` → classified through that provider's REAL
  loaded inventory (`isApartmentProvider`). External-link banners / providers absent from the feed =
  UNCLASSIFIED → kept on the Car listing (module content today is car-oriented), NEVER shown as apartment
  content without a real signal. `BannerWidget` gained an additive `section` param (default `all` → Home
  unchanged).

**Required BACKEND work** — `section` (`car` | `apartment` | `all`) on rental banners; category `type`
(consolidates items 7/13). **Required ADMIN work** — section selector when creating rental banners/categories.
**Frontend Integration Point** — ONLY `RentalApartmentAdapter.filterBanners` / `sectionCategories` change;
no UI/widget/architecture change.

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
- **Rental (Car Rental + Short Apartment Rental):** frontend redesign **in progress** (existing `rental_module`
  = "taxi"). **Rental Home (Screen 1)** is being built by reusing approved MoonJoin components. Car Rental uses
  the existing Taxi backend; Short Apartment Rental has no backend and uses an **isolated UI-layer placeholder**
  (`apartment_placeholder.dart`, `TODO(BACKEND)`) — **no mock repository**. Backend-pending Rental items now in
  this queue: **Hero Images** (item 3), **Category Images** (item 4), and **Short Apartment Rental** listing/
  details/booking (to be added as those screens are built).
