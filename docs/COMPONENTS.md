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
| `ProductCard` | `product_card.dart` | Item card: image, name, price/old price, rating, discount, favourite, add button |
| `RestaurantCard` | `restaurant_card.dart` | Store/provider card: banner, logo, name, rating, delivery time, distance |
| `PromotionBanner` | `promotion_banner.dart` | Offer card (title/subtitle/image) for carousels |
| `StatusBadge` | `status_badge.dart` | Pill for statuses/tags (In Stock, Non-Veg, order status, rating) — filled or tinted |
| `PriceRow` / `PriceView` | `price_row.dart` | Bill line (label+value, total/discount variants) / inline price with strikethrough old price |
| `QuantityStepper` | `quantity_stepper.dart` | − n + control |
| `MoonjoinFilterChip` / `FilterChipBar` | `filter_chip_widget.dart` | Selectable pill / horizontal chip row |
| `VariationSelector` | `variation_selector.dart` | Chip toggles for grocery variations (Size/Type) |
| `OptionGroupSelector` (`OptionItem`) | `option_group_selector.dart` | Food radio-card / checkbox-card option groups with Required/Optional tag |
| `BottomActionBar` | `bottom_action_bar.dart` | Pinned footer surface (card bg, top shadow, safe area) |
| `FloatingCheckoutBar` | `floating_checkout_bar.dart` | Details footer: Total + `QuantityStepper` + Add To Cart (composes `BottomActionBar`) |
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
