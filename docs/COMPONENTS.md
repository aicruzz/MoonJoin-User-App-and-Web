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
`SectionHeader`, `MoonjoinButton`. The remaining components (dialogs, bottom sheets, text field, empty/error
states, loading skeletons, success banner, information card, cart summary card, status badge, price row,
filter chip, variation/option selectors, bottom action bar, module icon/card) are **unused but reserved** as
generic foundation for upcoming modules (Parcel / Rental / Short Apartment Rental) — **keep, do not delete.**
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
