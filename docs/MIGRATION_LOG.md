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
