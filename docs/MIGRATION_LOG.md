# MoonJoin UI Redesign — Migration Log

Chronological record of each completed phase. Baseline `flutter analyze` before the redesign: **56
info/warning issues, 0 errors**. Rule for every phase: **zero new issues** (the 56 pre-existing ones are
tolerated; nothing new introduced).

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
