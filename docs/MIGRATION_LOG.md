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
