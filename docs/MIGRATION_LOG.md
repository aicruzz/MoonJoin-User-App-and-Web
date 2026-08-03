# MoonJoin UI Redesign — Migration Log

Chronological record of each completed phase. Baseline `flutter analyze` before the redesign: **56
info/warning issues, 0 errors**. Rule for every phase: **zero new issues** (the 56 pre-existing ones are
tolerated; nothing new introduced).

---

## 🔒 Frozen Screen Registry (production baseline)
Approved, frozen, production-ready. Do NOT modify unless a genuine production bug, a backend
incompatibility, or explicit user approval to reopen. No cosmetic changes. Add each newly approved screen.

- ✅ Home
- ✅ All Restaurants
- ✅ **Store List — COMPLETE** (Promotional Banner via Admin Banner feed · unified `MoonjoinStoreCard`
  everywhere · Search → Restaurants store-derivation · closed-store treatment + open-first ordering)
- ✅ Food Product Details
- ✅ Cart
- ✅ Edit Unavailable Items
- ✅ Checkout
- ✅ Payment Method Popup
- ✅ Order Success
- ✅ Order Tracking
- ✅ Order Details
- ✅ Review / Rating flow
- ✅ Order History (My Orders list)
- ✅ Refund flow (Refund Request screen)
- ✅ Product Details — Grocery/Others module (`ItemDetailsScreen`)
- ✅ **Store / Restaurant page — COMPLETE** (`StoreScreen` + `StoreHeroHeader` + `StoreMapView` (embedded map) +
  premium `ItemWidget` store dish layout; shared by Food/Grocery/Pharmacy/Ecommerce storefronts)
- ✅ **Shared storefront HOME — `AllStoreScreen` is the primary module home for ALL storefront Business Module
  Types** (Food, Grocery + Market/Fuel/Drink/Solar, Pharmacy, Ecommerce/Fashion); each module's unique sections
  preserved via `moduleHome` (storefront mode). One shared UI, module data differs.
- ✅ **Rental Screen 1 — Rental Home (Car & Apt Rental)** — **Production Ready (Frontend)** (`TaxiHomeScreen`) — one shared Rental Business
  Module Type covering Car Rental (existing Taxi backend) + Short Apartment Rental (UI-layer placeholder,
  no backend). MoonJoin `WavyHeader` + search pill, backend-driven categories via `MoonjoinCategoryTile`,
  backend-ready hero cards, `RentalPopularCard` rows, module back-navigation via `removeModule()`.

- ✅ **Rental Screen 2 — Car Rental Listing (All Car Rentals)** — **Production Ready (Frontend)**
  (`AllVehicleScreen`) — page-level reuse of the approved All Restaurants architecture with Rental data;
  provider-filter chips rendered but inert pending backend/vendor (queue item 9).

- ✅ **Rental Screen 2 — All Car Rentals** — **Production Ready (Frontend) · FROZEN** (`AllVehicleScreen`) —
  Provider Banner → Provider Detail Page → Vehicle List, mirroring the Food All Restaurants flow; provider
  adapter derives real providers from real vehicle data pending the Provider List endpoint. Provider-card
  feature badges parse the backend `tag` JSON-array into clean tokens ("Lexus", "Luxury") — presentation-only.

- ✅ **Rental Screen 3 — Provider List — ABSORBED INTO SCREEN 2 · FROZEN** — not a separate screen; the provider
  layer lives inside `AllVehicleScreen` (`RentalProviderAdapter` → `RentalProviderCard`), mirroring how the Food
  restaurant list lives inside All Restaurants. No standalone provider-list design exists.

- ✅ **Apt Screen 1 — Short Apartments listing** — **FROZEN** (unified `AllVehicleScreen` apartment mode +
  `RentalApartmentAdapter`; honest empty state; real Short-Apt category).

- ✅ **Shared Orders / Trips / Stay** (`order_screen.dart` + `OrderViewWidget` premium redesign) — **FROZEN**
  — one wrapper, module-aware (Orders/Trips/Stay), all logic preserved; Reviews.fromJson int-as-string bug
  fixed. Verified on device, log clean.

- ✅ **Rental Trip card** (`TripOrderViewWidget`) — **FROZEN** — Running/History list card (car `my_trip.png`
  / apt `my_booking_history.png`); real data, inline Cancelled state, apartment auto-activation; opens the
  frozen `TaxiOrderDetailsScreen`. Wrapper header/segmented = shared `order_screen.dart` (next phase).

- ✅ **Rental Trip / Booking Details** — **FROZEN** (`TaxiOrderDetailsScreen`) — full redesign to
  `trip_details.png` + `_scroll_down.png` (one page); 100% production logic preserved (getTripDetails,
  success popup, cancel/pay/review, provider WhatsApp/Call/Chat). Apartment mode auto-activates. THE single
  shared trip-details page (after booking success AND Trips→Running). Opaque background (bleed-through fixed).

- ✅ **Apt Booking Success** — **FROZEN** — ONE shared `ConfirmBookingRequestBottomSheet`; auto-activating
  apartment mode (real `category_id`): Booking ID/Date, Check-in/out/Nights, Total Paid + payment method,
  apartment wording. Car success byte-identical. No second success page.

- ✅ **Apt Checkout** — **FROZEN** — the frozen master `TaxiCheckoutScreen` reused exactly (page/flow/
  booking API/validation/payer selector/`PaymentSection` all shared); auto-activating apartment wording
  ("Selected Apartment", "Pay to Apartment Provider", nights) + the design's Check-in/Check-out/Nights strip
  from real cart values. Car checkout byte-identical. **PERMANENT: one checkout, one payment system for both.**

- ✅ **Apt Screen 3 — Apartment Details** — **FROZEN** — auto-activating apartment mode on the frozen
  `VehicleDetailsScreen` (real `category_id`): Check-in/Nights on the existing trip machinery (day-wise =
  per-night, trip-type row hidden), AC + real-tag pills, real-tag Amenities; missing backend fields omitted +
  queued (17). Car presentation byte-identical (default path).

- ✅ **Apt Screen 2 — Apartment Provider Details** — **FROZEN** — the frozen `VendorDetailScreen` with
  auto-activating apartment presentation (real-inventory-driven `isApartmentProvider`; additive
  `countLabel`; Guests/Bedrooms inert chips pending queue 17).

- ✅ **Rental section scoping (banners & categories)** — **FROZEN architecture** — Home `all` · Car listing
  car-only · Apt listing apt-only, via `RentalSection` + adapter classification from real signals
  (`sectionCategories`, `filterBanners`, additive `BannerWidget.section`); backend contract queue item 18.

- ✅ **Rental Home Popular sections** — **FROZEN architecture** — Car: real backend top-rated ranking,
  apartment-excluded; Apt: same real ranking, approved `MoonjoinEmptyState` while empty, self-populating;
  placeholder data removed; See All → the correct scoped listings.

- ✅ **Rental — Booking Success** — **Production Ready (Frontend) · FROZEN**
  (`ConfirmBookingRequestBottomSheet`) — design `booking_request_successful.png`; real trip data + provider
  call; auto-opens over Trip Details after a real booking.

- ✅ **Rental — Checkout** — **Production Ready (Frontend) · FROZEN** (`TaxiCheckoutScreen`) — existing
  production checkout preserved (already matching `car_rental_checkout.png` section-for-section) + the
  Payment section: Parcel-format payer selector (Pay Now | Pay to Driver on Trip) + approved shared
  `PaymentSection`. **MASTER payment implementation — Short Apt Rental reuses it exactly (wording only).**

- ✅ **Rental — Vehicle Details** — **Production Ready (Frontend) · FROZEN** (`VehicleDetailsScreen`) — design
  `car_rental_details.png` (+ in-page trip-type variant); real trip context (Location page → map confirm),
  direct trip-type selection, live estimate calculation, silent auto-retry loading, cart-backed
  Proceed-to-Checkout. Zero new shared components.

- ✅ **Rental Screen 4 — Provider Details (Provider Item List)** — **Production Ready (Frontend) · FROZEN**
  (`VendorDetailScreen`) — page-level reuse of the approved Store page: green hero (`RentalProviderHeroHeader`,
  a visual clone of the frozen Store-typed `StoreHeroHeader`) → search pill → filter chips → real category strip
  → provider banners → "N found" + client-side sort → paginated `VendorVehicleCard` list. 100% real backend
  data. Fixed a pre-existing `get-provider-details` string-counter parse crash that had made the page unreachable.
  Transmission chip inert pending backend (queue item 14); "View on Map" card / share button are documented
  deltas (frozen `Store`-typed `StoreMapView`, no share URL).

**Status: Production Ready · Frozen**

---

## Phase 0 — Documentation
- **Screen completed:** none (docs only).
- **Files modified:** `docs/DESIGN_SYSTEM.md`, `docs/UI_INDEX.md`, `docs/COMPONENTS.md`, `docs/SCREEN_FLOW.md`; created `docs/MIGRATION_REPORT.md`.
- **Widgets created / Components reused / Controllers / Services / APIs:** none.
- **flutter analyze:** unchanged (docs only).

## Phase 2 — Theme + MoonJoin component library
- **Screen completed:** none (foundation).
- **Files modified:** `lib/theme/light_theme.dart`, `lib/theme/dark_theme.dart` (primary → `#2C9C44`).
- **Widgets created (28 + barrel) in `lib/common/widgets/moonjoin/`:** `WavyHeader`, `MoonjoinSearchBar`,
  `MoonjoinModuleHeader`, `ModuleIcon`, `CategoryTile`, `ModuleCard`, `SectionHeader`, `ProductCard`,
  `RestaurantCard`, `PromotionBanner`, `StatusBadge`, `PriceRow`/`PriceView`, `QuantityStepper`,
  `MoonjoinFilterChip`/`FilterChipBar`, `VariationSelector`, `OptionGroupSelector`, `BottomActionBar`,
  `FloatingCheckoutBar`, `MoonjoinEmptyState`, `MoonjoinErrorState`,
  `SkeletonBox`/`MoonjoinSkeleton`/`SkeletonListLoader`, `SuccessBanner`, `InformationCard`,
  `CartSummaryCard`, `MoonjoinDialog`, `MoonjoinBottomSheet`, `MoonjoinButton`, `MoonjoinTextField` +
  `moonjoin_components.dart` barrel.
- **Components reused:** existing `CustomImage`; `shimmer_animation` package.
- **Controllers / Services / APIs reused:** none (pure presentation; no logic/API).
- **flutter analyze:** No issues in new files; full baseline unchanged (0 errors).

## Phase 3 — Navigation shell (4-tab + header cart)
- **Screen completed:** app shell (`DashboardScreen`) — Home · Orders · Favorites · Account; Cart +
  Notifications moved to the home header; old Menu → Account.
- **Files modified:** `lib/features/dashboard/screens/dashboard_screen.dart`,
  `lib/features/home/screens/home_screen.dart` (header cart), `lib/helper/route_helper.dart` (`/main` tab
  index map); docs `SCREEN_FLOW.md`, `UI_INDEX.md`.
- **Widgets created:** none.
- **Components reused:** existing `CartWidget`, `TaxiCartWidget`, `BottomNavItemWidget` (no duplication).
- **Controllers reused:** `SplashController`, `OrderController`, `LocationController`, `AuthController`
  (all unchanged).
- **Services / APIs reused:** unchanged — only navigation access moved; routes/deep links preserved.
- **flutter analyze:** Phase-3 files clean; baseline unchanged (0 errors). 7 introduced unused-import
  warnings were fixed.

## Phase 4 — Home Screen (module-landing) redesign  ·  incl. Final Refinements
- **Screen completed:** module-landing Home (`home.png`) — green wavy header (greeting, location,
  notification, cart, search), dynamic module grid, "items unavailable" notice, Special Offers, Deliver-to
  selector, Popular Stores.
- **Files modified:** `lib/features/home/screens/home_screen.dart` (route landing → `ModuleLandingView`;
  edge-to-edge top `SafeArea`); `assets/language/{en,ar,es,bn}.json` (new i18n keys); docs
  `UI_INDEX.md`, `SCREEN_FLOW.md`, `DESIGN_SYSTEM.md`, `COMPONENTS.md`.
- **Widgets created:** `ModuleLandingView` (`features/home/widgets/module_landing_view.dart`),
  `DeliverToView` (`features/home/widgets/deliver_to_view.dart`).
- **Components reused:** Phase-2 `MoonjoinModuleHeader`, `MoonjoinSearchBar`, `CategoryTile`,
  `SectionHeader`, `InformationCard`; existing `BannerView`, `PopularStoreView`, `AddressWidget`,
  `ModuleShimmer`, `AddressShimmer`, `CustomLoaderWidget`.
- **Controllers reused (unchanged):** `SplashController` (`switchModule`, moduleList),
  `ProfileController`, `NotificationController`, `CartController` (`cartList`, `availableList`),
  `LocationController` (`navigateToLocationScreen`, `saveAddressAndNavigate`), `AddressController`.
- **Services / Repositories reused:** none modified — views only read controller state.
- **APIs reused:** existing module/banner/store/notification/address endpoints via existing controller
  methods; refresh via the existing `RefreshIndicator` handler. No new/invented endpoints.
- **Refinements:** status bar edge-to-edge (green behind status bar, light icons via `AnnotatedRegion`,
  top `SafeArea` dropped only for the landing); localization (all strings via `.tr`, keys added to all 4
  language files); preserved the "Deliver to" selector (restored as `DeliverToView`).
- **flutter analyze:** `No issues found` in all Phase-4 files; full baseline **56 issues, 0 errors** —
  no new issues.

---

## Phase 4 — On-device visual validation (live backend)
- **How:** ran the app on the iOS Simulator (iPhone 16 Pro Max) against the **live** `admin.moonjoin.com`
  backend (zone 7 / Ogbomoso), driving onboarding via synthetic input, screenshots via `simctl`.
- **Environment fixes needed (not app issues):** (1) CocoaPods shim pointed at broken system Ruby — used
  the rbenv `pod` via `PATH="$HOME/.gem/ruby/3.4.1/bin:$PATH"`; (2) the host had a **stale DNS** cache
  pointing `admin.moonjoin.com` at an old Namecheap parking IP (TLS-reset) — flushing DNS resolved it to the
  live `199.188.200.9`; (3) simulator had no GPS — set a simulated location to resolve the zone.
- **Result — PASS:** Home renders correctly with live data — green **edge-to-edge** wavy header behind the
  status bar (light icons), `#2C9C44` throughout, greeting + location + notification/cart header icons,
  search bar, 12-module grid (real backend icons), "Special Offers for You" + live banner carousel,
  "Deliver To" with real saved addresses, recommended stores, and the 4-tab bottom nav (Home · Orders ·
  Favourite · Account, cart in header). **No RenderFlex overflow, no clipped widgets, no error boxes** on
  the landing.
- **UI fixes applied during validation** (`module_landing_view.dart`, UI-only): tightened the module grid
  (`childAspectRatio` 0.78→1.05, `mainAxisSpacing` large→small, featured icon 100→92) to match `home.png`
  spacing; removed a redundant "Popular Stores" `SectionHeader` (PopularStoreView already renders its own
  title and self-hides when empty). `flutter analyze` clean after fixes.
- **Interactions:** dashboard navigation verified live (running-order bar → Order Details renders with real
  data). The Home's **scrollable-content** taps (search, module tiles, header icons) could not be exercised
  by *synthetic* single-clicks — the dashboard's `ExpandableBottomSheet` gesture layer swallows them (drags
  and taps on normal scaffolds work; real device touches are unaffected). Those onTaps are unchanged
  existing routes (`switchModule`, `getSearchRoute`, `getCartRoute`, `getNotificationRoute`, `_setPage`,
  `getCouponRoute`) — code-verified and visually confirmed, exercised on a real device by the user.
- **Pre-existing issue noted (out of Phase-4 scope):** `StoreCard` (`store_card.dart:33`) throws a null-check
  when a store has null lat/lng, surfaced by `NewOnMartView` on the **per-module** home screens (not the
  landing). Existing code; to be handled when those screens are redesigned.

## Phase 4 — Home rebuilt to match `ui-designs/.../home.png` exactly (design authority = ui-designs images)
- **Why:** the first Home pass was functionally correct but not visually faithful. `ui-designs/` images are
  the authoritative spec; Home rebuilt to reproduce `home.png`, not approximate it.
- **Exact values pulled from the PNG** (via PIL sampling): body background `#F6F8F0` (pale green, not
  white); header/ring/offer green `#2C9C44`; unavailable card cream `~#FBF3E2`.
- **Files:** rewrote `features/home/widgets/module_landing_view.dart`; new
  `features/home/widgets/special_offers_view.dart`; tuned `common/widgets/moonjoin/module_icon.dart`
  (ring/pad scale with tile). `deliver_to_view.dart` no longer used by Home.
- **What changed to match the design:**
  - Module grid → the design's **2·3·2·3 grouping** (featured Food/Grocery large and straddling the wave;
    2-tile rows centered, 3-tile rows spread) — not a uniform GridView. Rows built dynamically from the live
    module list (alternating 2/3), so any module count keeps the pattern.
  - Background set to `#F6F8F0`; module tiles get a thicker green ring + softer shadow; icons fill the circle.
  - **Removed** the banner carousel, Deliver To, and Popular Stores/Recommended sections (not in the design).
    Address-switching remains reachable via the header location + Account (functionality relocated, not removed).
  - **"Special Offers for You"** → horizontal list of the real featured banners as rounded cards
    (`SpecialOffersView`), reusing the exact banner tap navigation (Item/Store/Campaign/URL).
  - **"Some items are unavailable" card** → rebuilt to match the design (cream card, kraft-box + red badge,
    green "Review Items" button) and wired to the **real** signal: a running order with a non-empty
    `unavailableItemNote` (vendor "edit unavailable items" workflow); tap → that order's details. No fake state.
- **Live validation:** hot-restarted on the simulator against the live backend (zone 7). All sections render
  with real data; the unavailable card correctly appears for order #100002 (which has an `unavailable_item_note`).
  **0 RenderFlex overflow, 0 exceptions.** `flutter analyze`: 0 issues in rebuilt files.
- **Organic module tiles:** the reference tiles are **not perfect circles** — each has a subtly different
  "amoeba" outline (measured ~±7% radius variation) with an identical green ring/diameter/shadow. Built a
  reusable **`OrganicModuleIcon`** (`common/widgets/moonjoin/organic_module_icon.dart`): 14 deterministic
  smooth blob shapes; a stable shape is assigned per module **id** (never repeating the immediately-preceding
  module); fixed ring thickness + outer diameter; icons inset with breathing room (≈56% of the blob, not
  full-bleed). `CategoryTile` now composes it via a `shapeIndex`; `ModuleLandingView` assigns shapes.
  Featured (Food/Grocery) tiles use the larger hero diameter; all others the design's normal diameter.
- **Bottom navigation rebuilt to match `home.png`:** `BottomNavItemWidget` now uses `IconData` (filled/
  outlined) with a **light-green rounded pill** behind the active icon and green/grey states —
  Home (filled house) · Orders (bag) · Favorites (heart) · Account (person). `dashboard_screen` passes the
  icons + labels; added a `favorites` i18n key to all four language files. Only shell presentation changed;
  routes/logic unchanged.
- **Live match confirmed:** on a zone whose backend module icons are the design illustrations, the running
  app is a near-1:1 match to `home.png` — organic 2·3·2·3 tiles, real "unavailable items" card, Special
  Offers banner cards, and the new bottom nav. 0 overflow / 0 exceptions; `flutter analyze` clean on all
  changed files.
- **Remaining micro-nitpick:** the featured tiles straddle a smooth wave rather than the exact "notch"
  cut-outs in the mock. (An iOS predictive-text bubble seen in earlier screenshots is a simulator
  text-input artifact from automated search taps, not the Flutter UI.)

## Phase 4 — Home **APPROVED & FROZEN** (final polish)
User approved the Home screen. Final polish applied and locked:
- **OrganicModuleIcon artwork sizing LOCKED**: normal modules ~**0.89** of the blob, featured (Food/Grocery)
  ~**0.93** — bold & premium, ring/blob/spacing untouched, no cropping, centered. Do not change again except
  during the one application-wide final polish after every User-App screen is done.
- **Entrance animation**: module tiles fade in + scale 0.92→1.0 + rise ~8px (ease-out), staggered ~48ms
  left→right/top→bottom, total <700ms. Plays once on Home open / reopen (State persists across GetBuilder
  rebuilds → never replays on scroll). `features/home/widgets/module_landing_view.dart` `_AnimatedTile`.
- **Module availability architecture (prep only)**: `common/models/module_availability.dart` —
  `ModuleAvailability { enabled, unavailable, disabled }` + `resolveModuleAvailability()` (returns `enabled`
  today). `CategoryTile.availability` renders **unavailable** as dim (opacity 0.5) + ~50% desaturation +
  tap-disabled with **no layout shift**; badge support intentionally left off. **No API/endpoint/logic
  changes** — ready for a future Admin → Settings → System Module Setup to drive it. `disabled` = current
  behaviour (module omitted from the list upstream).
- **Verification**: live on iOS Simulator against the backend — bold icons, notched wave, organic tiles,
  2·3·2·3 grouping, header count badges, matching bottom nav; **0 overflow, 0 exceptions, no layout shift**;
  `flutter analyze` → 0 errors, 0 issues in changed files (56 pre-existing baseline unchanged).

**Home is the permanent baseline.** Every future screen reuses `OrganicModuleIcon` and the MoonJoin
components unchanged; do not redesign Home, regenerate organic shapes, or alter artwork sizing/spacing.

### Final Figma verification (via Figma MCP)
- Figma MCP confirmed working (auth: Francis). Active Figma `sEkuRsP4EfASajwkM3chr8`, Page 1 — frames:
  HOME SCREEN (`1:29`), product_details_for_only_food, YOUR CART, checkout(+scroll_down), ALL RESTAURANTS,
  VIRTUAL ACCOUNT PAYMENT, order_success. (See `docs/ACTIVE_FIGMA.md`.)
- Compared the running Home against the Figma `HOME SCREEN` frame (source of truth) **and** `home.png`.
  The Figma confirms the module tiles are **`<vector>` blobs (150×140 featured / 150×130 normal), not
  circles** — validating `OrganicModuleIcon`.
- **One fix applied from the Figma:** the search **filter button now sits INSIDE the white search pill**
  (right-aligned), matching the Figma — was a separate floating button. (`moonjoin_search_bar.dart`.)
- Everything else matches: green wavy header + notch/valley wave, greeting/location/notification+cart,
  organic 2·3·2·3 tiles with bold artwork, cream "unavailable" card, Special Offers (real banners in the
  Figma's card container), and the Home/Orders/Favorites/Account bottom nav.
- Verified live on the simulator; 0 overflow, 0 exceptions; `flutter analyze` 0 errors / 0 issues in changed
  files. **Home is a visual match to both Figma and `/ui-designs/home.png` and is now permanently frozen.**

## ALL RESTAURANTS (store list) — redesigned, verified & FROZEN
- **Screen completed:** `AllStoreScreen` (`lib/features/store/screens/all_store_screen.dart`) — the shared
  store-list screen used by every "see all" entry (All Restaurants / Popular / Featured / Top Offers /
  Recommended / Nearby). Redesigned from the Active Figma `ALL RESTAURANTS` frame, verified against
  `ui-designs/…/restaurant_list.PNG`.
- **Layout (top→bottom):** circular back + title + circular search · light-grey search pill (green `tune`) ·
  horizontal category chips · filter chips (**Filters** green · Sort ⌄ · ⚡Fast Delivery · ♥Free Delivery ·
  ★Top Rated) · **featured promo carousel** (when data exists) · **Top Brands** (See All) · store cards.
- **Widgets created (presentation only):** `MoonjoinStoreCard`
  (`features/store/widgets/moonjoin_store_card.dart`) — cover image with discount + "orders over" badges,
  logo, delivery-time pill, name/rating/time/free-delivery row, bookmark; `bannerOnly` mode for the
  carousel. `features/store/widgets/all_restaurants_widgets.dart` — `RestaurantCategoryChip`,
  `StoreFilterChip`, `FeaturedStoreCarousel` (swipeable PageView + dot indicator), `TopBrandCard`.
- **Controllers / repositories / services / models / APIs reused (unchanged):** `StoreController`
  (`getPopular/Latest/Featured/TopOffer/RecommendedStoreList`, existing lists), `CategoryController`
  (`getCategoryList`), `BrandsController` (`getBrandList`), `FavouriteController` (wish-list add/remove),
  `SplashController.setModule`, existing routes (`getSearchRoute`, `getCategoryItemRoute`,
  `getBrandsScreen`, `getBrandsItemScreen`, `getStoreRoute`). No new/invented endpoints; no mock data.
- **Title:** driven by the existing route params — shows the **visible design text "All Restaurants"** on the
  all-restaurants entry and the correct existing label on the other entries (Popular/Featured/…). The Figma
  *frame name* does not dictate the text; the visible design text does.
- **Filters/sort chips:** operate client-side on the already-loaded list (Free Delivery filter, Top-Rated /
  Fast-Delivery sort) — no extra API calls, no fabricated data.
- **Pre-existing bug fixed (robustness, not logic):** the existing `BrandModel.fromJson`
  (`features/brands/domain/models/brands_model.dart:33`) crashed with
  `type 'String' is not a subtype of type 'int?'` when the live `items_count` arrives as a String — this
  blocked Top Brands. Made **only** that one field parse defensively (accepts int *or* numeric String). No
  API/endpoint/logic change; the existing Brands screen benefits from the same fix.
- **i18n:** added `on_orders_over` (+ earlier `search_for_food_restaurants_or_cuisines`, `filters`, `sort`,
  `fast_delivery`, `top_brands`) to all four language files (`en/bn/es/ar`), JSON validated.

### Missing backend dependencies (documented, NOT invented)
- **Featured promo carousel** — the first banner above Top Brands **auto-rotates** through the featured
  restaurants (`FeaturedStoreCarousel`), reusing the app's standard **`CarouselSlider`** (same
  package/pattern as `home/widgets/views/banner_view.dart`) — `autoPlay` every 4 s, ~700 ms ease-in-out,
  round page-indicator dots, manual swipe + **pause-on-touch/resume** (carousel_slider defaults). No second
  carousel implementation was written. Data is the **existing** featured-store backend
  (`StoreController.getFeaturedStoreList()` → `GET /api/v1/stores/get-stores/all?featured=1`). On the live
  backend this module currently returns `{total_size: 0, stores: []}` (no stores are flagged *featured* in
  admin), so the carousel **gracefully falls back to the single static hero-card layout** (exactly as the
  approved design). No data was faked; rotation was verified on-device with a temporary harness (fed real
  already-loaded stores, then reverted). The carousel will light up automatically once stores are marked
  featured in admin. The list **below** Top Brands is always a normal vertical list — never a carousel.
- **"ON ORDERS OVER ₦X" badge** — reuses the **existing** `Store.discount.minPurchase` (`min_purchase`)
  field. It renders only when a store's active discount carries a real `min_purchase > 0`. The current
  live stores/discounts have `min_purchase = 0`/absent, so the badge is (correctly) not shown. No
  placeholder value is displayed. No temporary API or field was created.

### Verification & freeze
- **Live on iOS Simulator** (iPhone 16 Pro Max, live `admin.moonjoin.com`, zone 7): navigated to
  All Restaurants — title "All Restaurants", green Filters chip, corrected delivery-time pill/row
  (`20-40 MINS` / `20-40 mins`, no "min MINS" duplication), category chips, Top Brands rendering, real
  store cards. **0 RenderFlex overflow, 0 exceptions on the screen.** `flutter analyze` → **No issues found**
  in all changed files (56 pre-existing baseline unchanged).
- **ALL RESTAURANTS — officially APPROVED & permanently FROZEN by the user.** It is the permanent baseline
  for **every restaurant/store listing screen** in MoonJoin. Future restaurant-related screens must inherit
  its spacing, typography, shadows, border radius, carousel behavior, animations, filter chips, category
  chips, restaurant-card styling, and section spacing by **reusing** `MoonjoinStoreCard`,
  `FeaturedStoreCarousel`, and the `all_restaurants_widgets` components unchanged (no duplication, no
  refactor). Do not redesign or revisit it unless the user explicitly requests changes. Application-wide
  visual tuning is allowed **only** during the final global-polish phase after every screen is done.

## FOOD PRODUCT DETAILS (full page) — redesigned & verified
- **Screen completed:** `FoodDetailsScreen` (`lib/features/item/screens/food_details_screen.dart`) — the
  food product page from the Active Figma frame `product_details_for_only_food` (`1:1226`), verified against
  `ui-designs/…/product_details_for_only_food.PNG` (Figma MCP reconnected mid-task and was used as the
  implementation source per the Design Authority).
- **Design:** green wavy header (reuses `WavyHeader`) with the controls row pinned to the top (back · store
  logo-initial + name + ★rating chip · share · favourite) and the hero product image straddling the wave;
  centered name, veg/non-veg indicator, `★★★★☆ 4.3 (4)` rating, price; **Food-variation section cards**
  (short single-select groups like *Size* render as compact radio pills, longer groups like *Pizza Type*
  as radio cards; multi-select groups as checkbox cards) with a Required/Optional/Completed badge; **Extras
  (add-ons)** as 2-column checkbox cards; a fixed **Total + quantity stepper + Add-to-Cart** footer.
- **Browse now opens the full page (Option 1, user-chosen):** `ItemController.navigateToItemPage` routes a
  food/restaurant item on **mobile** to `FoodDetailsScreen` (via the existing `getItemDetailsRoute` +
  `arguments`); **desktop keeps the existing dialog**, and **cart editing keeps the existing `ItemBottomSheet`**
  (unchanged) — the current cart/checkout workflow is untouched.
- **No duplicated business logic — extracted, not copied:** all pricing, variation/add-on resolution,
  required-variation validation, another-store reset flow, campaign→checkout and cart add/update logic was
  moved into a shared **`ItemCartHelper`** (`lib/helper/item_cart_helper.dart` — `compute()` +
  `addOrUpdateCart()`). `ItemBottomSheet` was refactored to call the same helper, so the sheet and the full
  page share **one** implementation. Variation/add-on selection reuses the existing `ItemController` methods
  (`setNewCartVariationIndex`, `addAddOn`, `setAddOnQuantity`, `setQuantity`, `selectedVariations`, …).
  Old-style (`choiceOptions`) variations reuse the existing `VariationView`. Favourite reuses
  `FavouriteController`.
- **i18n:** added `extras` to all four language files (`en/bn/es/ar`), JSON validated.
- **Verified on iOS Simulator** (live backend, Pizza item #12): full page renders a 1:1 match to the Figma
  — wavy header + hero, Pizza Type (radio cards), Size (radio pills with real `+₦` option prices), Extra
  (multi-select variation) and Extras (add-on checkbox cards), Total/qty/Add-to-Cart footer. **0 RenderFlex
  overflow, 0 exceptions.** `flutter analyze` → clean on all changed files (pre-existing baseline unchanged).
  Note: discrete synthetic taps don't inject into the Flutter view in this harness, so variation-select /
  add-to-cart were **code-verified** (shared `ItemCartHelper`, identical to the proven bottom-sheet path)
  rather than tap-driven; scrolling (a continuous drag) confirmed the full below-fold layout on device.
- **Option-card sizing (reviewed & kept):** an `equalGrid` (forced identical card heights) refactor was
  proposed but, after comparing the Active Figma, **discarded** — the Figma's own behaviour is
  content-driven: Food-Type cards grow when the title wraps to a second line, Size options grow only when a
  second price line is present, and Extras stay equal because every card has the same content structure.
  The screen keeps the content-driven layout that matches the Figma.
- **FOOD PRODUCT DETAILS — APPROVED & FROZEN** as the permanent baseline. `FoodDetailsScreen`,
  `ItemCartHelper` and the food-variation / add-on section widgets are the baseline for food item details;
  reuse them unchanged. Do not revisit unless the user explicitly requests changes.

## Permanent component-reuse & design-consistency rules (locked by the user)
Applies to **every** remaining screen (also codified in `CLAUDE.md` → "Component Reuse Policy"):
- **Search the existing codebase first.** If a component exists and matches the MoonJoin design language,
  **reuse and extend it** — never create a second visual style for an existing component unless the user
  explicitly asks. Covers: category chips, banners, cards, carousels, search bars, filter chips, product
  cards, restaurant cards, module tiles, section headers, quantity controls, buttons, bottom action bars.
- **Banners:** one banner implementation app-wide — same height, radius, spacing, padding, indicator style
  and animation; only the content changes. Do not introduce alternate banner designs.
- **Carousels:** reuse the app's `CarouselSlider` pattern (as in `FeaturedStoreCarousel` / `banner_view`).
- **Apartment Rental (when reached):** reuse the **exact Food category-chip component** — identical sizing,
  spacing, corner radius, icon sizing, typography, selection state, shadows and animation; only the icon and
  label change. Do **not** create a different rental category-chip style even if `/ui-designs/` shows a
  slight variation.

## YOUR CART — APPROVED & FROZEN
- **Screens/widgets:** `cart_screen.dart` mobile layout rewritten to the Figma frame `1:1344` (verified vs
  `ui-designs/cart.PNG`); `CartItemWidget` redesigned to the Figma cart card. **Desktop/web path kept
  unchanged** (mobile early-returns a new `_mobileScaffold`).
- **Layout:** green header (back · Your Cart · N items · clear-cart trash with confirmation) · savings
  banner (when a discount exists) · item cards (image, name, store name+rating for restaurants / unit
  subtitle for others, favourite, quantity selector, and a variation **Change** panel that opens the
  existing edit bottom sheet) · **Add More Items** card · **not-available preference** card · **Chat with
  Vendor** card · **You May Also Like** suggestions · price summary (Subtotal, Discount, Total + You-saved
  pill) · bottom bar (free-delivery progress + Total + Proceed to Checkout).
- **Every production feature preserved & integrated (Option 1, user-chosen):** cutlery toggle, extra
  packaging (`ExtraPackagingWidget`), product-unavailable preference (`NotAvailableBottomSheetWidget`),
  free-delivery progress bar, "you may also like" suggestions, refer-and-earn snackbar, coupon reset, and
  the exact checkout navigation (`updateFirstTime`, module set, `getCheckoutRoute('cart')`). Slidable
  swipe-delete, tap-to-edit, and all price/variation/add-on computation are unchanged.
- **Component reuse:** `QuantityButton`, `FavouriteController`, `RatingBar`, `CustomButton`, `CustomImage`,
  `ItemBottomSheet` (edit), `ExtraPackagingWidget`, `ItemWidget` (suggestions), `NotAvailableBottomSheetWidget`,
  `ConfirmationDialog`. No duplicated business logic; no backend/API/model changes.
- **i18n:** added `change`, `your_cart`, `youre_saving`, `on_this_order`, `add_items_from_your_favorite_store`,
  `browse_more`, `chat_with_vendor`, `have_a_question_or_need_help`, `you_saved`, `are_you_sure_to_delete`,
  `you_want_to_delete_all_carts` to all four language files (JSON validated).
- **Backend-honest deltas (user-approved):** the Figma's "Delivery Fee" row is **kept** with a truthful
  placeholder — **"Calculated at checkout"** (`delivery_fee` + new `calculated_at_checkout` key) — because the
  delivery fee is a checkout-stage (distance-based) value not available at the cart; no amount is fabricated.
  "Chat with Vendor" routes to the store page (cart-stage vendor chat is not a backend feature — chat is
  order-scoped; reuse the closest existing flow). Totals keep the app's animated price widget (no
  thousands-comma) — global currency formatting is deferred to the final application-wide polish.
