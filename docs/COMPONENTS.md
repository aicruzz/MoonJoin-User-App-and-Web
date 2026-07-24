# MoonJoin Shared Components

Documents reusable Flutter widgets. Update whenever a new reusable component is created. Reusable widgets
must never be duplicated — restyle the shared widget once and it propagates everywhere.

## Existing shared library — `lib/common/widgets/`

| Widget | Purpose |
|---|---|
| `custom_button.dart` | Primary/secondary action button (loading, radius, color) |
| `custom_app_bar.dart` | Standard app bar (title, back, actions) |
| `custom_text_field.dart` | Main form input (validation, prefix/suffix, focus) |
| `custom_image.dart` | Cached network image with placeholder |
| `custom_card.dart` | Rounded elevated card container |
| `custom_bottom_sheet_widget.dart` | Reusable bottom sheet container |
| `custom_dialog.dart` / `confirmation_dialog.dart` | Generic + yes/no dialogs |
| `custom_snackbar.dart` / `coustom_toast.dart` / `cart_snackbar.dart` | Toasts / add-to-cart snackbar |
| `custom_drop_down_button.dart` / `custom_dropdown.dart` | Dropdown selectors |
| `paginated_list_view.dart` | Infinite-scroll paginated list |
| `no_data_screen.dart` / `no_internet_screen.dart` / `not_found.dart` / `not_logged_in_screen.dart` | Empty / offline / 404 / guest-gate states |
| `not_available_widget.dart` | Item unavailable indicator |
| `quantity_button.dart` | +/- quantity stepper |
| `item_view.dart` / `item_widget.dart` / `item_bottom_sheet.dart` | Item list/grid, single tile, add-to-cart sheet |
| `card_design/{item_card,store_card,store_card_with_distance,visit_again_card}.dart` | Product/store cards |
| `cart_widget.dart` / `cart_count_view.dart` | Cart badge + count (used for the new header cart icon) |
| `custom_favourite_widget.dart` / `add_favourite_view.dart` | Favourite toggle |
| `rating_bar.dart` | Star rating |
| `discount_tag.dart` / `new_tag.dart` / `organic_tag.dart` / `veg_filter_widget.dart` | Badges & filters |
| `address_widget.dart` / `code_picker_widget.dart` / `image_picker_widget.dart` | Address card, dial-code, image upload |
| `title_widget.dart` | Section title + "see all" |
| `menu_drawer.dart` | App drawer (entries migrate into Account tab) |
| `payment_complete_dialog.dart` | Payment success dialog |
| Web set: `web_menu_bar`, `web_search_field`, `web_item_*`, `footer_view`, `web_page_title_widget`, `web_constrained_box` | Web layout variants (each redesigned component needs both mobile + web) |

## MoonJoin component library — `lib/common/widgets/moonjoin/` (BUILT in Phase 2)

Pure-presentation, design-system widgets shared across ALL modules. No business logic, no API calls, no
controllers/providers/services/repositories — behaviour flows in via constructor params and callbacks;
prices/ratings are pre-formatted strings. Import the barrel `moonjoin/moonjoin_components.dart` for all.

| Widget (class) | File | Purpose |
|---|---|---|
| `WavyHeader` | `wavy_header.dart` | Green header with curved/wavy bottom edge (ClipPath) — the signature motif |
| `MoonjoinSearchBar` | `moonjoin_search_bar.dart` | Rounded search field + green filter button; `readOnly`+`onTap` for tap-to-search |
| `MoonjoinModuleHeader` | `module_header.dart` | Green top area: greeting/title, location row, notification+cart action icons, embedded search (composes `WavyHeader`) |
| `ModuleIcon` | `module_icon.dart` | Circular white face + green ring glyph (superseded by `OrganicModuleIcon` for module tiles) |
| **`OrganicModuleIcon`** | `organic_module_icon.dart` | **Permanent module glyph** — white **organic blob** (not a circle) + fixed green ring + soft shadow. 14 deterministic smooth shapes; `shapeIndex` (stable per module id) picks one. `artworkFraction` **LOCKED**: 0.89 normal / 0.93 featured. Do not redesign, change ring/blob/spacing, or regenerate shapes. |
| `CategoryTile` | `category_tile.dart` | Module tile = `OrganicModuleIcon` + label. `shapeIndex`, `artworkFraction`, and `availability` (`ModuleAvailability`: enabled interactive / **unavailable** dimmed+desaturated+non-interactive, no layout shift / disabled omitted upstream). |
| `MoonjoinCategoryTile` | `moonjoin/moonjoin_category_tile.dart` | **Category entry** (circular backend image + label) — the approved MoonJoin category UI/UX (width 60, radius-100 image at height 60, `paddingSizeSmall` gap, `robotoMedium`/`fontSizeSmall`/`bodyMedium`, `radiusSmall` ink). Data-agnostic: caller supplies `label`/`image`/`onTap`, plus optional `icon` (imageless "All" tile) and `selected` (animated green ring). No styling values of its own — all from `Dimensions`/`styles`/theme. Category data always comes from the module's backend. |
| `ModuleCard` | `module_card.dart` | Card-surface module entry (icon + title + subtitle); composes `ModuleIcon` |
| `SectionHeader` | `section_header.dart` | Section title + optional "See all" action |
| `StatusBadge` | `status_badge.dart` | Pill for statuses/tags (In Stock, Non-Veg, order status, rating) — filled or tinted |
| `PriceRow` / `PriceView` | `price_row.dart` | Bill line (label+value, total/discount variants) / inline price with strikethrough old price |
| `MoonjoinFilterChip` / `FilterChipBar` | `filter_chip_widget.dart` | Selectable pill / horizontal chip row |
| `VariationSelector` | `variation_selector.dart` | Chip toggles for grocery variations (Size/Type) |
| `OptionGroupSelector` (`OptionItem`) | `option_group_selector.dart` | Food radio-card / checkbox-card option groups with Required/Optional tag |
| `BottomActionBar` | `bottom_action_bar.dart` | Pinned footer surface (card bg, top shadow, safe area) |
| `MoonjoinEmptyState` | `empty_state_widget.dart` | Empty-state placeholder + optional action |
| `MoonjoinErrorState` | `error_state_widget.dart` | Error/no-connection state + retry |
| `SkeletonBox` / `MoonjoinSkeleton` / `SkeletonListLoader` | `loading_skeleton.dart` | Shimmer skeleton primitives + ready-made list loader (uses `shimmer_animation`) |
| `SuccessBanner` | `success_banner.dart` | Success block (check badge, title, message, actions) |
| `InformationCard` | `information_card.dart` | Inline notice (icon + title + subtitle + action), e.g. "items unavailable" |
| `CartSummaryCard` (`SummaryLine`) | `cart_summary_card.dart` | Bill/order summary card; composes `PriceRow` |
| `MoonjoinDialog` | `moonjoin_dialog.dart` | Styled dialog (icon/title/message + confirm/cancel); composes `MoonjoinButton` |
| `MoonjoinBottomSheet` | `moonjoin_bottom_sheet.dart` | Styled sheet container (handle, title, scroll body) |
| `MoonjoinButton` | `moonjoin_button.dart` | Action button — primary / secondary / outline, icon + loading |
| `MoonjoinTextField` | `moonjoin_text_field.dart` | Rounded form input (label, prefix/suffix, obscure, error) |

**Barrel:** `moonjoin/moonjoin_components.dart` re-exports all of the above.

**Reserved Shared Foundation Components (Unused).** Most of this library is not yet wired into a live screen.
**Live** today: `WavyHeader`, `MoonjoinModuleHeader`, `MoonjoinSearchBar`, `OrganicModuleIcon`, `CategoryTile`,
`MoonjoinCategoryTile`, `SectionHeader`, `MoonjoinButton`, and the loading skeletons (`MoonjoinSkeleton` /
`SkeletonBox`) — the last three went live with Rental Screen 1. The remaining components (dialogs, bottom
sheets, text field, empty/error states, success banner, information card, cart summary card, status badge,
price row, filter chip, variation/option selectors, bottom action bar, module icon/card) are **unused but
reserved** as generic foundation for upcoming modules — **keep, do not delete.**
Components that duplicated an already-approved **frozen** production component were removed instead:
`RestaurantCard` (→ `MoonjoinStoreCard`), `ProductCard` (→ `ItemWidget`), `PromotionBanner` (→ the approved
rotating Promo Banner), `QuantityStepper` + `FloatingCheckoutBar` (→ the Shared Quantity Control). Rule going
forward: **one implementation per shared production responsibility — never two.**

**Navigation shell (Phase 3):** the 4-tab bottom bar lives in the rebuilt
`dashboard/screens/dashboard_screen.dart` and reuses `MoonjoinModuleHeader` (cart + notification header
icons). See `SCREEN_FLOW.md`.

## Feature-composed views (built from the library above — not standalone reusable components)

These are screen/section views that **compose** the shared library; they live under their feature folder
and hold no business logic (they only read existing controllers):

| View | File | Composes |
|---|---|---|
| `ModuleLandingView` | `features/home/widgets/module_landing_view.dart` | `MoonjoinModuleHeader`, `MoonjoinSearchBar`, `CategoryTile`, `SectionHeader`, `InformationCard` + existing `BannerView` / `PopularStoreView` / `DeliverToView` (Phase 4 Home). Edge-to-edge header via `AnnotatedRegion`. |
| `DeliverToView` | `features/home/widgets/deliver_to_view.dart` | `SectionHeader` + existing `AddressWidget` — the preserved "Deliver to" quick address selector. |

## Reuse policy

- Redesign the widest-surface shared widgets **once**: `custom_button`, `custom_text_field`,
  `custom_app_bar`, `custom_image`, `paginated_list_view`, `no_data_screen`,
  `custom_bottom_sheet_widget`, `card_design/*`.
- Fuel/Fashion/Market/Drink/Solar reuse the shop UI. Apartment Rental reuses car-rental widgets where
  visually identical. Never create multiple implementations of identical UI — drive it by data/config.

## Official Product Details architecture — exactly TWO implementations

MoonJoin has **only two** Product Details screens. **No third implementation may ever be created.**

1. **Food Product Details — `features/item/screens/food_details_screen.dart` (`FoodDetailsScreen`) — FROZEN.**
   Used only by the **Food** business module. Food-specific layout (green wavy hero, Veg/Non-Veg, required
   option groups, food add-ons). Hero image safe-area is fixed & frozen (see MIGRATION_LOG).
2. **Shared Product Details — `features/item/screens/item_details_screen.dart` (`ItemDetailsScreen`) — FROZEN.**
   Used by **every other storefront module**: Grocery, Market, Fuel & Gas, Drink Distributor, Solar & Power
   (all Grocery module type), Pharmacy, and Fashion (Ecommerce). Image carousel hero + variations/add-ons.

Only module data / APIs / terminology / business logic differ — the two UIs above are the complete set.

## Frozen Registry — official reusable production components (LOCKED)

These are approved, production, reusable. **Do not redesign or modify any of them without explicit product
owner approval.** Every storefront business module must reuse them.