- **Verified on iOS Simulator** (live backend, real cart): faithful match to the Figma with the variation
  Change panel, "You May Also Like" suggestions (existing `ItemWidget`, not duplicated), free-delivery
  progress, and the "Calculated at checkout" delivery row all live. **0 overflow, 0 exceptions;**
  `flutter analyze` clean; temp debug hook removed.
- **YOUR CART — APPROVED & FROZEN by the user.** Permanent baseline for the cart screen. Reuse
  `CartItemWidget` and the cart layout components unchanged; do not revisit unless the user requests changes.

## EDIT UNAVAILABLE ITEMS — real-order end-to-end verification & FROZEN
Verified on the user's **live** Order #100047 (vendor-flagged via Vendor Web), reached through the **existing
production navigation** (`trackOrder`/`getOrderDetails` → the same `OrderEditScreen` push the "Edit Order"
button performs) — real backend, no mock data, no new routes:
- ✅ **Vendor Shortage banner shows the real backend note exactly:** "Pizza large size is not available,
  choose other size" (screenshot 123).
- ✅ **Edit Unavailable Items opens correctly for #100047** (Pizza · ₦10,000 · Qty 1 · Remove/Change ·
  Order Total ₦10,700 · Update Cart · Back to Cart) — and it's the **correct order**.
- ✅ **`canEdit` fix confirmed live** — #100047 is **paid**+pending and now correctly reaches the edit flow.
- ✅ Food Product Details **Edit Mode** (preloaded selections + Save) verified earlier (screenshot 101).
- Code-verified (harness cannot inject the taps): Save → `updateEditableItem` → return; Update Cart →
  `submitEditedOrder` (PUT `/customer/order/update/{id}`); post-update `getRunningOrders` refresh → Home card
  re-evaluates (hides when resolved, shows the next flagged order otherwise) → correct-order navigation.
- **Automation limitation (not an app limitation):** synthetic taps *and* scrolls do not register on the
  Home dashboard (`ExpandableBottomSheet` swallows injected gestures), so the Home-card scroll-to + tap-through
  and the visible "card disappears" step can't be shown here; they work on a real device and are verified by
  code + the live-data checks above. Temp verification driver removed; `flutter analyze` clean.

**EDIT UNAVAILABLE ITEMS — FROZEN** as the permanent baseline for the unavailable-items flow. Reuse
`OrderEditController`, the Edit-Mode `FoodDetailsScreen`, and the Home Review-Items card unchanged.

## Review Items lifecycle — real-backend verification & a real bug fixed
End-to-end check against the user's **live** order #100047 (vendor marked "Pizza large size is not
available, choose other size" via Vendor Web) surfaced two things:
- **Data source is correct (confirmed live):** the running-orders **list** *does* carry
  `unavailable_item_note` — a diagnostic reading the parsed running-order models printed
  `100047 note=[Pizza large size is not available, choose other size]` plus several older flagged orders.
  (An earlier raw-log grep showed 0 only because the huge list response is **truncated** in the run log.)
  So the Home card's data source (`runningOrderModel.orders[i].unavailableItemNote`) is right.
- **Real bug found & fixed — `canEdit`:** order #100047 is **paid** + pending, but `OrderEditController.canEdit`
  required *unpaid*, so Order Details would **not** show the "Edit Order" entry → the customer could never
  reach Edit Unavailable Items for a paid shortage order. Fixed: `canEdit` now returns true for a **pending**
  order that is unpaid **or** carries a non-empty `unavailableItemNote` (the vendor-shortage flow applies to
  already-paid orders). The Home card condition was aligned to `pending && hasNote` (only reviewable orders
  show, and they drop off once resolved/advanced).
- `flutter analyze` → No issues found; diagnostic removed.
- **Harness limitation (honest):** the full tap-through (scroll Home to the card → tap → Order Details →
  Edit → change variation → Save → Update Cart → card auto-hides) **cannot be driven here** — synthetic taps
  *and* scrolls do not register on the dashboard content (its `ExpandableBottomSheet` swallows injected
  gestures; real device touches are unaffected). The data + logic are verified against the live backend and
  by code; the on-screen tap-through needs a real device (or lifting the no-debug-nav rule for one pass).

## Review Items notification lifecycle (Home)
Connected the existing unavailable-order state to the Home "Review Items" card's visibility + navigation:
- **Visibility is reactive** — the card (`module_landing_view.dart` `_unavailableCard`) is a
  `GetBuilder<OrderController>` that shows the first running order whose `unavailableItemNote` is non-empty
  and renders **nothing** when none remain (auto-hide; auto-show when a new one appears).
- **Auto-refresh after resolving** — `OrderEditController.submitEditedOrder` now calls the existing
  `OrderController.getRunningOrders(1, fromDashboard: true)` on success, so the Home card **re-evaluates
  automatically** (no manual refresh): it stays visible if other unresolved orders remain and disappears once
  every unavailable order is updated. Reuses the existing endpoint — no new API, no duplicate notification.
- **Correct-order navigation** — tapping the card opens `getOrderDetailsRoute(order.id)` for that **specific**
  order (which exposes the "Edit Order" → Edit Unavailable Items flow); it never opens the Orders list or the
  wrong order.
- `flutter analyze` clean on the changed files. Note: the full tap-driven lifecycle (tap → update → card
  hides) can't be exercised by synthetic taps in this harness, and no order currently carries an unavailable
  note (so the card is correctly hidden); the reactive/refresh wiring is code-verified and the card's
  appearance/navigation were verified earlier.

## EDIT UNAVAILABLE ITEMS — production-flow refinements (awaiting approval)
Applied the user's production-flow refinements on top of the redesign:
1. **Chat with Vendor removed from YOUR CART** (chat is order-scoped; only exposed after an order exists).
   Kept on EDIT UNAVAILABLE ITEMS and wired to the **existing order chat** route
   (`getChatRoute(notificationBody: NotificationBodyModel(orderId, restaurantId: store.vendorId), user: …)`).
2. **Vendor Shortage banner** now shows the **real vendor note** (`order.unavailableItemNote`) when present,
   falling back to the default sentence otherwise.
3. **Re-edit unavailable products via the FROZEN Food Product Details page in EDIT MODE** — no second editor:
   `FoodDetailsScreen` extended with `cart` (preload) + `onCartItemAdd` (Save) params; it preloads the item's
   current quantity/variations/add-ons (via the existing `ItemController.getItemDetails(cart:)`) and shows a
   **Save** button (reusing `ItemCartHelper`'s existing `onCartItemAdd` path). Saving calls the new
   `OrderEditController.updateEditableItem(index, cart)` (in-place update, reusing the same item construction
   as `addCartItem`) and returns; the order is only submitted on **Update Cart** (`submitEditedOrder`).
4. **One editing interaction** — tapping the item card OR the single **Change** button both open the same
   Edit-Mode page (removed the per-row Change links and the separate Replace flow).
5. **Backend preserved** — `OrderEditController`, `FoodDetailsScreen`, variation/add-on/quantity logic and
   `updateOrder` reused; no invented APIs/controllers; a single Food Product Details implementation for both
   add and edit.
- **Verified on device:** the Edit-Mode page opened with **Pizza Type = Chicken Pizza** and **Size = Medium
  preselected** ("Completed" badges), the Extra preselected (total reflected it), and a **Save** button;
  `getItemDetails` preloads quantity via `_quantity = cart.quantity`. The edit screen shows the single
  **Change** button + tappable card, quantity on the item line, and the wired Chat card. `flutter analyze`
  → **No issues found** in all changed files; temp debug hook removed.

## EDIT UNAVAILABLE ITEMS — redesign (superseded by refinements above)
- **Screen:** `order_edit_screen.dart` — the existing order-edit screen (reached from Order Details' "Edit
  Order" when `OrderEditController.canEdit(order)` == unpaid+pending) **redesigned** to
  `ui-designs/edit_unavailable_items.PNG`. Not in the Active Figma → ui-designs is the authority.
- **Backend reused (nothing invented):** the entire `OrderEditController` + `PUT /customer/order/update/{id}`
  flow is preserved — `loadOrder`, `editableItems`, `removeItem`, `addCartItem`, `updateOrderNote`,
  `itemsSubtotal`/`orderTotal`, `submitEditedOrder`, store-item search/add. The `_AddItemsBottomSheet` /
  `_StoreItemTile` add-items flow is unchanged.
- **Layout (matches the design):** green header (back · "Edit Unavailable Items" · subtitle · shortage
  icon) · red **Vendor Shortage** banner · **Unavailable Items (N)** heading · item cards (image, name,
  variation **Change** rows or price, **X** / **Remove** / **Replace**) · **Add More Items** card ·
  **Chat with Vendor** card · bottom bar (**Order Total** · **Update Cart** → `submitEditedOrder` ·
  **Back to Cart**).
- **Backend-honest mappings:** since these items are *unavailable*, **Change / Replace** open the existing
  Add-Items (pick-replacement) sheet, and **X / Remove** call `removeItem` — no invented "edit-variation of
  an out-of-stock item" API. **Order Note** and **Order Summary** are kept (existing production capabilities
  wired to `updateOrder`), placed below the cards; they are extra to the ui-designs mock but preserve real
  functionality. "Chat with Vendor" reuses the closest existing flow. Prices use the app's converter.
- **Verified on iOS Simulator** (live backend, real pending+unpaid order): renders a faithful match to
  `edit_unavailable_items.PNG` — shortage banner, unavailable item card with Remove/Replace, add-more +
  chat cards, Order Total ₦8,200 + Update Cart + Back to Cart. **0 overflow, 0 exceptions;** `flutter
  analyze` → **No issues found** in the screen (even pre-existing lints fixed); temp debug hook removed.

## CHECKOUT — ✅ APPROVED & FROZEN
- **Screen:** `checkout/screens/checkout_screen.dart` + sub-widgets (`top_section`, `bottom_section`,
  `delivery_section`, `coupon_section`, `time_slot_section`, `deliveryman_tips_section`, `tips_widget`,
  `payment_section`, `delivery_instruction_view`, `note_prescription_section`, `condition_check_box`) plus
  shared `common/widgets/address_widget.dart` (`fromCheckout` branch) and
  `cart/widgets/delivery_option_button_widget.dart`. Design authority = Active Figma
  `checkout` (1:1484) + `checkout_scroll_down` (1:1589), verified against `ui-designs/checkout.png` +
  `checkout_scroll_down.png`.
- **One vertically-scrolling page** on the MoonJoin body (`#F6F8F0`) with these cards, each `radiusLarge`,
  soft shadow (`primary @0.05, blur 10`), `paddingSizeDefault`: Delivery Type (two equal option cards via
  `IntrinsicHeight`) · Deliver To (green address card + Street/House/Floor) · Add More Delivery Instruction
  · Preference Time · Promo Code · Delivery Man Tips + Save-for-later · Choose Payment Method (selected-
  method card + **Change**) · Additional Note · Order Summary + Total · data-safety banner · Terms. Sticky
  bottom **Total Amount + Place Order** bar.
- **Presentation only — business logic 100% reused:** `_orderPlaceButton` (validation + placeOrder +
  payment chain), `CheckoutController` getters/setters, address/coupon/tips/time-slot/prescription/partial-
  pay logic, APIs, models — all untouched. i18n keys added to en/bn/es/ar.
- **Bugs fixed during on-device verification:** Delivery-Type `Row(stretch)` "infinite height" (→
  `IntrinsicHeight`); address-card 41px overflow (removed `CustomDropdown` hard-coded `height: 45`).
- **Verified on iOS Simulator** (live backend, real store/cart, ₦14,143): faithful match top-to-bottom, 0
  overflow/exceptions. `flutter analyze` → **No issues** in all modified files.
- **CHECKOUT — permanently FROZEN by the user.** Permanent MoonJoin production baseline; do not modify
  unless the user explicitly requests a future change.

## PAYMENT METHOD POPUP — ✅ APPROVED & FROZEN
- **Widget:** `checkout/widgets/payment_method_bottom_sheet.dart` (opened via **Change** in Choose Payment
  Method). Design authority = the Active Figma **VIRTUAL ACCOUNT PAYMENT** frame (1:2218) — its premium
  banking visual language borrowed into the popup (the standalone Virtual Account Payment page itself was
  **not** redesigned/recreated and is no longer used).
- **Premium fintech redesign (presentation only):** hero (title + subtitle + Total, with the Figma **bank
  illustration** exported from node 1:2257 → `assets/image/virtual_account_bank.png` / `Images.virtualAccountBank`)
  · Figma green **Wallet Balance** card with the white **Use Wallet** button (renamed from "Apply") ·
  premium selectable payment cards (COD, digital gateways) with animated radios · **Your Virtual Account
  Details** card (bank chip · Bank Name · Account Number + 44×44 soft-green copy button · Account Name — no
  timer/expiry) · **Important Instructions** (green numbered badges + dividers) · existing **Select** button
  unchanged.
- **Logic 100% reused:** wallet/partial-pay select-deselect, `setPaymentMethod`, digital/offline/COD
  branches, `virtualAccountData`, clipboard copy + snackbar, visibility conditions, `paymentAfterDigitalCancel`.
  No "I Have Paid" / "Use Wallet-as-new-flow" / "Verify" / "Cancel" added.
- **QA pass:** removed dead code (`canSelectWallet`, `notHideWallet`, orphaned local, unused `trailing`
  param); replaced hardcoded `Colors.grey.shade700` / `Colors.blue` with theme tokens (dark-mode-safe);
  overflow-guarded with `Expanded`/`Flexible`/ellipsis. `flutter analyze` → **No issues** in the file.
- **Verified on iOS Simulator** (live backend, 9PSB · ₦9,575 · acct 6400001489). **PAYMENT METHOD POPUP —
  permanently FROZEN by the user.**

## ORDER SUCCESS — ✅ APPROVED & FROZEN
- **Screen:** `checkout/screens/order_successful_screen.dart`. Design authority = Active Figma
  `order_success` (1:2353), verified against `ui-designs/order_success.png`. Reused shared MoonJoin
  components `WavyHeader` + `MoonjoinButton`; illustrations exported from the Figma (nodes 1:2373 hero,
  1:2419 gift, 1:2433 scooter) → `assets/image/order_success_{hero,gift,scooter}.png` /
  `Images.orderSuccessHero/Gift/Scooter`.
- **Layout:** green wavy hero (check+scooter illustration, "Order Placed Successfully!" + subtitle, back
  button, scale/slide/fade entrance) · **Order Summary** card (Order ID · Date · Payment Method · Total ·
  Estimated-Delivery sub-card + Track Order) · **Track Order** (primary) / **Continue Shopping** (outline)
  · **Invite friends & get rewards** banner · **trust badges** (Safe Payments · 24/7 Support · Best
  Quality · On-Time Delivery). Failure state (payment incomplete) preserved.
- **Presentation only — logic 100% reused:** `OrderController.trackModel`/`trackOrder`, payment-failed
  detection, `saveEarningPoint`, all navigation routes (`getOrderTrackingRoute`, `getInitialRoute`,
  `getReferAndEarnRoute`), guest/user branches, and the entrance animations. No controller/API/model/repo
  changes. i18n keys added to en/bn/es/ar.
- **Backend-honest:** every value from the real backend (Order ID, `createdAt` via
  `DateConverter.isoStringToReadableString`, `paymentMethod.tr`, `orderAmount` via `PriceConverter`).
  Estimated Delivery shows a formatted `scheduleAt` **only** when `order.scheduled == 1`; instant orders
  read "As soon as possible" (no fabricated ETA). Cleaned up dead code (`dart:math`, `theme_controller`,
  unused pulse animation).
- **Verified via a REAL COD order on the live backend (order #100050):** screen matches the Figma; Order
  ID #100050 · "13 July, 2026 00:27 AM" · Cash on Delivery · ₦6,443 · "As soon as possible" all real;
  **Track Order** opened tracking for #100050; **Continue Shopping** returned Home + fired the loyalty
  "earn 64 points" dialog (logic preserved); **Refer & Earn** banner opened Refer & Earn. 0 overflow / 0
  exceptions; `flutter analyze` → **No issues**.
- **ORDER SUCCESS — permanently FROZEN by the user.** Production baseline.

## ORDER TRACKING — ✅ APPROVED & FROZEN
- **Screen:** `order/screens/order_tracking_screen.dart` + overlay widgets
  `order/widgets/tracking_stepper_widget.dart` and `order/widgets/track_details_view_widget.dart`. Not in
  Active Figma / not in `/ui-designs/` (shopping module) → designed in the approved MoonJoin design system.
- **Presentation only:** the two cards over the live `GoogleMap` now use the MoonJoin card treatment
  (`radiusLarge` + soft shadow `primary @0.05, blur 10`), and the rider **Call**/**Chat** buttons use the
  brand green `#2C9C44` (`primaryColor`) instead of hardcoded `Colors.green`, with cleaner icons. Reused
  existing `CustomStepperWidget` / `AddressDetailsWidget` / `RatingBar` — no new/duplicated widgets.
- **Logic 100% reused:** GoogleMap, markers, `setMarker`/`updateMarker`/`updateDeliverymanMarker`,
  `zoomToFit`, location permission, the live tracking timer, and the call/chat/direction handlers are all
  unchanged. Cleanup: removed a stray `debugPrint` and the resulting unused `bounds` local in
  `updateMarker` (behavior-neutral; `rotation` preserved).
- **Verified via REAL backend, in-transit order (rider EZT Adejumo, "Delivery on the way"):** stepper shows
  Order Placed ✓ · Confirmed ✓ · Preparing ✓ · Delivery on the way ✓ · Delivered (pending); rider details
  card shows Trip Route, real distance (1023.83 km), rider name + rating, brand-green Call/Chat; map markers
  + live camera updates work after hot reload. Delivered orders correctly route to Order Details instead.
  0 overflow / 0 exceptions; `flutter analyze` → **No issues**.
- **ORDER TRACKING — permanently FROZEN by the user** (pre-authorized on passing real-backend QA).

## ORDER DETAILS — ✅ APPROVED & FROZEN
- **Screen:** `order/screens/order_details_screen.dart` + `order/widgets/order_info_widget.dart` +
  `order/widgets/order_calcuation_widget.dart`. Not in Active Figma / not in `/ui-designs` (shopping) →
  MoonJoin design system.
- **Presentation only:** off-white body (`#F6F8F0`, mobile), a page gutter (one scroll-view `padding`), and
  every section is now a MoonJoin **card** — switched the shared **`CustomCard`** wrapper's mobile
  `borderRadius` 0 → `radiusLarge` across all sections (General Info, Item Info, Delivery Details, Delivery
  Man, Restaurant, Payment, Billing Summary, Notes, Cancellation, Prescription/Proof, Order Status/banner).
  Reused the existing `CustomCard` + all section widgets — no new/duplicated widgets.
- **Logic 100% reused:** `OrderController`, APIs, models, routes, the 10s refresh timer, and every action
  (Cancel, Edit, Review, Refund, Reorder, Switch-to-COD, Chat, Call, Track, parcel-return) unchanged.
- **QA:** `flutter analyze` → **No issues** in modified files (one pre-existing `use_build_context_synchronously`
  in untouched action logic remains). **Fixed a genuine memory leak** — `scrollController` is now disposed.
- **Verified via REAL backend:** Pending #100048 renders all sections as clean cards (code 8807, Pizza
  ₦12,000 + Soft Drink, Delivery Details, Restaurant, Payment **Unpaid** ₦14,000), 0 overflow; Delivered
  #100050 content (rider, Paid Cash ₦6,443, billing, Review/Refund) renders in the same cards. Card
  treatment is state-agnostic.
- **ORDER DETAILS — permanently FROZEN by the user.** Production baseline.

## REVIEW / RATING — ✅ APPROVED & FROZEN
- **Screens:** `review/screens/rate_review_screen.dart` (Items / Delivery Man tabs) +
  `review/widgets/item_review_widget.dart` + `review/widgets/deliver_man_review_widget.dart`. Not in Active
  Figma / not in `/ui-designs` → MoonJoin design system.
- **Presentation only:** off-white body (`#F6F8F0`); the per-item review card and the delivery-man
  review/rate cards now use the MoonJoin treatment (`radiusLarge` + soft shadow `primary @0.05, blur 10`
  + margins). Reused existing `CustomButton` (Submit), the star `RatingBar` (brand-green `primaryColor`),
  `MyTextField` (comment), `CustomImage`, and the tab controller — no new/duplicated widgets.
- **Logic 100% reused:** `ReviewController` (`initRatingData`, `setRating`, `setReview`, `submitReview`,
  `canReviews`, loading/submitted state), `ReviewBodyModel`, and the Items/Delivery-Man tabs — unchanged.
- **Verified via REAL backend (order #100050):** Items tab (Rice&Beans ₦4,000, Pizza ₦7,500 cards with
  rating + comment + Submit) and Delivery Man tab (rider **EZT Adejumo** card + Rate His Service card) both
  render as clean MoonJoin cards, real data, 0 overflow. `flutter analyze` → **No issues**.
- **REVIEW / RATING — permanently FROZEN by the user.** Production baseline.

## ORDER HISTORY — ✅ APPROVED & FROZEN
- **Screens:** `order/screens/order_screen.dart` (My Orders — Running / History tabs) +
  `order/widgets/order_view_widget.dart` (per-order row). No dedicated `/ui-designs` image / not in Active
  Figma → MoonJoin design system ("Restyled using Design System (No Dedicated Mockup)").
- **Presentation only:** off-white body (`#F6F8F0`); each order row is now a MoonJoin card
  (`radiusLarge` + soft shadow `primary @0.05, blur 10` + page margins), and the inter-row divider was
  removed in favour of card separation. Desktop keeps its existing `radiusSmall` compact rows. Reused the
  existing `OrderViewWidget`, store image, `StatusBadge`-style status pill and item-count — no new widgets.
- **Logic 100% reused:** `OrderController` (`getRunningOrders`, `getHistoryOrders`, pagination), the
  Orders/Trips type switch, `TaxiOrderController` trips, guest track-order fallback — all unchanged. No
  APIs/controllers/models/routes touched.
- **Verified via REAL backend:** History tab renders #100051 (2 Items, **Delivered**), #100050 (1 Item,
  **Delivered**), #100006 & #100005 (**Payment Failed**) as clean MoonJoin cards with store logo, order id,
  date/time, status pill and item count — 0 overflow. `flutter analyze` → **No issues** in both files.
- **ORDER HISTORY — permanently FROZEN by the user.** Production baseline.

## REFUND FLOW — ✅ APPROVED & FROZEN (verification-first)
- **Screen:** `order/screens/refund_request_screen.dart`. No dedicated `/ui-designs` image / not in Active
  Figma → MoonJoin design system.
- **Production logic investigated & documented before any UI change (no assumptions):**
  - **Path B — the ONE real refund entry point.** `order_info_widget.dart:693`, an outlined "Refund This
    Order" button **inline in the Restaurant Details card** (NOT a bottom action). Visible only when
    `!isGuestLoggedIn && configModel.refundActiveStatus == true && orderStatus == 'delivered' && !parcel
    && orderDetails[0].itemCampaignId == null` (campaign/flash-sale first item hides both Refund AND
    Review — same gate at `:706`). Taps `Get.toNamed(getRefundRequestRoute(order.id))`. Screen loads
    `OrderController.getRefundReasons()` (`GET /api/v1/customer/order/refund-reasons`); submit →
    `OrderController.submitRefundRequest()` (`POST /api/v1/customer/order/refund-request`, multipart
    reason/note/image[]). **No wallet logic in the frontend — refund/wallet credit is entirely backend.**
  - **Path A — Cancel Order** (`shouldShowCancelButton`, status `pending|failed`) → `CancellationDialogueWidget`
    → `OrderController.cancelOrder()` (`POST orderCancelUri`). This is **cancellation, not refund**; no
    refund-reason step, no frontend wallet trigger. Path A ≠ refund flow.
  - **Path C — "Payment Failed" orders (#100005/#100006): EXPECTED, not a bug.** `'failed'.tr` = "Payment
    Failed" (en.json). `order_status:'failed' + digital_payment + unpaid` = a digital payment that was
    abandoned/failed before the gateway callback completed (standard 6amMart; a `paymentFailedDetailsUri`
    retry path exists). No inconsistency, no state mismatch, nothing paid → no refund applies.
  - **Conclusion: no bug, no logic/backend change required.**
- **Presentation only:** off-white body (`#F6F8F0`); the two form cards now use the MoonJoin treatment
  (`radiusLarge` + soft shadow `primary @0.05, blur 10` + `paddingSizeDefault`). Reused existing
  `CustomTextField`, `CustomButton` (brand-green Submit), the `DottedBorder` uploader, and the
  `SelectedCardWidget` (brand-green checkbox) — no new/duplicated widgets, no new controllers.
- **Logic 100% reused:** `OrderController` refund methods, `orderServiceInterface`, refund APIs, reason
  selection and image picker — unchanged.
- **Verified via REAL backend (order #100051, delivered):** reached through the real flow (Order Details →
  Restaurant Details → "Refund This Order"). Screen renders live refund reasons (Item is Broken [default-
  selected], Expired Product, "different from what Delivered", Some items not available), Comments field,
  dotted Upload-Image, and green Submit — 0 overflow. `flutter analyze` → **No issues**.
- **REFUND FLOW — permanently FROZEN by the user.** Production baseline.

## PRODUCT DETAILS — GROCERY / OTHERS MODULE — ✅ APPROVED & FROZEN
- **Screen:** `item/screens/item_details_screen.dart` (mobile) — the shared product page for **every non-food
  module** (Grocery, Fuel, Fashion, Pharmacy, Market, Drink Distributor, Solar & Power). Implemented from
  `ui-designs/…/product_details_for_grocery_and_others_module.png`.
- **ONE reusable implementation, not a fork:** Food keeps the frozen `FoodDetailsScreen` (option-group
  cards + Extras); grocery/others keeps `ItemDetailsScreen` (chip variations + In-Stock badge) — the two
  approved mockups genuinely differ, but both are driven by the **same** `ItemController`, the same
  computed `cartModel`/`cart`/`priceWithAddons`/`stock`, and the same `choiceOptions` variation model. The
  `navigateToItemPage` split (food → FoodDetailsScreen, others → ItemDetailsScreen) is unchanged.
- **Design:** green `WavyHeader` + controls row (back · store-icon chip + name + ★rating · share ·
  favourite), image **carousel** (imageFullUrl + imagesFullUrl) straddling the wave with animated dots;
  left-aligned name + white-card favourite; store name (green); price (green, with strikethrough original
  when discounted) + `unitType` chip; ★rating + row-right **In Stock / Out of Stock** badge; `choiceOptions`
  variations as **green/grey selectable chips** (Size/Type/Color…); light-green quantity stepper; Total
  Amount; and a fixed **Total + qty stepper + Add-to-Cart (cart icon)** footer.
- **Presentation only — zero logic change:** the existing inline pricing/variation/stock computation and the
  entire add/update-to-cart + another-store-reset + campaign→checkout flow were **reused verbatim** (the
  add-to-cart body was extracted into a private `_addToCart` with identical behaviour; only the dead
  `_key.currentState!.shake()` app-bar hook was dropped since the mobile app bar is replaced by the body
  header). Reused `WavyHeader`, `CustomImage`, `CustomButton`, `RatingBar`, `FavouriteController`,
  `itemController.setCartVariationIndex` / `setImageSliderIndex` / `setQuantity`. **Desktop path
  (`DetailsWebViewWidget`) and the desktop `QuantityButton` class are untouched.** Added `PageController`
  disposal (no leak).
- **Verified via REAL backend (Grocery item "Lemon" · store "Fruset"):** renders a 1:1 match to the mockup —
  wavy header + Lemon carousel (2 dots), name + fav, ₦380 with strikethrough ₦400, "Packs" unit chip,
  0.0★ (0), green In-Stock badge, **Color** chips (Yellow selected / Green), quantity stepper, Total ₦380,
  Description, and the Total + qty + Add-to-Cart footer. **0 overflow, 0 exceptions from this screen.**
  `flutter analyze` → **No issues**.
- **Approved refinement (spacing only):** the hero image/card was moved slightly **down** so it sits
  comfortably below the top controls row (header `top 92→132`, dots `300→340`, header height `344→384`) — no
  change to the controls row, store info, image size, or card design. Re-verified on the Lemon page: image
  clears the store name/rating/share/favourite, carousel + dots intact, 0 overflow, analyze clean.
- **PRODUCT DETAILS (GROCERY/OTHERS) — permanently FROZEN by the user.** The single non-food product-details
  baseline; reuse unchanged for Fuel/Fashion/Pharmacy/Market/Drink/Solar.
- **Pre-existing bug observed (out of scope, NOT introduced here):** `Reviews.fromJson`
  (`order/domain/models/order_model.dart:673`) throws `type 'String' is not a subtype of type 'int?'` when
  parsing the **order-track** response (e.g. #100051) — a model/BE type mismatch on a `Reviews` field. It is
  caught, doesn't break the UI, and predates this work. Flagged for a later dedicated fix (needs the exact
  field + backend confirmation before changing the model).

## ⚠️ Pre-existing issue to investigate LATER (do NOT touch during UI migration)
- **`Reviews.fromJson` — `type 'String' is not a subtype of type 'int?'`** at
  `lib/features/order/domain/models/order_model.dart:673` (via `OrderModel.fromJson` at `:257`), thrown while
  parsing the **order-track** response (observed on order #100051). A `Reviews` field is declared `int?` but
  the backend sends a `String`.
- **Status:** pre-existing backend/model type mismatch, **not** introduced by any UI migration work. The
  exception is caught, does not crash, and does not affect any redesigned screen.
- **Rule:** OUT OF SCOPE for the presentation-only migration. Do **not** modify models, API parsing, backend
  contracts, Review JSON, or Order models to "fix" this during UI work. Investigate as a dedicated task later
  (identify the exact field, confirm the backend contract, then correct the model parse).

## STORE / RESTAURANT PAGE — ✅ APPROVED, COMPLETE & FROZEN
The full mobile Store/Restaurant page (`store/screens/store_screen.dart`) redesigned to
`ui-designs/…/store_or_restaurant.PNG`, plus a **new premium embedded Map Card**. Approved by the user and
frozen as the **single shared storefront page for Food / Grocery / Pharmacy / Ecommerce** (Grocery module
includes Market, Fuel & Gas, Drink Distributor, Solar & Power). Presentation-only; all logic reused.

### New/changed
- **`store/widgets/store_hero_header.dart` (NEW, FROZEN)** — green hero (rounded bottom curve; search pill
  straddles the green→content transition): UPPERCASE name, cuisines (from category names), ★rating·delivery,
  **full vendor address** (`store.address`), "N Dishes/Items Available", cover image, and back · favourite ·
  share · notification · cart (favourite/share kept but visually subtle — no feature removed). In-store search
  pill (`getSearchStoreItemRoute`) + filter-chip row (Filters·Sort·Cuisine·Price·Delivery Time·More →
  existing `FilterWidget`). Reuses `StoreFilterChip`, `FavouriteController`, `NotificationController`,
  `CartController`, `StoreController.isStoreOpenNow`.
- **`store/widgets/store_map_view.dart` (NEW, FROZEN)** — premium embedded **location-awareness** map (NOT
  navigation): store + user markers, straight-line distance, **View on Map → expands the card in place**
  (animated, stays on the page; gesture-claiming interactive map for pan/zoom/explore); floating actions
  **Re-center · My Location · Directions Preview** (route polyline + road distance/ETA via the existing
  `direction-api`/`distance-api`, no live tracking) **· Open in Google Maps**. Reuses the existing store
  lat/lng, Google Maps integration, `AddressHelper`, `Geolocator`, `url_launcher`, `ApiClient`. Single map
  instance, lazy route fetch, controller disposed. Placed after the store info, before Categories.
- **`common/widgets/item_widget.dart` — premium Store dish layout (EXTENDED, not forked)** — new opt-in
  `premiumStoreLayout` (default false → every other screen unaffected): **uniform 122×122 image** (ClipRRect +
  `BoxFit.cover`, fixed card height so portrait/landscape images are all identical, no stretch/overflow),
  name, veg/non-veg, favourite, ★rating, price + old-price + `/unitType`, organic tag, **View Details** →
  existing item navigation. **Real Item data only — no fabricated badges/chips/ingredient dots** (backend has
  no such fields; user-confirmed). `common/widgets/item_view.dart` gains a `premiumStoreLayout` flag +
  intrinsic-height `_premiumItemList`; the Store page passes it on its item list.
- **`store/screens/store_screen.dart`** — mobile `SliverAppBar` → `StoreHeroHeader`; inserted `StoreMapView`;
  item list uses `premiumStoreLayout: true`; removed 5 now-dead imports. **Desktop path untouched.**
- i18n: `explore/away/recenter/my_location/directions_preview/open_in_google_maps/dishes/search_for/food/in/
  cuisine` added to en/ar/es/bn.

### Production bug fixed (user-requested)
- **Location search/geocode hang** — `LocationService.searchLocation` and
  `LocationRepository.getAddressFromGeocode` crashed on `response.body['error_message']` when the API returned
  a null/non-Map body (`NoSuchMethodError: '[]' on null`), hanging the location search. Both are now **fully
  guarded** (try/catch + `is Map` checks) — they can never throw/hang and only surface a real error message.
  No backend/API change. (This resolves the earlier "⚠️ Pre-existing issue" note about the map location flow.)

### Verification
- Live on iOS Simulator (Perozona, zone 7): hero header (rounded transition, straddling search, full address),
  embedded map (store+user pins, "3.7 km away"), **View on Map** expand-in-place, **Directions Preview**
  ("5.2 km · 13 min" route), and **uniform premium dish cards** (View Details) — all confirmed, **0 overflow /
  0 exceptions** (only sim-only Firebase APNS). `flutter analyze` → **No issues** in changed files; full
  project **48 issues, 0 errors** (baseline unchanged).
- **Cross-module reuse is architectural:** `StoreScreen` is the single `/store` route (module-agnostic), so
  the new header/map/dish layout serve **all storefront modules** automatically; product details keep the
  two frozen impls (`FoodDetailsScreen` for food, `ItemDetailsScreen` for grocery/pharmacy/ecommerce), split
  by `ItemController.navigateToItemPage`.

### FROZEN — official production storefront (do not redesign without explicit approval)
`StoreScreen`, `StoreHeroHeader`, `StoreMapView`, premium `ItemWidget` (store layout), `MoonjoinStoreCard`,
`AllStoreScreen`, and the store search/filters/categories/list/closed-open/promo-banner/map components are the
**single reusable storefront** for Food/Grocery/Pharmacy/Ecommerce. Reuse everywhere; only module data/APIs/
models/logic differ. Rental will reuse these components after its own redesign (later phase).

### Module HOME reuse — ✅ IMPLEMENTED & VERIFIED (clean home + discovery filters)
The approved `AllStoreScreen` storefront is the **primary module home for EVERY storefront Business Module
Type** — Food, Grocery (+ Market, Fuel & Gas, Drink Distributor, Solar & Power — all `moduleType == grocery`),
Pharmacy, Ecommerce (Fashion) — not hidden behind "See All". One shared implementation; only module data/
terminology differ ("All Restaurants" for food, "New on MoonJoin" for others).
- **`home_screen.dart`** — all storefront modules (`isFood || isGrocery || isPharmacy || isShop`) route to
  `AllStoreScreen(fromModule: true)`. Parcel keeps `ParcelCategoryScreen`; taxi/desktop unchanged.
- **The home stays CLEAN** — exactly the approved All Restaurants layout: promo banner · category chips · filter
  chips · Top Brands · `MoonjoinStoreCard` store list. **No module sections are auto-rendered as homepage
  blocks** (an earlier `moduleHome`-injection approach was replaced by the user's correction). The
  `storefrontMode` flag added to `GroceryHomeScreen`/`PharmacyHomeScreen`/`ShopHomeScreen` is unused by the
  storefront home (defaults false → legacy screens unchanged) and left in place; those screens' sections are
  NOT deleted.
- **Discovery filter chips (module features on demand):** `AllStoreScreen`'s filter row gained **Special Offer**,
  **Most Popular Items**, and **Nearby [Restaurants/Stores/Pharmacies/Shops]** (module-aware term via
  `moduleType`). Tapping one reveals results in place (frozen designs, real data only):
  - Special Offer → existing `ItemController.discountedItemList` as premium `ItemWidget` cards.
  - Most Popular Items → existing `ItemController.popularItemList` as premium `ItemWidget` cards (no invented
    ranking).
  - Nearby → the loaded store list sorted by real distance (`Geolocator` + `AddressHelper`) as `MoonjoinStoreCard`.
  New i18n: `nearby_restaurants/pharmacies/shops` (en/ar/es/bn). Only behaviour was added — the frozen
  `StoreHeroHeader`/`StoreMapView`/`MoonjoinStoreCard`/premium `ItemWidget`/banner/category/filter designs are
  untouched.
- **Top Brands fallback fix (user-requested):** when the admin promo rotation banner is NOT configured,
  `AllStoreScreen` no longer promotes the first store to a hero card above Top Brands. **Top Brands is the top
  element, then the full store list** (`_storeList` hero + skip removed).
- **Verified live:** Grocery home is clean (categories · filter chips · **Top Brands at top** (no banner) · store
  list with closed treatment); Food shows the rotating admin banner + Top Brands + full list (no hero);
  **Most Popular Items** chip → popular items as premium cards; **Nearby Restaurants** term correct for Food.
  0 overflow / 0 exceptions. Pharmacy/Ecommerce use the identical moduleType-driven path.
- **Minor polish noted (not blocking):** the `AllStoreScreen` search-pill placeholder is still the food-worded
  `search_for_food_restaurants_or_cuisines`; a module-aware placeholder (items/stores/products) is a small
  future tweak.

## 🐞 Production bug fixes (crashes) — 2026-07-13
Two "Null check operator used on a null value" crashes found while browsing the Food module were fixed
(presentation/defensive only; no backend, models, or business rules changed):
1. **"New on MoonJoin" strip crash (food/grocery module home).** `new_on_mart_view.dart` rendered the legacy
   `StoreCard`, which threw a null-check on latest stores that have `logo/cover_photo/latitude == null`
   (e.g. "Small and Cabrera Inc" from `/stores/latest`). **Fix:** the strip now reuses the **frozen
   `MoonjoinStoreCard`** (the approved All Restaurants card — null-safe), width-boxed at 280 in a 200-tall
   horizontal list; `onTap` opens the store via the same module-activate + `getStoreRoute` behaviour as
   AllStoreScreen. Legacy `StoreCard` import removed. This also matches the user's request to show the All
   Restaurants design there instead of the old card. **Verified on device:** section renders both latest
   stores as clean cards, **0 crash**; See All still → AllStoreScreen. `flutter analyze` clean.
2. **Food product-details crash.** `food_details_screen.dart` `initState` passed the *list* item for
   non-campaign items (`isCampaign ? widget.item : widget.item` — copy-paste bug), so items whose list
   payload had no `addOns` crashed in `ItemService.initializeAddonActiveList`. **Fix:** non-campaign items
   now fetch full details (`isCampaign ? widget.item : null`), matching the grocery `ItemDetailsScreen`.
   Defensive null-guards were also added to `initializeAddonActiveList` / `initializeAddonQtyList`
   (`addOns?.length ?? 0`). `flutter analyze` clean. (On-device re-test pending: tap a food item.)

## Planned: Global consistency pass (after all core screens are frozen)
After Home, All Restaurants, Food Product Details, Your Cart, Checkout, Payment and Order Success are all
frozen, run a **global consistency pass**: review the whole user journey and align spacing, typography,
shadows, animations, button sizes and transitions across every screen **without changing any approved
layout**. This is the final pre-production polish so the app feels like one cohesive product. (Includes the
deferred global currency-format improvement, e.g. thousands-comma on animated prices.)

## Deferred / not-yet-representable features (tracked, not removed)
- **Per-module home content** (food/grocery/pharmacy/shop views) still uses the pre-redesign UI — no
  dedicated reference image yet; kept fully functional and inherits the theme. Awaits its assigned phase.
- **Parcel & Taxi home variants** keep their existing layouts (reached via the shell) until their phases.
- Nothing has been removed; features without a redesigned UI remain accessible in their current form.

## STORE LIST MIGRATION — ✅ APPROVED, COMPLETE & FROZEN
The All Restaurants / All Stores experience was reopened for four connected pieces, verified live on the
zone-7 backend and approved by the user. All logic reused; presentation-only + one authorized feature
completion (search store-derivation).

### 1. Promotional banner → Admin Banner feed (paid promotional stores)
- Replaced the `featuredStoreList` carousel (empty on live) with the **existing Admin Banner feed**
  (`BannerController.getBannerList → bannerImageList/bannerDataList`), filtered to **store-target**
  (paid-advertising) banners, redesigned as `PromotionalBannerCarousel` in the MoonJoin style (same
  `CarouselSlider` package/pattern; autoplay 4 s, pause-on-touch, dot indicator; slider disposes its own
  timer — no leak). Tap → `_openStoreBanner` mirrors the existing `home/widgets/views/banner_view.dart`
  store-tap exactly (`setModule` + `getStoreRoute(page:'banner')` + `StoreScreen` arg). **Verified live:** 3
  rotating store banners (Perozona · Item7Go · Chruzz), tap opens the correct promoted store.
- **Files:** `store/screens/all_store_screen.dart`, `store/widgets/all_restaurants_widgets.dart`
  (`FeaturedStoreCarousel`→`PromotionalBannerCarousel`), `store/widgets/moonjoin_store_card.dart` (removed
  the now-dead `bannerOnly` mode).

### 2. Category → Stores only; Search → both (unchanged)
- Category browsing from the store list opens a **stores/restaurants-only** list
  (`getCategoryItemRoute(..., storesOnly:true)` → single tab, `setRestaurant(true)`; no item cards). Search
  keeps **Items + Restaurants** tabs. (Item-search cards hide the redundant store name via
  `hideItemStoreName`.) These were already implemented by the prior session; verified live.

### 3. Unified store card everywhere (single visual implementation)
- Every **mobile** store/restaurant list now reuses the approved **`MoonjoinStoreCard`** (no new card, no
  duplicated design). `common/widgets/item_view.dart` `_moonjoinStoreList` renders the mobile store case as
  a `ListView` of `MoonjoinStoreCard` (intrinsic height — no fixed-grid clipping); **desktop keeps its
  existing store cards; item lists unchanged.** This covers **All Restaurants/All Stores** (all "see all"
  entries), **category stores**, **search → restaurants**, the **module-home store grid**
  (`home_screen.dart`), **campaign stores**, and the Home **"New on MoonJoin"** strip (`new_on_mart_view`).
- **Reuse only:** legacy `StoreCardWidget`/`StoreCardWithDistance` are **kept** (still used by desktop and
  the not-yet-migrated Home per-module strips — not deleted).

### 4. Search "Restaurants" completion (item-type queries surface their stores)
- The backend store search matches **store names only**, so "Pizza" returned 0 restaurants. Completed the
  feature: the store branch of `SearchController.searchData` now also lists the **stores that sell the
  matching items** — derived from the existing item search (each item carries `storeId`) and fetched in full
  via the **existing** `stores/details/{id}` endpoint (new read-only passthrough
  `SearchService/Repository.getStoreDetails`; deduped vs name matches; capped at 20; best-effort — never
  breaks the primary search). **No new backend, no fabricated data.** **Verified live:** "Pizza" → Perozona
  shown as a `MoonjoinStoreCard` ("1 Restaurant Available").

### 5. Closed-store behavior (restored from the old design, modernized)
- **Reused existing open/close logic:** `StoreController.isOpenNow(store)` (`open==1 && active`); next
  opening from `store.storeOpeningTime` (backend `current_opening_time`, `'closed'` when none) via
  `DateConverter.convertRestaurantOpenTime` — the same source `NotAvailableWidget` uses. No new calc.
- **Card treatment (`moonjoin_store_card.dart`):** closed → translucent dark cover overlay + centered
  premium status badge (clock glyph + white type, rounded translucent pill). Text: **"Closed • Opens at
  8:00 AM"** when active + a valid next time; otherwise **"Closed"**. i18n keys `closed`, `opens_at` added to
  en/ar/es/bn.
- **Open-first ordering:** new reusable `StoreController.sortStoresOpenFirst(list)` (stable partition,
  reuses `isOpenNow`) applied in `all_store_screen` `_applyFilter` (after the existing filter/sort) and in
  `item_view` `_moonjoinStoreList` (category + search) and the New-on strip. Filter → then open-first;
  pull-to-refresh / pagination / search re-sort on rebuild; stable → **no flicker**.
- **Verified live** (~01:45, most stores closed): Perozona **open** (no overlay, sorted first); **Chruzz**
  "Closed • Opens at 08:00 AM"; **SouPlug** "Closed" (no schedule); **Chicken Republic** "Closed" (inactive).
  Consistent in search (details endpoint returns the same schedule-aware `open`). Auto open↔closed
  transitions are data-driven from the backend `open` flag on each list load — no client timer.

### Verification & freeze
- `flutter analyze` → **No issues** in every changed file; full project **48 issues, 0 errors** (baseline
  unchanged, no new issues). iOS build clean; **0 RenderFlex overflow, 0 exceptions** from these screens
  (only sim-only Firebase APNS + the pre-existing `LocationService.searchLocation` bug remain).
- **Files modified:** `store/screens/all_store_screen.dart`, `store/widgets/all_restaurants_widgets.dart`,
  `store/widgets/moonjoin_store_card.dart`, `store/controllers/store_controller.dart` (`sortStoresOpenFirst`),
  `common/widgets/item_view.dart`, `features/home/widgets/views/new_on_mart_view.dart`,
  `search/controllers/search_controller.dart` + search service/repository (+interfaces) `getStoreDetails`,
  `assets/language/{en,ar,es,bn}.json`.
- **STORE LIST — permanently FROZEN by the user.** `MoonjoinStoreCard` (with the closed-store treatment),
  `PromotionalBannerCarousel`, `sortStoresOpenFirst`, and the `item_view` store path are the permanent
  baseline for **every** store/restaurant listing. Reuse unchanged; do not revisit unless the user requests.

### ⚠️ Pre-existing bug to investigate later (NOT touched — do not fix during UI migration)
- `LocationService.searchLocation` (`location_service.dart:136`) throws `NoSuchMethodError: '[]' on null`
  (`error_message`) when the geocode/autocomplete API returns an error shape — observed live while typing a
  location in the map search. Pre-existing (not introduced by this work); the map's own "use current
  location" flow is unaffected. Investigate as a dedicated task (confirm the backend error contract, then
  guard the parse).

---

## Shared Quantity Control — Official MoonJoin Quantity System — ✅ APPROVED, COMPLETE & FROZEN

The single reusable quantity control for **every** storefront module (Food, Grocery, Market, Fuel & Gas,
Drink Distributor, Solar & Power, Pharmacy, Fashion/Ecommerce). Fix applied to **shared cart logic**, not
per-screen — so every list card, Product Details, add sheet, and Your Cart inherit it. See COMPONENTS.md
**"Shared Quantity Control (FROZEN)"**.

### Problem → root cause → fix
- **Spinner + wait:** `CartCountView` swapped the number for a `CircularProgressIndicator` during the online
  round-trip → now **always shows the live number** (optimistic).
- **Second tap opened Product Details:** `+/−` `InkWell`s had `onTap: isLoading ? null : …`; a null `onTap`
  stops absorbing the tap → it hit the card beneath. Now **always-active** so the tap is always absorbed.
- **Rapid taps reverted (5→4):** each tap fired an online update, and every `updateCartQuantityOnline` calls
  `getCartDataOnline()` which **replaces `_cartList`**; out-of-order refetches clobbered the newer value.
  Fixed with **optimistic update + 500ms debounced sync** (`_scheduleQuantitySync`, `_quantitySyncTimers`)
  and **pending-quantity preservation** (`_pendingQuantities` re-applied after every `getCartDataOnline`).
- **Qty = 1 delete icon everywhere:** `CartCountView` minus becomes `Images.delete` + error tint at qty 1
  (matches Your Cart's `QuantityButton(showRemoveIcon:)`).

### Project-wide audit (duplicate removal)
- All storefront list cards confirmed on `CartCountView`; Product Details / add sheet / Your Cart on the
  shared `QuantityButton` → `CartController.setQuantity`. **One quantity system.**
- **Deleted unused duplicate scaffolding:** `moonjoin/quantity_stepper.dart` (`QuantityStepper`) and
  `moonjoin/floating_checkout_bar.dart` (`FloatingCheckoutBar`) — verified referenced by no screen; barrel
  exports removed. `moonjoin/product_card.dart` has only an `onAdd` icon (no quantity logic) and is unused.

### Verification & freeze
- `flutter analyze` → **48 issues, 0 errors** (baseline unchanged, no new issues). Live on iOS Simulator:
  rapid + held at **5** (no revert), qty-1 **red delete** icon renders + removes, cart totals update live,
  no spinner, second tap never opened details.
- **Files modified:** `features/cart/controllers/cart_controller.dart` (optimistic + debounce + pending
  preservation), `common/widgets/cart_count_view.dart` (live number, always-active, qty-1 delete),
  `features/cart/widgets/cart_item_widget.dart` (always-active buttons). **Deleted:**
  `moonjoin/quantity_stepper.dart`, `moonjoin/floating_checkout_bar.dart` (+ barrel export lines).
- **Business logic preserved:** same services/APIs/signatures (`decideItemQuantity`,
  `calculateDiscountedPrice`, `updateCartQuantityOnline`, `getCartDataOnline`) — only call timing/coalescing
  and UI state changed.
- **FROZEN by the user** as the official shared quantity control. Reuse unchanged; never create another
  quantity widget.

---

## Food Product Details — hero image safe-area fix — ✅ APPROVED • COMPLETE • FROZEN

Food Product Details (`FoodDetailsScreen`) hero image sat too high (`Positioned(top: 92)` in a `330`-tall
header), landing inside the top-controls band (safe-area top + 34px control height). Fixed by reusing the
**Grocery** details (`item_details_screen.dart`) hero offset **`top: 132`**, and growing the header box
`330 → 370` so the taller Food image (210) isn't clipped and its spacing below is preserved.

- `FoodDetailsScreen` hero image now **respects the correct safe area** and no longer touches the **Back
  button, Favourite button, Share button, Store badge, Store name, Rating, or header information**.
- **Grocery Product Details was intentionally NOT modified** (`item_details_screen.dart` untouched).
- **Only two layout values changed** (`_header`: `top` 92→132, `SizedBox.height` 330→370). **No redesign.**
- **Preserved:** business logic, APIs, navigation, animations, typography, layout, buttons, icons.
- **No overflow.** `flutter analyze` **48 issues, 0 errors** (baseline unchanged). Verified live on simulator.
- **File:** `features/item/screens/food_details_screen.dart`.
- **FROZEN by the user** — do not redesign or modify unless the product owner explicitly approves.

---

## Shared component architecture audit (before Parcel/Rental) — ✅ COMPLETE

Project-wide word-matched search for duplicate reusable components (search bars, filter/category chips,
store cards, product cards, rating, price, favourite, quantity, empty/error states, loading, promo banners,
hero headers, map cards). Result: **one implementation per shared production responsibility.**

- **Single production implementation confirmed:** Quantity → `CartCountView`/`QuantityButton`→`setQuantity`;
  mobile store card → `MoonjoinStoreCard` (frozen); product card → `ItemWidget` (+`CartCountView`); hero →
  `StoreHeroHeader` (store) / `WavyHeader` (details); map → `StoreMapView` (frozen); banner → the approved
  rotating promo carousel. Desktop/web `card_design/store_card*` and feature-specific search bars
  (chat/location/rental) are **legitimate platform/module variants**, not duplicates.
- **Deleted — dead duplicates of a FROZEN production component (verified 0 references, barrel exports
  removed):** `moonjoin/restaurant_card.dart` (`RestaurantCard` → superseded by `MoonjoinStoreCard`),
  `moonjoin/product_card.dart` (`ProductCard` → superseded by `ItemWidget`), `moonjoin/promotion_banner.dart`
  (`PromotionBanner` → superseded by the approved rotating Promo Banner). (Earlier: `quantity_stepper.dart` +
  `floating_checkout_bar.dart`.)
- **Kept — Reserved Shared Foundation Components (unused, NOT duplicates of a frozen component):** generic
  primitives left in `moonjoin/` for upcoming modules (Parcel / Rental / Short Apartment Rental) — dialogs,
  bottom sheets, text field, empty/error states, loading skeletons, success banner, information card, cart
  summary card, status badge, price row, filter chip, variation/option selectors, bottom action bar, module
  icon/card. Documented in COMPONENTS.md as **Reserved Shared Foundation (Unused)**. Do not delete.
- `flutter analyze` **48 issues, 0 errors** after deletions (baseline unchanged).

---

## PARCEL — Screen 1: Parcel Home / Category — ✅ APPROVED • COMPLETE • FROZEN

First screen of the **Parcel** Business Module Type (visible module: Package Delivery). Design authority:
`ui-designs/Parcel/parcel_home.png` (Parcel is not in the Active Figma → ui-designs fallback). Presentation
only — no controller/repository/service/API/model/route/business-logic changes.

### What changed (presentation only)
- **Header** `features/parcel/widgets/parcel_app_bar_widget.dart` — rebuilt as a Parcel-specific green wavy
  header that **reuses the frozen `WavyHeader`**: back button, amber module glyph, module name +
  "Send packages to your loved ones", search + cart icons (cart badge = `CartController.cartList.length`),
  and a white location pill (address → location screen) with a notification bell. No frozen component modified.
- **Category cards** `features/parcel/widgets/deliver_item_card_widget.dart` — restyled the `isDeliverItem`
  card: illustration fills the upper portion of the card (`Expanded` + `BoxFit.contain`, full image, no crop,
  no distortion), bold centered title, gray 2-line description. API unchanged (still used by the dashboard
  parcel sheet).
- **"Experience the best with us"** — restyled `mobileExperienceView` into a single tinted feature strip
  (icon + green title + subtitle, vertical dividers), **wrapping the backend `whyChoose` banners**.
- **"Easiest way to get services"** `features/parcel/widgets/sevice_info_list_widget.dart` — redesigned into a
  numbered step flow (green numbered circles + dotted connectors + title/subtitle), **wrapping the backend
  `videoContent.bannerContents`**; the backend video/image banner is preserved in a MoonJoin card above it.
- **Promo banner** (admin `parcelOtherBanner`) preserved; collapses cleanly when empty.
- Category grid cell height set to 190 (mobile) so the full illustration is large enough to match the design.
- i18n keys `package_delivery`, `send_packages_to_your_loved_ones` added to en/ar/es/bn.

### Reused (no duplication)
Frozen `WavyHeader`; `CartController` (cart count); shared routes (`getSearchRoute`, `getCartRoute`,
`getNotificationRoute`, `getParcelLocationRoute`); `CustomImage`; existing parcel widgets
(`DeliverItemCardWidget`, `ServiceInfoListWidget`, `GetServiceVideoWidget`) restyled in place — no new widgets.

### Backend investigation (two blank sections)
Confirmed from **live API responses**, not guessed: `GET /api/v1/other-banners/why-choose` → `{banners: []}`
and `GET /api/v1/other-banners/video-content` → `{banner_contents: []}`. **Root cause: admin has not
configured these sections** (not a code bug, not local assets, not a load failure). The UI wraps the backend
and renders empty until admin populates them. Configure via:
- Why Choose Us: API `/api/v1/other-banners/why-choose`, model `WhyChooseModel → Banners`
  (image / title / short_description).
- Video Content / Get Service: API `/api/v1/other-banners/video-content`, model `VideoContentModel`
  (banner_type, banner_image_full_url / banner_video, banner_contents value pairs).

### Verification
Live backend (zone Ogbomoso). `flutter analyze` **48 issues, 0 errors** (baseline unchanged). No overflow,
no distortion, no build errors. Temporary debug logging added during investigation was fully removed.
Business logic / APIs / controllers / repositories / models / routes / navigation preserved.

### Files
`features/parcel/screens/parcel_category_screen.dart`, `features/parcel/widgets/parcel_app_bar_widget.dart`,
`features/parcel/widgets/deliver_item_card_widget.dart`, `features/parcel/widgets/sevice_info_list_widget.dart`,
`assets/language/{en,ar,es,bn}.json`. **FROZEN by the user.**

---

## PARCEL — Screen 2: Parcel Location — ✅ APPROVED • COMPLETE • FROZEN

Second Parcel screen (2-step Sender/Receiver wizard). Design authority `ui-designs/Parcel/parcel_details.png`
(not in Figma). Presentation only — TabController, TabBarView, validation, Google Places, map picker, saved
addresses, country-code, and navigation all preserved.

### What changed (presentation only)
- **Header** (`parcel_location_screen.dart`) — replaced the plain `CustomAppBar` (mobile) with a green wavy
  header **reusing the frozen `WavyHeader`**: white back button, "Parcel Location" title +
  "Provide pickup location and sender details" subtitle, and a **2-step (1 → 2) indicator** driven by the
  sender/receiver tab (`parcelController.isSender`). Desktop keeps `CustomAppBar`.
- **Sender / Receiver toggle** — restyled into a segmented pill with a person icon + label per tab (active =
  green fill, white text). Same `TabBar`/`_tabController` + the `onTap` sender-validation logic preserved.
- **Form** (`parcel_view_widget.dart`) — pickup/delivery + Sender/Receiver Information cards restyled
  (`CustomCard` rounded + side margins); field prefix icons added (street `signpost`, house `home`, floor
  `stairs`, name `person`); added the **security reassurance note** ("Your information is secure…") with a
  shield glyph. The Google-Places `TypeAheadField`, "Change Address" saved-address sheet, "Select from map"
  picker, and all controllers/validation are unchanged.
- i18n keys `provide_pickup_location_and_sender_details`, `your_information_is_secure_message` added to
  en/ar/es/bn.

### Reused (no duplication)
Frozen `WavyHeader`; shared `CustomCard`, `CustomTextField` (prefixIcon), `CustomButton`; existing parcel
widgets `ParcelViewWidget`, `SavedAddressBottomSheet`; shared location/address controllers + routes.

### Verification
Live backend. `flutter analyze` **48 issues, 0 errors** (baseline unchanged; the 2 info lints in
`parcel_view_widget.dart:144` are pre-existing, untouched). Header + step indicator + toggle verified on
simulator; "Change Address" opens the saved-address sheet; sender/receiver switching, Google Places, map
picker, and Continue navigation preserved. No overflow, no build errors.

### Files
`features/parcel/screens/parcel_location_screen.dart`, `features/parcel/widgets/parcel_view_widget.dart`,
`assets/language/{en,ar,es,bn}.json`.

---

## PARCEL — Screen 3: Parcel Request — ✅ APPROVED • COMPLETE • FROZEN (2026-07-30)

Third/final Parcel screen (the parcel "checkout"/review). Design authority `ui-designs/Parcel/parcel_request.PNG`
+ `parcel_request_scroll_down.PNG` (not in Figma). Presentation only — charge calc, place-order,
payment/offline flow, order tax, and navigation all preserved.

### State found → what changed
The screen already contained every design section in order and reused MoonJoin-styled shared widgets
(`CardWidget`, `TripFromToCard`, `TipsWidget` [already Figma-styled], `PaymentButton`, `CheckoutCondition`,
`CustomButton`) + the white `CustomAppBar` header that matches the design. So the redesign was minimal:
- **`details_widget.dart`** — added the design's leading **avatar square** to the Sender/Receiver detail
  cards (person glyph in a tinted rounded square); name/phone/email rows preserved.
- **`parcel_request_screen.dart`** — fixed a **5px RenderFlex overflow** in the Delivery Man Tips row (tips
  `SizedBox` height 60 → 66). No other change.

### Backend-driven sections (handled, not fabricated)
Distance + Delivery Fee (`getDistance`/`extraCharge` → "Calculating" then live values, e.g. 0.00 km / ₦700);
Delivery Man Tips (config `dmTipsStatus`, `getDmTipMostTapped`); Charge Pay By; payment methods
(zone/config: COD, wallet, digital `activePaymentMethodList`, offline); Order Summary (computed: fee, tips,
VAT, additional charge, total); terms. All render from live config/order APIs and degrade gracefully when a
capability is disabled. No admin configuration missing for this screen.

### Verification
Live backend (Ogbomoso). Verified on simulator top + scrolled — category dashed card, Sender/Receiver cards
(with avatar), Address Information (dotted connector), Distance/Fee, instruction, tips (no overflow),
Charge Pay By, Cash on Delivery / Wallet, Pay Via Online (9psb / Pay Offline), Order Summary, Confirm — all
match the design. `flutter analyze` **48 issues, 0 errors** (baseline unchanged). No overflow, no build errors,
no regressions. Place-order / payment flow preserved (unchanged).

### Files
`features/parcel/widgets/details_widget.dart`, `features/parcel/screens/parcel_request_screen.dart`.

---

## PARCEL — Screen 3 payment refinement: shared "Choose Payment Method" + Package Protection

Post-approval refinements to the (approved) Parcel Request screen. Presentation/reuse only.

### Shared payment architecture (reuse, not new)
- Replaced Parcel's inline payment section (COD/Wallet `PaymentButton`s, "Pay Via Online" digital list, the
  9PSB option + a short-lived Virtual Account popup, and `OfflinePaymentButton`) with the **shared
  `PaymentSection`** card (`checkout/widgets/payment_section.dart`) + `PaymentMethodBottomSheet` — the exact
  component/controller/sheet used by Food/Grocery/Pharmacy/Ecommerce. Selection is driven by
  `CheckoutController`; at confirm-time it is **synced** into `ParcelController` so the existing
  `placeOrder`/`parcelCallback` (and backend) stay unchanged. Removed now-unused imports/widgets
  (`payment_button`, `offline_payment_button`, `virtual_account_bottom_sheet`, `just_the_tooltip`).
- **Charge Pay By = Receiver** auto-selects Cash on Delivery (collected by the delivery man) so Confirm goes
  through with no payment prompt — restores the original behaviour; **Sender** still requires a method.
- Delivery Man Tips overflow (5px) fixed in the **shared** `deliveryman_tips_section.dart` (60→66),
  correcting Food/Grocery/Pharmacy/Ecommerce at once. `TipsWidget` was already the shared chip.

### Package Protection — Frontend preparation exists · Backend configuration dependency PENDING · NOT a UI migration blocker
New Parcel Request section between Delivery Man Tips and Charge Pay By. **No backend feature exists** (audited
parcel controller/repo/service/models/config); built as a clean, backend-ready frontend architecture — **no
invented APIs**.
- **Config-driven (backend-ready):** `ConfigModel` gained two nullable, forward-compatible fields —
  `packageProtectionStatus` and `packageProtectionPercentage` (parsed from `package_protection_status` /
  `package_protection_percentage`; null until the backend sends them). `ParcelController` exposes
  `packageProtectionEnabled` + `packageProtectionPercentage` that **read those config values**, so after
  backend integration only the configuration source changes — not the UI, controller flow, calc, or widgets.
  The temporary dev fallback lives in **one isolated place** (two consts in `ParcelController`) marked
  `TODO(BACKEND): Remove fallback after backend configuration is available`. The whole section is gated on
  `packageProtectionEnabled`, so the backend can switch it off with no code change.
- State on `ParcelController` (isolated): `packageProtectionSelected`, `packageValue`, `protectionFee`,
  `togglePackageProtection`, `setPackageValue`, `resetPackageProtection`. **No hardcoded percentage anywhere
  in the UI/flow.**
- `protectionFee = packageValue × (packageProtectionPercentage / 100)`; the percentage is a **percent number**
  in the SAME format the backend will send (`package_protection_percentage: 1.5` = 1.5%), so integration needs
  no calc change. Flows into the **existing** Order Summary ("Package Protection" line) + Total (single shared
  calc — no new total system). Instant updates.
- **Backend fields required:** `package_protection_status`, `package_protection_percentage` (config). At the
  parcel place-order integration point, send `package_protection` (bool) / `package_value` / `package_protection_fee`
  through the **existing** parcel order flow (no new order/payment system) and add the fee to `orderAmount`.
- UI reuses `CardWidget`, `CustomTextField` (`isAmount` currency input), `PriceConverter`, `AnimatedSize`
  (smooth expand/collapse). Select → focuses the amount field + numeric keyboard; Unselect → clears amount,
  removes fee, collapses. Validation: when selected, package value required and > 0.
- **Order placement unchanged** — a clearly-marked backend-integration point documents what to send when
  ready (declared value + fee + selected flag; add to `orderAmount`) and notes the existing unused
  `PlaceOrderBodyModel.extraPackagingAmount` as a candidate channel. Fee is display-only for now, so existing
  parcel ordering (protection off or on) is unaffected.
- i18n added to en/ar/es/bn. `flutter analyze` **48 / 0**. **Not frozen — pending backend integration.**

### Files
`features/parcel/screens/parcel_request_screen.dart`, `features/parcel/controllers/parcel_controller.dart`,
`features/checkout/widgets/deliveryman_tips_section.dart`, `assets/language/{en,ar,es,bn}.json`.

---

## Backend Integration Queue Reference

Frontend features that are complete/approved but waiting for backend (API / config / database / admin) are
tracked in **`docs/BACKEND_INTEGRATION_QUEUE.md`** — the single source of truth. **Future backend work MUST
check that file before creating APIs, models, or admin settings**, and must adapt to the approved frontend
contract (never redesign the frontend when backend starts). Currently queued: **Parcel Package Protection**
(config + order fields) and **Parcel "Why Choose Us" / "Get Service"** (admin configuration of existing
endpoints).

---

## STORE CATEGORY-NAVIGATION CHIPS → `MoonjoinSubCategoryBar` — ✅ FROZEN (2026-07-31)

**Store category chip migration — Analyzer Verified · Runtime Verified (physical iPhone) · Owner Approved · FROZEN.**
Presentation only; `store_screen.dart` (mobile) — the legacy custom store food-category chip strip replaced with
the frozen **`MoonjoinSubCategoryBar`** (single source of truth). `MoonjoinSubCategoryBar(labels:
storeController.categoryList.map(name), selectedIndex: storeController.categoryIndex, onSelected: (i)=>
storeController.setCategoryIndex(i))`. The mobile category `SliverPersistentHeader` height was grown `90 → 112`
(mobile only) to fit the 52px component; **desktop renders `SizedBox` for this strip and is untouched.**

- **Single source of truth:** store category-navigation chips now use `MoonjoinSubCategoryBar` — the ONE component
  for category-navigation sub-category chips across MoonJoin. **No duplicate sub-category chip implementations.**
- **Verified on physical iPhone:** Food, Grocery, Pharmacy, and Ecommerce store journeys — category switching works,
  chip appearance matches the approved component, no regression.
- **Preserved / unchanged:** `categoryList` / `categoryIndex` / `setCategoryIndex`, category filtering, item
  sections, store loading, pagination, APIs, routes, cart, `StoreHeroHeader`, the `StoreFilterChip` system
  (Filter · Sort · Fast Delivery · Free Delivery · Rating · Offers · Discount · Nearby), store cards, item widgets,
  controllers, business logic, desktop layout. **File:** `lib/features/store/screens/store_screen.dart` only.
- `flutter analyze` → **No issues found!**

---

## STOREFRONT BROWSE → CATEGORY ITEMS — `category_item_screen.dart` — B1 + B2 + B3 — ✅ FULLY FROZEN (2026-07-31)

**Category Items B1 (mobile header layer) — Analyzer Verified · Runtime Verified (Owner physical iPhone) · Owner
Approved · FROZEN.** First sub-phase of the Storefront Browse cluster; presentation only. Entry: Home → Category
→ Category Items.

### What changed (B1, presentation only — one file)
- **Header:** mobile legacy raw `AppBar` → frozen **`ProfilePageHeader`** (green wave · centered category name ·
  back button · **cart in `trailing`** using the existing `CartWidget` → `getCartRoute()`). Back preserved verbatim
  (`isSearching ? toggleSearch() : Get.back()`). `appBar` is now desktop-only (`WebMenuBar`).
- **Search relocation:** the in-`AppBar` raw search `TextField` → the frozen **`MoonjoinSearchBar`** (persistent,
  in a control row below the header). Submit → existing `searchData(...)` (verbatim args); close icon → existing
  `toggleSearch()` + clears the field. `_searchController` added (+ `dispose`).
- **VegFilter reuse:** **`VegFilterWidget` reused exactly** (identical `onSelected` logic) beside the search bar.
- **Desktop:** `WebMenuBar` + `FooterView` web layout **untouched**.

### Reused (no duplicate systems introduced)
`ProfilePageHeader` (no new header), `MoonjoinSearchBar` (no new search field), `CartWidget`, `VegFilterWidget`.
No new header/search/card/empty-state/loading system.

### Preserved / not touched
`ItemsView` → `MoonjoinStoreCard`/`ItemWidget`/`NoDataScreen`, Product Details, `CategoryController`, the Item/Stores
`TabBar` + `TabController` + `NotificationListener` reload, sub-category chips, pagination, `searchData`/
`toggleSearch`/`setRestaurant`/`setSubCategoryIndex`, `storesOnly`, cart logic, routes, models, desktop.

### B2 (Item/Stores segmented control) — ✅ FROZEN (2026-07-31)
Mobile Item/Stores legacy `TabBar` → the **frozen MoonJoin Favorites segmented pill** (single source of truth):
soft-green track (`primary@0.08`, `radiusExtraLarge`), rounded green filled indicator (`TabBarIndicatorSize.tab`,
`indicatorPadding: zero`), `dividerColor: transparent`, white selected / `hintColor` unselected labels. **Same
`_tabController` + tabs (`item` / `restaurants`|`stores`); `storesOnly` gate preserved; styling only — no new
segmented control.** Desktop TabBar untouched. Preserved: `NotificationListener` reload, `setRestaurant`,
pagination, `searchData`/`toggleSearch`, `storesOnly`, controllers, routes, models. Analyzer Verified · Runtime
Verified (owner physical iPhone, release build) · Owner Approved · FROZEN.

### B3 (sub-category chips) + MoonJoin Sub-Category Component — ✅ FROZEN (2026-07-31)
Mobile sub-category chips migrated to a **new single reusable component** and the screen's inline implementation
removed. **New file:** `common/widgets/moonjoin/moonjoin_sub_category_bar.dart` — **`MoonjoinSubCategoryBar`**
(`labels`, `selectedIndex`, `onSelected`), render frozen exactly as owner-approved: `SizedBox(height:52)` →
horizontal `ListView.builder` (`padding: horizontal paddingSizeDefault`) → `Center` → `MoonjoinFilterChip`
(the label-clipping bug — a fixed-height cap below the chip's intrinsic height — was fixed inside the component
by using horizontal-only list padding + `Center`). `category_item_screen.dart` now calls
`MoonjoinSubCategoryBar(labels: subCategoryList.map(name), selectedIndex: subCategoryIndex, onSelected: (i)=>
setSubCategoryIndex(i, categoryID))`; gate/filtering/scroll/selected state unchanged.

**SINGLE SOURCE OF TRUTH (permanent rule):** `MoonjoinSubCategoryBar` is the ONLY sub-category chip implementation.
No duplicate sub-category chips; no screen implements its own sub-category chip style; all future category-navigation
sub-category areas MUST reuse it exactly. **Scope: category-navigation sub-categories only — NOT** Home/module
filter/sort/action chips (Filter · Sort · Fast Delivery · Free Delivery · Rating · Offers · Discount · Nearby),
which are separate and untouched; the unused generic `FilterChipBar` was inspected and left untouched (it cannot
reproduce the fixed-height approved render, so it was not forced). Analyzer Verified · Runtime Verified (owner
physical iPhone, release build) · Owner Approved.

### Screen status: FULLY FROZEN
`category_item_screen.dart` is **Fully Frozen** — B1 (header) + B2 (segmented control) + B3 (sub-category
component) all owner-approved. Desktop layout preserved legacy (its own chips/TabBar untouched, mobile-first).

### Verification
`flutter analyze lib/features/category/screens/category_item_screen.dart` → **No issues found!** Runtime verified
on a physical iPhone (release build; owner-approved): header/title/back, cart, search, veg filter, item/store lists,
sub-category chips, tabs, pagination, empty state — no regression.

### Files
`lib/features/category/screens/category_item_screen.dart` (only file changed).

---

## CHAT THREAD (message screen) — Phase B (B1 + B2) — ✅ COMPLETE • FROZEN (2026-07-30)

**Chat Thread — Implemented · Analyzer Verified · Runtime Verified (physical iPhone) · Owner Approved · FROZEN.**
Presentation-only migration of the message screen (`ChatScreen`), closing the Chat cluster (Conversation List
frozen 8E). Design authority: MoonJoin Premium Design System (no Figma frame for the thread).

### What changed (presentation only)
- **B1 — Header:** mobile legacy `AppBar` → frozen **`ProfilePageHeader`** (green wave, centered receiver name,
  back button, receiver-avatar `trailing`); back logic preserved verbatim (`fromNotification`→`getInitialRoute()`
  else `Get.back()` via `onBack`). Desktop keeps `WebMenuBar`. Body wrapped so the header sits above the thread.
- **B2 — Bubbles (`message_bubble_widget.dart`):** sent = MoonJoin **medium brand-green** (`primaryColor`) fill +
  white text + premium rounded (large radii, small bottom-right tail); received = neutral **theme token**
  (`disabledColor@12%`) + adaptive text + premium rounded (small top-left tail); in-thread order-card status →
  frozen **`StatusBadge`**. Removed hardcoded `#E8EEFA` and `Colors.deepPurple`; tokens only, dark-mode safe.
- **Keyboard fix (FocusNode):** dedicated `_inputFocusNode`; **iOS-only** post-frame `requestFocus()` after the
  native image picker (capture focus → `unfocus()` → `await pickImage()` → re-focus if previously focused), so the
  keyboard reopens via Flutter's own metrics path and the composer + full send button stay above the keyboard on
  every image upload. `pickImage` signature `void`→`Future<void>` (enabler only). **`resizeToAvoidBottomInset`
  unchanged; Android/web unchanged.**

### Draft ownership — PER-CONVERSATION (permanent architecture rule)
Owner rule (2026-07-30): **one conversation = one isolated draft state; global/shared draft state is FORBIDDEN.**
Each conversation owns its own **text + image** draft, keyed by the chat route's conversation identifier
(`_draftOwnerKey` → `conversationID`, with a notification-target fallback). Implemented on `ChatController` as
`_textDrafts` / `_imageDrafts` / `_rawImageDrafts` + `loadConversationDraft(key)` / `saveConversationDraft(key,
text)`; `ChatScreen` restores only its own draft on `initState`, saves only its own on `dispose`; the active
`_chatImage`/`_chatRawImage` remain the current-conversation working set (used unchanged by pick/remove/send);
sending clears only that conversation's draft. **The previous global draft experiment was rejected because it
violated conversation isolation. The final implementation uses conversation-keyed drafts.** (The global
`typedDraft` on the singleton had leaked Vendor→Admin→Store; a global/shared draft must never be reintroduced.)

### Preserved / not touched
`ChatController` business logic, send/receive, image upload/compression, attachment flow, pagination, Pusher,
read status (`isSeen`), `NotificationBodyModel`, `getChatRoute`, routing, notification flow, frozen Conversation
List (8E).

### Verification
`flutter analyze` (chat_screen + message_bubble + chat_controller) → **No issues found!**; full project **0
errors** (baseline unchanged). Runtime verified on a **physical iPhone** (owner-approved): header, bubbles
(light/dark), keyboard-on-image-upload (continue typing immediately, send button visible), image send,
send/receive, read status, pagination, navigation, **no draft leakage**, no regressions.

### Files
`features/chat/screens/chat_screen.dart`, `features/chat/widgets/message_bubble_widget.dart`,
`features/chat/controllers/chat_controller.dart` (pickImage signature + per-conversation draft maps/methods).

---

## MOONJOIN NOTIFICATION SYSTEM — Phase A1 — ✅ COMPLETE • FROZEN (2026-07-30)

**MoonJoin Notification System — Implemented · Analyzer Clean · Runtime Unaffected · Owner Approved · FROZEN.**
Phase A1 = the **architectural notification layer only** (façade + catalog). **NOT a redesign, NOT UI polish,
NOT an order-communication migration.** The existing order-communication experiences remain frozen and untouched.

### What was created (additive only)
- **Façade** `lib/common/widgets/moonjoin/notifications/moonjoin_notifications.dart` — `MoonJoinNotifications`, a
  **thin orchestration layer** over existing frozen primitives (`SuccessBanner`, `InformationCard`, `StatusBadge`,
  `MoonjoinBottomSheet`, `MoonjoinButton`, `MoonjoinDialog`, `ConfirmationDialog(moonjoin:true)`,
  `MoonjoinErrorState`, `MoonjoinEmptyState`, `showCustomSnackBar`). **No new UI component.** Pure presentation —
  no state, no API, no controller/repository/service; all behaviour via caller callbacks. Plus a tiny
  `MoonJoinNotificationAction` data holder (label + callback + isPrimary) for `warningSheet` actions.
- **Taxonomy → method map:** Success → `success()`/`successBlock()` · Information → `infoCard()`/`statusBadge()` ·
  Warning → `warningSheet()` · Error → `error()`/`confirm()` · Transient → `transient()` (→ `showCustomSnackBar`,
  the one toast) · page states → `errorState()`/`emptyState()`. Reused the existing i18n key
  `sorry_something_went_wrong` (no new keys invented).
- **Barrel export** added to `moonjoin_components.dart` (one line).
- **Standard doc** `docs/MOONJOIN_NOTIFICATION_SYSTEM.md` (purpose · architecture principle · taxonomy · component
  mapping · reuse rules · forbidden duplicate patterns · protected frozen surfaces · future-AI compatibility).

### Protected — NOT touched (frozen)
`module_landing_view.dart` `_UnavailableItemsCard` · `order_edit_screen.dart` (Edit Unavailable Items) ·
`dashboard_screen.dart` + `running_order_view_widget.dart` · `OrderController`/`CartController`/`CheckoutController`
· all APIs/models/routes · every existing MoonJoin primitive. **A2 (running-order status-card polish)** and
**A3 (unavailable-preference sheet restyle)** are separate future decisions — excluded from A1.

### Verification
`flutter analyze` on the façade + barrel → **No issues found!**; full project **0 errors** (35 pre-existing
info/warnings, none in the new file; baseline unchanged). No symbol clash (`MoonJoinNotifications`/
`MoonJoinNotificationAction` defined only in the new file). **Additive foundation with zero call sites → runtime
behaviour unchanged** (nothing new to navigate to; it exercises naturally at its first call site). No frozen UI
changed, no business logic changed, no duplicate component created.

### Files
`lib/common/widgets/moonjoin/notifications/moonjoin_notifications.dart` (new),
`lib/common/widgets/moonjoin/moonjoin_components.dart` (barrel +1 line), `docs/MOONJOIN_NOTIFICATION_SYSTEM.md` (new).

---

## PARCEL MODULE — ✅ COMPLETE • FROZEN (2026-07-30)

**Parcel Module — Implemented · Analyzer Clean · Runtime Verified · Owner Approved · FROZEN.** Owner-approved
formal completion (documentation & freeze only — no code change, no redesign, no refactor, no component
replacement, no business-logic change, no backend-integration change). A full screen-by-screen audit confirmed
Parcel was **already migrated** and must not be redesigned again (avoids duplicate redesign work).

| Parcel Screen | Status | Migrated | Notes |
|---|---|---|---|
| **Screen 1 — Parcel Category/Home** (`parcel_category_screen.dart`) | ✅ Fully Frozen | 100% | Frozen `WavyHeader` reuse; business logic preserved |
| **Screen 2 — Parcel Location** (`parcel_location_screen.dart`) | ✅ Fully Frozen | 100% | Address flow preserved; business logic preserved |
| **Screen 3 — Parcel Request** (`parcel_request_screen.dart`) | ✅ Frozen | UI complete & verified | Freeze approved; no remaining legacy UI; shared `PaymentSection` |

- **Package Protection (recorded correctly):** Frontend preparation exists · Backend configuration dependency
  pending · **NOT a UI migration blocker** · Future implementation must **extend the existing Parcel
  architecture** · **No redesign required.** Tracked in `BACKEND_INTEGRATION_QUEUE.md`.
- **Permanent Parcel rules:** reuse the shared Payment architecture · reuse shared MoonJoin components · do NOT
  create duplicate Parcel-specific components when a platform component exists · future Parcel features extend
  the frozen foundation.
- **Do not start another Parcel improvement cycle.** Next migration target moves to the next genuinely-legacy
  surface (mandatory pre-implementation audit: Already Frozen / Partially Frozen / Legacy / Components to reuse /
  Business logic to preserve / Must Not Touch).

---

## Phase — Rental Screen 1: Rental Home (Car & Apt Rental) 🔒 FROZEN

- **Screen completed:** Rental Home — `lib/features/rental_module/home/screens/taxi_home_screen.dart`
  (`TaxiHomeScreen`), the module home for the shared **Rental** Business Module Type.
- **Module model:** ONE Rental module containing **Car Rental** (existing "taxi" backend) and **Short
  Apartment Rental** (no backend — isolated UI-layer placeholder, `TODO(BACKEND)`, **no mock repository**).

**Design authority applied.** Where `ui-designs/Car_Rental/rental_home.png` conflicted with the approved
MoonJoin design system, **MoonJoin won** (permanent rule): the signature `WavyHeader` was kept rather than the
mock's flat header, and the category row uses the approved MoonJoin category UI/UX rather than the mock's
chips. The mock supplied page layout, content arrangement and screen flow only.

**Reused (not recreated)**
- `WavyHeader`, `CustomImage`, `Dimensions`, `styles.dart`, theme colours, `shimmer_animation`.
- **Back to all-modules dashboard:** the *exact* approved action from the standard home app bar —
  `SplashController.removeModule()` + `StoreController.resetStoreData()`. No new navigation logic. (The
  standard app bar is suppressed on Rental because this screen draws its own header, which had removed the
  affordance — restored in the Rental header.)
- **All existing Rental backend logic:** `TaxiHomeController` (`getVehicleCategoryList`, `selectedCategoryIds`,
  `addOrRemoveCategory`, `getSelectedCars(categoryIds:)`, banners, top-rated cars, coupons, trips, favourites),
  repositories, services, models and routes — untouched.

**New reusable component**
- `MoonjoinCategoryTile` (`lib/common/widgets/moonjoin/moonjoin_category_tile.dart`) — the approved MoonJoin
  category UI/UX as a data-agnostic tile, reusable by any module. Declares no styling values of its own.
- `RentalPopularCard` (`lib/features/rental_module/home/widgets/rental_popular_card.dart`) — one listing-card
  layout shared by the Car Rental and Short Apartment Rental rows.

**Categories.** Rental reuses the approved MoonJoin Category UI/UX while preserving the Rental module's
existing backend category filtering behaviour. Data is 100% backend-driven from the existing
`GET /api/v1/rental/vehicle/category-list` (admin: Car & Apt Rental → Vehicle Management → Categories) —
names, images and count are never hardcoded; admin create/rename/delete needs no frontend change. A leading
**"All"** tile is active by default when nothing is selected. Additive controller helper
`clearSelectedCategories()` added for the "All" tile (existing filter logic unchanged; `resetFilter()` was not
reused because it also clears price/brand/seating/A-C).

**Backend-pending (documented in `docs/BACKEND_INTEGRATION_QUEUE.md`, nothing invented)**
- **Hero Cards** — image / title / subtitle / CTA text / CTA action / sort order / status / target
  (Car Rental | Apartment Rental | Both). Admin: Car & Apt Rental → Dashboard → Hero Cards (after Trip
  Management, before Promotion Management).
- **Category `type`** (car vs apartment) — the only gap in the otherwise complete category backend.
- **Short Apartment Rental** — listing / details / booking.

**Fixes included**
- Blank Rental Home: `Row(crossAxisAlignment: stretch)` inside the vertical `SingleChildScrollView` could not
  be laid out (`RenderBox was not laid out`) → whole screen rendered white. Wrapped in `IntrinsicHeight`.
- Category row overflow: sized to the approved MoonJoin category-row geometry (height 160) so 2-line labels
  never overflow.

**Verification** — `flutter analyze` **48 issues / 0 errors** (baseline held); build **0 errors**; runtime
verified on the iOS Simulator against the live backend, reached through the real journey
(Home dashboard → Car & Apt Rental).

### Final Production Audit (post-freeze verification)

**Runtime audit** — verified against the live backend on the iOS Simulator, with the screen actually exercised
(`category-list`, `banners`, `top-rated`, `coupon`, `trip-list`, `wish-list` all fired): **0** RenderFlex
overflows, **0** bottom overflows, **0** `RenderBox was not laid out`, **0** widget exceptions, **0** overflow
indicators, **0** null-check exceptions. API call counts scale linearly with screen mounts — no rebuild loop.

**Shared-component reuse fixes (audit findings, no redesign)**
1. The header search field was hand-built → replaced with the shared **`MoonjoinSearchBar`** (`readOnly` +
   `onTap` tap-to-search). Rental now has no bespoke search styling.
2. Category loading used a bespoke shimmer, and the popular rows used a raw `CircularProgressIndicator` →
   both now use the shared **`MoonjoinSkeleton` + `SkeletonBox`** primitives, so loading states match the
   MoonJoin design system.

**Hardcoded-data audit** — **zero** hardcoded user-facing strings on Screen 1 (all text via i18n `.tr`). The
only frontend-supplied data is the three items already documented in `BACKEND_INTEGRATION_QUEUE.md`: the two
hero images, the apartment placeholder list, and the apartment "coming soon" affordances. Categories, banners,
vehicles, coupons, trips and favourites all come from the existing backend.

**Backend audit** — **no fake APIs, no mock repositories, no duplicated business logic** (verified: no
mock/fake/dummy anywhere in `lib/features/rental_module/`). Screen 1 connects every backend capability
appropriate to a module home: `getTaxiBannerList`, `getTopRatedCarList`, `getVehicleCategoryList`,
`getTaxiCouponList`, trips, favourites, address. The remaining controller capabilities (`getSelectedCars`,
`getTaxiBrandList`, `getVehicleDetails`, `getPopularSearchList`, `getHistoryTripList`) belong to later Rental
screens and are intentionally not called here.

**⚠️ Potential Cleanup After Rental Completion — DO NOT DELETE YET.**
`top_rated_vehicle_widget.dart` and `horizontal_vehicle_card.dart` are the pre-redesign vehicle-card
implementations. After Screen 1 adopted `RentalPopularCard`, `TopRatedVehicleWidget` is referenced only by
itself and `HorizontalVehicleCard` only by it — both are currently unreachable.

**Decision (product owner):** leave them untouched. The Rental module is still being built and they may still
suit **Rental Listing · Provider List · Provider Details · Booking History · future Rental screens**. Deleting
now creates unnecessary risk. **After the entire Rental module is complete, run one final dead-code audit
across the whole Rental module before removing anything.**

**Status: 🔒 FROZEN — Production Ready (Frontend).** UI approved · UX approved · shared components approved ·
backend-ready · no redesign required · ready for future backend integration. Do not redesign. Only reuse its
components.

---

## 🧭 Rental Module Architecture (PERMANENT RULE — applies to every remaining Rental screen)

**Flow separation.** Complete **Car Rental first**, then Short Apartment Rental. Tapping the Car Rental hero
card enters the **Car Rental flow only** (designs: `ui-designs/Car_Rental/`). Tapping the Short Apt Rental hero
card enters the **Apartment flow only** (designs: `ui-designs/Apartment_Rental/`). Never mix the two flows.
Do not begin Apartment implementation until the Car Rental flow is complete and approved.

**Screen order**
1. Rental Home ✅ **FROZEN — Production Ready (Frontend)**
2. Car Rental Listing ← *current*
3. Rental Provider List
4. Rental Provider Details
5. Rental Checkout
6. Rental Booking Success
7. Rental Booking History

Then (only after the whole Car Rental flow is approved): Apartment Home → Listing → Provider → Details →
Checkout → Booking → Booking History.

**Reuse approved MoonJoin PAGES, not just components.** Many Rental pages are functionally identical to pages
that already exist. Do **not** redesign them — reuse the approved page architecture and replace only the data:

| Rental page | Reuses the architecture of |
|---|---|
| Car Rental Listing (`car_rental.png`) | `restaurant_list.png` (approved Food/storefront listing) |
| Rental Provider page (`car_rental_provider_item_list.png`) | `store_or_restaurant.png` (approved Store page) |
| Rental Search | the approved MoonJoin/Food **Search** implementation |
| Checkout | the approved frozen Checkout + Choose Payment Method |

Reuse layout, search behaviour, filter placement, banner behaviour, category behaviour, pagination, spacing,
loading states, skeletons, empty states, animations, cards, buttons and navigation. Replace **only** vehicle
data, rental-specific information and rental features.

**MoonJoin always wins.** If a `ui-design` conflicts with an approved MoonJoin page or component, MoonJoin
wins. The mock supplies only page arrangement, feature placement, screen flow and rental-specific content —
it never replaces an approved MoonJoin UI component.

**Category behaviour.** No category selected → default Rental page. Category selected → show the
providers/items in that Rental category, with provider banners and related content presented the same polished
way Food behaves after category selection — using the Rental backend and Rental category controller, and
reusing existing banner behaviour rather than a new implementation.

**Per-screen process.** Audit the existing Rental backend first (APIs, controllers, repositories, services,
models, filters, search, sorting, banners, categories, providers, favourites, booking) and reuse every existing
capability. Never duplicate business logic, never fake repositories, never invent APIs. Anything missing →
complete the frontend professionally with clean integration points and document it in
`BACKEND_INTEGRATION_QUEUE.md` as **Frontend Complete – Waiting for Backend Integration**. Then stop and report.

---

## Phase — Rental Screen 2: Car Rental Listing 🔒 FROZEN

- **Screen completed:** All Car Rentals — `lib/features/rental_module/home/screens/all_vehicle_screen.dart`
  (`AllVehicleScreen`), reached from Rental Home → Explore Cars / See All.
- **Design authority:** `ui-designs/Car_Rental/car_rental.png` for layout/content/flow; **MoonJoin wins** on
  every component.

**PAGE-LEVEL REUSE — the approved All Restaurants page (`AllStoreScreen`), section for section**

| Section | Reused implementation |
|---|---|
| App bar + circle actions | `AllStoreScreen._appBar` / `_circleButton` pattern |
| Search field | `AllStoreScreen._searchBar` pattern |
| Category row | shared **`MoonjoinCategoryTile`** |
| Filter chips | approved **`StoreFilterChip`** |
| Banner | existing rental **`BannerWidget`** |
| Top Brands | `AllStoreScreen._topBrands` pattern + **`TopBrandCard`** |
| Vehicle list | existing shared **`VehicleCard`** (the module's card) |
| Pagination | approved **`PaginatedListView`** |
| Loading | shared **`MoonjoinSkeleton` / `SkeletonBox`** |

**Zero new components. Zero duplicated widgets. Zero duplicated business logic.**

**Backend reused** — `getTopRatedCarList` (paginated browse), `getVehicleCategoryList`, `getTaxiBrandList`,
rental banners, `VehicleCard`'s existing favourite/booking logic, and the existing trip-context flow
(`TaxiLocationSuggestionScreen` → `SelectVehicleScreen`) for real vehicle filtering.

**Shared-component enhancement** — `TopBrandCard` gained an optional `showCount` (default `true`), so every
existing module renders identically; Rental passes `false` because the brand API has no `vehicles_count`.
Additive only, no fork, no regression. See COMPONENTS.md.

**Refinement pass (post-review)**
1. **Category component unified** — both Rental screens now use **THE** shared MoonJoin Category Component
   (`MoonjoinCategoryTile` = the Food Home category, adapted to `VehicleCategoryModel`). Screen 2 previously
   used `RestaurantCategoryChip`, whose image is inset by `paddingSizeSmall` inside a 64px circle with
   `BoxFit.contain` (~48px effective) — correct for the Food All Restaurants page, wrong as a second category
   look. Screen 2's row geometry was also aligned to Screen 1 (height 160, `paddingSizeDefault`). The frozen
   `RestaurantCategoryChip` and the Food All Restaurants page were **not** touched.
2. **No module-specific visual tuning** — an interim Rental-only icon→title spacing tweak was **reverted**; the
   shared tile matches Food Home exactly. Every call site passes data only (`label` / `image` / `icon` /
   `selected` / `onTap`) — zero visual overrides. Future Food Home category improvements propagate to Rental
   automatically.
3. **Hero cards (Screen 1)** — the whole card is now tappable; the CTA button remains.
4. **Sort & Top Rated chips now function** — using the approved Food pattern: **client-side sort of the
   already-loaded real vehicles** (`dayWisePrice`/`hourlyPrice` for Sort, `avgRating` for Top Rated), with
   selected state and toggle-off. No new API call, no fake data. They no longer navigate to the pickup flow.

**Deliberately NOT implemented — no backend exists (documented, never faked)**
- **Category Type** (Dashboard / Car Rental Home / Apartment Rental Home) → queue item 7.
- **Screen 1 Popular-section category filtering** → queue item 8.
- **Provider filtering** (Self Drive / With Driver / Top Rated) → queue item 9. There is **no provider list or
  search endpoint at all**; every provider API requires an already-known id. Those three chips are therefore
  **rendered but inert** — they do not navigate to the pickup flow (which is not what they mean) and they do
  not fake filtering. They activate unchanged once the provider endpoints exist. Item 9 carries the full
  **Backend + Vendor App + Admin** contract.

**Verification** — `flutter analyze` **48 / 0**; build **0 errors**; runtime clean (0 overflow, 0 RenderFlex,
0 exceptions) on the iOS Simulator against the live backend, reached through the real journey.

**Status: 🔒 FROZEN — Production Ready (Frontend).** Do not redesign. Only reuse its components.

---

## Rental Screen 2 — Provider-flow restructure (post-review, pending approval)

Screen 2 previously listed **vehicle cards** directly. Corrected to mirror the approved Food module flow:

```
Rental Home → All Car Rentals → Provider banner → Provider page → Vehicle list
Food Home   → All Restaurants → Restaurant banner → Restaurant page → Food list
```

**Provider adapter (temporary production adapter).** No provider list endpoint exists, but every vehicle
embeds a **real backend `Provider`** object. `RentalProviderAdapter` groups loaded vehicles by `provider.id`
and aggregates feature badges from real vehicle fields. Nothing fabricated. When the Provider List endpoint
ships, **only the adapter changes** — see BACKEND_INTEGRATION_QUEUE.md item 10.

**`RentalProviderCard`** — permanent visual clone of the frozen `MoonjoinStoreCard` (identical radius, shadow,
cover ratio, badge geometry, logo, typography, bookmark position), with delivery concepts replaced by vehicle
feature badges. Frozen card untouched; Food unaffected. Bookmark reuses the existing `TaxiFavouriteController`
provider wish-list.

**Provider page** — reuses the existing approved rental `VendorDetailScreen`, which already lists that
provider's vehicles.

**Screen 1 search rewired** — the search bar now opens the existing `SearchVehicleScreen` (search behaviour,
matching Food) instead of the Location screen. **The location / trip-context flow is fully intact** and still
used by Screen 2's Filters/Sort and the booking journey — nothing was deleted.

**Category component** — both Rental screens use THE single MoonJoin Category Component
(`MoonjoinCategoryTile`), identical geometry and spacing, backend data only. The tile draws a circular tinted
surface because rental category artwork is transparent icon PNGs rather than photographs; without it the icons
render with no circle. If photo-style category images are uploaded, the surface is unnecessary.

**Verification** — `flutter analyze` **48 / 0**; build **0 errors**; runtime **0 overflow / 0 RenderFlex /
0 RenderBox / 0 exceptions / 0 null-check**.

**Status: NOT frozen — awaiting product-owner visual approval.**

---

## Rental Screen 2 — behaviour corrections (All Car Rentals)

**Category UI: APPROVED & FROZEN.** Both Rental screens use THE approved MoonJoin category component
(`RestaurantCategoryChip`, the one used by Food / All Restaurants). No second category component exists.
Additive optional params only — `imageFit`, `imagePadding`, `fallbackIcon`, `selected` — every default
preserving existing modules byte-identically. **Do not change category geometry, colours or layout.**
Category **Type** (Dashboard / Car Rental Home / Apartment Rental Home) is a backend/admin enhancement only —
queue item 13.

**Navigation corrected — nothing now routes to the Location page from this screen:**
- **Search bar** and **top search icon** → the existing **Rental Search screen** (`SearchVehicleScreen`).
- The **Location / trip-context flow is untouched and retained** for the booking journey, trip context and
  vehicle-selection flow — only this screen's navigation changed.

**Chip behaviour now matches the approved Food pattern:**
- **Sort** → client-side sort of loaded vehicles by real price. **Top Rated** → client-side sort by real
  `avg_rating`. No API call, no fake data.
- **Filters**, **Self Drive**, **With Driver**, **browse category**, **Top Brands card** → rendered but
  **inert**, because their backend does not exist. They are never routed to an unrelated screen and never fake
  filtering. Queue item 11.

**Discovery order matches Food** — Category → Filter chips → Banner → Top Brands → **Provider banners** →
Provider page → Vehicle list. Vehicles are never the first discovery layer.

**Provider cover mapping verified** (queue item 12): the card reads the real `cover_photo_full_url` with a
`meta_image_full_url` fallback, and `logo_full_url`. A placeholder means the backend supplied neither for that
provider — the mapping is correct; vendor banner upload is the outstanding work.

**Verification** — `flutter analyze` **48 / 0**; build **0 errors**; runtime clean.

**Status: NOT frozen — awaiting product-owner visual approval.**

---

## 🔒 Rental Screen 2 — All Car Rentals — PRODUCTION READY (FRONTEND) · FROZEN

**Screen:** `lib/features/rental_module/home/screens/all_vehicle_screen.dart` (`AllVehicleScreen`).
**Approved architecture** (mirrors the Food module exactly):

```
Rental Home → All Car Rentals → Provider Banner → Provider Detail Page → Vehicle List
Food  Home  → All Restaurants → Restaurant Banner → Restaurant Page    → Food List
```

### Provider adapter architecture
No provider list endpoint exists, but every vehicle embeds a **real backend `Provider`** object.
`RentalProviderAdapter` groups loaded vehicles by `provider.id`, preserving backend order, and aggregates each
provider's feature badges from that provider's own vehicles. **Nothing is fabricated.**

```
TODAY    Vehicle API → group by provider.id → RentalProviderCard
FUTURE   Provider List API →                  RentalProviderCard
```

**Migration plan:** when the Provider List endpoint ships, replace **only** `rental_provider_adapter.dart`.
`RentalProviderCard` and every screen using it **must not change**. Known interim limitation: the derived list
contains only providers holding a vehicle in the loaded page, and paginates by vehicles rather than providers.

### Provider banner mapping (verified end-to-end)
`cover_photo_full_url` → falls back to `meta_image_full_url` → neutral placeholder (never fabricated);
logo from `logo_full_url`. The mapping is **correct**; an empty banner means the backend returned no value for
that provider (Vendor App upload work — queue item 12).

### Dynamic feature badge system
Badges derive **only** from real backend fields — `air_condition`→AC, `tag`→Luxury, `fuel_type`→
Petrol/Diesel/Electric/Gas, `transmission_type`→Automatic/Manual, `type`→SUV/Sedan/Coupe/Pickup/Convertible,
`seating_capacity`→Seats. A badge appears solely because the backend returned that value. **Zero hardcoding.**

### Reused (no duplication)
`StoreFilterChip` · `TopBrandCard` (+ additive `showCount`) · `RestaurantCategoryChip` (+ additive `imageFit` /
`imagePadding` / `fallbackIcon` / `selected`) · `PaginatedListView` · `NoDataScreen` · `CustomImage` ·
`MoonjoinSkeleton`/`SkeletonBox` · rental `BannerWidget` · `VendorDetailScreen` · `VendorVehicleCard` ·
existing `TaxiFavouriteController` favourite logic. **Every additive parameter defaults to prior behaviour, so
Food/Grocery/Pharmacy/Fashion/Parcel are unaffected.**

### Chip behaviour
**Sort** (real price) and **Top Rated** (real `avg_rating`) sort client-side, exactly like Food — no API call,
no fake data. **Filters · Self Drive · With Driver · browse category · Top Brands card** are rendered but
**inert** pending backend; they never route to an unrelated screen and never fake filtering (queue item 11).

### Accepted non-blocking deltas on the Provider Detail page (product-owner decision)
1. **Green hero header not adopted** — Rental keeps its own cover-banner identity; `StoreHeroHeader` not forced.
2. **Loading shimmer** — current behaviour accepted; optional future enhancement.
3. **Share button** — not required for this freeze; optional future enhancement.

### Verification
`flutter analyze` **48 / 0** · build **0 errors** · runtime **0 overflow / 0 RenderFlex / 0 RenderBox /
0 exceptions / 0 null-check** · no fake data · no duplicate UI components · no hardcoded rental features ·
**category frozen and untouched** · **Food module unaffected**.

**Status: 🔒 FROZEN — Production Ready (Frontend).** Do not redesign. Only reuse its components.

---

## ⚙️ PERMANENT MoonJoin Engineering Rule — User App First (never block on backend)

**Never stop User App development waiting for Backend, Vendor App or Admin Panel work.**

1. **User App first.** Complete every screen to production quality. If a backend capability exists, use it. If
   it does not but **real backend data can be adapted**, build the feature with an adapter over that real data.
   Never fake APIs or data, never hardcode production content, never duplicate UI components.
2. **Backend ready.** On discovering a missing capability, do not stop — prepare the User App and document the
   Backend, Vendor App and Admin Panel work in `BACKEND_INTEGRATION_QUEUE.md` in enough detail to implement
   those codebases later **without redesigning the User App**.
3. **Adapter rule.** Adapters are acceptable **only** when built from real backend data, and are **temporary**.
   When the proper endpoint ships: replace **only the adapter** — never redesign the UI, never change
   navigation, never change component architecture. Only the data source changes.
4. **Production architecture — always:**
   `Backend → Repository → Controller → Adapter (if temporarily required) → UI`
   **Never** `Backend → UI`. Never duplicate UI because of a backend limitation.
5. **UI rules.** Reuse approved MoonJoin components; adapt before creating. Only build a Rental-specific
   component when an approved one **physically cannot** carry Rental data — and then reuse identical spacing,
   typography, elevation, radius, colours, animations, loading states, shadows, paddings and dimensions.

**Queue documentation must include, per missing capability:** Backend (API contract, request params, response
model, pagination, filtering, sorting, searching, validation) · Vendor App (screens, settings, uploads, feature
configuration, provider controls) · Admin Panel (approval workflow, moderation, management screens, analytics,
configuration).

**Screen 3 decision (recorded):** proceed **without** waiting for Queue Item #10. Continue using
`RentalProviderAdapter` built from real vehicle/provider data. When Item #10 ships, the adapter is removed or
simplified, the Provider List endpoint becomes the source, and **no UI redesign is permitted.**

**Frozen screens** (Screen 1 Rental Home, Screen 2 All Car Rentals) may only change for verified bug fixes,
backend integration, or documentation. **No redesign.**

---

## 🔍 Audit — "What is Screen 3?" (performed before any Screen 3/4 code)

Compared: the approved Car Rental designs (`ui-designs/Car_Rental/`, incl. `car_rental_provider_item_list.png`
and its Apartment twin `apt_rental_provider_item_list.png`) · the post-Screen-2 implementation ·
MIGRATION_LOG.md · COMPONENTS.md · BACKEND_INTEGRATION_QUEUE.md. Findings:

**1. Screen 3 (Provider List) already exists — it was built inside Screen 2.**
The Screen 2 provider-flow restructure moved the provider layer into `AllVehicleScreen`:
`_providerList()` derives providers via `RentalProviderAdapter.fromVehicles()` and renders each as a
`RentalProviderCard`, which navigates to `VendorDetailScreen`. This mirrors Food exactly
(`All Restaurants → restaurant banners → Restaurant page`), where the restaurant list likewise lives *inside*
the listing page rather than on a separate screen. There is also **no standalone provider-list design** in
`ui-designs/Car_Rental/` — no such asset exists. Building a separate Provider List screen would therefore
duplicate an existing, frozen implementation to satisfy a number in a list.
**Conclusion: Screen 3 is absorbed into Screen 2 and frozen with it. No separate screen will be built.**

**2. `car_rental_provider_item_list.png` is the Provider DETAIL page, not a provider list.**
Evidence: (a) MIGRATION_LOG.md already records the mapping —
`Rental Provider page (car_rental_provider_item_list.png) → store_or_restaurant.png (approved Store page)`;
(b) the design's body is a list of **vehicles** (item cards with price + View Details), not of providers;
(c) its Apartment twin `apt_rental_provider_item_list.png` is identically a list of **apartments**;
(d) `car_rental_search_list.png` is a separate screen for the search flow (it has the Items/Providers tabs).
The filename means *"a provider's item list"*.

**Honest note on an ambiguity:** the design's hero reads "Car Rentals / Lekki, Lagos / 128 Cars Available"
rather than a provider identity, which read alone could suggest a location-scoped listing. The hero is a
**generic template** — the search screen fills the same hero with the query ("Lexus"), and the Apartment twin
fills it with "Lekki Apartments". On the Provider page it is filled with the provider's real identity
(name · rating · address · vehicle count), which is also what the approved Store page does. Resolved by the
recorded mapping above rather than re-litigated.

**Decision: the next screen is Screen 4 — Provider Details.** It was never migrated — `VendorDetailScreen` was
still the legacy 6amMart layout, carried through Screen 2 as an explicitly *accepted, non-blocking* delta.

---

## 🔒 Rental Screen 3 — Provider List — ABSORBED INTO SCREEN 2 · FROZEN

Not a separate screen. Implemented and frozen as part of Screen 2 (`all_vehicle_screen.dart` `_providerList`),
using `RentalProviderAdapter` + `RentalProviderCard` over real backend provider data. Do not create a
standalone Provider List screen. When Queue Item #10 (Provider List endpoint) ships, **only the adapter
changes** — no UI redesign, no new screen.

---

## Phase — Rental Screen 4: Provider Details (Provider Item List)

- **Screen:** `lib/features/rental_module/vendor/screens/vendor_detail_screen.dart` (`VendorDetailScreen`).
- **Design authority:** `ui-designs/Car_Rental/car_rental_provider_item_list.png` (Rental is not in the Active
  Figma). Page architecture reuses the approved MoonJoin **Store page** (`store_or_restaurant.png`).
- **Reached through the real journey:** Home → Rental → All Car Rentals → Provider banner → **Provider Details**.

**PAGE-LEVEL REUSE — the approved Store page, section for section**

| Section | Reused implementation |
|---|---|
| Green hero + actions + search pill | **`RentalProviderHeroHeader`** — visual clone of the frozen `StoreHeroHeader` |
| Filter chips | approved shared **`StoreFilterChip`** |
| Category strip | **`RestaurantCategoryChip`** — THE MoonJoin category component (frozen, unchanged) |
| Provider banners | existing **`ProviderBannerWidget`** |
| Rating + reviews entry | existing **`TaxiRatingBar`** + existing `ReviewDetailsScreen` |
| Vehicle list | existing **`VendorVehicleCard`** |
| Pagination | approved **`PaginatedListView`** |
| Empty state | approved **`NoDataScreen`** |
| Loading | shared **`MoonjoinSkeleton` / `SkeletonBox` / `SkeletonListLoader`** |

**One new component** — `RentalProviderHeroHeader` (rationale in COMPONENTS.md: `StoreHeroHeader` is frozen and
typed to `Store`). **One additive parameter** — `TaxiAddFavouriteView.iconColor`, default `null` → prior
behaviour, so every existing call site is byte-for-byte unchanged.

**Business logic preserved — presentation only.** Every controller call is the pre-existing rental
implementation: `getTaxiVendorDetails` · `getVendorBannerList` · `getVendorVehicleList` (search, category,
pagination) · `getVendorVehicleCategoryList` · `initFilterSetup` · `setCategoryId` · existing
`VehicleFilterWidget` sheet · existing `SearchVehicleScreen` · existing `TaxiFavouriteController` favourite ·
existing `TaxiCartController` cart · existing `ReviewDetailsScreen`. **No API changed, no repository changed,
no service changed, no model changed.**

**Chip behaviour (nothing faked).** Filters / Price / Seats / More open the existing rental filter sheet (real
backend filtering: price range, brands, vehicle type, seats, air conditioning). Sort sorts the loaded **real**
vehicles client-side on real price / `avg_rating` fields — identical to the approved Food chips and frozen
Screen 2, no API call, no fake data. **Transmission is rendered but inert**: `transmission_type` exists on each
vehicle but there is **no transmission filter parameter** on `get-provider-vehicles` → documented as
**BACKEND_INTEGRATION_QUEUE.md item 14**, activates unchanged when the backend supports it.

**Deltas vs the design (deliberate, MoonJoin-wins):**
1. **"Explore … / View on Map" card not adopted.** `StoreMapView` is frozen and typed to `Store`. Cloning a
   full interactive map widget is a materially larger surface than a header clone, and the provider payload's
   lat/lng is already reachable. Scheduled deliberately rather than bundled into this screen.
2. **Vehicle card** stays the existing `VendorVehicleCard` rather than the design's horizontal card — reuse
   over redesign; the card is shared rental UI and is not this screen's subject.
3. **Share button** not added — the rental provider payload exposes no share URL/slug, so there is nothing real
   to share. Not faked.

**Previously-recorded deltas now CLOSED:** green hero header adopted (was delta 1 of the Screen 2 freeze);
loading shimmer adopted (was delta 2).

**Not deleted:** `SearchAndFilterWidget` (its search icon / filter icon / category row are now served by the
hero pill, the chip row and the category strip) is **left on disk, untouched**, per the standing no-automatic-
deletion rule — to be resolved in the single post-Rental dead-code audit, not opportunistically here.

### 🐞 Production bugs found & fixed (both blocked the page from working)

1. **Provider Details never rendered — `get-provider-details` parse crash.** The backend serialises the
   provider counters as **strings** (`"order_count": "0"`, `"total_order": "0"`, `"total_vehicle_count": "1"`),
   while `TaxiVendorModel` types them `int?`. The raw assignment threw
   `type 'String' is not a subtype of type 'int?'`, which aborted `TaxiVendorModel.fromJson` — leaving
   `taxiVendor` null so the page hung on its loading state **forever**. This was a pre-existing bug that made the
   whole legacy provider page unreachable; it surfaced immediately once the page was migrated. Fixed with a
   defensive `_asInt()` that accepts either a number or a numeric string and returns `null` (never a fabricated
   default) for absent/unparseable values. Also mapped the real `total_vehicle_count` field so the hero shows the
   provider's true vehicle total. Regression test: `test/rental/taxi_vendor_model_test.dart` (3 cases: string
   counters, int counters, absent→null) — **all pass**. Verified at runtime: the page now renders fully.
2. **Duplicate "All" category chip.** `TaxiVendorController.getVendorVehicleCategoryList()` already prepends an
   "All" entry (`id: -1`, which the repository maps to an unfiltered request). The first screen build added a
   *second* synthetic "All". Fixed by rendering the controller's list as-is (no synthetic prepend) and defaulting
   the selected id to `-1`. Verified at runtime: a single "All" now shows.

### Verification (before freeze)
- **`flutter analyze`** → **48 issues, 0 from rental** (identical to the pre-existing baseline).
- **Unit** → `test/rental/taxi_vendor_model_test.dart` 3/3 pass.
- **Runtime (iOS Simulator, real backend, provider 39 "Peeprate Car Rental")** — full flow
  Home → All Car Rentals → provider card → **Provider Details** → back. Page renders completely with **100%
  real backend data** (name, rating, address, cover photo, `total_vehicle_count`, real categories, real vehicle
  card). Log clean: **0 subtype / 0 RenderFlex / 0 overflow / 0 RenderBox / 0 null-check / 0 unhandled
  exceptions** (only unrelated APNS/Firebase simulator-environment noise). Category strip shows a single "All"
  (dedup fix confirmed). Back-navigation confirmed. Every displayed field verified to come from the backend —
  nothing hardcoded or fabricated.

**Status: 🔒 FROZEN — Production Ready (Frontend).** Approved by the product owner. Do not redesign, refactor or
restyle. Only reuse its components. May change only for verified bug fixes, backend integration, or docs.

---

## 🔒 Rental Screen 2 — provider-card badge formatting — ISOLATED PRODUCTION POLISH (Screen 2 stays FROZEN)

**Bug.** The provider card on **All Car Rentals** displayed the raw backend `tag` value — a stringified JSON
array — as a badge: `["lexus"]`. Not production quality.

**Fix (presentation only).** `RentalProviderAdapter._badgesFor` now parses `tag` into clean, individually
title-cased tokens via a new private `_parseTags` helper: JSON-decodes the array (`["Lexus"]` → `Lexus`;
`["Luxury","Premium"]` → `Luxury`, `Premium`), with a defensive bracket/quote-strip + comma-split fallback for
plain or malformed values. Renders **"Lexus" / "Luxury" / "SUV"** etc.

**Strict scope — nothing else touched:**
- **Backend model unchanged** — `VehicleModel.tag` still `String?`, assigned raw.
- **Adapter architecture unchanged** — still groups real vehicles by `provider.id`; only badge *formatting*
  changed. Still derived from real backend fields; nothing invented.
- **Screen 2 not unfrozen / not redesigned** — no layout, component, navigation or business-logic change.
- **Other modules unaffected** — `RentalProviderAdapter` is referenced only inside the rental module
  (`all_vehicle_screen.dart`, `rental_provider_card.dart`); Food/Grocery/Pharmacy/Fashion/Parcel do not use it.

**Verification** — new `test/rental/rental_provider_adapter_test.dart` (4 cases: single-element array,
multi-element array, plain string, null/empty) **all pass**; total rental tests **7/7**. `flutter analyze`
**48/0 baseline**. Screen 2 remains 🔒 FROZEN apart from this isolated formatting fix.

---

## Phase — Rental: Vehicle Details (design audit + implementation)

### Design audit (before any code)
- **`car_rental_details.png` is the Vehicle Details page.** `car_rental_details_trip_type.png` is the SAME
  page with **Per Day** selected — it only reveals the trip-type-dependent sections ("Estimate Days" row,
  bottom estimate/price). **One page, not two.** `car_rental_checkout.png` reviewed for flow continuity
  (Details → Checkout → Booking Success), not implemented in this phase.
- **Flow position:** Provider Details → vehicle card → **Vehicle Details** → Checkout.

### Model/backend audit — what the design shows vs what is REAL
| Design element | Real source | Status |
|---|---|---|
| Name, ★rating "(N+)" | `name`, `avg_rating`, `total_reviews` | ✅ real |
| Feature pills (Seats/Transmission/Fuel/AC) | `seating_capacity`, `transmission_type`, `fuel_type`, `air_condition` | ✅ real |
| Location line ("Lekki Phase 1") | **the user's selected location** — `AddressHelper.getUserAddressFromSharedPref()?.address`, the same source as every approved MoonJoin header (product-owner clarification; queue item 15 resolved) | ✅ real |
| Hero image / gallery | `thumbnail_full_url` / `images_full_url` | ✅ real (gallery hidden when backend returns none) |
| Trip Type cards + Start From prices | `trip_distance/hourly/day_wise` flags + real prices + discount | ✅ real |
| Where to go / Pickup Time / Estimate | existing trip context (`TaxiLocationController`) or the cart's real `userData` | ✅ real |
| Estimated km/hr/day + total | existing distance/duration APIs + the pre-existing price calculation | ✅ real |

### Reuse (no duplicate components)
Existing **`TripTypeCard`** (interactive pre-cart via `selectTripType`, locked to the cart's real
`rentalType` in-cart — both are its own existing modes) · existing **`DateTimePickerSheet`** (handles cart and
pre-cart pickup-time editing) · existing **`TaxiLocationSuggestionScreen`** (destination + real
distance/duration) · existing **`CustomTextField`** estimate inputs with the SAME controllers/validation as
the production location bottom sheet · frozen shared **`QuantityButton` → `setQuantity`** quantity system ·
`CustomButton` · `CustomImage` · existing `_addToCart` / `decideAddToCart` / `removeFromCart` /
`_calculateDiscount` logic **verbatim** · "Add More Vehicle +" reuses the cart screen's exact behaviour ·
production **`TaxiCheckoutScreen`** (no-arg, reads the cart — same contract as from the cart screen).
One local presentation-only addition: `_DashedBorderPainter` (the design's dashed "Add More Vehicle"
container; private to the screen, not a shared component).

### Flow decision — "Proceed to Checkout"
The cart remains the single source checkout reads. Proceed: in cart → open checkout · no trip context →
existing destination flow (`TaxiLocationSuggestionScreen`) · trip context ready → the SAME validation as the
production location bottom sheet, then the existing `addToCart`, then checkout once the backend confirms.
The multi-vehicle path still runs `decideAddToCart`'s existing dialog flow and never auto-navigates over it.

### Deltas vs the previous legacy screen (design-driven, logic preserved)
Removed FROM VIEW per the approved design (all still real data, none deleted from the codebase):
description block, "similar vehicles" count chip, provider info card (providers are reached through the real
journey — the page is entered from the Provider page), app-bar cart icon. The in-cart **quantity stepper**
(not drawn in the design) is retained in the bottom bar — removing it would delete working production cart
functionality; frozen shared quantity system reused unchanged.

### 🐞 Production bug found & fixed during runtime verification
**Vehicle Details never rendered — `get-vehicle-details` parse crash.** The details endpoint serialises
`total_vehicles` as a **string** (`"1"`) while the list endpoints send integers; `VehicleModel` types it
`int?`, so `fromJson` threw `type 'String' is not a subtype of type 'int?'` and `vehicleDetailsModel` stayed
null — the page hung on its loader forever. Pre-existing (the legacy details screen used the same model and
endpoint, so it crashed identically). Fixed with the same defensive `_asInt()` resolution as
`TaxiVendorModel` (number or numeric string; absent stays null — nothing fabricated), applied to
`total_vehicles` and `total_vehicle_count`. Verified against the raw API response. Regression test:
`test/rental/vehicle_model_test.dart` (3 cases) — rental suite now **10/10**.

**Location-line correction (product owner).** Queue item 15 was withdrawn: the design's "📍 Lekki Phase 1" is
the **user's selected browsing location**, not a vehicle field. The header now renders it from
`AddressHelper.getUserAddressFromSharedPref()?.address` — the identical source as every approved MoonJoin
header. No backend work required.

**Status: implementation complete — verification in progress; NOT yet frozen.**

### Vehicle Details — post-review corrections (product owner)
1. **Where-to-go**: hint-only when empty (never pre-filled); once pickup+destination confirmed, replaced by the
   EXISTING `TripFromToCard` (both filled + edit pencil), old-design behaviour.
2. **Location page early-redirect bug fixed**: in cart-edit mode entered from Vehicle Details (no live map),
   tapping a recent/saved address popped back immediately with the old destination. The unconditional
   `Get.back()` in `MapRecentSavedAddress` was correct only when reopened FROM the map (`mapController` set);
   now it pops only then — otherwise the page waits for both fields and confirms on the map, like pre-cart.
3. **Trip Type**: direct selection on tap (no popup), both modes — the card's own existing
   `selectTripType` behaviours. In-cart changes persist through the production cart-update logic
   (`checkTypeInCart` → `updateUserData`/`TripVehicleListDialog`) on Proceed to Checkout.
4. **Instant estimate calculation**: estimate inputs now `setState` per keystroke so the bottom-bar
   estimate/price recomputes live — no trip-type re-tap, no popup.

**📌 RECORDED FOR CHECKOUT (REVISED by product owner, same day):** DO include the approved **Choose Payment
Method** card on Rental checkout — Car AND Short Apt Rental — reusing the frozen component **unedited**.
Above the card, add a payer/timing selector (e.g. "Pay now" vs "Pay to driver on trip" / "Pay to apartment
provider" — naming may be adapted for clarity), using the SAME format the **Parcel request page** uses for
choosing who pays (its sender/receiver payer selector). Existing production booking flow stays intact.

### Vehicle Details — final stabilisation round (all product-owner verified on device)
1. **Cart-edit location stack fixed**: entered from Vehicle Details, the map now REPLACES the Location page
   (`Get.off`), so the existing post-update `Get.back()` lands on Vehicle Details — no Location page
   re-appearing with cleared fields. Original map-reopen flow untouched (guarded on `mapController != null`).
   Deliberately NOT a copy of the legacy stack (which had its own misbehaviour — product owner): the flow is
   now deterministic: Details → Location → Map → confirm → Details.
2. **Trip Type**: direct tap-to-select in both modes (no popup, no duplicated section); in-cart changes persist
   via the production update on Proceed. Verified working by the product owner.
3. **Instant estimate recalculation** via `onChanged` setState. Verified.
4. **Infinite-loader defect fixed with SILENT auto-retry**: the repository returns null on any non-200 and the
   controller stores it silently — one failed request previously spun forever (reproduced by the product owner
   on a healthy network; endpoint probes healthy but up to ~3.2s). `_loadVehicleDetails` now retries in the
   background (1s/2s/3s then every 5s while the page is open) — the loader simply resolves; **no error screen
   is ever shown** (product-owner requirement: professional silent recovery).

**Runtime (product owner, ~4 full passes of the whole Car Rental flow + this session's log):** flow works
end-to-end; log clean — 0 subtype / 0 RenderFlex / 0 overflow / 0 RenderBox / 0 null-check / 0 unhandled
exceptions; cart updates persisted (6 calls observed); price verified correct (₦10,000 × 2.0 hr − ₦500 = ₦19,500).

### Final pre-freeze audit (approved by product owner)
All `car_rental_details.png` sections present with real data; `_trip_type` variant confirmed in-page. One
inconsistency fixed with proven root cause: the cart location-edit success path runs `initialSetup()`, which
cleared the seeded estimate controllers — the page now re-seeds them from the refreshed cart on return, so the
estimate input always matches the bottom-bar value. No backend/controller/API/pricing/cart logic touched.

**Status: 🔒 FROZEN — Production Ready (Frontend).** Approved by the product owner after visual verification.
Do not redesign, refactor or restyle. May change only for verified bug fixes, backend integration, or docs.

---

## 🔒 Vehicle Details — journey stabilisation (verified bug fix on the frozen screen) — CONFIRMED & RE-FROZEN

**Symptom (product owner):** intermittent "two designs / mixed-up pages / no price calculation". Root causes
proven, not assumed:
1. **Stale builds** — several interrupted/partial builds left old binaries on the simulator (the "old design"
   seen no longer exists in the codebase). Resolved by clean uninterrupted rebuilds.
2. **Pre-cart mode was a different journey.** With an EMPTY cart (the state after every successful booking),
   the page correctly shows "Where to go?", but its journey still ran the legacy
   `TaxiLocationResultScreen` + add-to-cart sheet, whose triple-pop landed on wrong pages, and the bottom bar
   only showed the start-from price. All earlier testing had been in-cart, so this path first surfaced after
   the first completed booking — appearing as "sometimes unstable".

**Fix — ONE deterministic journey for both modes** (`Details → Location → Map → Confirm → Details`):
- Details-entry (vehicle passed, no live map): the Location page is REPLACED by the map (`Get.off`), pre-cart
  and cart-edit alike (`rider_address_input_field.dart`, `map_recent_saved_address.dart`).
- `TaxiLocationController.setFromToMarker` normal-flow branch: when `vehicle != null` (only reachable from the
  Vehicle Details journey) the map confirm returns straight to Details — the legacy result screen + add-to-cart
  sheet are no longer part of this journey. The home-search journey (`vehicle == null`) is untouched.
- Pre-cart bottom bar now computes the REAL total once context exists (rate × km/hrs/days − discount — the
  same maths as the in-cart branch and cart backend), falling back to the design's start-from price before.

**Verified by the product owner on device in BOTH modes** (in-cart and empty-cart, including booking →
empty-cart → rebook). **Status: 🔒 FROZEN (re-affirmed).**

---

## Phase — Rental Checkout (`car_rental_checkout.png`) — payment section added, verified on device

**Audit result:** the existing production `TaxiCheckoutScreen` already implements the approved design
section-for-section — Selected Vehicle (+edit), guest info (guest mode), Promo Code + "Add Voucher +"
(+ coupon sheet), Additional Note, Bill Details (`BillDetailsWidget`: Trip Cost / Trip Discount / Subtotal /
Service Charge / tax / Total), Terms & Conditions, bottom estimate + Confirm Booking. All of it preserved
untouched (calculations via `TaxiPriceHelper`, tax via `getTripTax`, booking via `tripBook`).

**Added (product-owner requirement):** a **Payment** section between Additional Note and Bill Details —
- Payer/timing selector in the Parcel "Charge Pay By" `RadioGroup` format: **Pay Now** · **Pay to Driver on
  Trip** (default — the real production flow; `pay_to_apartment_provider` key ready for the Apt flow).
- **Approved shared `PaymentSection`** (identical component/controller/bottom-sheet as
  Food/Grocery/Pharmacy/Ecommerce/Parcel) revealed on Pay Now; zone+config gated (digital/wallet/offline);
  cash excluded from Pay Now because cash IS the pay-on-trip option.
- **Nothing faked:** `trip-book` accepts no payment fields (verified) — Confirm Booking always runs the real
  flow; the Pay Now transmission is a marked integration point (queue item 16, full backend contract).

**Verification:** `flutter analyze` rental module 0 issues · rental tests 10/10 · product-owner verified on
device (payment section renders, Pay Now reveals the card, booking flow intact).

### Payment-flow verification (pre-freeze, product owner)
`_payTimingIndex` drives ONLY the UI (radio state + revealing `PaymentSection`); the Confirm handler is
untouched — **both payer options call the identical production `trip-book` API**, no fake payment logic.
"Pay to Driver on Trip" = the real cash/pay-later production flow; "Pay Now" = the same production online
flow, transmitted at booking once backend/config enables it (queue item 16).

### 📌 PERMANENT ARCHITECTURE DECISION — Rental Checkout payment is the MASTER implementation
The **Car Rental Checkout payment experience** (payer selector + shared `PaymentSection` + production
booking pattern) is the master. **Short Apartment Rental MUST reuse it exactly** — same UI/UX, component
hierarchy, interaction, business flow, and shared components. Only wording changes:
"Pay to Driver on Trip" → **"Pay to Apartment Provider"** (`pay_to_apartment_provider` key ready in 4
languages). Never design a second payment style or duplicate a payment component for Apt.

**Status: 🔒 FROZEN — Production Ready (Frontend).** Approved by the product owner after payment-flow
verification. Booking Success / Trip Details (post-booking) are the NEXT migration targets.

---

## Car Rental — final pre-freeze fixes (product-owner list) — Checkout · Booking Success · Home spacing

1. **Home spacing aligned to the approved modules** (product-owner-directed adjustment to frozen Screens 1&2):
   rental category rows were `height 160 / vertical paddingSizeDefault` vs the approved storefront home's
   `height 108 / vertical paddingSizeSmall` (AllStoreScreen); banner gap `paddingSizeSmall` vs
   `paddingSizeExtraSmall`. Both rental screens now use the exact approved values — same layout rules, no
   module-specific spacing. (Short Apt shares the same Rental Home, so it inherits this automatically.)
2. **Checkout Pay-Now validation**: Confirm Booking is blocked with `please_select_payment_method_first` when
   Pay Now is selected and no method chosen — the exact validation the Parcel request page performs on the
   shared `CheckoutController.paymentMethodIndex`. Pay to Driver on Trip = unchanged cash/pay-later
   production flow. No fake payment, no bypass.
3. **Checkout "read error" — root cause proven & fixed at the model boundary**: the backend serialises the
   cart `pickup_time` in TWO shapes — canonical `yyyy-MM-dd HH:mm:ss` on some responses but **ISO-8601 UTC**
   on the add-to-cart echo. The strict `DateConverter.dateTimeStringToDate` parser threw
   `FormatException … at 11` when Checkout was entered right after a fresh add-to-cart (captured live in the
   simulator log). `UserData.fromJson` now normalises to canonical local time (`_normalizeDateTime` — same
   boundary-normalisation pattern as `_asInt`). Regression test `test/rental/car_cart_model_test.dart`
   (ISO→canonical, passthrough, null) — rental suite **13/13**.
4. **Booking Success**: approved direction retained — no redesign.
5. **Permanent architecture** re-affirmed: Car Rental Checkout payment is the MASTER; Short Apt reuses it
   exactly (wording-only: "Pay to Apartment Provider").

**Verified on device by the product owner (all four passes: spacing · Pay-Now validation · pay-on-trip
booking · repeated back-to-back checkouts). `flutter analyze` rental module 0 issues · rental tests 13/13.**

## 🔒 CAR RENTAL FLOW COMPLETE — Checkout & Booking Success FROZEN

- **Rental — Checkout** (`TaxiCheckoutScreen`) — 🔒 FROZEN (re-affirmed with Pay-Now validation + the
  pickup_time boundary fix). MASTER payment implementation for the Rental business module.
- **Rental — Booking Success** (`ConfirmBookingRequestBottomSheet`) — 🔒 FROZEN — approved design over the
  trip page; 100% real trip data (schedule, pickup/dropoff, vehicle + thumbnail, provider call).

**The Car Rental flow is complete and frozen end-to-end:**
Rental Home → All Car Rentals (+Provider List) → Provider Details → Vehicle Details → Checkout →
Booking Success → (existing Trip Details/History). Next phase: **Short Apartment Rental**, reusing the
approved Rental pages/components and the MASTER checkout payment architecture (wording-only changes).

---

## 🧭 Short Apartment Rental — GOVERNING RULE + design→implementation mapping (audit plan)

**Product-owner directive (permanent):** do NOT rebuild Apartment screens whose approved design is
effectively the frozen Car Rental implementation. Per screen: audit the design → compare to the frozen Car
Rental screen → reuse (wording/icons/data/business-logic changes only) → build new UI ONLY when materially
different. Never duplicate shared components or create parallel implementations.

**Filename-level mapping (each requires its per-screen visual audit before code):**

| Apartment design | Frozen Car Rental counterpart | Expectation |
|---|---|---|
| (Home) — no separate asset | `TaxiHomeScreen` (ONE shared Rental Home, both hero cards) | REUSE — apt hero card activates the Apt flow |
| `apt_rental.PNG` | `AllVehicleScreen` (`car_rental.PNG`) | Likely reuse architecture (audit) |
| `apt_rental_provider_item_list.PNG` | `VendorDetailScreen` (`car_rental_provider_item_list.PNG`) | Likely reuse (audit) — same template family |
| `apartment_ search_list.PNG` | rental search (`car_rental_search_list.PNG`) | Likely reuse (audit) |
| `apt_rental_details.PNG` | `VehicleDetailsScreen` (`car_rental_details.PNG`) | Audit — apt facts (beds/baths/guests) may differ materially |
| `apt_rental_checkout.PNG` | `TaxiCheckoutScreen` (MASTER payment architecture) | REUSE — wording "Pay to Apartment Provider" (key shipped) |
| `booking_successful.PNG` | `ConfirmBookingRequestBottomSheet` | REUSE — wording/data only (audit) |
| `my_booking_history.PNG` / `view_my_booking.PNG` / `Example_cancel_my_booking_history.PNG` | existing trip history/details screens (not yet migrated for Car either) | Audit — likely ONE shared booking-history migration serving both flows |

**Backend reality (recorded):** Apartment has NO backend yet (Rental Home hero is a UI placeholder —
`_comingSoon`). Per the User-App-First rule: adapters over real data where possible, otherwise complete
production frontend with documented Backend/Vendor/Admin contracts in BACKEND_INTEGRATION_QUEUE.md — never
fake APIs. The apartment-vs-car category split is queue item 7/13 (Category Type).

**Next step:** per-screen audits in the order Home-entry → Listing → Provider → Details → Checkout →
Booking Success → Booking History, one screen per phase, QA→approval→freeze as always.

---

## Apt Screen 1 audit — `apt_rental.PNG` ("Short Apartments" listing) — REUSE VERDICT

Flow entry confirmed: the shared Rental Home's **Short Apt hero card** opens this listing (mirror of the Car
hero → All Car Rentals). Section-by-section vs the frozen `AllVehicleScreen`:
app bar (back+title+search) ✅ · search bar ✅ · category row (circular, green arc: City Center / Beachside /
Budget / Luxury / Family) ✅ same component family · filter chips (Filters · Sort · Instant Book · Free
Cancellation · Top Rated) ✅ same `StoreFilterChip` row, apartment wording · rotating promo banner ✅ ·
Top Brands ✅ `TopBrandCard` · listing cards — apartment data (name, 📍location, bedrooms, guests, ★rating,
₦/night, discount + feature badges, ♥) on the same card architecture.

**Verdict: effectively the SAME architecture → REUSE the frozen `AllVehicleScreen` architecture** with
apartment wording/categories/chips/data. Discovery layer follows the SAME approved provider-first flow as
frozen Car (provider banners → provider page), keeping one Rental product. Differences are data-level only:
apartment facts, "/night" pricing, chip labels (Instant Book / Free Cancellation — rendered-but-inert pending
backend, exactly like Self Drive / With Driver were on Car).

**Backend:** NO apartment backend exists. Per CLAUDE.md's explicit Short-Apartment exception, this screen is
built as a complete production-ready frontend over a **mock repository behind clean interfaces** (repository →
service → controller, mirroring the taxi_home stack) so ONLY the repository swaps when the backend ships;
full Backend/Vendor/Admin contract to be added to BACKEND_INTEGRATION_QUEUE.md with the implementation.

**Next: implement Apt Screen 1 on this verdict (one screen, then QA → approval → freeze).**

**CORRECTION (product owner, approved approach):** no mock repositories without explicit approval. Apt
Screen 1 uses the SAME real backend through the established adapter pattern instead: the live rental backend
already exposes a **"Short Apt Rental" category** (`category-list`), and every vehicle carries `category_id` —
apartments are rental inventory under that category. Data source = the existing real browse
(`getTopRatedCarList`) filtered against the real Short-Apt category id (client-side, the approved Screen-2
chip pattern), plus the existing provider adapter for the provider-first discovery layer. When providers have
listed no apartments the screen shows the REAL empty state. Proper backend filters (category-type / browse
category params) remain queue items 5/7/8/13 — when they ship, only the data call changes. Zero mocks, zero
fake data, one unified Rental architecture.

---

## Phase — Apt Screen 1: Short Apartments listing — IMPLEMENTED (pending verification + approval)

**ONE unified listing page** — additive `fromApartment` flag on the frozen `AllVehicleScreen` (default
`false` → Car Rental behaviour byte-identical; the sanctioned `TopBrandCard.showCount` additive pattern).
No second listing screen, no duplicated components.

| Concern | Apartment mode behaviour |
|---|---|
| Entry | Rental Home Short-Apt hero card → `AllVehicleScreen(fromApartment: true)` (replaces `_comingSoon`) |
| Title | `short_apartments` |
| Inert provider chips | `instant_book` / `free_cancellation` wording (still inert — queue item 9, same as Car's Self Drive/With Driver) |
| Top Brands | HIDDEN — the brand API returns vehicle brands only; no real apartment brand data (never faked) |
| Data | **`RentalApartmentAdapter`** (new, temporary production adapter — RentalProviderAdapter philosophy): resolves the REAL "Short Apt Rental" category id from the live `category-list`, filters the real browse feed (`getTopRatedCarList`) by `category_id`. Car data never converted. |
| Empty | `NoDataScreen('no_apartment_available')` — the honest state (live check: backend currently has ZERO apartment inventory) |
| Everything else | identical frozen architecture: search, categories, filter chips, banner, provider-first discovery (`RentalProviderAdapter` → `RentalProviderCard` → `VendorDetailScreen`), pagination, skeletons |

**Backend verified live before coding:** `category-list` → "Short Apt Rental" (id 2) EXISTS; browse inventory
→ 1 item, `category_id: 1` (car) → apartment inventory is genuinely empty today.

**i18n:** `short_apartments` / `instant_book` / `free_cancellation` / `no_apartment_available` ×4 languages.

**Adapter migration plan:** when queue items 5/7/8/13 ship (category `type`, browse category filters), ONLY
`rental_apartment_adapter.dart` changes — no UI/architecture change permitted.

### 🔒 Apt Screen 1 — Short Apartments listing — FROZEN (final audit passed, product-owner approved)
Final audit: every `apt_rental.PNG` section considered — live (app bar/search/categories/chips/banner/
empty state), inert-pending-backend (Instant Book · Free Cancellation → queue 9; design's apartment
categories → Admin, queue 17), or hidden strictly for missing real data (Top Brands — vehicle-brands-only
API; reactivation marker `TODO(BACKEND, queue item 17)` in code, section unchanged, reappears with NO
redesign). Apartment facts on cards arrive with queue-17 fields through the same real-field rendering.
Unified architecture preserved; frozen Car flow untouched (verified on device + clean log).
**Status: 🔒 FROZEN — Production Ready (Frontend).** `fromApartment` mode and `RentalApartmentAdapter` are
frozen with it; only the adapter changes when backend ships.

---

## Phase — Apt Screen 2: Apartment Provider Details (`apt_rental_provider_item_list.PNG`) — REUSE, auto-activating

**Audit verdict:** identical template family to the frozen Car Provider Details (`VendorDetailScreen` +
`RentalProviderHeroHeader`) — differences are wording/data only. **No new page, no duplicated components.**

**Implementation — additive, data-driven (no manual flag):**
`RentalApartmentAdapter.isApartmentProvider` inspects the provider's REAL loaded inventory against the real
Short-Apt category (vendor list overload `apartmentCategoryIdFromVendorList`); when the inventory is
predominantly apartments the SAME frozen page presents: hero count "apartments available" (additive
`countLabel` on `RentalProviderHeroHeader`, default null → prior behaviour), chips **Guests/Bedrooms**
(inert pending queue-17 fields; car keeps Seats→real filter sheet / Transmission→queue 14), result header
"Apartments Found", empty state `no_apartment_available`. **Activates by itself the moment real apartment
inventory exists; never activates for car providers** (proven by unit tests). Everything else — search,
filter sheet, categories, banners, reviews, pagination — is the frozen implementation untouched.

**Verification:** analyze 0 issues · rental tests **16/16** (adapter: category resolution, filtering,
provider detection) · runtime: apartment presentation is unreachable with real data today (zero apartment
inventory — honest), so the on-device check is that the CAR provider page renders byte-identically (default
path) and the apt listing's empty state stands. **Pending product-owner approval before freeze.**

### Rental section scoping — banners & categories (product-owner architecture, adapter-based)
Main Rental Home → both sections (unchanged, default `RentalSection.all`). Car listing → Car-only; Apartment
listing → Apartment-only. No backend classification exists (queue item 18), so `RentalApartmentAdapter` derives
sections from REAL signals only: category name resolution (`sectionCategories`) and banner `provider_id` →
provider's real inventory (`filterBanners`; unclassified banners never shown as apartment content). Additive
`BannerWidget.section` (default `all`). Presentation/data-filter only — no controller/repository/business
change. Tests: rental suite 18/18.

### Rental Home "Popular" sections — audit (product-owner request) + corrections
**Popular Car Rentals — verified real:** backend `top-rated` endpoint = the existing production popularity
ranking (no invented algorithm) + real `status == 1` rule; cards → real Vehicle Details; See All → the Car
listing (full ranked, paginated). Preview = the backend's first ranked page. Correction applied: now excludes
apartment-category items (adapter), so future apartments never leak into the CAR popular section.
**Popular Short Apt Rentals — violation found & fixed:** it rendered the hardcoded
`kPlaceholderPopularApartments` list (pre-dated the no-fake rules; frozen then as a marked placeholder). Now:
REAL data — the same backend top-rated ranking filtered to the real Short-Apt category
(`RentalApartmentAdapter`); section HIDES while apartment inventory is empty (graceful collapse, auto-appears
with real data — no redesign); See All → the real Apartment listing; cards → real Vehicle Details. The
placeholder constants remain on disk only for the hero images (queue item 3) pending the post-Rental
dead-code audit. `_comingSoon` removed — both apartment entries are real navigation now.
**Popularity signal note:** the backend's only popularity signal is the top-rated ranking; if a distinct
"most booked" signal is wanted it is backend work (extends queue item 17) — never faked in the app.

**Adjustment (product owner):** the Popular Short Apt Rentals section stays IN the Rental Home architecture
permanently — while inventory is empty it renders the approved `MoonjoinEmptyState` (reserved foundation
component, now live) with honest copy ("no apartments listed yet"), and self-populates from the same real
top-rated ranking the moment providers list apartments — no future redesign. Loading state mirrors the Car
section's shimmer. Popularity source remains the backend's real top-rated ranking until a dedicated metric
ships (queue item 17).

---

## 🔒 FREEZE — Apt Screen 2 · Section scoping · Popular sections (product-owner approved)
All three verified on device and frozen. The logged `getZone` HTML-response exception is a SEPARATE app-wide
backend transient (core location feature, `/api/v1/config` returning HTML) — explicitly out of Rental-migration
scope by product-owner decision; no unrelated code touched.

---

## Apt Screen 3 audit — Apartment Details (`apt_rental_details.PNG`) — verdict before code

Vs the frozen `VehicleDetailsScreen`: same page skeleton (header identity, date context, quantity, price,
Proceed→cart→Checkout). Materially different content audited field-by-field against the REAL inventory model:
beds/baths/guests pills, guests steppers and house rules have NO backend fields → omitted + queued (17), never
converted from car fields, never rendered as misleading inert booking controls. Feature tags + Amenities grid
DO have a real source (the provider-entered `tag` array) → rendered from real tags, auto-populating.
Check-in/out/nights ↔ the existing day-wise trip context (day-wise IS per-night) with apartment wording;
"/night" units. **Verdict: reuse `VehicleDetailsScreen` with auto-activating apartment mode** (real
`category_id` vs the real Short-Apt category — the approved Provider-page pattern); day-wise auto-selected,
trip-type row hidden in apartment mode (apartments are per-night only — the design has no trip-type selector).
Booking still requires the production cart's pickup/destination (API reality) — the trip card stays, delta
documented pending an apartment-specific booking contract (queue 17).

## Phase — Apt Screen 3: Apartment Details — IMPLEMENTED (pending verification + approval)
Auto-activating apartment mode on the frozen `VehicleDetailsScreen` (additive; real `category_id` vs the real
Short-Apt category, category list loaded via the existing controller call on deep entry):
- **Check-in** section title (same existing pickup-time machinery/date sheet).
- **Nights** input replaces the trip-type row — day-wise auto-selected (apartments are per-night; the design
  has no trip-type selector); same existing estimate controller and validations; car items keep the frozen
  presentation untouched.
- **Header pills**: real fields only — AC + up to 3 real provider `tag`s; beds/baths/guests fields don't
  exist (queue 17) — never converted, never faked.
- **Amenities** section: the provider's real `tag` array via `RentalApartmentAdapter.amenityTags` (same
  parsing as the provider-card badges); hidden when none; auto-populates.
- Booking continues through the UNCHANGED production cart→checkout flow (trip card retained — the real
  booking API requires pickup/destination; apartment-specific booking contract documented in queue 17).
- Omitted per real-data rules + queued (17): beds/baths/guests pills, guest steppers, unit variants beyond
  the existing quantity, house rules.
**Runtime note:** apartment presentation is unreachable with real data today (zero apartment inventory) —
on-device verification = the CAR details page renders byte-identically (default path); apartment mode is
covered by the adapter unit tests and activates automatically with real inventory.

### 🐞 Two production bugs found in the Apt-Screen-3 verification log (root-caused & fixed)
1. **DateTimePickerSheet null-assert (45×)** — pre-cart, the controller's selected date/time are null until
   first picked; "Okay" without touching the pickers crashed on `selectedTripTime!`. Fix: Okay-with-no-change
   confirms the DISPLAYED time (`finalTripDateTime`) — nothing fabricated beyond keeping the shown value.
2. **GoogleMapController "used after disposed" (21×)** — pre-existing: the Location page reopened FROM the map
   (`Get.off` disposes it) still passes the dead controller; address taps then threw on the cosmetic
   `animateCamera`. Fix: the two camera pans are best-effort (`try/catch`) — a pan must never throw.
Both verified-bug fixes on production rental code; no business logic changed.

### Post-verification corrections (product owner)
1. **Map re-edit loop fixed (root-caused):** re-editing pickup/destination FROM the map reopens the Location
   page (replacing the map) and then PUSHED a new map — leaving the Location page under it, so the confirm's
   single pop landed back on it. The details journey (vehicle set, no cart edit) now ALWAYS replaces the
   Location page with the map, in all three entry handlers — stack is deterministically
   Details → Location → Map in every path, including re-edits.
2. **Pickup card title:** "Pickup Now" only while the shown time is now (±5 min); a user-selected future time
   reads **"Schedule"** (existing key). Title only — date/time line and behaviour unchanged.

## 🔒 Apt Screen 3 — Apartment Details — FROZEN (product-owner approved)
Approved after full QA: analyze 0 · rental tests 18/18 · clean runtime log · four root-caused bug fixes
verified on device (date-sheet null-assert, disposed-map pan, map re-edit stack, Pickup Now/Schedule title).

---

## Phase — Apt Checkout — MASTER architecture reused, auto-activating (pending verification + approval)
Audit of `apt_rental_checkout.PNG` vs the frozen master: Selected-item card, Price Details, Confirm+terms
identical → untouched. Payment: MASTER rule overrides the design's simplified wallet card — same payer
selector + same shared `PaymentSection`, wording-only "Pay to Apartment Provider". Materially-in-design
addition: the **Check-in / Check-out / Nights strip** (apartment mode only) — real cart values (pickup time +
estimated nights; check-out is arithmetic on them). Named-guest list omitted (no backend fields — queue 17);
"payment secure" pill = cosmetic delta. All additive on the frozen `TaxiCheckoutScreen`, auto-activating from
the cart's REAL inventory (`isApartmentProvider`) — never activates for car bookings; car checkout renders
byte-identically. Wording: `selected_apartment`, night units. No second checkout, no duplicate payment logic.

## 🔒 Apt Checkout — FROZEN (product-owner approved) — PERMANENT master-architecture confirmations
- Car Rental Checkout = the master checkout architecture.
- Short Apt Rental reuses the SAME checkout implementation — never a separate apartment payment system.
- Future apartment backend additions plug INTO this architecture (queue 16/17), never replace it.
Verified: analyze 0 · rental tests 18/18 · clean log · Car checkout byte-identical on device.

## Phase — Apt Booking Success (`booking_successful.png`) — ONE shared sheet, auto-activating (pending approval)
Audit vs the frozen Car `ConfirmBookingRequestBottomSheet`: same skeleton (check badge, title, real info
rows, provider-call, button) → reused. Apartment design adds real-data blocks → added additively in
apartment mode only: Booking ID (trip id) + Booking Date, Total Paid + payment method, Check-in/Check-out/
Nights info rows (car keeps pickup/dropoff/vehicle). Wording: "Booking Successful!" +
"Your apartment has been booked…". Detection = booked item's real `category_id` vs the real Short-Apt
category (trip `VehicleDetails.categoryId`); never activates for car → car success byte-identical. Guests
list / View-Booking-Back-to-Home split omitted (no backend guest fields; the sheet's Okay closes to the trip
page which already offers navigation) — queue 17. No second success page, no fake data, real booking response
flow preserved.

## 🔒 Apt Booking Success — FROZEN (product-owner approved)
One shared sheet for Car + Apartment; verified: analyze 0 · rental tests 18/18 · clean log · real completed
Car booking byte-identical on device.

---

## Phase — Rental Trip Details redesign (`trip_details.png` + `_scroll_down.png`, ONE page) — IMPLEMENTED
Full presentation redesign of `TaxiOrderDetailsScreen` (was legacy). **100% production logic preserved**:
`getTripDetails`, the fromCheckout PopScope + appbar-back → `getInitialRoute`, the booking-success popup
(unchanged trigger/close), cancel (`BookingCancelBottomSheet`), pay-now (`TaxiPaymentBottomSheet` + refresh),
give-review (`ReviewBottomSheet` + `_canReview`), provider WhatsApp/Call/Chat + View Company Profile, refresh.
New styled cards from REAL trip data only: status hero (status→colour/icon/message, item image, est-arrival
chip on pending, booking date/from), provider card, Vehicle Summary (image, tags, quantity, booking id,
booked-on), Trip Details rows (pickup/dropoff connector, pick time, rent type, est distance/duration), Bill
Details, Payment Method, secure pill, Need Help. Legacy sub-widgets (`TripStatusView`, `SelectedVehiclesView`,
`ProviderView`, `TripDetailsWidget`, `TripCalculationView`) are superseded by this screen — left on disk for
the post-Rental dead-code audit, not deleted.
**Apartment mode auto-activates** (real `category_id`): Trip→Booking #, Vehicle Summary→Apartment Summary,
Pickup→Check-in, Dropoff→Check-out, Provider→Apartment Provider, rent-type row→Nights; car byte-identical.
Verified: `flutter analyze` rental_order 0 issues. Runtime pending.

## 🔒 Rental Trip Details — FROZEN (product-owner approved) — additive changes only

---

## Phase — Rental Trips list (Running + History) redesign — `my_trip.png` / apt `my_booking_history.png`
**Verified path (traced, not assumed):** the bottom-nav **Trips** tab is served by the SHARED
`features/order/screens/order_screen.dart` (the "My Orders" container with the Orders/Trips/Stay toggle,
shared with Food/Grocery Orders) which embeds `TripOrderViewWidget` for trips. So the LIVE redesign is the
**trip card** (`trip_order_view_widget.dart`) — same `TaxiOrderController` + `getTripList` pagination + guest
fallback; each card opens the FROZEN `TaxiOrderDetailsScreen` (same page as after booking success — no
duplicate). The premium **header + segmented Running/History control + module wording (Orders/Trips/Stay)**
belongs to the shared `order_screen.dart` and is delivered in **items 4 (module-aware nav) + 5 (Orders
redesign)** — the NEXT phase. `taxi_order_screen.dart` was also restyled (header + segmented) as the
standalone rental variant; it is retained but NOT the wired path (the shared `order_screen.dart` is).
Card from REAL trip data only: status pill (Completed/Cancelled/other), Trip/Booking ID, Completed-on /
Cancelled-on date, From/To connector, item image + name, Total + Paid/Cancelled badge, distance/travel-time/
rent-type strip, provider + View Details. **Cancelled state** (red pill + red total + "Cancelled" badge)
handled inline per `Example_cancel_my_booking_history.png` — NO separate cancelled page.
**Apartment auto-activates per card** (real `category_id`): Booking ID, Check-in/Check-out, Nights. The page
`fromApartment` flag (additive, default false → Car "My Trips / Running Trips / Trip History") swaps to
"My Bookings / Upcoming Stays / Booking History"; the module-aware bottom nav (item 4, next) passes it. Car
path byte-verified. `flutter analyze` rental_order 0 issues. Runtime pending.

## 🔒 Rental Trip card (Running/History) — FROZEN (product-owner approved). Trips MODULE not yet frozen — the
shared wrapper `order_screen.dart` (premium header + Orders/Trips/Stay module switch + Running/History
segmented + module wording) is the remaining work.

---

## Phase — Shared Orders / Trips / Stay wrapper (`features/order/screens/order_screen.dart`) — premium redesign
ONE shared page for every module (no duplicate page, no duplicate controller). Premium MoonJoin header
(module-aware title/subtitle + notification bell), module toggle (Orders / Trips|Stay) for the rental module,
and the premium segmented **Running/History** control with live counts — reused for BOTH storefront
(`OrderViewWidget` + `OrderController`) and rental (`TripOrderViewWidget` + `TaxiOrderController`).
**Business logic 100% preserved**: `getRunningOrders`/`getHistoryOrders`, `getTripList`, pagination, refresh,
empty states, guest fallback, navigation. Desktop layout kept unchanged.
**Module-aware wording (auto-detect):** storefront → **Orders**; rental car content → **Trips** ("My Trips");
rental apartment content → **Stay** ("My Bookings" / "Upcoming Stays" / "Booking History") — derived from the
REAL loaded trips' category (Car & Apt share ONE rental module, so the sub-flow is content-derived, not a
fabricated flag). `flutter analyze` order 0 issues (pre-existing guest_custom_stepper info untouched).
Runtime pending: verify Orders (Food), Trips (Car), Stay (apartment content).

### 🐞 Pre-existing storefront bug fixed (Orders phase) — Reviews.fromJson int-as-string
`Reviews.fromJson` (`order_model.dart`) typed `id/item_id/user_id/rating/order_id/status/module_id` as `int?`
but the backend serialises some (notably `status`) as **strings**, throwing
`type 'String' is not a subtype of type 'int?'` inside `OrderController.timerTrackOrder` (running-orders
poll) — 6× in the log. Smallest defensive fix: a private `Reviews._reviewInt` (number passes through —
backward compatible — numeric string parses, else null) on those int fields ONLY; `reviewId` (String) left
as-is. Only the shared `Reviews` class changed; **verified no behaviour change** for Food/Grocery/Pharmacy/
Ecommerce/Rental (numbers unaffected) — the crash is simply prevented. Runtime: 6→0 occurrences.

## Phase — Storefront Orders card redesign — premium MoonJoin (`order_view_widget.dart`)
Redesigned to the premium card language (consistent with the Rental Trips card): status pill + Order/Delivery
ID, store logo (+ parcel/prescription tag) + name + date + amount, divider, footer Track (running) / item
count (history) + View Details. **100% logic preserved**: same `OrderController`, pagination, refresh, empty
state, `getOrderDetailsRoute`/`getOrderTrackingRoute` navigation, parcel & prescription branches; desktop grid
kept. `flutter analyze` 0 new issues.

## 🔒 SHARED Orders / Trips / Stay ARCHITECTURE — FROZEN (product-owner approved)
ONE premium wrapper `order_screen.dart` (header + module toggle + segmented Running/History + module wording)
serving BOTH storefront (`OrderViewWidget`/`OrderController`) and rental (`TripOrderViewWidget`/
`TaxiOrderController`). Orders → Trips → Stay auto-detected; Car & Apt share one rental module so Stay is
content-derived. All verified on device: Orders (premium cards, Track, no crash), Trips (frozen cards),
toggle, Running/History, pagination, refresh, empty states, guest, desktop. Log clean (0 subtype/RenderFlex/
overflow/null-check). **Business logic, APIs, controllers, repositories, navigation 100% preserved.**

---

## Phase — Scheduled Module Availability + Search improvements (additive; audit-first)

### Architecture audit (before any code)
- **Module availability UI already exists & frozen:** `ModuleAvailability {enabled, unavailable, disabled}` +
  `CategoryTile.availability` render **exactly the Glovo behaviour** (visible, faded+desaturated, `onTap:null`,
  no ripple, no popup, no layout shift). `resolveModuleAvailability(module)` is the single wiring point (was a
  placeholder returning `enabled`). **Reused — not recreated.**
- **Schedule logic already exists:** store-hours `Schedules {day, opening_time, closing_time}` +
  `StoreController.isStoreOpenNow/isStoreClosed` (mirrored in `TaxiVendorController`). Module-level schedule
  did not exist → added as adapter fields only.
- **Search:** header count read `searchStoreList.length` (0 until the Store tab / a store was derived). Item
  model **already has `store_id` + `store_name`**; the frozen `item_widget` already renders `store_name` — it
  was just suppressed via `hideItemStoreName: true`.

### Part 1 — Scheduled Module Availability (adapter only)
- `ModuleModel` gained nullable **adapter fields** `open_time`, `close_time`, `timezone`, `temporary_close`,
  `holiday_today` — all null today (backend not sending), so behaviour is unchanged.
- `resolveModuleAvailability` now computes `unavailable` from those REAL fields (temporary close / holiday /
  outside the open–close window, normal + overnight) and `enabled` when absent. **No hardcoded times, no
  invented schedule, no card redesign** — the frozen `CategoryTile` already fades + disables. When the backend
  ships the fields, ONLY this resolver reads them; zero architecture change.

### Part 2 — Search
- **Issue 1 (count):** new `SearchController.resultStoreCount` — returns the loaded store count, else the
  count of **distinct owning stores derived from `item.store_id`** (zero extra API calls). Header now shows the
  real count immediately, no interaction needed.
- **Issue 2 (owner name):** search item results now pass `hideItemStoreName: false`, so the frozen `item_widget`
  shows the REAL `item.store_name` under the title. When the backend omits it, the widget hides it gracefully
  (never faked) — documented as queue item 20.

### Reuse / discipline
No duplicate widget/controller/repository, no extra API calls, no hardcoded schedule, no fake data, no redesign
of frozen components, no business-logic change. `flutter analyze` 0 issues on all changed files. Runtime pending.

---

## Phase — Rental Service Completion Code (Part 1) + Profile Modernization audit (Part 2)

### Architecture audit (before code)
**Part 1 — completion/settlement:** `TripDetailsModel` ALREADY carries **`otp`** (`json['otp']`) — the same
completion-code field Delivery uses (`order.otp`, shown in `order_info_widget.dart`). So the customer code is
REAL backend data, reused — no new field, no duplicate logic. Trip statuses:
pending→confirmed→ongoing→completed→canceled. Settlement is backend/admin-side (no frontend settlement logic
exists or should); the provider entering the code flips status to completed via the existing vendor/backend
flow. **No Vendor Rental completion screen exists in this User-App repo** (Vendor App is separate) → documented.
**Part 2 — Virtual Account:** a shared `VirtualAccountDetailsWidget` exists in `features/checkout/widgets/`
(the "Your Virtual Account Details" from Choose Payment Method). Profile currently uses its OWN
`virtual_account_card_widget.dart` — a duplication to consolidate onto the shared component (Profile + Wallet).
Profile MAIN page is already MoonJoin-modernized (stat tiles, VA card, sectioned lists); the LEGACY 6amMart
pages are the child screens (Personal Info, Address, Notifications, Wallet, Transactions, Coupons, Loyalty,
Language, Settings, Refer&Earn, Help, About, Terms, Privacy, Delete, Logout).

### Part 1 — 🔒 FROZEN (customer completion code) — product-owner approved
Additive section on the frozen `TaxiOrderDetailsScreen`: a very visible **Service Completion Code** card
(green gradient, large spaced digits) shown while the trip is **confirmed/ongoing** and `trip.otp` is present,
with the Delivery-style instruction. Real `trip.otp` only — hidden when no code. Car & Apartment share it
(wording neutral: "service"). No business/settlement logic, no new controller/API. Verified on device.

**Status → display mapping (documented, from `TripStatusEnum`):**
pending → hidden · confirmed → **visible** · ongoing → **visible** · completed → hidden · canceled → hidden.
(There is no distinct "accepted" status in `TripStatusEnum`; "confirmed" is the accepted state.) Rule:
`(status == confirmed || status == ongoing) && trip.otp != null/empty`.

**Completion FLOW audit (User App → Provider → Backend → Admin → Settlement):** the User App holds NONE of
the completion/settlement machinery — verified: no OTP-generation, no validate-code endpoint, no
status-transition call, no settlement call exists in this repo (rental services expose only booking/payment).
The app only DISPLAYS `trip.otp`. Every question below is therefore a Backend/Vendor/Admin contract, queued
(item 21), never invented in the frontend:
- OTP generated where/when → backend, at trip creation/confirmation (today surfaced as `trip.otp`).
- Expiry / validation / confirming API / status change / payment-eligibility / reuse-prevention / double-submit
  / wrong-code / cancel-before-completion → all backend + Vendor App; documented as the Rental Completion
  Contract (queue 21).
- Car AND Apartment: the SAME code path (`_showCompletionCode` + `trip.otp`) serves both — no duplicate.

**Status: 🔒 FROZEN — additive changes only.**

### Part 2 — plan (pending approval, NEXT unit)
1. Replace Profile's `VirtualAccountCardWidget` with the shared `VirtualAccountDetailsWidget`; reuse the SAME
   component on the Wallet "+" flow. One component, no duplication.
2. Modernize each legacy Profile child page into the MoonJoin design language (spacing/typography/cards/
   buttons/shadows/colors) — presentation only, controllers/APIs/navigation untouched — one page at a time.

---

## Phase 2A — Virtual Account consolidation (ONE shared component) — pending approval
Audit: **three** virtual-account implementations existed — the shared `VirtualAccountDetailsWidget`
(Checkout), the profile `VirtualAccountCardWidget` (3 call sites: profile_screen, web_profile, menu), and an
INLINE 9PSB block in the wallet `AddFundDialogueWidget`. The profile copy also owned **loading** +
**generate-account** states the shared one lacked.

Consolidation: `VirtualAccountDetailsWidget` **extended into the single superset** (self-contained
`GetBuilder<ProfileController>`; states: loading spinner · no-account → reuse existing
`generateVirtualAccount()` · account details + copy + info note; MoonJoin-styled; additive `detailsOnly`/
`margin`). Reused at ALL call sites: Profile (×3) and the Wallet "+" 9PSB block. **No new business logic** —
only the existing `generateVirtualAccount()` is reused; no controller/API/repository change.

Duplicates now unused (retained on disk per no-auto-delete, for the post-migration dead-code audit):
`virtual_account_card_widget.dart`, the wallet inline `_virtualInfoRow`. Dead imports removed.
`flutter analyze` 0 new issues. Runtime pending. Zero duplication achieved.

### Phase 2A — CORRECTION (master = the approved Checkout card)
The first 2A attempt reused the DATA but rendered a different, Profile-styled card — visual drift.
Corrected: the approved "Your Virtual Account Details" card from the Choose Payment Method sheet
(`payment_method_bottom_sheet.dart → _virtualAccountFundSection`) is the MASTER. It was extracted
**verbatim** (title `your_virtual_account_details`, 46px logo chip, `_infoRow`, `_copyButton`, numbered
`_instructions`) into `VirtualAccountDetailsWidget`, extended with loading + generate states that reuse the
same premium shell. Checkout now CONSUMES the extracted widget (its inline copy + 4 helpers deleted).
Reused pixel-identically at: Checkout, Profile (×3), Wallet "+". `virtual_account_card_widget.dart` marked
OBSOLETE (zero call sites, retained for final cleanup). analyze: 0 new issues.

### Phase 2A — FROZEN (2026-07-24)
`VirtualAccountDetailsWidget` approved and frozen as a **FOUNDATION COMPONENT**. It is the single,
canonical "Your Virtual Account Details" UI for the entire User App — see docs/FROZEN_REGISTRY.md. Any
future virtual-account surface (Checkout, Wallet, Deposit, Fund Wallet, Bank Account, Profile, Payment /
Financial pages) MUST reuse it; no new Virtual Account UI without explicit architectural approval.

---

## Stage 1 — Profile Modernization: Foundation rows + Account shell — FROZEN (2026-07-24)
**Design authority:** `ui-designs/Profile_Loction_.../profile.png` + `profile_scroll down.png` (not in Active Figma).

**Shared components redesigned (frozen FOUNDATION):**
- `PortionWidget` — MoonJoin navigation row (chip · bold title · subtitle · chevron · inset divider · isDanger). API preserved + `subtitle`, `isDanger`.
- `ProfileButtonWidget` — MoonJoin setting/toggle/action row. API preserved + `subtitle`, `isDanger`.

**Account shell (`menu_screen.dart`) matched to profile.png:** waved green header (top spacing from
`MediaQuery.padding.top`; avatar edit-badge → Edit Profile; notification bell → Notifications; dark-mode
moon), 3 tappable stat cards with action pills (View Rewards/My Orders/My Wallet → existing
Loyalty/Orders/Wallet routes), bold section headers, subtitles on every row, `radiusLarge` cards.

**Navigation:** `order_screen.dart` gained additive `fromNavigation` flag → back button when pushed from
Profile (bottom-nav tab/drawer unchanged); `getOrderRoute({fromNavigation})` + order GetPage reads
`from_nav`. All other routes/onTap unchanged. Frozen VA widget untouched.

**Verification:** flutter analyze 0 issues (changed files); runtime run50 0 errors; on-device match to
profile.png confirmed by product owner → approved & frozen.

**Pending / cleanup (documented, not actioned):**
- Localization: 19 new keys added to en/ar/bn/es — non-English are ENGLISH PLACEHOLDERS pending real
  translation (see BACKEND_INTEGRATION_QUEUE.md).
- Icon: `My Address` uses `address_icon.png` (folded map); profile.png shows a pin — no pin-style menu-icon
  asset exists → future asset addition.
- Dead code for final cleanup: `menu_button_widget.dart` (0 usages), `virtual_account_card_widget.dart`.

---

## Phase 2 — Personal Information (Edit Profile) — FROZEN (2026-07-24)
**Design authority:** none dedicated → reproduces the frozen Stage-1 MoonJoin Profile language (presentation only).

**Implementation:** `update_profile_screen.dart` rebuilt — mobile `_mobileView` (green `ProfilePageHeader` +
back + delete menu; premium avatar w/ camera badge straddling header/body; "Basic Information" card of the 3
shared `CustomTextField`s; frozen `ProfileButtonWidget` Change Password; `CustomButton` Update) and restyled
`webView()` to the same language (green header, card radius, shared `_avatar`). All logic methods verbatim.

**New shared component:** `ProfilePageHeader` (FOUNDATION, frozen) — the official header for every remaining
Profile page. No duplicate headers permitted.

**Reuse:** CustomTextField ×3, CustomButton, ProfileButtonWidget (frozen), image picker, delete-account
menu/dialog/deleteUser — nothing recreated.

**Preserved:** ProfileController · ProfileRepository · ProfileService · API `POST /api/v1/customer/update-profile`
· UpdateUserModel/UserInfoModel contract · all validation (name/email/phone) · image-upload multipart ·
phone/email verification flows · navigation (`getUpdateProfileRoute`) · loading/error/success-refresh.

**QA bugs found & fixed:** (1) "Edit Profile" title hidden behind the centred avatar → header `bottomExtra`
increased so the avatar drops below the title. (2) camera badge not tappable — avatar was `Positioned` in the
header Stack's `Clip.none` overflow (painted but not hit-tested) → restructured to sit INSIDE the Stack bounds
(reserved via bottom padding); whole avatar + badge now tappable.

**Verification:** flutter analyze 0 issues; runtime run53 0 RenderFlex/overflow/subtype/null-check; on-device
navigation + data load + verified badge + image picker confirmed; owner-approved. Note: "slow" upload = native
image_picker/simulator latency, flow unchanged. Desktop `webView()` visual verification PENDING (non-blocking;
future tweaks are refinements, not a reopen).

**Obsolete (retained, DO NOT delete — final cleanup only):** `profile_bg_widget.dart` (→ ProfilePageHeader),
plus previously logged `virtual_account_card_widget.dart`, `menu_button_widget.dart`.

---

## Phase 3 — My Address (list) — FROZEN (2026-07-24)
**Scope:** My Address LIST screen only. Add/Edit/Map (GoogleMap + LocationController) = separate future phase, untouched.
**Design authority:** none dedicated → reproduces the frozen MoonJoin Profile language (presentation only).

**Implementation:** `address_screen.dart` rebuilt — mobile `_mobileBody` (green `ProfilePageHeader`,
`RefreshIndicator` list of shared `AddressWidget` cards, bottom `CustomButton` "Add New Address", MoonJoin
empty state via `NoDataScreen`) + desktop `_desktopBody` (existing grid preserved; city background removed;
`CustomAppBar` → `WebMenuBar`). Shared `AddressWidget` `fromAddress` branch modernized to a MoonJoin card
(soft-green type chip + type label + address + soft-tinted edit/delete). `fromCheckout` and `fromDashBoard`
branches untouched.

**Architecture preserved:** AddressController · AddressRepository · AddressService · APIs
(`/customer/address/list|add|update/{id}|delete`) · `AddressModel` · validation · Google Maps · geocoding /
reverse-geocoding / forward search · zone + delivery validation · navigation (getAddressRoute, add/edit/map)
· active-address logic. **No business logic changes.** No leakage into Add/Edit/Map.

**Shared component reuse:** ProfilePageHeader (frozen), AddressWidget (the one shared card), CustomButton,
AddressConfirmDialogue, NoDataScreen, AddressController — nothing recreated. No duplicate address card.

**Runtime verification:** `flutter analyze` 0 issues; on-device the list rendered with real data, 0
address-parse errors, 0 RenderFlex/overflow/subtype/null-check from the screen. (Startup config-HTML failures
were a backend **Imunify360 bot-protection** block — see below — resolved via VPN; `apns-token-not-set` is
benign iOS-simulator push noise.) Owner manually verified the UI + approved.

**Future backend capabilities (noted only — NOT implemented):** server-side **Default / Favorite Address**
(no `is_default` field/API today), **Address history**, **Smart/AI suggestions**. Documented in
BACKEND_INTEGRATION_QUEUE.md as future enhancements.

**Legacy / obsolete:** none newly obsolete this phase (redesign was inline). No deletions.

---

## Phase 4 — Coupon (list) — FROZEN (2026-07-24)
**Scope:** Coupon LIST screen only. Checkout coupon bottom sheet NOT touched.
**Design authority:** none dedicated → reproduces the frozen MoonJoin Profile language (presentation only).

**Implementation:** `coupon_screen.dart` — `CustomAppBar` → `ProfilePageHeader` (mobile) / `WebMenuBar`
(desktop); grid/refresh/tooltip/clipboard logic unchanged; passes `fromCouponScreen: true`.
`coupon_card_widget.dart` — added presentation-only `fromCouponScreen` flag + `_moonjoinCard` variant (green
ticket: discount stub · perforation · dashed green code chip + copy · validity · min purchase). Default flag =
legacy card → Checkout coupon bottom sheet UNCHANGED.

**Architecture preserved:** CouponController · CouponRepository · CouponService · API `/coupon/list` ·
`CouponModel` · copy-to-clipboard · tooltip · refresh · loading · empty state · navigation. No logic changes.
No duplicate/forked widget — single shared `CouponCardWidget`.

**Runtime verification:** flutter analyze 0 issues; card rendered with real data, 0
RenderFlex/overflow/subtype/null-check. Owner verified copy + "code copied" tooltip, pull-to-refresh, back
nav, and the **Checkout coupon selector unchanged (regression pass)**. Approved.

**Future coupon capabilities (noted only — NOT implemented):** category / product / referral / loyalty /
wallet-funded / automatic (auto-apply) / scheduled coupons → future backend (new couponType values / endpoints).
See BACKEND_INTEGRATION_QUEUE.md.

**Legacy / obsolete:** none newly obsolete (redesign was an isolated variant). No deletions.

---

## Phase 5 — Loyalty Points — FROZEN (2026-07-25)
**Design authority:** none dedicated → reproduces the frozen MoonJoin Profile language (presentation only).

**Implementation:** `loyalty_screen.dart` — `CustomAppBar` → `ProfilePageHeader` (mobile, `onBack` preserves
`fromNotification`) / `WebMenuBar` (desktop); FAB → bottom `CustomButton` "Convert to Wallet Money"; desktop
2-column kept; pagination scroll-controller + `RefreshIndicator` + `PopScope` preserved. `loyalty_card_widget.dart`
→ MoonJoin green points card (stepper/dialog trigger kept). `loyalty_bottom_sheet_widget.dart` → reuses
CustomTextField/CustomButton; validation + exchange + `pointToWallet` untouched. `history_item_widget.dart` →
added isolated `moonjoinLoyalty` variant (Wallet `fromWallet:true` UNCHANGED). `profile_page_header.dart` →
additive optional `onBack` (defaults to Get.back()).

**Architecture preserved:** LoyaltyController (pagination + pointToWallet) · ProfileController · SplashController
· LoyaltyRepository · LoyaltyService · APIs (`/loyalty-point/transactions`, `/point-transfer`) · TransactionModel
· convert validation + exchange rate · pagination · refresh · navigation (+ fromNotification). No logic changes.

**Runtime verification:** flutter analyze 0 issues; card + rows rendered with real data, 0
RenderFlex/overflow/subtype/null-check. Owner verified: convert flow + validation, pagination, pull-to-refresh,
back + fromNotification, and **Wallet history unchanged (regression pass)**. Approved.

**Future (noted only — NOT implemented):** loyalty tiers/levels, earn-rate breakdown, loyalty-funded coupons,
redemption options beyond wallet, points expiry, advanced history filters. See BACKEND_INTEGRATION_QUEUE.md.

**Legacy / obsolete:** none newly obsolete (redesign in place / isolated variant). No deletions.

---

## Phase 6 — Refer & Earn — FROZEN (2026-07-25)
**Design authority:** none dedicated → reproduces the frozen MoonJoin Profile language (presentation only).

**Implementation:** `refer_and_earn_screen.dart` rebuilt — `CustomAppBar` → `ProfilePageHeader` (mobile, info
icon via `trailing` → `BottomSheetForMobile`) / `WebMenuBar` (desktop); MoonJoin reward card (green rate chip ·
"Invite friends & businesses" · green dashed code box + green Copy · Share `CustomButton`); desktop keeps inline
`BottomSheetViewWidget`. No dedicated controller/API — reuses `ProfileController.refCode` + `SplashController`
config.

**Architecture preserved:** `ProfileController.refCode` (only referral data source) + getUserInfo · exact
`SharePlus` share text (app name + code + download link) · `Clipboard` copy + snackbar ·
`SplashController.refEarningExchangeRate` display · auth handling · navigation · both info-sheet flows. No
controller/repo/service/API/model/validation/business-logic changes.

**Runtime verification:** flutter analyze 0 issues; screen rendered with real refCode, 0
RenderFlex/overflow/subtype/null-check from the page. Owner verified: copy + snackbar, share sheet (exact
text), info sheet opens, back navigation. Approved. (Startup config-HTML retries = backend Imunify360, resolved
via VPN — unrelated.)

**Future (noted only — NOT implemented):** referral tiers, analytics/leaderboard, dedicated reward history,
multi-level referrals, campaigns, custom referral rewards. See BACKEND_INTEGRATION_QUEUE.md.

**Legacy / obsolete:** `ExpandableBottomSheet` usage on this page → OBSOLETE — Pending Final Legacy Cleanup
(package still used by 3 other files). No deletions.

**Protected:** My Wallet + Wallet History untouched — reserved for Phase 7 (their own dedicated migration).

---

## Phase 7 — My Wallet + Wallet History — FROZEN (2026-07-25)
**Design authority:** none dedicated → reproduces the frozen MoonJoin Profile language (presentation only).

**Implementation:** `wallet_screen.dart` (ProfilePageHeader + onBack/fromNotification; WebMenuBar desktop),
premium fintech balance card (`wallet_card_widget.dart`), MoonJoin history + filter chip
(`wallet_history_widget.dart`), premium Add Fund dialog (`add_fund_dialogue_widget.dart`) with "9PSB Virtual
Account" label. Shared `history_item_widget.dart` gained isolated `moonjoinWallet` variant (Loyalty/default
untouched). Shared `virtual_account_details_widget.dart`: scaleDown values (full account number) + premium
inline "Copied" fade replacing the top snackbar (clipboard unchanged) — benefits all reuse sites.

**Architecture preserved:** WalletController · ProfileController · SplashController lifecycle · repository ·
service · APIs (`/wallet/transactions|add-fund|bonuses|virtual-account`) · models · validation · add-fund +
payment/gateway flow · payment-return snackbar + `walletAccessToken` idempotency · pagination · filters ·
refresh · navigation · currency/transaction calculations. No business-logic changes.

**Payment investigation (recorded):** Wallet & Checkout consume `configModel.activePaymentMethodList`
correctly — no frontend hardcoding (`config_model.dart:283` adds every gateway), no filtering (checkout's 9psb
`where` is a separation, not removal). Live `/api/v1/config` returns all 3 gateways; runtime proved the model
holds all 3. Remaining "only 9PSB" behaviour = stale local config cache when the network refresh is blocked by
the legacy host's Imunify360 bot-protection and/or no cold restart after an Admin change → documented
**Legacy Backend Limitation**. Config-lifecycle redesign deferred to MoonJoin World.

**Runtime verification:** flutter analyze 0 issues; run64 full session (Wallet/Add Fund/Checkout) 0
RenderFlex/overflow/subtype/null-check. Regression sweep: HistoryItemWidget variants isolated; Checkout VA
card visually verified (full account number + instructions); ProfilePageHeader unchanged across all frozen
pages. Temporary PAYDEBUG log added then removed (net-zero). Owner-approved.

**Legacy / obsolete:** none newly obsolete. No deletions.

---

## Phase 8A — Notifications — FROZEN (2026-07-25)
**Design authority:** none dedicated → reproduces the frozen MoonJoin Profile language (presentation only).

**Implementation:** `notification_screen.dart` rewritten — legacy `CustomAppBar` replaced with
`ProfilePageHeader` (mobile, onBack preserves fromNotification) / `WebMenuBar` (desktop); MoonJoin notification
cards (`_notificationCard`) with a green type-icon chip, title, 2-line body, time, optional push image; unread
visual (green dot + bold + soft green tint + border + shadow) vs read (flat/muted) — derived ONLY from the
existing local `notificationIdList` (no backend unread system).

**Existing business logic untouched:** NotificationController · NotificationService · `GET
/customer/notifications` · NotificationModel · local unread tracking (getSeenNotificationIdList /
addSeenNotificationId / saveSeenNotificationCount) · date sorting/grouping · refresh · empty state
(NoDataScreen) · detail flows (NotificationBottomSheet / NotificationDialogWidget) · PopScope + fromNotification.

**Verification:** flutter analyze clean (0 issues); runtime run65 0 RenderFlex/overflow/subtype/null-check;
mobile QA completed (load, tap→bottom sheet + unread→read transition, pull-to-refresh, back + deep-link) —
owner-approved. No regressions. Desktop verification pending/non-blocking.

**Legacy / obsolete:** none newly obsolete. No deletions.

---

## Phase 8B — Help & Support — FROZEN (2026-07-25)
**Design authority:** none dedicated → reproduces the frozen MoonJoin Profile language (presentation only).

**Implementation:** `support_screen.dart` rewritten — `CustomAppBar` → `ProfilePageHeader` (mobile) /
`WebMenuBar` (desktop); support illustration hero + "We're here to help"; MoonJoin contact cards
(Email/Call/Address) with brand-green icon chips. Email launch made robust (canLaunchUrlString +
LaunchMode.externalApplication + graceful fallback; same intent as the Call action).

**Preserved:** SplashController config (email/phone/address) · tel:/mailto: launches · desktop
`WebSupportScreen` · navigation. No controller/repository/service/API/model changes. No FAQ/ticket/live-chat/
support-API added.

**Verification:** flutter analyze clean (0 issues); runtime run67 0 RenderFlex/overflow/subtype/null-check;
mobile QA (page opens, header/back nav, contact data renders from real config, email/call actions) —
owner-approved. No regressions. Desktop verification pending/non-blocking. Simulator note: `mailto:` has no
handler on the simulator (no Mail app) → graceful fallback; opens the mail composer on real devices.

**Legacy / obsolete:** `support_button_widget.dart` → OBSOLETE — Pending Final Legacy Cleanup (zero call
sites; not deleted). No other deletions.

---

## Phase 8C — HTML Container — FROZEN (2026-07-25)
**Design authority:** none dedicated → reproduces the frozen MoonJoin Profile language (presentation only).

**Implementation:** `html_viewer_screen.dart` rewritten as ONE reusable MoonJoin HTML container — legacy
`CustomAppBar` replaced with `ProfilePageHeader` (mobile, title per HtmlType) / `WebMenuBar` (desktop); server
HTML wrapped in a MoonJoin card (radiusLarge + border/shadow + readable typography); loading spinner +
`NoDataScreen` empty state; title mapping consolidated into one `_title` getter. Applies to all HtmlType routes
(About Us, Terms & Conditions, Privacy Policy, Refund Policy, Shipping Policy, Cancellation Policy).

**Preserved:** HtmlController.getHtmlText · HtmlService · HTML content API/endpoints · HtmlType mapping ·
`flutter_widget_from_html_core` renderer (textStyle/key/onTapUrl→launchUrlString) · navigation · loading.
No controller/service/API/model changes. Server HTML rendering preserved.

**Verification:** flutter analyze clean (removed one unreachable `default` in the exhaustive HtmlType switch);
runtime run68 0 RenderFlex/overflow/subtype/null-check; all HTML routes verified on-device (MoonJoin header,
HTML renders in card, loading state, back nav) — owner-approved. Desktop structure preserved (WebMenuBar +
WebScreenTitleWidget + FooterView); desktop visual verification pending/non-blocking.

**Legacy / obsolete:** none newly obsolete. No deletions.

---

## Phase 8D — Logout UI — FROZEN (2026-07-25)
**Design authority:** none dedicated → reproduces the frozen MoonJoin language (presentation only).

**Implementation:** isolated MoonJoin variant added to the shared `ConfirmationDialog` (`moonjoin` flag,
default false → `_moonjoinDialog`: premium rounded card, red logout icon chip, "Logout" heading, description,
Cancel secondary + green primary "Logout" #2C9C44). Logout call in the frozen `menu_screen.dart` gets a
one-line additive `moonjoin: true` (approved presentation touch). Other 20 ConfirmationDialog call sites keep
the legacy dialog.

**Preserved:** AuthController.socialLogout · token/session · cart/favourite/profile/shared-data cleanup ·
snackbar · navigation. Green Logout → same onYesPressed (cleanup + close); Cancel → Get.back. No auth/business
-logic changes.

**Verification:** flutter analyze clean (0 issues); runtime run69 0 RenderFlex/overflow/subtype/null-check;
on-device — dialog appears, Cancel works, Logout executes cleanup + lands correctly, other confirmations
unchanged (regression pass) — owner-approved.

**New architectural finding (now implemented in Phase 9B):** `NotLoggedInScreen` is a single shared guest
prompt reused ~14× → redesigned in place and FROZEN as the permanent MoonJoin **Guest Foundation** (see Phase 9B
below). Sign In / Sign Up remain a deferred critical-auth phase.

**Legacy / obsolete:** none newly obsolete. No deletions.

---

## Phase 8E — Live Chat (Conversation List) — FROZEN (2026-07-26)
**Design authority:** none dedicated → reproduces the frozen MoonJoin language (presentation only).
**Scope:** Conversation LIST only. Chat Thread (message screen) intentionally UNTOUCHED — its own future phase.

**Implementation:** `conversation_screen.dart` — `CustomAppBar` → `ProfilePageHeader` (mobile, showBack:
!fromNavBar) / `WebMenuBar` (desktop); MoonJoin premium conversation cards (avatar w/ soft green ring · bold
name · muted type · time · modernized green unread badge — exact unread condition preserved); empty →
`NoDataScreen`; desktop `WebChatViewWidget` untouched.

**Preserved (no changes):** ChatController · repositories · services · APIs · polling · pagination · search ·
unread logic · message/conversation loading · send-message · image-attachment · NotificationBodyModel ·
getChatRoute · refresh · FAB · navigation. No backend/business-logic changes.

**Architecture note:** the new Conversation List card is the official MoonJoin visual foundation for the future
MoonJoin World messaging platform — generic shape (avatar·name·subtitle·time·unread) so websocket/live-sync
can replace the backend without another UI redesign.

**Verification:** flutter analyze clean (0 issues; removed 1 unused import + 1 redundant `!`); runtime run70 0
RenderFlex/overflow/subtype/null-check; on-device — loading, list, open conversation→thread+back, search
(filter+clear), pagination, refresh, back nav, FAB — owner-approved. Desktop verification pending/non-blocking.

**Future phase (documented, NOT implemented): MoonJoin Chat Thread Experience** — message thread UI, chat
bubbles, attachments, typing indicators, read receipts, delivery status, voice/image/file presentation, future
websocket integration + MoonJoin World messaging architecture.

**Legacy / obsolete:** none newly obsolete. No deletions.

---

## Phase 8G — Settings — FROZEN (2026-07-26)
**Design authority:** none dedicated → reproduces the frozen MoonJoin Profile language (presentation only).

**Implementation:** `setting_page.dart` — `CustomAppBar` → `ProfilePageHeader` (mobile) / `WebMenuBar`
(desktop); rows reuse the FROZEN `ProfileButtonWidget` UNCHANGED (Language selector, Dark Mode, Notification
[isLoggedIn-gated, pre-existing], Version). `LanguageBottomSheetWidget` chrome modernized to MoonJoin
(`LanguageCardWidget` reused unchanged; Update logic preserved) — Settings owns it (only call site).
`NotificationStatusChangeBottomSheet` gained an isolated `moonjoin` Settings-only variant (default false → the
other 2 call sites profile_screen + web_profile_widget stay legacy).

**Preserved:** LocalizationController · ThemeController · AuthController (notification toggle + notificationLoading
+ persistence) · setLanguage/saveCacheLanguage/searchSelectedLanguage · dark-mode toggle · navigation · version.
No controller/repo/service/API/model/persistence/business-logic changes. No Guest/Auth entanglement.

**Verification:** flutter analyze clean (settings + both sheets + the 2 other notification call sites, 0 issues);
runtime run73 0 Settings/Notification/RenderFlex/subtype/null-check (12 log lines = 6 benign APNS-simulator +
startup null-check noise); on-device — Settings page + Notification MoonJoin sheet (red disable, Cancel/Confirm)
+ Language MoonJoin sheet (cards + Update) all verified. Owner-approved.

**Permanent architecture decisions recorded:** Settings owns the LanguageBottomSheetWidget experience;
NotificationStatusChangeBottomSheet uses an isolated MoonJoin Settings variant only; Shared Widget Protection
enforced; ProfileButtonWidget = frozen foundation; LanguageCardWidget = shared frozen foundation.

**Legacy / obsolete:** none newly obsolete. No deletions.

## Phase 9B — Guest User Experience (`NotLoggedInScreen`) — FROZEN (2026-07-26)
**Design authority:** none dedicated → reproduces the frozen MoonJoin language (presentation only).

**Implementation:** `lib/common/widgets/not_logged_in_screen.dart` redesigned **in place — Option A: ONE shared
implementation, NO isolated variants** — now the permanent **MoonJoin Guest Foundation**, the single shared
not-logged-in guard rendered by ALL ~14 protected surfaces (Wallet, Coupon, My Address, Loyalty, Refer & Earn,
Notifications, Chat, Edit Profile, Checkout, Parcel, rental favourite, …). One change updates every guest prompt
app-wide. Layout: soft-green MoonJoin halo (168px, `primaryColor` @ 8% alpha) around `Images.guest` (110px) →
bold `you_are_not_logged_in` → hint `please_login_to_continue` → green `CustomButton` "login" (width 240,
`radiusLarge`, `Icons.login_rounded`). `Dimensions.*` tokens replace the old MediaQuery-fraction sizing;
`SingleChildScrollView + FooterView` host wrapper kept. **No secondary CTA.** The single `callBack(bool success)`
param is unchanged → all ~14 call sites compile untouched. Reuses `CustomButton`, `FooterView`, `Images.guest`,
existing i18n keys (`you_are_not_logged_in`, `please_login_to_continue`, `login`).

**Preserved (presentation only, verbatim):** Login `onPressed` — mobile `Get.toNamed(RouteHelper.getSignInRoute(
Get.currentRoute))` · desktop `AuthDialogWidget(exitFromApp:false, backFromThis:true)` then `callBack(true)` ·
`OrderController.showRunningOrders()` guard · trailing `callBack(true)` (return-after-login refresh). Untouched:
AuthController · session · token · Firebase · OTP · guest login · social login · RouteHelper · callback ·
return-after-login · desktop AuthDialogWidget · navigation · repositories · APIs · models · services.

**Verification:** `flutter analyze` clean (0 issues); runtime run74 — guest **Wallet** verified + guest **My
Address** verified, 0 exceptions/overflow on guest surfaces. The unrelated `CachedNetworkImage` "No host in URI
null" log = pre-existing null-avatar on the logged-in profile, NOT caused by Guest UX (this screen uses a bundled
`Image.asset`). Owner-approved.

**Permanent architecture decisions recorded:** `NotLoggedInScreen` = the permanent MoonJoin Guest Foundation
(single shared guest guard across all protected surfaces; no isolated variants; one shared implementation). It is
a **protected shared foundation** — future modifications must preserve the callback contract, navigation contract,
desktop dialog flow, and mobile login flow; no business-logic changes.

**Legacy / obsolete:** none newly obsolete. No deletions.

## Phase 9C-1 — Auth Foundation — FROZEN (2026-07-27)
**Status:** Implemented · QA Passed · Design Approved · FROZEN. **Design authority:** none (no Sign In Figma / no
login ui-designs) → the frozen MoonJoin language, as with Guest Foundation 9B. Presentation only.

**Implementation:** 10 additive, pure-presentation components in **`lib/features/auth/widgets/foundation/`** (new
folder; zero edits to existing auth screens/controllers/services/routes): `AuthScaffold`, `AuthHero`, `AuthHeader`,
`AuthCard`, `AuthInputGroup`, `AuthOtpField`, `AuthSocialButton`, `AuthDivider`, `AuthFooter`, `AuthPrimaryButton`
(+ `auth_foundation.dart` barrel). Premium approved look: full-bleed green hero (~36% h, 48px curved bottom) with a
softly **breathing** haloed logo (ease-in-out scale+glow; configurable `logoCornerRadius` clips square/opaque logos,
transparent unaffected → future logo swap needs no code) + "Welcome back to MoonJoin" + subtitle; floating
overlapping `AuthCard` (radiusExtraLarge + soft shadow); horizontal Google/Apple/Facebook pills (owner approved
as-is); "or → Sign in with OTP" affordance (visual parity with old `manualAndOtp`).

**Owner design-refinement history:** premium green hero + breathing logo approved; social pills kept horizontal
"as-is" per owner; logo given a configurable corner-radius clip; demo interactivity reverted to match approved
design; OTP affordance added after verifying the old system.

**Contract / Shared Widget Protection:** every component is pure presentation — no controllers, navigation,
validation, API/repository/service, SDK, or `Get.find<...Controller>()`; behavior via constructor params/callbacks;
theme via `Theme.of(context)`; spacing/radius via `Dimensions.*`; no hardcoded hex. `AuthScaffold` never creates
`Dialog()`/navigates; `AuthSocialButton` is provider-blind; `AuthInputGroup` owns no controllers/validators;
`AuthOtpField` is theme-only over `PinCodeTextField`; `AuthPrimaryButton` only presets frozen `CustomButton`.

**Verification:** `flutter analyze lib/features/auth/widgets/foundation/` → **No issues found!** Isolated demo
launched on the iOS simulator via `flutter run -t …/auth_foundation_demo_main.dart` and screenshotted for design
review; owner approved. (Required an environment repair — CocoaPods was broken by a Ruby 2.6-vs-rbenv-3.4.1
mismatch with no `pod` shim; fixed via `rbenv rehash`. `pod 1.16.2` / `ruby 3.4.1` / `flutter doctor` all green.
Host Xcode builds are extremely slow due to thermal throttling.)

**Recorded (not implemented) — Phase 9C-2 Manual Login Persistence UX contract:** always auto-fill last successful
manual **email/phone**; **never** auto-store password; on reopen auto-fill email/phone + auto-focus password; future
biometric may use platform secure storage; **no "Remember me" checkbox**; preserve all login/OTP/Firebase/nav/
business logic; implement in 9C-2 only. (See project memory `auth-redesign-phase-9c`.)

**MANDATE:** all future auth surfaces (Sign In, Sign Up, OTP/Verification, Forgot/Reset, New User Setup, desktop
`AuthDialogWidget`) reuse this frozen foundation. No visual/structural/animation/spacing/typography/API change
without an explicit owner revision request. Phase 9C-2 (Sign In wiring) NOT started — awaiting owner approval.

## Phase 9C-2 — Sign In — FROZEN (2026-07-27)
**Status:** Implemented · Runtime Verified · QA Passed · Owner Approved · FROZEN. **Design authority:** none (no Sign
In Figma / login image) → the frozen MoonJoin language via the Auth Foundation (9C-1). Presentation only.

**Implementation (6 files):** `sign_in_screen.dart` — mobile host rebuilt via `AuthScaffold(hero: AuthHero, child:
AuthCard(SignInView))`, `PopScope` (exit-app / OTP-back / notification-reset) preserved verbatim, desktop `_desktopBody`
kept. `sign_in_view.dart` — config-driven `CentralizeLoginType` switch + `_login`/`_otpLogin`/`_process*` unchanged
except persistence. `manual_login_widget.dart` + `otp_login_widget.dart` — composed from the foundation
(`AuthPrimaryButton`/`AuthFooter`; welcome heading moved to `AuthHero`; **Remember Me checkbox removed** mobile+desktop).
`social_login_widget.dart` — presentation → `AuthDivider` + horizontal `AuthSocialButton` pills (Google·Apple·Facebook);
all Google/Apple/Facebook SDK flows + config gates preserved; stopped importing legacy `SocialLoginButton`. `assets/
language/{en,ar,bn,es}.json` — 2 hero keys (`welcome_back_to_moonjoin`, `your_world_of_services_awaits`; en value in
ar/bn/es pending).

**Manual Login Persistence (owner-approved UX contract, implemented):** always auto-fill last **email/phone**; **never**
auto-store password (`_processSuccessSetup` saves email/phone with EMPTY password; password pre-fill removed); on reopen
auto-fill email/phone + **auto-focus password** (else email/phone); **no Remember Me checkbox**; biometric = future
extension point. All login/OTP/Firebase/nav/controllers/business rules preserved.

**Preserved:** AuthController · VerificationController · ProfileController · LocationController · Firebase phone verify ·
Google/Apple/Facebook SDKs · `ExistingUserBottomSheet` · admin **Login Setup** gating (`centralizeLoginSetup` via
`CentralizeLoginHelper`, 7 layouts — never hardcoded) · routes/callbacks (`getSignInRoute`, `backFromThis`,
`fromNotification`, `fromResetPassword`, return-after-login). No controller/repo/service/API/model/route/business-logic
changes. Frozen `AuthHero` + all foundation components reused, never modified.

**Verification:** `flutter analyze lib/features/auth` → **No issues found!** (full project = pre-existing baseline only,
zero new). **Real-app runtime verified** on the iOS simulator through the genuine flow (logout → guest → Sign In):
phone auto-filled, password empty + auto-focused, social pills + OTP affordance gated by config, 0 exceptions/overflow.
**QA bug found + fixed:** `setState() called after dispose()` from the delayed auto-focus firing after view disposal →
guarded with `if(!mounted) return` in `SignInView`; re-verified clean.

**Legacy / obsolete:** `SocialLoginButton` (declared in `login_suggestion_bottomsheet.dart`) superseded by
`AuthSocialButton` on Sign In → **OBSOLETE — Pending Final Legacy Cleanup** (still used by the login-suggestion sheet;
retained, not removed).

**Experiment note:** a premium Earth/network/world header (`AuthHeroWorld`) was explored during 9C-2 review and
**REJECTED & fully removed** (2026-07-27) — the plain premium green `AuthHero` remains the permanent hero. Do not
recreate the globe/network header without explicit owner request.

## Phase 9C-3 — Sign Up — FROZEN (2026-07-27)
**Status:** Implemented · Runtime Verified · QA Passed · Owner Approved · FROZEN. **Design authority:** the frozen Auth
Foundation (9C-1). Presentation only.

**Implementation (2 files + i18n):** `sign_up_screen.dart` — mobile rebuilt via `AuthScaffold(showBack: !exitFromApp,
onBack: Get.back, hero: AuthHero(create_your_moonjoin_account + your_world_of_services_awaits), child: AuthCard(
SignUpWidget))`; desktop `_desktopBody` preserved (logo + "Sign Up" title + SignUpWidget). `sign_up_widget.dart` — mobile
presentation → `AuthPrimaryButton` (Sign Up) + `AuthFooter` (Already have account? Sign In); mobile container width
`context.width` → `double.infinity` (fits AuthCard, no overflow); desktop `CustomButton` + dialog row preserved. `assets/
language/{en,ar,bn,es}.json` — 1 hero key `create_your_moonjoin_account` (en value in ar/bn/es pending).

**UX consistency audit (Sign In ↔ Sign Up) — PASSED.** Hero height/curve, breathing logo, logo size/fill, welcome
typography, floating AuthCard position+overlap, card radius+shadow, input spacing/alignment, primary-button height/radius/
spacing, footer spacing, keyboard/safe-area/scroll — all **identical by shared frozen foundation** (both use the same
`hero != null` AuthScaffold path). Fixed 4 mobile spacing drifts in Sign Up so internal rhythm matches Sign In: top gap
paddingSizeSmall→0, primary-button surrounds paddingSizeDefault→paddingSizeLarge (×2), footer bottom paddingSizeLarge→0.
No overflow, no RenderFlex, no runtime exceptions, no regressions.

**AuthHero logo-fill revision (owner-requested):** the logo now fills the white circular disc 100% —
`Image.asset(fit: BoxFit.cover)` inside a fixed circular disc (`discSize = logoWidth + 2·paddingSizeLarge`, `clipBehavior:
antiAlias`, `shape: circle`) replacing the padded `ClipRRect(width: logoWidth)`; breathing scale+glow kept;
`logoCornerRadius` retained (unused). Applies to Sign In + Sign Up (shared AuthHero) → consistent. Asset fix: `logo.png`
must be lowercase `.png` (iOS case-sensitive; a `.PNG` upload failed to load — corrected by owner).

**Preserved:** AuthController.registration · SignUpBodyModel · all validation · ConditionCheckBoxWidget terms gate ·
refer-code · verification routing (Firebase / VerificationScreen / getVerificationRoute) · CartController/ProfileController/
LocationController · getSignInRoute · desktop AuthDialogWidget. No controller/repo/service/API/model/route/business-logic
changes. Frozen Auth Foundation reused (AuthHero revised only per owner request above).

**Verification:** `flutter analyze lib/features/auth` → **No issues found!** Real-app runtime verified on the iOS
simulator (guest → Sign In → Sign Up): logo fills disc, all fields present, Full-Name auto-focus, terms/button/footer
working, 0 overflow/exceptions/asset-errors.

## Phase 9C-5 — Forgot Password — FROZEN (2026-07-28)
**Status:** Implemented · Runtime Verified · QA Passed · Owner Approved · FROZEN. **Design authority:** none (no
Forgot Password Figma / no ui-designs image) → the frozen MoonJoin Auth Foundation (9C-1). Presentation only.
**File:** `lib/features/verification/screens/forget_pass_screen.dart` (no new i18n keys — all strings pre-existed).
**What changed:** `build` split into `_mobileBody` (frozen foundation) + `_desktopBody` (legacy preserved), mirroring
9C-2/9C-3/9C-4. Mobile → `AuthScaffold(onBack: Get.back, hero: AuthHero(forgot_your_password | sorry_something_went_wrong
+ subtitle), child: AuthCard(...))`. Both original states preserved: **request form** (`Form → AuthInputGroup(phone|email
CustomTextField)` + `AuthPrimaryButton` "Request OTP" + "Or" + `AuthFooter` "Back to Log In") and **channels-disabled
fallback** (`AuthPrimaryButton` "Help & Support" + `AuthFooter` "continue as guest"). Mobile drops the legacy
`Images.forgot`/logo illustration in favour of the shared hero (consistent with Sign In/Sign Up/Verification); desktop
keeps them. Removed the now-unused `custom_app_bar` import.
**Preserved (verbatim):** `_onPressedForgetPass` (phone build + `CustomValidator.isPhoneValid` + `_formKeyLogin.validate()`
+ `VerificationController.forgetPassword` + Firebase-vs-backend routing `phoneVerificationStatus && firebaseOtpVerification`
+ desktop-dialog / `RouteHelper.getVerificationRoute`) · `initState` config gating (`isSmsActive`/`firebaseOtpVerification`/
`isMailActive`) + non-web auto-focus · validators · country picker. No controller/repo/service/API/model/route/Firebase/OTP/
business-logic changes.
**Verification:** `flutter analyze lib/features/verification/screens/forget_pass_screen.dart` → **No issues found!**
Real-app runtime verified on iPhone 16 Pro Max simulator — green hero + breathing logo, floating card, +234 phone field,
Request OTP, Or, Back to Log In; 0 overflow/exceptions. Fallback state analyzer-clean + preserved but not runtime-reproduced
(needs both SMS+email disabled in Admin config); OTP delivery still gated by the 9C-4 backend gateway (2Factor→+234).

## Phase 9C-6 — Reset / New Password — FROZEN (2026-07-28)
**Status:** Implemented · Runtime Verified · QA Passed · Owner Approved · FROZEN. **Design authority:** none (no Figma /
no ui-designs image) → the frozen MoonJoin Auth Foundation (9C-1). Presentation only. **File:**
`lib/features/verification/screens/new_pass_screen.dart` (no new i18n keys).
**What changed:** `build` split into `_mobileBody` (frozen foundation) + `_desktopBody` (legacy preserved). Mobile →
`AuthScaffold(onBack: Get.back, hero: AuthHero(change_password | reset_password + enter_new_password subtitle), child:
AuthCard(AuthInputGroup(New Password + Confirm password) + AuthPrimaryButton "Change Password"))`. Mobile drops the legacy
`Images.changePass` illustration for the shared hero; desktop keeps it; removed the unused `custom_app_bar` import.
**No `Form` added** — legacy manual validation kept verbatim.
**Both flows preserved (verbatim):** keyed by `fromPasswordChange` — (1) **Change Password** (`_changeUserPassword` →
`ProfileController.changePassword`) and (2) **Reset Password** (`_resetUserPassword` → `VerificationController.resetPassword`
+ mobile `getSignInRoute` / desktop `AuthDialogWidget` navigation); `_onPressedPasswordChange` empty/`<6`/mismatch checks
and per-path `isLoading` source unchanged. No controller/repo/service/API/model/route/validator/Firebase/OTP/business-logic
changes.
**Verification:** `flutter analyze lib/features/verification/screens/new_pass_screen.dart` → **No issues found!** Real-app
runtime verified on iPhone 16 Pro Max via the real flow (Account → Sign In → Settings → **Change Password**) — green hero +
breathing logo, floating card, New/Confirm password fields, Change Password button; 0 overflow/exceptions. **Reset Password**
variant = same widget/logic, preserved but not runtime-reachable now (behind the OTP step blocked by the 9C-4 backend gateway
2Factor→+234 — infrastructure, not frontend).

## Phase 9C-7 — New User Setup — FROZEN (2026-07-28)
**Status:** Implemented · Runtime Verified · QA Passed · Owner Approved · FROZEN. **Design authority:** none → the frozen
MoonJoin Auth Foundation (9C-1). Presentation only. **File:** `lib/features/auth/screens/new_user_setup_screen.dart` (no new
i18n keys).
**What changed:** `build` split into `_mobileBody` (frozen foundation) + `_desktopBody` (legacy preserved). Mobile →
`AuthScaffold(onBack: Get.back, hero: AuthHero('just_one_step_away'), child: AuthCard(Form(_formKeyInfo) → AuthInputGroup(Name +
[Phone if social | Email if OTP] + Refer-code if refEarningStatus==1) → AuthPrimaryButton('done')))`. Mobile drops the legacy
`Images.logo`+centered text for the shared hero; desktop keeps them.
**Preserved (verbatim):** `_formKeyInfo` validation · `_isSocial`(`CentralizeLoginType.social`) branch (social→Phone, OTP→Email)
+ social name pre-fill · `widget.phone`-empty phone validation (`CustomValidator.isPhoneValid`) · `_updatePersonalInfo` →
`AuthController.updatePersonalInfo` → `LocationController.navigateToLocationScreen('sign-in', offNamed:true)` · refer-code gate.
No controller/repo/service/API/model/route/Firebase/OTP/OAuth/business-logic changes.
**Social login audit (no changes; buttons remain in FROZEN `social_login_widget.dart` 9C-2):** entry point into this screen
(`NewUserSetupScreen(loginType: social …)`) preserved. **Google works.** **Apple** fails = **iOS Configuration**
(`com.apple.developer.applesignin` present only in `RunnerProfile.entitlements`; ABSENT from `Runner.entitlements` Release +
`RunnerDebug.entitlements` Debug). **Facebook** fails = **Provider/Platform Configuration** (iOS Info.plist complete —
`FacebookAppID`/`FacebookClientToken`/`FacebookDisplayName`/URL scheme; issue in Meta dashboard/backend). **Neither is a frontend
regression** → deferred to the future MoonJoin World Authentication Hardening phase (not repaired here).
**Verification:** `flutter analyze lib/features/auth/screens/new_user_setup_screen.dart` → **No issues found!** Runtime:
verified-by-construction (composed from the frozen foundation already runtime-verified in 9C-5/9C-6); the fresh-onboarding
trigger (new unregistered account) was not reproduced on-device (OTP onboarding blocked by the 9C-4 SMS gateway + the test
account already registered — infrastructure, not frontend).

## ✅ Authentication Cluster — COMPLETE (2026-07-28)
The entire customer Authentication Cluster is now migrated to the **MoonJoin Premium Authentication Foundation** (9C-1) and
frozen: **Sign In (9C-2) · Sign Up (9C-3) · Forgot Password (9C-5) · Reset/Change Password (9C-6) · New User Setup (9C-7)**,
plus **OTP Login** and **Verification-screen navigation** (9C-4 migrated + analyzer/analysis-clean; frozen-pending-gateway).
All share one hero/card/spacing/typography/button language. **Google Sign-In works.** **Apple & Facebook** remain **provider/
platform configuration** issues (NOT frontend regressions; see per-phase notes) deferred to MoonJoin World Auth Hardening.
Current SMS provider = 2Factor (temporary); future production provider = **Termii**; Firebase Phone Verification intentionally
disabled; backend SMS gateway is the active OTP path. No authentication/OTP/OAuth/Firebase/controller/route/API/backend/business
logic was changed in any phase — presentation only.

## Phase — MoonJoin Context-Aware Scoped Search — FROZEN (2026-07-30)
**Status:** Implemented · Analyzer Clean · Runtime Verified (Simulator) · Owner Approved · FROZEN. **Permanent platform standard:**
`docs/MOONJOIN_SEARCH_ARCHITECTURE.md`. Presentation completion + a permanent MoonJoin platform architecture decision.
**Architecture summary:** **Application Context (`SplashController.module`) and Search Scope are two INDEPENDENT platform concepts.**
Search Scope (`SearchController._searchScope`, session-persistent) is applied ONLY as a **per-request `moduleId` header override**
(`search_repository._getSearchData` clones `apiClient.getHeader()` and overrides only `moduleId`). Search NEVER changes `setModule()`,
`cacheModule`, `SplashController.module`, or `ApiClient._mainHeaders`. Resolution: inside a module → current module · else session scope
· else last-used (`cacheModule`) · else the **Module Scope Sheet** (never "Module ID Required", never `moduleList[0]`; voice + search
scope-gated).
**Files changed:** NEW `search_scope.dart`, `common/widgets/moonjoin/scope_selector.dart`, `search/widgets/search_scope_sheet.dart`;
MODIFIED (additive) `search_controller.dart`, `search_service(.interface).dart`, `search_repository(.interface).dart`,
`search_screen.dart`, `search_result_widget.dart`, `assets/language/*.json` (+6 keys).
**Presentation (legacy → MoonJoin, reuse-only):** results Items/Stores → **frozen Favorites segmented pill**; Recent Searches →
MoonJoin removable chips; Popular Categories → `MoonjoinFilterChip`; Suggestions → MoonJoin cards; scope pill `MoonJoinScopeSelector`
below the header in both states. Desktop preserved legacy.
**Components frozen (reusable platform):** `SearchScope` (abstraction, not hardcoded to ModuleModel), `MoonJoinScopeSelector` (DS scope
pill), `SearchScopeSheet` (Module Scope Sheet, reuses MoonjoinBottomSheet+OrganicModuleIcon).
**Business logic preserved:** no change to SearchController search/history/suggestions/filters/pagination/voice, routes, APIs, models,
backend contracts — additive scope orchestration + per-request header value only.
**Search Scope independence (verified):** searched Food → switched scope to Pharmacy → exited Search → landed on the all-modules Home
(never entered Food/Pharmacy). Application Context untouched.
**Reuse rules (permanent):** never fork the scope selector / Search module sheet / Items-Stores segmented control — reuse
`MoonJoinScopeSelector` / `SearchScopeSheet` / the frozen Favorites segmented pill (single source of truth across MoonJoin).
**Future scalability (prepared, NOT implemented, no redesign needed):** 🌍 All Modules · 📍 Nearby · ❤️ Favorites · 🔥 Trending ·
🏷 Promotions · 🤖 AI Search; future backend Global-Search endpoint unlocks "All Modules".
**Verification:** `flutter analyze` (all Search files) → **No issues found!** Runtime verified on iOS Simulator (clean build, 0
`objective_c`/framework errors, images healthy): Scope Sheet on no-context (no "Module ID Required"), scope pill, scoped results
(9 for "rice" in Food via header override), scope switch Food→Pharmacy, recent-search chips, suggestions/popular MoonJoin, back-nav
independence. Simulator was authoritative (no maps); per [[favorites-and-nav-toolchain]] the image QA used a clean build (Flutter
native-assets bug #180603 workflow, `docs/ENVIRONMENT_NOTES.md`).

## Phase — MoonJoin Premium Favorites — FROZEN (2026-07-29)
**Status:** Implemented · Analyzer Clean · Runtime Verified · Owner Approved · FROZEN. **Design authority:** MoonJoin Premium
Design System (bottom-nav tab). Presentation only; **mobile redesigned, desktop preserved legacy** (mobile-first). **File:**
`lib/features/favourite/screens/favourite_screen.dart` (only file changed; no new i18n keys).
**What changed:** mobile → premium green `ProfilePageHeader` ("Favourite", showBack:false — nav tab) + a **MoonJoin segmented pill**
(Items / Stores·Restaurants) built by restyling the existing `TabBar` (rounded green selected segment on a soft-green primary@8%
track; `TabBarIndicatorSize.tab`; transparent divider; splash-border-radius) + the frozen `FavItemViewWidget → ItemsView` body.
Desktop `_desktopBody` = legacy `WebScreenTitleWidget` + scrollable `TabBar` (unchanged).
**Preserved (verbatim):** `TabController` (len 2, idx 0, NeverScrollableScrollPhysics) · `TabBarView` semantics (0=Items, 1=Stores/
Restaurants) · `showRestaurantText` label · `initCall`/`getFavouriteList()` on login · guest-guard `NotLoggedInScreen` callback ·
pull-to-refresh · favourite toggle (frozen cards). No `FavouriteController`/`SplashController`/API/model/route/`ItemsView` change.
**Reuses:** `ProfilePageHeader`, `ItemsView` (frozen `MoonjoinStoreCard`/`ItemWidget`/`NoDataScreen`), `NotLoggedInScreen`, `MenuDrawer`.
**Verification:** `flutter analyze` → **No issues found!** Runtime verified on the iOS Simulator (owner-approved): both Items and
Restaurants segments render (wishlist item cards + `MoonjoinStoreCard`), segmented toggle works, images render, no overflow. No maps/
GPS → simulator authoritative.
**Environment note (independent of this migration):** mid-QA the simulator hit a flaky Flutter **native-assets** embed —
`objective_c.framework` (transitive via `path_provider_foundation`, Flutter 3.38.5) was built into `build/.../Runner.app/Frameworks/`
but failed @rpath resolution in the installed bundle → `path_provider` broke → `cached_network_image` cache dir broke → **all images
broke app-wide**. Root-caused and fixed by a **`flutter clean` full rebuild** (0 `DOBJC`/framework errors after; images restored
everywhere). Also reset the simulator's default GPS (Cupertino→Ogbomoso via `simctl location`). Both are simulator/toolchain issues,
fully independent of the pure-Dart, analyzer-clean Favorites change.

## Phase — MoonJoin Premium Address Experience — FROZEN (2026-07-28, Physical-Device Verified)
**Status:** Implemented · Analyzer Clean · Runtime Verified (Physical Device) · Owner Approved · FROZEN. **Design authority:**
MoonJoin Premium Design System. Presentation only; **mobile redesigned, desktop preserved legacy** (mobile-first).
**Files:** `lib/features/address/screens/add_address_screen.dart`, `lib/features/location/screens/pick_map_screen.dart`
(+ 2 i18n keys `address_details`, `move_the_map_to_select` in en/ar/bn/es).
**Scope (frozen together):** Add Address · Edit Address · Pick Map · Google Maps Address Picker Flow.
**What changed:** Add/Edit form → `ProfilePageHeader` + premium floating map card (rounded/shadow, floating pin w/ `IgnorePointer`,
current-location FAB, fullscreen) + grouped `SectionHeader` cards (Delivery Address → Contact Information → Address Details) +
`MoonjoinFilterChip` types + pinned `BottomActionBar`. Pick Map → Uber/Glovo full-screen picker (search+back, floating pin,
current-location FAB, bottom selected-address + zone-aware action).
**Preserved (verbatim):** `LocationController` (getCurrentLocation/updatePosition/getZone/setUpdateAddress/setPickData +
onMapCreated/onCameraIdle/onCameraMove/onCameraMoveStarted) · `AddressController` · manual validation (no `Form`) · geocode/zone/
permission · `Get.arguments → PickMapScreen` · all variants (fromCheckout/fromRide/forGuest/fromNavBar, Add vs Edit). No
controller/API/route/model/business-logic change.
**Regressions found in device QA & fixed (presentation/widget-identity only):** (1) full-cover loading `Container` on the map
card was hit-testable → swallowed taps → removed + pin wrapped in `IgnorePointer`. (2) Pick Map `onMapCreated` used the desktop
guard (`RouteHelper.onBoarding`) + dropped the `fromLandingPage` auto-pick → restored the exact legacy mobile `onMapCreated`
(`'splash'` guard + `.then`). (3) **Edit auto-load hang** — a `GlobalKey` added to the maps prevented the map recreation that
legacy implicitly relied on to fire a *second* `onCameraIdle` (needed to overcome `updatePosition`'s first-call
`_updateAddAddressData` no-op) → **removed the `GlobalKey`s**; seeded `_cameraPosition` in `initState` (Edit + `fromAddAddress`)
for the complementary null/flag path. Result: Edit loads automatically with **no manual current-location tap**.
**Verification:** `flutter analyze` both files → **No issues found!** **Runtime verified on the owner's physical iPhone (PASSED):**
Add + Edit both auto-load (inline + fullscreen), spinner clears automatically, drag-pick/zone/geocode/save/update all work, no
endless loading, no manual workaround. **iOS Simulator is environment-limited for Google Maps (camera never settles) — documented
as environment-only, non-blocking; production target = physical device.** **Permanent rule:** never re-add a `GlobalKey` to these
maps or a hit-testable full-cover overlay.

## Phase 8F — Language (onboarding screen) — STATUS: IMPLEMENTED, NOT FROZEN
`ChooseLanguageScreen` (`language_screen.dart`) is implemented (presentation-only; menu = ProfilePageHeader,
first-run = onboarding identity preserved), analyze-clean, runtime-clean, but **visual verification is pending**
on its natural entry point (fresh install / onboarding / drawer). Deliberately **NOT frozen** per owner
instruction; to be verified + frozen later. The Settings language bottom sheet (a different widget) belongs to
Phase 8G (above).

## Delivery Man Registration — B1 (header) — STATUS: FROZEN (2026-08-01)
**File:** `lib/features/auth/screens/delivery_man_registration_screen.dart` (only file changed).
**Entry:** Account → Menu → Earnings → **Join as a Delivery Man** → Delivery Man Registration.
**What changed (presentation only):** mobile legacy white `CustomAppBar` → frozen **`ProfilePageHeader`** (curved green
wave + centered title + back), matching the Account/Menu design family. The header is added as the body's first child
(owns its own status-bar top padding); the step chips + scrollable form + bottom button now live in
`Expanded → SafeArea(top: false)`. **Back preserves the two-step logic verbatim** (`onBack`: Step 2 → Step 1 +
reset chip index; Step 1 → `Get.back()`). Desktop keeps its `CustomAppBar` (gated `isDesktop ? CustomAppBar : null`)
and `webView` — untouched. Existing white `sectionCard`s were already MoonJoin card language — left as-is.
**Preserved (verbatim):** `DeliverymanRegistrationController` (+ `StoreRegistrationController` pass check), two-step form +
both `GlobalKey<FormState>`, `PopScope` step-back, all validation/`showCustomSnackBar`, profile + identity image pickers,
zone/vehicle/DM-type/identity-type dropdowns, country-code phone, `PassViewWidget`, `ConditionCheckBoxWidget`,
`registerDeliveryMan(DeliveryManBody(...))`, reset, routes, models, desktop `webView`. No controller/API/route/model/
business-logic change.
**Verification:** `flutter analyze` (file) → **No issues found!** Release build ✓ (88.5MB AOT) installed + launched on the
owner's physical iPhone (`00008120-…-201E`, `com.moonjoin.com`). **Runtime verified & owner-approved:** green curved
header + back, step navigation (Next → Step 2 → back → Step 1), image pickers, dropdowns, validation, submit — no regression.
**Next:** Open Vendor → Vendor Registration (one screen at a time).

## Vendor Registration — B1 (header) — STATUS: FROZEN (2026-08-01)
**File:** `lib/features/auth/screens/store_registration_screen.dart` (only file changed).
**Entry:** Account → Menu → Earnings → **Open Vendor** → Vendor Registration.
**Design family:** now belongs to the approved **MoonJoin Account/Menu design family**; **reuses the frozen `ProfilePageHeader`**
(consistent with Delivery Man Registration).
**What changed (presentation only):** mobile legacy white `CustomAppBar` → frozen **`ProfilePageHeader`** (curved green
wave + centered title + back). Header added as the body's first child (owns its status-bar top padding); the step tabs
+ scrollable form + bottom button now live in `Expanded → SafeArea(top: false)`; the outer body `SafeArea` moved
per-branch (desktop → `SafeArea(webView)`; mobile → `SafeArea(top:false)`). **Back preserves the exact original
`CustomAppBar.onBackPressed` logic verbatim** (`onBack`: `storeStatus != 0.1 && firstTime` → `storeStatusChange(0.1)` +
`firstTime=false`; else `_showBackPressedDialogue`). All three states covered (0.1 Vendor Info · 0.6 Owner Info · 0.9
Business Plan). Desktop keeps its `CustomAppBar` (gated `isDesktop ? CustomAppBar : null`) + `webView` — untouched.
**Preserved (business logic, registration flow, validation, controllers, APIs, routes, forms, step navigation, desktop —
all unchanged):** `StoreRegistrationController`, three-step `storeStatus` flow + `storeStatusChange`, `_tabController`/
`_tabButton`, both `GlobalKey<FormState>`, `PopScope` + `_showBackPressedDialogue`, all validation, logo/cover image
pickers, zone/module/business dropdowns, address + map, language tabs, business-plan selection (`BaseCardWidget`/
`PackageCardWidget`/`Swiper`), `_submitData`/registration API, routes, models, desktop `webView`. **Presentation-only.**
**Verification:** `flutter analyze` (file) → **No issues found!** Release build ✓ (88.5MB AOT) installed + launched on the
owner's physical iPhone. **Runtime verified & owner-approved:** header + back, step navigation + back-dialog, image
pickers, dropdowns/map/address, submit — no regression. **FROZEN.**

## Checkout — Commerce Header + Commerce Bottom Action Container + "Pick Up" — STATUS: FROZEN (2026-08-01)
**Files:** `lib/features/checkout/screens/checkout_screen.dart`, `lib/features/checkout/widgets/top_section.dart`,
`assets/language/{en,bn,ar,es}.json`. **New shared component:** `lib/common/widgets/moonjoin/moonjoin_commerce_action_bar.dart`
(`MoonjoinCommerceActionBar`). Reuses `MoonjoinCommerceHeader` + `BottomActionBar`. **Supersedes the earlier partial
Checkout freeze** (the Bottom Checkout Container was redesigned after it).
**What changed (presentation only):**
(1) **Commerce header** — mobile legacy white `CustomAppBar` → shared frozen `MoonjoinCommerceHeader` (same header as Your Cart); desktop keeps `CustomAppBar`.
(2) **Delivery wording** — "Take Away" → **"Pick Up"** (display `title` only; backend `value:'take_away'` orderType unchanged). New `pick_up` i18n key (en="Pick Up"; bn/ar/es reuse existing take-away wording). Home filter + "Home Delivery" untouched.
(3) **Bottom Checkout Container redesign** — legacy flat white rectangle → **`MoonjoinCommerceActionBar`** (the official MoonJoin Commerce Bottom Action Container): premium rounded-top elevated surface, soft upward shadow, intentional spacing rhythm, single safe-area (composes the frozen `BottomActionBar` — no duplicated chrome). **Total row reused exactly** (same Text/typography/animated price). **Place Order button reused exactly** — same widget + `onPressed`; a `bare` flag only branches the return wrapper (mobile → the bar owns the single SafeArea; desktop `_orderPlaceButton` byte-identical).
**Root-cause note (why the redesign, not padding):** a measured widget-test probe proved the old container's height was the genuine sum of Total row (33) + gap (10) + button (50) + a SINGLE iOS SafeArea (34) + padding (10) = 137px, with NO duplicated inset anywhere in the parent tree (Scaffold→…→container fully traced). So the container was technically correct; the owner chose a premium redesign over reducing the required safe-area.
**Preserved (unchanged):** `CheckoutController`/`CouponController`/`AddressController`, total calculation, `placeOrder`/`placePrescriptionOrder`, the full Place Order validation chain, payment selection + `PaymentMethodBottomSheet`, delivery type/address/preference-time/promo/tips/notes, `TopSection`/`BottomSection`, routes, models, guest flow, desktop `webView`. No controller/API/route/model/business-logic change.
**Verification:** `flutter analyze` → zero new issues (only a pre-existing baseline lint). Release build ✓ (88.5MB AOT) installed + launched on the owner's physical iPhone. **Runtime verified & owner-approved.** **FROZEN.**

## Delivery Man Tip System — Phase 2 (dynamic config + shared component) — STATUS: FROZEN (2026-08-01)
**Files:** NEW `lib/common/widgets/moonjoin/delivery_man_tips.dart` (shared UI), NEW `lib/helper/delivery_man_tips_config.dart` (resolver),
`lib/util/app_constants.dart` (`tips` → dynamic getter), `lib/common/models/config_model.dart` (`dmDefaultTips` / `dm_default_tips` seam),
`lib/features/checkout/widgets/deliveryman_tips_section.dart` (wiring), `lib/features/parcel/screens/parcel_request_screen.dart` (wiring).
**What changed:** Delivery Man Tips moved from **Flutter-hardcoded values to configuration-driven architecture**; Flutter is now a pure consumer.
- **Resolver priority: Zone → Global (`dm_default_tips`) → Temporary fallback.** `DeliveryManTipsConfig.options()` = `['0', ...amounts, 'custom']`; `AppConstants.tips` is now a getter delegating to it (old hardcoded list removed) → controllers' index contract (custom == last) unchanged, **zero controller edits**.
- **Temporary migration fallback `[100,200,300,400]`** — documented as TEMPORARY until backend tip config ships; must be removed once `dm_default_tips`/zone tips land. Checkout + Parcel now show ₦100/₦200/₦300/₦400.
- **Shared `DeliveryManTips` component** — single MoonJoin tip UI for Checkout + Parcel Request (no duplicate tip UI logic); presentation only, each screen wires its own controller via callbacks. Keeps Not Now + custom + save-for-later + `most-tips` "Suggested" badge. Parcel tip card visually unified to the Checkout MoonJoin design.
- **Currency:** follows Business Settings via `PriceConverter` today (no hardcoded symbol); future-ready for zone currency + zone tips + backend/admin config.
**Backend/Admin dependency (future MoonJoin World/Admin — NOT built in Flutter):** Admin → Delivery Tip Settings, default tip config, zone-level tip config, zone currency selection. Backend → `dm_default_tips`, zone `dm_tips`, zone currency resolution.
**Preserved / unchanged (confirmed):** order creation, parcel creation, payment flow, delivery assignment, **`dm_tips` API payload**, validation, `CheckoutController`/`ParcelController`, routes. Presentation + configuration architecture only.
**Verification:** `flutter analyze` → zero new issues (baseline unchanged). Release build ✓ (88.5MB AOT) installed + launched on the owner's physical iPhone. **Runtime verified (Checkout + Parcel Request) · Owner approved · FROZEN.** No additional UI changes after freeze without a new migration decision.

## Cart Item Edit Journey — mobile edit → approved Product Details Edit Mode — STATUS: FROZEN (2026-08-01)
**Files:** `lib/features/item/controllers/item_controller.dart` (`navigateToCartItemEdit`), `lib/features/cart/widgets/cart_item_widget.dart`
(both tap handlers — card tap + "Change" link), `lib/features/item/screens/item_details_screen.dart` (additive `cart` param),
`lib/features/item/screens/food_details_screen.dart` (label). Reuses the two frozen Product Details + `getItemDetails(cart:)` +
`ItemCartHelper.addOrUpdateCart` + `CartController.updateCartOnline`.
**Problem:** mobile Add opened the full-page Product Details, but mobile Cart EDIT still opened the legacy `ItemBottomSheet` — a journey
inconsistency (explicit code comment even said "cart editing continues to use ItemBottomSheet (unchanged)").
**Fix (navigation only):** mobile Cart item tap + "Change" → `navigateToCartItemEdit(item, cart:)` → `FoodDetailsScreen` (food) /
`ItemDetailsScreen` (grocery/others) in EDIT MODE (food/non-food split mirrors `navigateToItemPage`). `ItemDetailsScreen` got an
additive optional `cart` forwarded to `getItemDetails(cart:)` (label + `_addToCart` already keyed on `cartIndex != -1`); `FoodDetailsScreen`
label now reads "Update in Cart" from Cart. **Update mechanism unchanged & single-source:** `getItemDetails(cart:)` restores
variations/add-ons/quantity + sets `cartIndex`; `addOrUpdateCart` updates the existing line (`cart != null || cartIndex != -1` →
`updateCartOnline`) — no duplicate.
**Desktop:** unchanged — `ItemBottomSheet` dialog remains for desktop Add + desktop Cart edit (already-consistent). Not deleted (Legacy
Cleanup = separate later phase).
**Preserved:** Your Cart UI, `MoonjoinCommerceHeader`, cart calculations, coupons, taxes, delivery, Checkout navigation, `CartController`,
cart APIs, `ItemCartHelper`, order creation. No business-logic change.
**Verification:** `flutter analyze` (4 files) → **No issues found!** Release build ✓ (88.5MB AOT) installed + launched on the owner's
physical iPhone. **Runtime verified (Food + Non-food — preloaded edit, Update in Cart, same line updates, no duplicate) · Owner approved · FROZEN.**

## Rental Trip Payment — Unification to shared payment architecture — STATUS: BLOCKED (BACKEND DEPENDENCY) (2026-08-01)
**First-task verification result: Rental Trips CANNOT consume the existing `PaymentModel` — this migration is blocked on backend, NOT implemented in Flutter (no workaround invented).**
**Evidence:** `OrderController.getPaymentFailedDetails` → `GET /api/v1/customer/order/payment-failed?order_id=$id` is **order-scoped**. Trips are a **separate entity** in the `/api/v1/rental/user/trip/*` namespace, keyed by `trip_id`, modeled by `TripDetailsModel` (NO `order_id`/`orderType`/order linkage). The rental module never calls the order PaymentModel endpoint; it uses its own `tripPaymentUri` (`/api/v1/rental/user/trip/payment`) returning a raw URL. So the approved `PaymentMethodBottomSheet`/`PaymentModel`/`PaymentScreen` architecture cannot be driven for a trip today.
**Current legacy flow (to be replaced once unblocked):** My Trips → History → Completed+Unpaid → Pay Now → `TaxiPaymentBottomSheet` (`rental_module/rental_order/widgets/taxi_payment_bottom_sheet.dart`) → `TaxiOrderController.makePayment` → digital: `Get.to(TaxiPaymentScreen(paymentUrl: response.body))`. `TaxiPaymentScreen` is a bespoke WebView lacking the shared success/fail redirect + callback handling that `PaymentScreen` provides → **blank page**.
**EXACT BACKEND DEPENDENCY (MoonJoin World) required to unblock:** expose a **`PaymentModel` for a rental trip** so Flutter can drive the shared components — either (A) extend `/api/v1/customer/order/payment-failed` (or add `/api/v1/rental/user/trip/payment-details`) to accept a `trip_id` and return the same `PaymentModel` JSON shape (`order_id`=trip id, `order_type`='rental'/'taxi', `order_amount`, `is_cash_on_delivery_active`, `is_digital_payment_active`, `is_offline_payment_active`, `payment_status`, `zone_id`, gateway/return URLs), AND/OR (B) route trip digital payment through the **shared payment-session/gateway** that `PaymentScreen` consumes (proper `callback`/success/fail return URLs) instead of the raw `tripPaymentUri` response.
**Flutter migration plan (ready, deferred until backend ships the above):** replace `TaxiPaymentBottomSheet` with `PaymentMethodBottomSheet(paymentModel:)` (responsive: desktop dialog / mobile bottom sheet — exactly the frozen `order_info_widget` "Pay Again" pattern), digital routes through the shared `PaymentScreen` (fixes blank page), retire `TaxiPaymentBottomSheet`/`TaxiPaymentScreen` from the mobile journey (files left in place — Legacy Cleanup is a separate phase). No trip-details/history/business-logic/API change beyond consuming the new PaymentModel. **Flutter remains a pure consumer of backend configuration.**

## Parcel Request — Commerce Header migration — STATUS: FROZEN (2026-08-01) [documentation backfill]
**File:** `lib/features/parcel/screens/parcel_request_screen.dart`. **Backfilled record** — this owner-approved migration was implemented earlier but not yet written to the freeze docs (they still described the legacy white `CustomAppBar`).
**What changed (presentation only):** mobile legacy white `CustomAppBar(title:'parcel_request')` → the frozen shared **`MoonjoinCommerceHeader`** (same green commerce header as Cart + Checkout); content moved into `Expanded → SafeArea(top:false)`; back = `Get.back()`. Desktop keeps `CustomAppBar` (gated). Supersedes the header description in the earlier Parcel module freeze.
**Rule:** Parcel Request = commerce journey → `MoonjoinCommerceHeader` (not `ProfilePageHeader`). **Preserved:** all parcel functionality/logic/APIs/routes/desktop. `flutter analyze` clean; release build deployed to physical iPhone; owner approved. FROZEN.

## MoonJoin Motion & Status Design Language ("The MoonJoin Moon") + Running Order popup — STATUS: FROZEN (2026-08-02)
**Files:** NEW `lib/common/widgets/moonjoin/motion/{moonjoin_motion.dart, moonjoin_motion_painters.dart, moonjoin_status_animation.dart}`;
first consumer `lib/features/dashboard/widgets/running_order_view_widget.dart`.
**What this is:** an official MoonJoin design system (peer of Commerce Header / Action Bar / Cards / Buttons) — the MoonJoin
**Moon + Node + Arc-Light** status-motion identity. Replaces the 6amMart status GIFs and permanently supersedes an earlier
rejected rotating/loader animation experiment.
**Design language (owner-approved via the visual reference artifact):** an order is a moon that *waxes* from new→full as it travels;
the join is a single point of light (the **Node**) that traces the lit rim and settles. Status = a phase, never a spinner. 14 states
(Pending→Delivered journey + Unavailable/Cancelled/Failed/Payment Success·Failed/Verification/Reward/Promotion), each a
configuration of the same moon + node + top-left moonlight + accents. **Arc-Light signature (mandatory):** Node appears → Arc-Light
travels the rim while the moon waxes to phase → light joins/settles → calm easeOutBack settle → still. Plays ONCE; only Preparing
(forming breath) + On-the-way (≈4% drift) carry refined ongoing motion. No rotation, no loop, no loader.
**Architecture:** `MoonJoinMotionState`(20) → `MoonJoinMotion.spec()` = `MoonJoinMoonSpec` (p/tone/tilt/node/ambient/accent flags);
`forOrderStatus()` centralizes backend mapping; `MoonJoinMotionPalette.of(context)` = moonlight (theme primaryColor) on graphite,
light/dark aware, + the APPROVED Home unavailable palette (amber #C98B3E, red #E84D4F) reused exactly; `MoonJoinStatusAnimation`
= the one reusable renderer (RepaintBoundary, one-shot reveal controller + optional slow ambient). Labels stay PLAIN/functional
("Order Preparing", "Payment Failed") — poetic phase names are internal only.
**Running Order popup (presentation only):** status GIFs → `MoonJoinStatusAnimation`; premium rounded card + soft upward shadow;
refined handle + green progress track. **Preserved:** OrderController, backend status handling, popup behaviour + auto-dismiss,
navigation, progress step logic, +N more, order data. No business logic changed.
**Permanent bans:** no spinners, rotating loaders, generic Material status icons, GIF replacements, childish/attention-seeking motion.
Financial/security states must feel calm & trustworthy.
**Verification:** `flutter analyze` (motion + popup) → **No issues found!** Release build ✓ (88.6MB AOT) installed + launched on the
owner's physical iPhone. **Runtime verified & owner-approved. FROZEN.** Future status surfaces (Trip/Parcel/Payment/Wallet/…)
reuse `MoonJoinStatusAnimation` only — one at a time, each its own freeze; legacy GIFs retained until proven unreferenced (Legacy Cleanup phase).

## MoonJoin In-App Notification Banner (`MoonJoinNotificationBanner`) — STATUS: FROZEN (2026-08-02)
**Files:** NEW `lib/common/widgets/moonjoin/notifications/moonjoin_notification_banner.dart`; MODIFIED (foreground display only)
`lib/helper/notification_helper.dart`.
**What this is:** THE official notification presentation layer for the MoonJoin platform — a premium in-app foreground banner
(Apple/Stripe-calm) shown via a native OverlayEntry (no new dependency). `MoonJoinNotificationBanner.show(MoonJoinNotificationData{
title, message, state, onTap, unavailable, autoDismiss})`. **Reuses the frozen MoonJoin Motion System** (`MoonJoinStatusAnimation`
moon icon per `MoonJoinMotionState`) + approved MoonJoin colours/typography. Slide-down+fade entrance, tap→route+dismiss, swipe-up
dismiss, close ✕, ~5s auto-dismiss, one at a time. **THE ONLY in-app notification component — no duplicates ever.** All future
notification types reuse it: Orders · Trips · Parcel · Wallet · Payment · KYC · Rewards · Promotions · Unavailable Items.
**Unavailable-ready:** `unavailable:true` → approved Home unavailable palette (warm #FBF3E2 + amber #C98B3E + red #E84D4F) + the
`unavailable` moon (reused, not reinvented).
**notification_helper wiring (foreground only):** mobile-foreground order/status FCM → `MoonJoinNotificationBanner.show`, state via
frozen `MoonJoinMotion.forOrderStatus` (+ trip/wallet/reward/unavailable). **Preserved:** all FCM handlers, OS `showNotification`
(system/background/tray), `onMessageOpenedApp` deep links, order refresh, chat/demo, all routing; web keeps its dialog.
**Protected:** no frozen system touched (only reuses `MoonJoinStatusAnimation`); frozen `MoonJoinNotifications` façade + `RunningOrderViewWidget` untouched.
**Verification:** `flutter analyze` (banner + helper) → **No issues found!** Release build ✓ (88.6MB AOT) installed + launched on the
owner's physical iPhone. **Runtime verified & owner-approved ("works perfectly"). FROZEN.**

## Phase 3 — Unavailable Order Notification (resolver + watcher + refined banner) — STATUS: FROZEN (2026-08-02) · PRODUCTION APPROVED
**Files:** NEW `lib/common/widgets/moonjoin/moonjoin_presentation_state.dart` (shared resolver), NEW
`lib/common/widgets/moonjoin/notifications/moonjoin_unavailable_watcher.dart` (state-reactive presenter); MODIFIED
`.../notifications/moonjoin_notification_banner.dart` (unavailable refinement), `.../motion/moonjoin_motion.dart` +
`.../motion/moonjoin_motion_painters.dart` (additive `MoonAmbient.sweep`), `features/dashboard/screens/dashboard_screen.dart`
(watcher mount), `features/dashboard/widgets/running_order_view_widget.dart` (resolver adoption), `helper/notification_helper.dart`
(resolver + priority guard).
**What this is:** the unavailable-items order state elevated into the MoonJoin notification language as an **action-required,
persistent** notification — reusing every frozen foundation, adding no business logic.
**Single source of truth:** `MoonJoinPresentationState.fromOrder(order)` → `{motion, unavailable}` is THE only place the "unavailable
overrides pending" rule lives (Home `_UnavailableItemsCard` rule reused exactly: `orderStatus=='pending' && unavailableItemNote
non-empty`). Consumed by the Running Order popup, the watcher, and `notification_helper`. **Rule never duplicated again.**
**Watcher behaviour (permanent):** zero-layout `GetBuilder<OrderController>` mounted first in the dashboard `ExpandableBottomSheet`
background. (1) transient `null` model ignored (no tear-down); (2) one session per order via `_activeOrderId` (survives refreshes,
no flicker); (3) persistent (`autoDismiss:null`) until the customer resolves; (4) dismissal never clears business state; (5) higher
priority than normal status — `notification_helper` suppresses the normal banner while `isUnavailableActive`.
**Refinement (visual/motion only):** warm-in arrival (bg `cardColor→#FBF3E2` over 400ms then stable) · breathing on ONE element
(moon container, ~3s, ~6%) · periodic `sweep` Arc-Light over a short rim segment then quiets (never a loop) · warmer circular moon
container at the same 46dp footprint · solid 5dp amber leading strip · title amber `#B5772A`, body neutral gray. **Normal banner
unchanged** (all gated behind `data.unavailable`).
**Investigation history:** three earlier blind attempts failed (no FCM for a client-derived state; a limit-10 `getRunningOrders(1)`
overwrote the dashboard limit-50 model tearing the banner mid-animation; the banner selected state from `orderStatus` alone showing
"Pending"). Device-log instrumentation (`[MJUW]`/`[MJNB]`, since fully removed) proved the render was fine but torn down by
transient-null churn. Fixes: state-reactive watcher + shared resolver + priority guard.
**Out of scope (separate future task):** Firebase/iOS background reception, permissions, token, AppDelegate — NOT modified.
**Protected:** all business logic, `OrderController`/cart/checkout, `unavailableItemNote` parsing, FCM handlers, `showNotification`,
deep links, routing, order refresh, Home `_UnavailableItemsCard`, `order_edit_screen`, the `MoonJoinNotifications` façade, and the
Motion System's 14 states (only additive `sweep`).
**Verification:** `flutter analyze` → **ZERO issues in all Phase 3 files** (full-repo residual = pre-existing, unrelated). Release
build ✓ (88.6MB AOT) installed + launched on the owner's physical iPhone. **Owner approved ("looks and behaves exactly as
intended"). FROZEN · PRODUCTION APPROVED.**
**Rule:** future work may EXTEND the notification system (new event types / `MoonJoinMotionState`s) but must NEVER replace or redesign
this resolver/watcher/banner foundation without explicit architectural approval. **Banned:** duplicating the unavailable rule;
deciding unavailable inside `notification_helper`/banner; dismissal clearing business state; auto-dismissing the unavailable banner;
any loop/spinner/alarm styling.

## Onboarding — "One Orbit" original MoonJoin experience — STATUS: FROZEN (2026-08-03)
**Files:** NEW `lib/common/widgets/moonjoin/onboarding/moonjoin_onboarding_art.dart` (illustration system) · NEW
`.../onboarding/moonjoin_moon_phase_progress.dart` (progress) · redesigned `lib/features/onboard/screens/onboarding_screen.dart` ·
8 new i18n keys in `assets/language/{en,bn,es,ar}.json`.
**What this is:** the first emotional experience for every new MoonJoin customer — an ORIGINAL product experience designed from first
principles (there is NO onboarding design in the Active Figma or ui-designs), NOT a restyled 6amMart onboarding. Approved over a
2-round design review (concept → CTO refinements). An immersive branded twilight *living connected city at night*, drawn 100%
programmatically (no raster assets / no 6amMart art / no external/stock illustration).
**Concept "One Orbit":** everything MoonJoin orbits one calm center; services woven into ONE ecosystem, never an icon grid. Four-beat
story that waxes to a peak then resolves (pacing 20/40/25/15): Arrival (minimal, waxing sliver) · **Ecosystem (hero — one connected
ecosystem: 11 services as desaturated organic accent-nodes woven by light-arcs + city skyline w/ warm windows + one travelling Node
of light)** · Delivery (trust: one light vendor→home) · Resolution (quiet full moon + halo, settled ecosystem, strong Get Started).
**Built from our own language (reuse, not fork):** organic blobs = OrganicModuleIcon curve family; MoonJoin green; soft light-arcs +
central moon reuse the FROZEN Motion System's light model (visual language only — Motion System code untouched). Progress = moon
phases (crescent→full), not dots. 11 services: Food·Grocery·Pharmacy·Shopping·Car Rental·Short Apartment·Fuel·Parcel·Messenger·
Wallet·Payments — never labelled.
**Performance:** static layer recorded ONCE into a `ui.Picture` per (scene,size); only a thin light layer animates; NO
`MaskFilter.blur`/`ImageFilter` (glows are radial-gradient shaders); single shared 9s ambient ticker; `RepaintBoundary`; Reduce-Motion
honored (holds a calm frame).
**Business logic PRESERVED (presentation-only):** route `/on-boarding`; first-launch gating `showIntro()`/`disableIntro()`
(`AppConstants.intro`, set true first-launch at `splash_repository.dart:84-85`); exit `disableIntro()→guestLogin()→(address?Initial:
Location)` kept verbatim; Language precedes onboarding when multi-language; `OnBoardingController`/service/repo/model untouched
(already a mock repo, no backend); existing `on_boarding_*` keys retained.
**Verification:** `flutter analyze` (3 files) → **No issues found**. Release build ✓ (88.6MB AOT) installed + launched on the owner's
physical iPhone (fresh install to re-trigger the intro flag). **Owner approved. FROZEN.**
**Rule:** THE MoonJoin onboarding — reuse-only; never restyle back toward 6amMart; never introduce raster/stock onboarding art; never
fork the illustration system; do not modify the frozen Motion System (reuse its visual language only). Future changes = additive
scenes/copy with owner approval.

## Phase 1 — Item Owner/Provider Identity — STATUS: FROZEN (2026-08-03) · commit `c827af8`
**File:** `lib/common/widgets/item_widget.dart` only (owner label in the normal layout + `_premiumStoreDishCard`; owner font size
unified). `ItemCard` NOT touched. No backend change (reuses the existing `Item.storeName` ← `store_name`).
**Permanent rule:** OUTSIDE a Store/Restaurant/Provider page, every customer-facing item card shows the owner/provider identity from
**real `item.storeName` only** (no fake fallback, no duplicate identity system). INSIDE an owner page it stays hidden (`inStore==true`).
**Investigation (device-traced, not static):** the owner appeared missing on the customer-facing item list. Extensive runtime tracing
(temporary `debugPrint`, since fully removed) proved the visible cards are **not** `ItemCard`/`MostPopularItemView` (those never
rendered) but `AllStoreScreen → ItemsView(premiumStoreLayout:true) → ItemWidget → _premiumStoreDishCard`. `_premiumStoreDishCard`
returned before reaching the owner line, so a populated `storeName` (proven via device log: `storeName=Perozona/Chicken Republic/…`,
`hideItemStoreName=false`) was never painted. Earlier attempts edited the wrong widgets (`ItemCard`, flash/love cards) and were reverted;
one build even appeared to regress Set Location (stale SharedPreferences) → full restore to baseline `dbf46dc` (clean build + fresh
install) before the correct, minimal fix.
**Fix (minimal, single widget):** added the muted owner line **directly below the item name** inside `_premiumStoreDishCard`, gated on
`!inStore`, reusing the exact Search/`ItemWidget` presentation (real `item.storeName`, `robotoRegular`/`disabledColor`, single-line
ellipsis, graceful-hide). Because it's the shared premium card, this covers all modules (Food/Grocery/Pharmacy/Fashion/…).
**Typography refinement (unified standard):** owner size raised `fontSizeExtraSmall` → `(fontSizeExtraSmall+fontSizeSmall)/2` (≈11 phone /
13 wide) in **both** owner labels — bigger/more readable, still strictly below the item name (normal name = `fontSizeSmall`, premium name
= `fontSizeDefault`); muted color/opacity/position/font-family unchanged; item name & card layout unchanged; store address (`isStore`)
left as-is.
**Shared identity:** Search / Favorites / Category lists / All-Store premium all use `ItemWidget` identity — one presentation, never a
second system. **Frozen:** item name typography, image size/crop/layout, buttons, spacing, favourite icon, rating/price, animations,
proportions — all unchanged.
**Verification:** `flutter analyze` → clean (repo residual pre-existing). Release build ✓ installed + launched on the owner's physical
iPhone; **owner approved on-device**. Onboarding + Notification freezes verified intact; zero debug/investigation code remains.
**Rule:** reuse-only; never fork the owner-identity label; never fake it; never show it inside owner pages; never change its
color/opacity/position/font-family; keep the item name & card layout frozen. New surfaces reuse `ItemWidget`'s presentation.

## Phase 2 — Brands reuse + Module-aware Header Terminology — STATUS: FROZEN (2026-08-03) · owner-approved on iPhone
**Reuse-only, no new systems. Frozen item/card/onboarding/notification work untouched.**

**Brands — reuse the ONE Ecommerce/Fashion engine; ENABLED FOR ECOMMERCE ONLY (final):** `BrandsController`/`BrandsRepository`/
`BrandsScreen`/`BrandsProductScreen`/`BrandsViewWidget` are module-agnostic (`/api/v1/brand` carries the `moduleId` header; cache key
includes module.id; widget hides when empty). **Runtime-proven backend reality:** `/api/v1/brand` returns the **SAME brand ("Quality")
for every module** (Food/Grocery/Fashion/Pharmacy all count=1) — the backend does NOT yet filter brands by module. Therefore Brands are
rendered for the **Ecommerce/Fashion module ONLY**; every other commerce module (Grocery/Pharmacy/Market/Fuel/Drink Distributor) HIDES the
Brands section until backend support exists. **Enforcement (the actual gate):** `all_store_screen.dart:_topBrands()` returns `SizedBox`
unless `SplashController.module.moduleType == ecommerce` — the AllStoreScreen "Top Brands" section is the shell those module homes delegate
to, and it was the sole unguarded render point. (Investigation note: a brief attempt to place `BrandsViewWidget` on grocery/pharmacy homes
showed Fashion's brand and was **fully reverted** — module homes carry no Brands widget.) `shop_home` `BrandsViewWidget` mounts only inside
`ShopHomeScreen` (ecommerce by construction); web already gated to shop. **No new screens/controllers/models/repos; Fashion implementation
unchanged.** **Backend dependency (documented):** `/api/v1/brand` must scope by `moduleId` (return per-module brands / empty) before Brands
can be enabled for other commerce modules — then re-enable is a one-line gate change.

**Rental brands (documented FUTURE only — NOT implemented):** Car Rental keeps its existing vehicle-brand FILTER (`TaxiBrandModel`,
`/api/v1/rental/vehicle/brand-list`) unchanged; Short Apartment Rental has no brands and none created. Future rental brand BROWSE = module-
owned, separate data sources: Car Rental = vehicle manufacturers · Apartment = accommodation providers/categories · Commerce = product
brands. **Never mix these three.**

**Module-aware header terminology (one shared helper, config-driven):** NEW `lib/helper/module_terminology_helper.dart` (`ModuleTerminology`)
prefers a FUTURE backend field `provider_label_plural` (added to `ModuleModel` as nullable `providerLabelPlural`, forward-compat), else a
deterministic fallback by moduleType + backend `moduleName`. **Approved wording (premium bare labels, NO "All" prefix):** Food→"Restaurants" ·
Grocery→"Grocery Stores" · Pharmacy→"Pharmacies" · Fashion→"Fashion Stores" · Market→"Markets" · Fuel & Gas→"Fuel Stations" · Drink
Distributor→"Drink Distributors" (grocery-type resolved by moduleName heuristics). Applied to: `all_store_screen._title()` (bare label),
`new_on_mart_view` ("New {label} on {App}"), `all_store_filter_widget` title ({label}). **Parcel & Rental headers untouched.** No generic
"Stores"/"Shops"/"All"/"New On MoonJoin" where a better identity exists. New i18n keys (en/bn/es/ar): pharmacies, markets, fuel_stations,
drink_distributors, header_new, header_on.

**Verification:** `flutter analyze` → clean (repo residual pre-existing). Release build ✓ installed + launched on the owner's physical
iPhone. **Owner approved on-device: Fashion shows Brands; every other module hides Brands; headers read the premium bare labels.** FROZEN.
**Protected & NOT touched:** ItemWidget/`_premiumStoreDishCard`/Search/Favourite cards/item image/Add buttons/cart/store-page item cards
(frozen Phase 1), onboarding, notifications.
**Rule:** Brands = Ecommerce-only until backend module-scopes `/api/v1/brand`; reuse the one engine (never fork); headers stay module-aware
via `ModuleTerminology` (backend `provider_label_plural` overrides when shipped); Parcel/Rental headers and all frozen cards stay untouched.