| # | Frozen component | Location |
|---|---|---|
| 1 | **Shared Storefront Home** (`AllStoreScreen`) | `features/store/screens/all_store_screen.dart` |
| 2 | **Shared Store / Restaurant Page** | `features/store/screens/store_screen.dart` (single `/store` route) |
| 3 | **Shared `MoonjoinStoreCard`** | `features/store/widgets/moonjoin_store_card.dart` |
| 4 | **Shared `StoreHeroHeader`** | `features/store/widgets/store_hero_header.dart` |
| 5 | **Shared `StoreMapView`** (map card) | `features/store/widgets/store_map_view.dart` |
| 6 | **Shared Quantity Control** | `common/widgets/cart_count_view.dart` + `QuantityButton` → `CartController.setQuantity` |
| 7 | **Food Product Details** (`FoodDetailsScreen`) | `features/item/screens/food_details_screen.dart` |
| 8 | **Shared Product Details** (`ItemDetailsScreen`) | `features/item/screens/item_details_screen.dart` |
| 9 | **Parcel Screen 1** (Parcel Home/Category) | `features/parcel/screens/parcel_category_screen.dart` |
| 10 | **Parcel Screen 2** (Parcel Location) | `features/parcel/screens/parcel_location_screen.dart` |
| 11 | **Rental Provider Details** (`VendorDetailScreen`) | `features/rental_module/vendor/screens/vendor_detail_screen.dart` |
| 12 | **`RentalProviderHeroHeader`** (Store-hero clone for rental) | `features/rental_module/vendor/widgets/rental_provider_hero_header.dart` |

Together these form the **official MoonJoin reusable storefront foundation**. No future redesign should
recreate them; reuse them unchanged.

## Business Module Types (permanent) — six only

MoonJoin has **only six** official Business Module Types. Visible modules map onto them; never redesign a
visible module independently — reuse its Business Module Type implementation. Only data / APIs / terminology
/ business logic differ.

| Business Module Type | Visible modules mapped to it |
|---|---|
| **Food** | Food |
| **Grocery** | Grocery, Market, Fuel & Gas, Drink Distributor, Solar & Power |
| **Pharmacy** | Pharmacy |
| **Ecommerce** | Fashion |
| **Parcel** | Package Delivery |
| **Rental** | Car Rental, Short Apartment Rental |

Rental note: Car Rental and Short Apartment Rental share the **Rental** business module — when Rental begins,
reuse the Car Rental architecture; use mock repositories only where the backend isn't yet available; never
invent backend APIs.

## Parcel (Package Delivery) components — migration in progress

Parcel is redesigned from `ui-designs/Parcel/`. Screen 1 (Parcel Home/Category) and Screen 2 (Parcel
Location) are both **FROZEN**. Both reuse the frozen **`WavyHeader`** for their
green headers (Screen 1 header: `parcel/widgets/parcel_app_bar_widget.dart`; Screen 2 header inline in
`parcel_location_screen.dart` with a 2-step indicator), the shared `CartController` cart-count, and shared
routes. Screen 2 also reuses shared `CustomCard` / `CustomTextField` (prefixIcon) / `CustomButton` and the
existing `ParcelViewWidget` + `SavedAddressBottomSheet`. Screen 3 (Parcel Request — approved) is the parcel
checkout: it reuses the white `CustomAppBar` + shared `CardWidget`, `TripFromToCard`, `TipsWidget`,
`CheckoutCondition`, `CustomButton`, and parcel `DetailsWidget` (restyled with a leading avatar).

**Parcel payment = the shared payment architecture.** Screen 3 now uses the **shared `PaymentSection`** card +
`PaymentMethodBottomSheet` (the same one used by Food/Grocery/Pharmacy/Ecommerce), driven by
`CheckoutController` and synced into `ParcelController` at confirm-time — one shared "Choose Payment Method"
implementation across every module. Delivery Man Tips uses the shared `TipsWidget` chip; the tips-section
height overflow was fixed in the shared `deliveryman_tips_section.dart`.

**Package Protection — Frontend: COMPLETE · Backend: READY FOR CONFIGURATION · Status: NOT FROZEN.** New
Parcel Request section (between Delivery Man Tips and Charge Pay By). **Config-driven & backend-ready:**
`ConfigModel` has nullable `packageProtectionStatus` + `packageProtectionPercentage` (parsed from the config
API; null until the backend sends them). `ParcelController.packageProtectionEnabled` /
`packageProtectionPercentage` read those config values; the whole section is gated on
`packageProtectionEnabled`, and `protectionFee = packageValue × (packageProtectionPercentage / 100)` feeds
the existing Order Summary/Total (percentage is a percent number, e.g. `package_protection_percentage: 1.5`).
Backend config fields required: `package_protection_status`, `package_protection_percentage`. The **only** temporary dev fallback lives in one isolated place (two consts in
`ParcelController`, marked `TODO(BACKEND): Remove fallback…`) — no hardcoded percentage in the UI/flow. After
backend integration only the config source changes; UI/controller/calc/widgets stay identical. Reuses
`CardWidget` / `CustomTextField` (`isAmount`) / `PriceConverter` / `AnimatedSize`; nothing sent to the API yet
(integration point + unused `PlaceOrderBodyModel.extraPackagingAmount` documented). No new shared component
and no frozen component modified. Parcel-specific widgets (restyled in place, not
duplicated): `DeliverItemCardWidget` (category card + dashboard parcel sheet), `ServiceInfoListWidget`
(numbered "get services" steps, wraps backend `videoContent.bannerContents`), `GetServiceVideoWidget`. The
"Why Choose Us" and "Video Content / Get Service" sections are backend/admin-driven (empty until admin
configures them — see MIGRATION_LOG).

## Shared Quantity Control — Official MoonJoin Quantity System (FROZEN)

The **one** quantity control for every storefront module (Food, Grocery, Market, Fuel & Gas, Drink
Distributor, Solar & Power, Pharmacy, Fashion/Ecommerce). There must be **no other** quantity widget in the
storefront — the former `QuantityStepper` + `FloatingCheckoutBar` (unused scaffolding) were **deleted**.

- **In-list control — `common/widgets/cart_count_view.dart` (`CartCountView`)**: qty 0 → styled **Add**
  (or `child`); qty ≥ 1 → `[ − n + ]`. Used by every storefront list card (`ItemWidget` both layouts,
  `card_design/item_card`, flash-sale / review / "items you love" / medicine cards, view-all, web item widget).
- **Details / add sheet — `QuantityButton` → `CartController.setQuantity` / `ItemController.setQuantity`**:
  Product Details, `item_bottom_sheet`, `food_details`. Shared primitive + shared logic (not a second system).
- **Your Cart — `cart_item_widget.dart`** uses `QuantityButton` → the same `CartController.setQuantity`.

**Behaviour (all callers, single source `CartController.setQuantity`):**
- **Optimistic + instant** — quantity + `calculationCart()` + `update()` fire immediately; **never** a spinner
  in place of the number.
- **Debounced backend sync (500ms)** — rapid taps send **one** `updateCartQuantityOnline` carrying the final
  quantity (`_scheduleQuantitySync` + `_quantitySyncTimers`). No concurrent update/refetch races.
- **Pending-quantity preservation** — `_pendingQuantities` is re-applied after `getCartDataOnline()` so an
  in-flight refetch (incl. pull-to-refresh) can never revert a just-changed number.
- **Always-active buttons** — `+/−` always absorb the tap (never fall through to open Product Details).
- **Qty = 1 → Delete** — the minus becomes `Images.delete` + error tint (matches Your Cart's `showRemoveIcon`).
- **Live cart totals** update on every tap.

Preserves all business logic/APIs/signatures (`decideItemQuantity`, `calculateDiscountedPrice`,
`updateCartQuantityOnline`, `getCartDataOnline`). **Reuse unchanged — do not create another quantity widget.**

## Single store/restaurant card — `MoonjoinStoreCard` (FROZEN)

`features/store/widgets/moonjoin_store_card.dart` is the **one** mobile store/restaurant card across the app
(All Restaurants/All Stores, category stores, search → restaurants, module-home store grid, campaign stores,
Home "New on MoonJoin" strip). It renders cover + discount/`min_purchase` badges + logo + delivery-time pill
+ name/rating/free-delivery row + bookmark, and a **closed-store treatment** (dim overlay + centered
"Closed • Opens at HH:MM" / "Closed" badge) driven by the existing `StoreController.isOpenNow` +
`store.storeOpeningTime` + `DateConverter.convertRestaurantOpenTime` (no new logic). Open-first ordering uses
the reusable `StoreController.sortStoresOpenFirst(list)`. The shared mobile store list is rendered by
`common/widgets/item_view.dart` `ItemsView` (`_moonjoinStoreList`). **Reuse these unchanged** — do not create
another store card. Desktop keeps its existing `card_design/store_card_with_distance` / web store cards; the
not-yet-migrated Home per-module strips still use the legacy cards (kept, not deleted).

## Store / Restaurant page components (FROZEN — official shared storefront page)

The Store page (`store/screens/store_screen.dart`, single `/store` route) is shared by **Food / Grocery /
Pharmacy / Ecommerce** (Grocery = Grocery, Market, Fuel & Gas, Drink Distributor, Solar & Power). Reuse these;
never duplicate them per module. Only module data/APIs/models/logic differ — the UI is shared.

| Widget | File | Purpose |
|---|---|---|
| `StoreHeroHeader` | `features/store/widgets/store_hero_header.dart` | Green store hero (rounded bottom curve; search pill straddles the transition): name, cuisines, ★rating·delivery, full address, "N items available", cover image, back·favourite·share·notification·cart, in-store search pill + filter chips. Reuses `StoreFilterChip` + existing controllers/routes. |
| `StoreMapView` | `features/store/widgets/store_map_view.dart` | Premium embedded location-awareness map (NOT navigation): store+user markers, distance, **View on Map** expands in place, floating Re-center/My-Location/Directions-Preview(route+ETA)/Open-in-Google-Maps. Reuses Google Maps + `direction-api`/`distance-api` + `AddressHelper` + `url_launcher`; single map instance. |
| **`ItemWidget` premium store layout** | `common/widgets/item_widget.dart` (opt-in `premiumStoreLayout`) | The **one** item card, extended (not forked): uniform 122×122 image, name, veg, favourite, ★rating, price+old-price+`/unitType`, organic tag, View Details. Real Item data only. Default off — all other screens unchanged. Flows via `ItemsView.premiumStoreLayout` → `_premiumItemList`. |

**Reuse rule:** these + `MoonjoinStoreCard` + `AllStoreScreen` are the frozen storefront. When Rental is
redesigned it will reuse `StoreHeroHeader`, `StoreMapView`, search, filter chips, cards, dialogs, loading/
empty states where appropriate; only Rental-specific booking screens get their own UI.

## Backend Integration Queue Reference

Frontend components/features that are complete but waiting for backend are listed in
**`docs/BACKEND_INTEGRATION_QUEUE.md`**. Before adding any API, model, or admin setting for a MoonJoin
feature, check that queue first and adapt the backend to the approved frontend contract — do not redesign the
frontend. Permanent rule: complete all three apps' frontends (User → Vendor → Delivery Man) before backend,
documenting gaps as *Frontend Complete — Waiting for Backend Integration*.

---

## 🔒 THE MoonJoin Category Component (PERMANENT — one category UI/UX application-wide)

**There is exactly ONE category UI/UX in MoonJoin.** It is the category component used on **Food Home**, and
by extension Grocery Home, Pharmacy Home, Fashion Home, Parcel Home and every approved module Home.
`MoonjoinCategoryTile` is that component expressed as a data-agnostic widget.

**Use it everywhere categories appear** — Rental Home (Screen 1), All Car Rentals (Screen 2), future Apartment
Rental screens, and every future category row.

**Never** substitute a different category widget. In particular this is **NOT** the All Restaurants
`RestaurantCategoryChip` (tinted circle, inset `BoxFit.contain` image) — that one stays exclusive to the Food
All Restaurants page.

> **The MoonJoin Category Component is a shared global design component and must not be visually customized by
> individual modules. Modules may only supply different backend data or adapters.**

**Only the backend data changes.** Everything else is identical everywhere: spacing · icon size · padding ·
border radius · geometry · animation · typography · colours · shadows · selected state · unselected state ·
loading state.

**No module-specific visual adjustments may exist** — not even small ones. One shared component means one
shared appearance. Because of this, any future improvement to the Food Home category is inherited by Rental
(and every other module) automatically, with no extra work. If you find yourself wanting to tweak a value "just
for this module", that is a defect: change it once in the shared component, or supply different data.

Never hardcode category names or icons. Never duplicate the component. Never redesign it. If a module's data
model differs (Rental uses `VehicleCategoryModel`, not `CategoryModel`), adapt **through the adapter** —
never by modifying a frozen component.

---

## Architectural decision — Rental categories use an adapter, not the frozen shared `CategoryView`

**Decision.** The Rental module renders its category row with the shared `MoonjoinCategoryTile` fed by
`VehicleCategoryModel` + `TaxiHomeController`, **instead of** reusing the shared `CategoryView` /
`FoodCategoryView` implementation.

**Rule (permanent).** *Rental reuses the approved MoonJoin Category UI/UX while preserving the Rental module's
existing backend category filtering behaviour.*

**Why.** The shared `CategoryView` is **frozen** and bound to a different data path (`CategoryController`,
`CategoryModel`). Rental categories come from their own existing backend
(`/api/v1/rental/vehicle/category-list` → `VehicleCategoryModel`) with their own established filtering state
(`selectedCategoryIds`). Feeding Rental data through `CategoryView` would require modifying a frozen component
used by four approved modules (Food, Grocery, Pharmacy, Ecommerce) — prohibited.

**How.** Reuse the approved MoonJoin category **design**, not necessarily the exact implementation, whenever
the data model differs. The adapter reproduces the approved MoonJoin category UI/UX exactly and must **not**
redeclare styling values — all sizing, spacing, typography, colours, radius and animation come from
`Dimensions`, `styles.dart`, and the theme, so a change to the design system still propagates.

**Result.** Identical MoonJoin UI/UX, different data source, zero duplication of styling values, zero changes
to frozen components. `MoonjoinCategoryTile` is generic and reusable by any future module in the same
situation — it is the single implementation of the MoonJoin category tile look.

---

## Shared-component enhancement — `TopBrandCard.showCount` (additive, backward-compatible)

`TopBrandCard` (`features/store/widgets/all_restaurants_widgets.dart`) gained one **optional** parameter:

```dart
final bool showCount; // default: true
```

**Default `true` ⇒ zero behaviour change.** Food, Grocery, Pharmacy, Fashion, Parcel and every existing caller
render exactly as before — the "N+ items" line is untouched.

**Why.** The Rental brand API (`/api/v1/rental/vehicle/brand-list`) returns `id`, `image`, `name`,
`image_full_url` — there is **no vehicle count**. Rather than duplicate the card or display a fabricated
`0+ items`, Rental passes `showCount: false` and the count line is hidden.

**Rule.** This is a *reusability improvement to one shared component*, **not** a redesign and **not** a fork:
one shared component · no duplicate widget · no fake data · backward compatible · additive only · no
regression. When the backend exposes `vehicles_count`, Rental passes it as `itemCount` and drops
`showCount: false` — **no widget redesign required.** See `docs/BACKEND_INTEGRATION_QUEUE.md` item 6.

---

## Rental Provider banners & provider cards — reuse decision (pending backend)

**Decision.** When Rental provider listing becomes possible, it must **reuse the approved MoonJoin
store/restaurant presentation** — `MoonjoinStoreCard` for the provider entry and the approved store/restaurant
**banner** behaviour for provider banners — supplying Rental data only. Do **not** redesign, and do **not**
create Rental-specific provider cards or banner widgets.

Applies to **Car Rental Providers** and **Apartment Rental Providers** alike:

| Food / storefront | Rental equivalent |
|---|---|
| Restaurant/store card | Provider card |
| Restaurant banner | Provider banner |
| Restaurant page | Provider vehicle listing |

**Reuse first — redesign only if Rental genuinely needs functionality the shared implementation cannot
express.** If that ever happens, extend the shared component with an additive, backward-compatible parameter
(the `TopBrandCard.showCount` pattern) rather than forking it.

**Status: blocked on backend.** There is currently **no provider list/search endpoint** — every rental provider
API requires an already-known provider id — so no provider list or provider banner can be rendered yet. The
full Backend + Vendor App + Admin contract is in `docs/BACKEND_INTEGRATION_QUEUE.md` item 9
(**Frontend Complete — Waiting for Backend/Vendor Integration**). Per-provider banners already exist
(`/api/v1/rental/banners/{id}`) and will slot straight into the approved banner behaviour once providers can
be listed.

---

## `RentalProviderCard` — permanent Rental provider banner (visual clone of `MoonjoinStoreCard`)

**File:** `lib/features/rental_module/provider_adapter/rental_provider_card.dart`

- **Visual clone of `MoonjoinStoreCard`.** Every value is copied from the approved store/restaurant card:
  `radiusExtraLarge` card radius · shadow (black @6%, blur 10, offset 0,4) · `AspectRatio(2.55)` cover ·
  badge geometry and colours · 42px circular logo at `paddingSizeSmall` top-right · info-row padding ·
  name/rating typography · `_nameColor` / `_metaColor` · bookmark in the same trailing position.
- **Shares the same design system.** No new styling values, no second design language, no duplicated
  constants — everything comes from `Dimensions`, `styles.dart` and the theme.
- **Uses Rental business data.** `MoonjoinStoreCard` renders delivery concepts (delivery time, free delivery,
  opening hours, closed state) that do not exist for a rental provider. Those are replaced by the provider's
  **feature badges** (AC, Luxury, Petrol, Diesel, Electric, Gas, Automatic, Manual, SUV, Sedan, Coupe,
  Convertible, Pickup, 5/7 Seats), aggregated by `RentalProviderAdapter` from **real backend vehicle fields** —
  never hardcoded, and only badges that actually exist are shown.
- **Why an adapter and not literal reuse:** `MoonjoinStoreCard` is **frozen** and typed to `Store`, reading
  delivery-only fields. Feeding it a rental provider would either require modifying a frozen component (used by
  four approved modules) or displaying delivery data rental has no equivalent for. Same resolution as
  `MoonjoinCategoryTile`: adapt the data, clone the visual, never fork the design.
- **Permanent component.** Future backend changes only replace the **adapter**, not the UI:
  `Vehicle API → group by provider.id → RentalProviderCard` becomes
  `Provider List API → RentalProviderCard`. **This card must never be redesigned.**
- **Reuses existing logic:** the bookmark uses the existing `TaxiFavouriteController` provider wish-list
  (`isProvider: true`) — no new favourite logic.

See `docs/BACKEND_INTEGRATION_QUEUE.md` item 10 for the Provider List endpoint and the Vendor/Admin work still
required.

---

## Audit — Rental Provider Page (`VendorDetailScreen`) vs the approved Store/Restaurant page

Audited section-by-section. The existing Rental provider page **already implements the approved Store-page
pattern** with rental data, so it was **left as-is** (no redesign, no duplicate widgets):

| Store page section | Rental Provider page | Status |
|---|---|---|
| Cover/banner image | `CustomImage(vendor.coverPhotoFullUrl)` (180h, cover) | ✅ present |
| Logo | `CustomImage(vendor.logoFullUrl)` | ✅ present |
| Name | ✅ | ✅ present |
| Rating + rating count | `avgRating` / `ratingCount` + `TaxiRatingBar` | ✅ present |
| Address / location | `vendor.address` | ✅ present |
| Favourite | `TaxiAddFavouriteView` (existing rental favourite logic) | ✅ present |
| In-page search + filter | `SearchAndFilterWidget` (+ active-search chip, clear) | ✅ present |
| Item list → **vehicle list** | `PaginatedListView` + `VendorVehicleCard` | ✅ present |
| Pagination | `PaginatedListView` (approved shared component) | ✅ present |
| Empty state | `NoDataScreen` (approved shared component) | ✅ present |

**Deltas vs the approved Store page (cosmetic only, NOT defects):**
1. **Loading** uses `CircularProgressIndicator`; the Store page uses `StoreDetailsScreenShimmerWidget`.
2. **Header treatment** is a plain cover image; the Store page uses the frozen `StoreHeroHeader` (green hero
   with curved transition + search pill). `StoreHeroHeader` is **frozen and typed to `Store`**, so adopting it
   would require a Rental adapter — a change to a working, already-approved rental page.
3. **No share button** (the Store page has one).

**Recommendation:** leave the page as-is for now. It reuses every approved shared component
(`PaginatedListView`, `NoDataScreen`, `CustomImage`, existing favourite logic) and follows the same structure.
The three deltas are cosmetic alignment that can be scheduled deliberately rather than bundled into Screen 2.

> **RESOLVED — Rental Screen 4 (Provider Details).** The three deltas above were the deliberate schedule this
> audit recommended, and Screen 4 closed two of them: the page now uses the green hero
> (`RentalProviderHeroHeader`, below) and a `MoonjoinSkeleton` loading state instead of a bare
> `CircularProgressIndicator`. Delta 3 (share button) stays out — the rental provider payload exposes no share
> URL/slug, so there is nothing real to share; it is not faked. See MIGRATION_LOG.md.

---

## `RentalProviderHeroHeader` — Rental Provider page hero (visual clone of the frozen `StoreHeroHeader`)

**File:** `lib/features/rental_module/vendor/widgets/rental_provider_hero_header.dart`

- **Visual clone of `StoreHeroHeader`.** Identical green hero with the rounded bottom curve
  (`radiusExtraLarge`), identical `SafeArea` + padding geometry, identical 42px action circles and 38px subtle
  circles, identical badge geometry, identical name (28 bold) / ★rating / location / amber `0xFFFFC107` count
  typography, identical 104px hero image at `radiusLarge`, and the identical 52px search pill straddling the
  green → content transition (same shadow, same trailing tune button).
- **Why a clone rather than literal reuse:** `StoreHeroHeader` is **frozen** and typed to `Store`, reading
  store/delivery-only data (`deliveryTime`, cuisines via `StoreController`, `FavouriteController`,
  `CartController`, the store item search route). A rental provider has none of those. Same resolution already
  recorded for `RentalProviderCard` vs the frozen `MoonjoinStoreCard`: **adapt the data, clone the visual,
  never fork the design.**
- **Reuses existing rental logic only** — `TaxiAddFavouriteView` (existing provider wish-list),
  `TaxiCartController` + `TaxiCartScreen` (existing rental cart), `NotificationController` +
  `RouteHelper.getNotificationRoute()`. No new business logic, no new favourite/cart implementation.
- **Real backend data only** — `name`, `avg_rating`, `rating_count`, `address`, `cover_photo_full_url`, and the
  vehicle count from the real `get-provider-vehicles` `totalSize`. Nothing fabricated.

**Additive parameter on a shared rental component (backward compatible):**
`TaxiAddFavouriteView.iconColor` — default `null` → theme primary, i.e. **every existing call site renders
exactly as before**. The provider hero passes white so the heart stays legible on the green.

**Status: 🔒 FROZEN** (with Rental Screen 4). Never redesign. `RentalProviderHeroHeader` exists solely because
`StoreHeroHeader` is frozen and `Store`-typed; it must not be forked further.

---

## `RentalProviderAdapter` — provider-card feature-badge formatting (Screen 2)

**File:** `lib/features/rental_module/provider_adapter/rental_provider_adapter.dart`

The backend `tag` field is a **stringified JSON array** (`["Lexus"]`). `_badgesFor` now runs it through a
private `_parseTags` helper that JSON-decodes the array into clean tokens (`Lexus`; `["Luxury","Premium"]` →
`Luxury`, `Premium`), with a defensive bracket/quote-strip + comma-split fallback, then title-cases each. The
card renders **"Lexus" / "Luxury" / "SUV"** instead of the raw `["lexus"]`.

- **Presentation-only.** The backend model (`VehicleModel.tag`) and the adapter architecture (group real
  vehicles by `provider.id`) are unchanged; nothing is invented — only the real value is reformatted.
- **Scope-safe.** `RentalProviderAdapter` is referenced only inside the rental module, so
  Food/Grocery/Pharmacy/Fashion/Parcel are unaffected.
- **Tested.** `test/rental/rental_provider_adapter_test.dart` (4 cases). Screen 2 stays 🔒 FROZEN apart from this
  isolated formatting fix.

---

## 🔒 Rental Screen 2 component status — FROZEN

`RentalProviderCard` and `RentalProviderAdapter` are **frozen** as of the Screen 2 freeze.

- **`RentalProviderCard`** — permanent provider banner, visual clone of the frozen `MoonjoinStoreCard`.
  **Never redesign.** When the Provider List endpoint ships, only the adapter changes.
- **`RentalProviderAdapter`** — the ONLY file that changes when the backend provider endpoint arrives.
- **Additive parameters added to frozen shared components** (all defaults preserve prior behaviour exactly, so
  Food/Grocery/Pharmacy/Fashion/Parcel render identically):
  - `TopBrandCard.showCount` (default `true`)
  - `RestaurantCategoryChip.imageFit` / `.imagePadding` / `.fallbackIcon` / `.selected` (defaults `BoxFit.contain`
    / `paddingSizeSmall` / `Icons.category` / `false`)
- **`RestaurantCategoryChip` is THE MoonJoin category component** used by Rental Home and All Car Rentals.
  Category UI is **frozen** — do not change geometry, colours or layout, and do not create another category
  component. `MoonjoinCategoryTile` is **no longer used** by any screen (retained on disk, not deleted, pending
  the post-Rental dead-code audit).

---

## Rental Vehicle Details — component reuse record

**Screen:** `lib/features/rental_module/vehicle_details_screen/vehicle_details_screen.dart`
(design `ui-designs/Car_Rental/car_rental_details.png`; the `_trip_type` variant is the same page with
Per Day selected).

**Zero new shared components.** Reused: `TripTypeCard` (both of its existing modes) · `DateTimePickerSheet` ·
`TaxiLocationSuggestionScreen` · `CustomTextField` (same estimate controllers/validation as the production
location bottom sheet) · frozen `QuantityButton`→`setQuantity` quantity system · `CustomButton` ·
`CustomImage` · production `TaxiCheckoutScreen`. The only addition is `_DashedBorderPainter`, a private
CustomPainter for the design's dashed "Add More Vehicle +" container — screen-local presentation, not a
shared component (do not promote it without approval).

**Location line:** the user's selected address via `AddressHelper.getUserAddressFromSharedPref()` — the same
source as every approved MoonJoin header (queue item 15 resolved; no backend gap).

**Vehicle Details status: 🔒 FROZEN** (product-owner approved). The screen and its journey pages
(`TaxiLocationSuggestionScreen` restyle, `MapRecentSavedAddress` restyle) are locked; only verified bug
fixes, backend integration, or docs may touch them.

---

## `RentalApartmentAdapter` — apartment view over REAL rental data (temporary production adapter)

**File:** `lib/features/rental_module/provider_adapter/rental_apartment_adapter.dart`

Same philosophy as `RentalProviderAdapter`: resolves the REAL "Short Apt Rental" category from the live
`category-list` (name-matched because the backend has no category `type` yet) and filters the real browse
feed by `category_id`. Nothing fabricated; empty result → honest `NoDataScreen`. Consumed only by
`AllVehicleScreen`'s additive `fromApartment` mode (ONE unified Rental listing page — no second screen).
When the proper backend filters ship (queue items 5/7/8/13), ONLY this adapter changes.

**`RentalApartmentAdapter` — section scoping (added):** `RentalSection {all, car, apartment}` ·
`sectionCategories` (real-name split of the live category list) · `filterBanners` (real `provider_id` →
provider-inventory classification; unclassified → Car only, never Apartment). Additive `BannerWidget.section`
param (default `all` — Home byte-identical). Only the adapter changes when queue item 18 ships.

**Frozen (Apt phase 1-2):** `RentalApartmentAdapter` (category resolution · apartment filter ·
`isApartmentProvider` · `RentalSection` scoping `sectionCategories`/`filterBanners`) · additive
`BannerWidget.section` · additive `RentalProviderHeroHeader.countLabel` · `MoonjoinEmptyState` now LIVE
(Rental Home Popular Short Apt empty state). Only the adapter changes when queue items 17/18 ship.

**Apt Screen 3 FROZEN:** `VehicleDetailsScreen` apartment mode + `RentalApartmentAdapter.amenityTags`.

**Apt Checkout FROZEN:** the master `TaxiCheckoutScreen` reused (no second checkout). Apartment mode is
additive/auto-activating (wording + Check-in/out/Nights strip). PERMANENT: one checkout + one payment system
(payer selector + shared `PaymentSection`) serves Car and Apartment; future apartment backend plugs in, never
replaces.

**Apt Booking Success FROZEN:** shared `ConfirmBookingRequestBottomSheet` (no second success page); apartment
mode additive/auto-activating (Booking ID/Date, Check-in/out/Nights, Total Paid, wording).

**Rental Trip Details FROZEN:** `TaxiOrderDetailsScreen` is THE single shared trip-details page (booking
success + Trips→Running). Additive changes only. Legacy sub-widgets (TripStatusView/SelectedVehiclesView/
ProviderView/TripDetailsWidget/TripCalculationView) superseded, retained for the post-Rental dead-code audit.

**Rental Trip card FROZEN:** `TripOrderViewWidget` (Running/History card; real data, inline Cancelled state,
apartment auto-activation, opens frozen `TaxiOrderDetailsScreen`). NOTE: the shared `order_screen.dart`
wrapper (header + Orders/Trips/Stay switch + segmented tabs + wording) is NOT yet frozen — next phase.

**Shared Orders/Trips/Stay FROZEN:** `order_screen.dart` (one premium wrapper, module-aware wording via
`haveTaxiModule` + real-content apartment detection), `OrderViewWidget` (premium storefront order card),
`TripOrderViewWidget` (frozen trip card). One page, one set of controllers — no duplication. Additive changes
only. `Reviews._reviewInt` defensive parse added to the shared `order_model.dart` (backward compatible).

**Scheduled Module Availability (additive):** `ModuleModel` adapter fields (open/close/timezone/
temporary_close/holiday_today, null today) + `resolveModuleAvailability` (real-schedule resolver) drive the
FROZEN `CategoryTile`/`ModuleAvailability` fade+disable — no card redesign. **Search:**
`SearchController.resultStoreCount` (immediate real count, no extra calls) + `hideItemStoreName:false` on
search results (frozen `item_widget` shows real `store_name`).

**`VirtualAccountDetailsWidget` (THE shared Virtual Account component):** one self-contained widget
(loading / generate / details) reused by Checkout, Profile (×3), and Wallet "+". Superset of the removed
per-screen copies; reuses the existing `ProfileController.generateVirtualAccount()`. Duplicate
`VirtualAccountCardWidget` + wallet inline block are now unused (retained for the dead-code audit).

### 🧊 FOUNDATION COMPONENT — `VirtualAccountDetailsWidget` (FROZEN 2026-07-24)
`lib/features/checkout/widgets/virtual_account_details_widget.dart` — the ONLY approved Virtual Account UI
in MoonJoin (states: details / loading / generate; flags: `detailsOnly`, `showTitle`, `showInstructions`,
`margin`). Reused by Checkout, Profile (×3), Wallet "+". **Mandatory reuse** on every current/future
virtual-account surface (Checkout, Wallet, Deposit, Fund Wallet, Bank Account, Profile, Payment/Financial
pages). No alternate Virtual Account UI without explicit architectural approval. See docs/FROZEN_REGISTRY.md.
`virtual_account_card_widget.dart` = OBSOLETE (dead, retained for final cleanup).

### 🧊 FOUNDATION — `PortionWidget` (Account navigation row) (FROZEN 2026-07-24)
`lib/features/menu/widgets/portion_widget.dart` — the single MoonJoin list-navigation row (46px soft-green
icon chip · bold title · optional subtitle · trailing chevron / count `suffix` · inset divider · `isDanger`).
Used by `menu_screen.dart` for all Account/Menu rows. No alternate menu-row widget permitted.
`menu_button_widget.dart` = OBSOLETE (zero usages; retained for cleanup).

### 🧊 FOUNDATION — `ProfileButtonWidget` (setting / toggle / action row) (FROZEN 2026-07-24)
`lib/features/profile/widgets/profile_button_widget.dart` — the single MoonJoin standalone-card row (icon
chip · title · optional subtitle · adaptive trailing: Cupertino toggle / language selector / chevron; red
danger variant). Used by profile_screen, setting_page, update_profile, web_profile. Every Profile
toggle/action/setting row must reuse it.

### 🧊 Account (Profile) shell — `menu_screen.dart` (FROZEN 2026-07-24)
Redesigned to `profile.png`: waved green header (`_HeaderWaveClipper`), avatar edit-badge, notification
bell, dark-mode toggle, three tappable stat cards (Loyalty/Orders/Wallet action pills), grouped
`PortionWidget` sections, frozen `VirtualAccountDetailsWidget`. Presentation only; navigation/logic unchanged.

### 🧊 FOUNDATION — `ProfilePageHeader` (shared Profile header) (FROZEN 2026-07-24)
`lib/features/profile/widgets/profile_page_header.dart` — THE official green waved header for every Profile
child page (title + back + optional trailing + `bottomExtra` avatar overlap; status-bar-aware top spacing;
concave wave mirroring the Stage-1 Account header). MANDATORY reuse on all remaining Profile screens; no
duplicate headers. First consumer: Personal Information.

### 🧊 Personal Information (Edit Profile) — `update_profile_screen.dart` (FROZEN 2026-07-24)
Presentation-only redesign to the MoonJoin language. Mobile `_mobileView` + desktop `webView()`. Reuses
`ProfilePageHeader`, `CustomTextField` ×3, `CustomButton`, frozen `ProfileButtonWidget` (Change Password),
`CustomPopupMenuButton`+`ConfirmationDialog`+`deleteUser`, existing `pickImage()`. Controllers / repository /
service / API `/customer/update-profile` / validation / image-upload / verification flows / navigation all
preserved. QA fixes: title-behind-avatar (header height), un-tappable camera badge (avatar moved inside Stack
bounds). Web desktop verification pending (non-blocking). Obsolete `ProfileBgWidget` retained for cleanup.
