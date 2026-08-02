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
| `MoonjoinCommerceActionBar` | `moonjoin/moonjoin_commerce_action_bar.dart` | **Official MoonJoin Commerce Bottom Action Container** — summary line + primary action; composes `BottomActionBar` (single safe-area, no duplicate chrome). Reuse across Checkout/Parcel/Wallet/Booking/Subscription |
| `MoonjoinCommerceHeader` | `moonjoin/moonjoin_commerce_header.dart` | Shared flat green commerce header (Cart + Checkout) — back + title + optional subtitle/trailing |
| `DeliveryManTips` | `moonjoin/delivery_man_tips.dart` | **Single MoonJoin Delivery Man Tips UI** (Checkout + Parcel Request) — dynamic tip options + Not Now + custom + save-for-later; presentation only, controller wired via callbacks |
| `DeliveryManTipsConfig` | `helper/delivery_man_tips_config.dart` | Tip resolver — Zone → Global (`dm_default_tips`) → temporary fallback [100,200,300,400]; feeds `AppConstants.tips` (now a dynamic getter) |
| `MoonJoinStatusAnimation` | `moonjoin/motion/moonjoin_status_animation.dart` | **THE MoonJoin status motion** — `MoonJoinStatusAnimation({state, size, play})`. The Moon + Node + Arc-Light system; single renderer for every animated status (order/trip/parcel/payment/wallet/verification/reward). No spinners, no GIF, no Lottie |
| `MoonJoinMotion` / `MoonJoinMoonSpec` / `MoonJoinMotionPalette` | `moonjoin/motion/moonjoin_motion.dart` | Motion model: 20 states → moon spec (phase/tone/node/accents), `forOrderStatus()` mapping, theme palette (moonlight + approved unavailable amber/red) |
| `MoonJoinMoonPainter` | `moonjoin/motion/moonjoin_motion_painters.dart` | Flutter-native moon renderer + Arc-Light choreography (Node→trace rim→resolve→settle). Internal to the widget |
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

**Both screens also serve as the Cart Item EDIT surface (FROZEN 2026-08-01).** Mobile "Your Cart" item tap → `ItemController.navigateToCartItemEdit(item, cart:)` → the same `FoodDetailsScreen`/`ItemDetailsScreen` in edit mode (preloaded via `getItemDetails(cart:)`; updates the existing line in place via `ItemCartHelper.addOrUpdateCart` → `CartController.updateCartOnline`; no duplicate). `ItemDetailsScreen` gained an additive optional `cart` param. The legacy `ItemBottomSheet` is now **desktop-only** (desktop Add + desktop Cart edit). Never reintroduce the mobile `ItemBottomSheet` edit surface; never create a third Product Details.

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
| 10b | **Parcel Screen 3** (Parcel Request) | `features/parcel/screens/parcel_request_screen.dart` |
| 11 | **Rental Provider Details** (`VendorDetailScreen`) | `features/rental_module/vendor/screens/vendor_detail_screen.dart` |
| 12 | **`RentalProviderHeroHeader`** (Store-hero clone for rental) | `features/rental_module/vendor/widgets/rental_provider_hero_header.dart` |
| 13 | **MoonJoin Notification System** (façade + catalog) | `common/widgets/moonjoin/notifications/moonjoin_notifications.dart` (`MoonJoinNotifications`) · doc `docs/MOONJOIN_NOTIFICATION_SYSTEM.md` |
| 14 | **Chat Thread** (message screen, B1 header + B2 bubbles + keyboard fix) | `features/chat/screens/chat_screen.dart` + `features/chat/widgets/message_bubble_widget.dart` |
| 15 | **Category Items** (Storefront Browse, **B1 + B2 + B3 — FULLY FROZEN**) | `features/category/screens/category_item_screen.dart` |
| 16 | **MoonJoin Sub-Category Component** (`MoonjoinSubCategoryBar`) — single source of truth for category sub-category chips | `common/widgets/moonjoin/moonjoin_sub_category_bar.dart` |

Together these form the **official MoonJoin reusable storefront foundation**. No future redesign should
recreate them; reuse them unchanged.

## MoonJoin Sub-Category Component (`MoonjoinSubCategoryBar`) — FROZEN (2026-07-31)

**THE single source of truth for category-navigation sub-category chips.** `MoonjoinSubCategoryBar`
(`common/widgets/moonjoin/moonjoin_sub_category_bar.dart`) — a horizontal scrolling row of `MoonjoinFilterChip`
for category sub-categories (Category Items: All/Red Meat/Poultry…; Restaurant categories; Grocery categories).
API: `MoonjoinSubCategoryBar({required labels, required selectedIndex, onSelected})`. Frozen render: `SizedBox(52)`
→ horizontal `ListView` (h-padding only) → `Center` → `MoonjoinFilterChip`. Analyzer Verified · Runtime Verified
(owner physical iPhone) · Owner Approved. **No duplicate sub-category implementations allowed; no screen may
implement its own sub-category chip style; all future category sub-category navigation MUST reuse this component
exactly.** **NOT** for Home/module filter/sort/action chips (Filter · Sort · Fast Delivery · Free Delivery ·
Rating · Offers · Discount · Nearby) — those are separate and untouched; the unused generic `FilterChipBar` is a
separate concern, left untouched. **Consumers:** `category_item_screen.dart` (mobile) · `store_screen.dart` (mobile
store/restaurant category strip — Food/Grocery/Pharmacy/Ecommerce; migrated & physical-iPhone verified 2026-07-31,
`categoryList`/`categoryIndex`/`setCategoryIndex` preserved, desktop untouched). Any new category-navigation
sub-category area MUST reuse this component — no duplicate implementations.

## Storefront Browse → Category Items — B1 header + B2 segmented control + B3 sub-category component — FULLY FROZEN (2026-07-31)

**`category_item_screen.dart` B1 (mobile header) + B2 (Item/Stores segmented control) are FROZEN** (Analyzer
Verified · Runtime Verified on owner's physical iPhone · Owner Approved). **B1:** mobile legacy `AppBar` → frozen
**`ProfilePageHeader`** (category name + back + **cart** in trailing); **search relocated** into the frozen
**`MoonjoinSearchBar`** (drives existing `searchData`/`toggleSearch` verbatim); **`VegFilterWidget` reused
unchanged**. **B2:** mobile Item/Stores legacy `TabBar` → the **frozen Favorites segmented pill** (single source of
truth — soft-green track, green selected segment, white label; same `_tabController` + tabs + `storesOnly` gate;
styling only). Desktop `WebMenuBar`/TabBar untouched. **No duplicate systems** (reused ProfilePageHeader +
MoonjoinSearchBar + Favorites pill). **B3:** mobile sub-category chips → the frozen **`MoonjoinSubCategoryBar`**
component (single source of truth; see above). **Untouched:** `ItemsView`, `MoonjoinStoreCard`, `ItemWidget`,
`NoDataScreen`, Product Details, `CategoryController`, `TabController` + `NotificationListener` reload +
`setRestaurant`, pagination, `searchData`/`toggleSearch`/`setSubCategoryIndex`, cart, routes, models, desktop.
**Screen status: FULLY FROZEN** (B1+B2+B3 owner-approved). Do not modify without owner approval; sub-category chips
come from `MoonjoinSubCategoryBar` only.

## Chat Thread (message screen) — FROZEN (Phase B, 2026-07-30)

**Chat Thread uses isolated conversation-owned draft state. Global draft sharing is forbidden.**

**The Chat Thread presentation migration is COMPLETE and FROZEN**, closing the Chat cluster (Conversation List
frozen 8E). B1 = mobile header → frozen **`ProfilePageHeader`** (receiver name + avatar), desktop `WebMenuBar`
preserved. B2 = `MessageBubbleWidget` retokenized (sent = medium brand-green `primaryColor` + white text;
received = neutral `disabledColor@12%` token; in-thread order status → **`StatusBadge`**; removed hardcoded
`#E8EEFA`/`deepPurple`, dark-mode safe). Keyboard fix = dedicated `_inputFocusNode` with iOS-only post-frame
`requestFocus` after the image picker (composer stays above the keyboard; `resizeToAvoidBottomInset` untouched).
**Permanent rule: per-conversation draft ownership — one conversation = one isolated draft state; global/shared
draft state is FORBIDDEN.** Each conversation owns its own text + image draft, keyed by the chat route's
`conversationID` (`ChatController._textDrafts`/`_imageDrafts`/`_rawImageDrafts` + `loadConversationDraft`/
`saveConversationDraft`; restored on `initState`, saved on `dispose`; sending clears only that conversation). The
rejected global `typedDraft` (leaked Vendor→Admin→Store) must never return. Preserved: ChatController send/receive
logic, upload/compression, attachments, pagination, Pusher, read status, APIs, models, routing, notification flow.
**Do not polish, tweak, or refactor without owner approval; never reintroduce a shared draft.**

## MoonJoin Notification System — FROZEN (Phase A1, 2026-07-30)

**THE single notification language for MoonJoin.** `MoonJoinNotifications`
(`common/widgets/moonjoin/notifications/moonjoin_notifications.dart`) is a **thin façade that orchestrates the
existing frozen primitives** — it creates **no new UI** and holds **no business logic** (callbacks only). Import
via the barrel `moonjoin_components.dart`. **Any feature that must tell the user something calls this façade and
picks a category — never a bespoke dialog/sheet/banner/toast.** Full standard: `docs/MOONJOIN_NOTIFICATION_SYSTEM.md`.

| Category | Façade method | Renders via (existing primitive) |
|---|---|---|
| **Success** (order placed, payment successful) | `success()` / `successBlock()` | `SuccessBanner` |
| **Information** (updates, progress) | `infoCard()` / `statusBadge()` | `InformationCard` / `StatusBadge` |
| **Warning** (attention required) | `warningSheet()` | `MoonjoinBottomSheet` + `InformationCard` (+ `MoonjoinButton`) |
| **Error** (payment/order failed) | `error()` / `confirm()` | `MoonjoinDialog` / `ConfirmationDialog(moonjoin:true)` |
| **Transient** (saved, updated) | `transient()` | `showCustomSnackBar` — the ONE toast |
| Page states (error/empty) | `errorState()` / `emptyState()` | `MoonjoinErrorState` / `MoonjoinEmptyState` |

**Rules:** reuse — never fork; extend the catalog (add a primitive to `moonjoin/` + map it here) rather than a
one-off in a feature; **AI/vendor/delivery/admin/customer messages must all use this system — AI must never build
its own notification UI**. **Protected (untouched by A1):** the frozen order-communication surfaces (Home
`_UnavailableItemsCard`, `order_edit_screen.dart`, `running_order_view_widget.dart`) and all order/cart
controllers. A2 (running-order polish) / A3 (unavailable-preference sheet) are separate future decisions.

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

## Parcel (Package Delivery) components — MODULE FROZEN (2026-07-30)

**The Parcel Module is COMPLETE and FROZEN — Implemented · Analyzer Clean · Runtime Verified · Owner Approved.**
All three screens are migrated; there is **no remaining legacy UI**. Do not redesign, refactor Parcel widgets,
replace components, or open another Parcel improvement cycle — reuse only.

Parcel is redesigned from `ui-designs/Parcel/`. Screen 1 (Parcel Home/Category), Screen 2 (Parcel Location)
and Screen 3 (Parcel Request) are all **FROZEN**. Screens 1 & 2 reuse the frozen **`WavyHeader`** for their
green headers (Screen 1 header: `parcel/widgets/parcel_app_bar_widget.dart`; Screen 2 header inline in
`parcel_location_screen.dart` with a 2-step indicator), the shared `CartController` cart-count, and shared
routes. Screen 2 also reuses shared `CustomCard` / `CustomTextField` (prefixIcon) / `CustomButton` and the
existing `ParcelViewWidget` + `SavedAddressBottomSheet`. Screen 3 (Parcel Request — **freeze approved**) is the
parcel checkout: it reuses the white `CustomAppBar` (the approved `parcel_request.PNG` header) + shared
`CardWidget`, `TripFromToCard`, `TipsWidget`, `CheckoutCondition`, `CustomButton`, and parcel `DetailsWidget`
(restyled with a leading avatar).

**Permanent Parcel rules:** reuse the **shared Payment architecture**; reuse shared MoonJoin components; **never
create duplicate Parcel-specific components when a platform component already exists**; all future Parcel
features **extend the frozen foundation** — never a second redesign.

**Parcel payment = the shared payment architecture.** Screen 3 now uses the **shared `PaymentSection`** card +
`PaymentMethodBottomSheet` (the same one used by Food/Grocery/Pharmacy/Ecommerce), driven by
`CheckoutController` and synced into `ParcelController` at confirm-time — one shared "Choose Payment Method"
implementation across every module. Delivery Man Tips uses the shared `TipsWidget` chip; the tips-section
height overflow was fixed in the shared `deliveryman_tips_section.dart`.

**Package Protection — Frontend preparation exists · Backend configuration dependency PENDING · NOT a UI migration blocker.** Future implementation must **extend the existing Parcel architecture** (no redesign, no new total/order/payment system). New
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
duplicate headers. First consumer: Personal Information. **Registration-flow consumers (FROZEN 2026-08-01):**
`delivery_man_registration_screen.dart` (Account → Menu → Earnings → Join as a Delivery Man) and
`store_registration_screen.dart` (Account → Menu → Earnings → Open Vendor) — both mobile legacy `CustomAppBar`
→ `ProfilePageHeader` (presentation-only; back preserves each screen's exact step-back logic via `onBack`;
desktop keeps `CustomAppBar` + `webView`). These registration pages now belong to the Account/Menu design family.

### 🧊 Personal Information (Edit Profile) — `update_profile_screen.dart` (FROZEN 2026-07-24)
Presentation-only redesign to the MoonJoin language. Mobile `_mobileView` + desktop `webView()`. Reuses
`ProfilePageHeader`, `CustomTextField` ×3, `CustomButton`, frozen `ProfileButtonWidget` (Change Password),
`CustomPopupMenuButton`+`ConfirmationDialog`+`deleteUser`, existing `pickImage()`. Controllers / repository /
service / API `/customer/update-profile` / validation / image-upload / verification flows / navigation all
preserved. QA fixes: title-behind-avatar (header height), un-tappable camera badge (avatar moved inside Stack
bounds). Web desktop verification pending (non-blocking). Obsolete `ProfileBgWidget` retained for cleanup.

### 🧊 My Address (list) — `address_screen.dart` (FROZEN 2026-07-24, Phase 3)
Presentation-only redesign of the My Address **list screen** to the MoonJoin language. Mobile: green
`ProfilePageHeader` + `RefreshIndicator` list of `AddressWidget` cards + bottom `CustomButton` "Add New
Address". Desktop: grid preserved (city bg removed; `WebMenuBar`). Reuses `ProfilePageHeader`, shared
`AddressWidget`, `CustomButton`, `AddressConfirmDialogue`, `NoDataScreen`, `AddressController`. All business
logic (controller/repo/service/APIs/models/validation/Google Maps/geocoding/zone) preserved. Add/Edit/Map =
separate future phase, untouched.

### `AddressWidget` — the single shared Address card (list variant modernized, FROZEN 2026-07-24)
`lib/common/widgets/address_widget.dart` — ONE shared address card with three context branches:
`fromAddress` (My Address list — **modernized to MoonJoin, frozen**), `fromCheckout` (Checkout, MoonJoin,
unchanged), `fromDashBoard` (Dashboard selection, unchanged). No duplicate address card exists. Only the
`fromAddress` branch was touched this phase; Checkout/Dashboard render identically. Reused by Address list,
Checkout, Dashboard, Home, Parcel, Location screens (all `fromAddress:false` except the list).

### 🧊 Coupon (list) — `coupon_screen.dart` (FROZEN 2026-07-24, Phase 4)
Presentation-only redesign of the Coupon **list** to MoonJoin. Mobile: green `ProfilePageHeader` +
`RefreshIndicator` grid of MoonJoin coupon cards. Desktop: grid kept, `WebMenuBar`. Reuses `ProfilePageHeader`,
shared `CouponCardWidget` (list variant), `NoDataScreen`, existing copy/tooltip. All logic
(controller/repo/service/API `/coupon/list`/model/clipboard/tooltip/refresh) preserved.

### `CouponCardWidget` — single shared coupon card (list variant modernized, FROZEN 2026-07-24)
`lib/features/coupon/widgets/coupon_card_widget.dart` — ONE shared coupon card with a presentation-only
`fromCouponScreen` flag. `true` = MoonJoin `_moonjoinCard` (My Coupons list, frozen); `false` (default) =
legacy card used by the **Checkout coupon bottom sheet** (unchanged). No duplicate/fork. Only the list variant
was touched this phase; Checkout renders identically (owner-verified).

### 🧊 Loyalty Points — `loyalty_screen.dart` (FROZEN 2026-07-25, Phase 5)
Presentation-only redesign to MoonJoin. Mobile: `ProfilePageHeader` (onBack keeps fromNotification) + green
points card + MoonJoin history + bottom `CustomButton` convert. Desktop: 2-column + `WebMenuBar`. Reuses
`ProfilePageHeader`, `CustomButton`, `CustomTextField`, `NoDataScreen`, `WalletShimmer`, shared
`HistoryItemWidget` (loyalty variant). `LoyaltyCardWidget`/`LoyaltyStepper`/`LoyaltyBottomSheetWidget`
redesigned (loyalty-only). All logic (controller pagination + pointToWallet / repo / service / APIs / model /
validation / exchange / refresh / navigation) preserved.

### `HistoryItemWidget` — single shared transaction row (loyalty variant modernized, FROZEN 2026-07-25)
`lib/common/widgets/history_item_widget.dart` — ONE shared row with a presentation-only `moonjoinLoyalty`
flag. `true` = MoonJoin loyalty row (Loyalty history, frozen); `false` (default) = legacy row used by **Wallet
history** (`fromWallet:true`, unchanged). No duplicate/fork. Only the loyalty variant touched this phase;
Wallet renders identically (owner-verified).

### `ProfilePageHeader` — additive `onBack` (Phase 5)
Added optional `onBack` (defaults to `Get.back()`); enables pages with custom back logic (e.g. notification
deep-links) to reuse the shared header without forking. All prior callers unchanged.

### 🧊 Refer & Earn — `refer_and_earn_screen.dart` (FROZEN 2026-07-25, Phase 6)
Presentation-only redesign to MoonJoin. Mobile: `ProfilePageHeader` (info icon in `trailing` →
`BottomSheetForMobile`) + illustration + MoonJoin reward card (green rate chip · green dashed code box + green
Copy · Share `CustomButton`). Desktop: `WebMenuBar` + inline `BottomSheetViewWidget`. Reuses `ProfilePageHeader`,
`CustomButton`, `ProfileController.refCode`, `SharePlus`, `Clipboard`, both info widgets — no new/duplicate
components. Business logic preserved: refCode source, exact SharePlus text (app name + code + download link),
Clipboard + snackbar, exchange-rate display, auth, navigation. No controller/API/model/validation changes.
`ExpandableBottomSheet` usage on this page → OBSOLETE — Pending Final Legacy Cleanup (package still used
elsewhere; nothing deleted).

### 🧊 My Wallet + Wallet History — `wallet_screen.dart` (FROZEN 2026-07-25, Phase 7)
Presentation-only redesign to MoonJoin. `ProfilePageHeader` + premium fintech balance card + MoonJoin history
+ filter chip + premium Add Fund dialog ("9PSB Virtual Account" label; amount hidden for VA / shown for online
gateways). Reuses `ProfilePageHeader`, `CustomButton`, `CustomTextField`, `NoDataScreen`, `WalletShimmer`,
shared `HistoryItemWidget` (wallet variant), frozen `VirtualAccountDetailsWidget`. All wallet logic
(controller/repo/service/APIs/models/validation/add-fund/payment/idempotency/pagination/filters) preserved.

### `HistoryItemWidget` — variant map complete (FROZEN wallet variant 2026-07-25)
ONE shared transaction row. Variants: `default` (legacy, retained for cleanup) · `moonjoinLoyalty:true`
(Loyalty, frozen Phase 5) · `moonjoinWallet:true` (Wallet, frozen Phase 7). Isolated, no duplication.

### `VirtualAccountDetailsWidget` — Phase 7 improvements (FOUNDATION, still frozen)
scaleDown values (full account number, no truncation) + premium inline "Copied" fade (`_CopyButton`, no
snackbar; clipboard unchanged). Applies to all reuse sites (Checkout, Profile ×3, Wallet). Single approved
Virtual Account UI — unchanged elsewhere.

### 🧊 Notifications — `notification_screen.dart` (FROZEN 2026-07-25, Phase 8A)
Presentation-only redesign to MoonJoin. `ProfilePageHeader` (mobile, onBack keeps fromNotification) /
`WebMenuBar` (desktop) + MoonJoin notification cards. Reuses `ProfilePageHeader`, `NoDataScreen`,
`CustomImage`, `CustomAssetImageWidget`, `FooterView`, `WebScreenTitleWidget`. All notification logic
(NotificationController / NotificationService / `/customer/notifications` / NotificationModel / local unread
tracking / sorting / refresh / detail sheet+dialog / navigation) preserved.

**Notification card component (`_notificationCard`) — unread/read states:** one card style with a green
type-icon chip · title · 2-line body · time · optional push image.
- **Unread** (id NOT in local `notificationIdList`): green unread **dot** + bold title + soft green-tint
  background + green border + soft shadow.
- **Read** (id in list after tap → `addSeenNotificationId`): flat card, muted title/body, no dot.
Unread state is derived ONLY from the existing local id-list — no backend unread field/logic added.

### 🧊 Help & Support — `support_screen.dart` (FROZEN 2026-07-25, Phase 8B)
Presentation-only redesign to MoonJoin. `ProfilePageHeader` (mobile) / `WebMenuBar` (desktop) + support hero +
MoonJoin **contact cards** (`_contactCard`: brand-green icon chip · title · info · chevron) for Email/Call/
Address. Reuses `ProfilePageHeader`, `FooterView`, `WebMenuBar`. Preserves SplashController config values +
tel:/mailto: launches (email made robust: canLaunch + externalApplication + fallback). No API/controller/model
changes; no FAQ/ticket/support-API added. `support_button_widget.dart` = OBSOLETE — Pending Final Legacy
Cleanup (superseded; not deleted).

### 🧊 HTML Container — `html_viewer_screen.dart` (FROZEN 2026-07-25, Phase 8C)
ONE reusable MoonJoin HTML container. Presentation-only: `ProfilePageHeader` (mobile, title per HtmlType) /
`WebMenuBar` (desktop) + server HTML (`HtmlWidget`) wrapped in a MoonJoin card; loading spinner + `NoDataScreen`
empty state. **A single screen serves ALL HTML pages** — About Us, Terms & Conditions, Privacy Policy, Refund
Policy, Shipping Policy, Cancellation Policy (+ any future HtmlType) — no per-page widget, no duplication.
Reused foundations: `ProfilePageHeader`, `WebMenuBar`, `FooterView`, `MenuDrawer`, `WebScreenTitleWidget`,
`NoDataScreen`. Preserved: HtmlController / HtmlService / HTML content API / renderer / navigation.

### 🧊 Logout confirmation — `ConfirmationDialog` MoonJoin variant (FROZEN 2026-07-25, Phase 8D)
`lib/common/widgets/confirmation_dialog.dart` — added an isolated presentation-only `moonjoin` flag (default
false). `true` → `_moonjoinDialog` (premium card, red logout icon chip, "Logout" heading, Cancel + green
primary "Logout"). Used ONLY by the logout call in `menu_screen.dart`. The other 20 call sites keep the legacy
dialog. No duplicate dialog; callbacks/behaviour identical (green Logout → onYesPressed cleanup; Cancel →
Get.back). Reuses `CustomButton`.

### 🧊 Guest Foundation — `NotLoggedInScreen` (FROZEN 2026-07-26, Phase 9B)
`lib/common/widgets/not_logged_in_screen.dart` — THE single, permanent **MoonJoin Guest Foundation**: ONE shared
not-logged-in guard rendered by ALL ~14 protected surfaces (Wallet, Coupon, My Address, Loyalty, Refer & Earn,
Notifications, Chat, Edit Profile, Checkout, Parcel, rental favourite, …). Redesigned **in place — Option A, one
shared implementation, NO isolated variants**; one change updates every guest prompt app-wide. Layout: soft-green
MoonJoin halo (168px, `primaryColor` @ 8% alpha) around `Images.guest` (110px) → bold `you_are_not_logged_in` →
hint `please_login_to_continue` → green `CustomButton` "login" (width 240, `radiusLarge`, `Icons.login_rounded`);
`Dimensions.*` tokens (no MediaQuery fractions); `SingleChildScrollView + FooterView` host wrapper kept. **No
secondary CTA.** Reuses `CustomButton`, `FooterView`, `Images.guest`, existing i18n keys. **Protected shared
foundation** — future changes MUST preserve the callback contract (`callBack(bool)`), navigation contract, desktop
dialog flow, and mobile login flow; no variants, no business-logic changes. Login `onPressed` preserved verbatim
(mobile `getSignInRoute(Get.currentRoute)` · desktop `AuthDialogWidget` · `OrderController.showRunningOrders()` ·
`callBack(true)` return-refresh); `AuthController`/session/token/Firebase/OTP/guest+social login/`RouteHelper`/
navigation/repos/APIs/models/services all untouched. `flutter analyze` clean; guest Wallet + My Address verified.

### 🧊 Auth Foundation — `lib/features/auth/widgets/foundation/` (FROZEN 2026-07-27, Phase 9C-1)
THE 10 canonical, additive, pure-presentation MoonJoin authentication components — the single visual language for
ALL auth surfaces (Sign In, Sign Up, OTP/Verification, Forgot/Reset Password, New User Setup, desktop
`AuthDialogWidget`). Barrel: `auth_foundation.dart`. Isolated demo (`auth_foundation_demo_main.dart`) runs ONLY via
`flutter run -t …`; never wired to production.
- **`AuthScaffold`** — one shell for both hosts (mobile full-screen / desktop dialog-body via `isDialog`); full-bleed hero + floating overlapping card; renders back/close affordance but never creates `Dialog()`/navigates (host owns that).
- **`AuthHero`** — full-bleed green hero (~36% h, 48px curved bottom) + softly breathing haloed logo (`logoAssetPath` default `Images.logo`, `logoCornerRadius` default 14 clips square/opaque logos; transparent unaffected) + title + subtitle (no `.tr` inside).
- **`AuthHeader`** — titled bar for verification/forgot/new-pass (auth-scoped `CustomAppBar` replacement; plain widget).
- **`AuthCard`** — floating surface, fixed `radiusExtraLarge` + soft shadow; only padding/margin/width configurable.
- **`AuthInputGroup`** — wraps caller's `CustomTextField`s (owns no controller/validator); `crossAxisAlignment`.
- **`AuthOtpField`** — theme-only wrapper over `PinCodeTextField`; `autoFocus`; behavior untouched.
- **`AuthSocialButton`** — provider-blind pill (icon/label/onTap/`fullWidth`); supersedes legacy `SocialLoginButton` (staged migration).
- **`AuthDivider`** — "or"/"or continue with"; caller supplies label.
- **`AuthFooter`** — cross-link row; `enabled` visual-only, never routes.
- **`AuthPrimaryButton`** — thin preset over frozen `CustomButton` (green, `radiusLarge`, default height 54); loading text stays CustomButton's.
All pure-presentation: no controllers/nav/validation/API/SDK/`Get.find`; theme via `Theme.of(context)`, spacing via
`Dimensions.*`, no hardcoded hex. `flutter analyze` = 0 issues. **MANDATE:** all auth surfaces reuse these; no
alternate auth shell/hero/card/social widgets. **Do not change any component's visuals/structure/animation/spacing/
typography/API without an explicit owner revision request.** Config-driven login gating (`centralizeLoginSetup` via
`CentralizeLoginHelper`) stays in `SignInView`; wired to this foundation in Phase 9C-2 (FROZEN below).
**REJECTED (never recreate):** the experimental Earth/network/world header (`AuthHeroWorld`) was explored and fully
removed 2026-07-27 — the plain premium green `AuthHero` is the permanent hero. Do not recreate the globe/network
header unless the owner explicitly requests it.

### 🧊 Sign In — `sign_in_screen.dart` (+ SignInView/Manual/OTP/Social) (FROZEN 2026-07-27, Phase 9C-2)
Presentation-only migration of the mobile Sign In to the **frozen Auth Foundation**: `AuthScaffold(hero: AuthHero,
child: AuthCard(SignInView))`. `ManualLoginWidget` + `OtpLoginWidget` composed from foundation (`AuthPrimaryButton`/
`AuthFooter`; welcome heading now in `AuthHero`); `SocialLoginWidget` → `AuthDivider` + horizontal `AuthSocialButton`
pills (Google·Apple·Facebook). **Manual Login Persistence (owner-approved):** auto-fill last email/phone only, NEVER
store password, no "Remember me" checkbox anywhere, auto-focus password on reopen (else email/phone), biometric =
future extension. Preserved: `AuthController`/`LocationController`/Firebase/Google-Apple-Facebook SDK/`ExistingUserBottomSheet`/
`SignInView` config switch (`CentralizeLoginHelper`, 7 layouts, never hardcoded)/`PopScope`/`getSignInRoute`/return-after-login.
QA bug fixed: `setState() after dispose()` from delayed auto-focus → `if(!mounted) return`. Real-app verified; analyze clean.
`SocialLoginButton` (in `login_suggestion_bottomsheet.dart`) superseded by `AuthSocialButton` on Sign In → OBSOLETE-candidate
(still used by the login-suggestion sheet; retained).
**AuthHero owner revision (2026-07-27):** the logo now fills the white disc 100% (`Image.asset(fit: BoxFit.cover)` in a
fixed circular disc, `clipBehavior: antiAlias`; `logoCornerRadius` retained but unused). Applies to Sign In + Sign Up.
`logo.png` must be lowercase `.png` (iOS case-sensitive).

### 🧊 Search (Context-Aware Scoped Search) — `search_screen.dart` + scope components (FROZEN 2026-07-30)
Presentation completion + **Context-Aware Scoped Search architecture** (permanent platform standard, `docs/MOONJOIN_SEARCH_ARCHITECTURE.md`).
**Application Context (`SplashController.module`) and Search Scope are independent** — Search Scope is applied ONLY via a per-request
`moduleId` header override (`search_repository._getSearchData` clones `apiClient.getHeader()`); Search NEVER changes
`setModule`/`cacheModule`/`SplashController.module`/`ApiClient._mainHeaders`. Resolution: in-module→current · session · last-used ·
else Module Scope Sheet (no "Module ID Required", never moduleList[0]; voice+search scope-gated). Presentation (reuse-only): results
Items/Stores → **frozen Favorites segmented pill**; Recent Searches → MoonJoin chips; Popular → `MoonjoinFilterChip`; Suggestions →
MoonJoin cards; scope pill `MoonJoinScopeSelector`. Preserved: `_searchHeroHeader`/`MoonjoinSearchBar`/`SearchResultWidget`/`ItemsView`/
frozen cards/`SearchFieldWidget` logic/`BottomCartWidget`/all SearchController search-history-suggestions-filters-pagination-voice/routes/
APIs/models. analyze clean; runtime verified (simulator, back-nav independence proven).
**NEW frozen reusable platform components (reuse, NEVER fork):**
- **`SearchScope`** (`features/search/domain/models/search_scope.dart`) — scope abstraction; not hardcoded to `ModuleModel` (future
  types 🌍AllModules/📍Nearby/❤️Favorites/🔥Trending/🏷Promotions/🤖AISearch add without redesign).
- **`MoonJoinScopeSelector`** (`common/widgets/moonjoin/scope_selector.dart`) — reusable DS scope pill (Search/AI/Notifications/Offers/
  Coupons/Analytics/future Global Search). **Never create another scope selector.**
- **`SearchScopeSheet`** (`features/search/widgets/search_scope_sheet.dart`) — Module Scope Sheet, reuses `MoonjoinBottomSheet` +
  `OrganicModuleIcon`. **Never create another Search module-selection sheet.**
**The frozen Favorites segmented pill is the single source of truth for EVERY Items/Stores segmented control across MoonJoin.**

### 🧊 Favorites — `favourite_screen.dart` (FROZEN 2026-07-29)
Presentation-only mobile redesign of the Favorites bottom-nav tab to the MoonJoin Premium Design System; **desktop preserved
legacy** (mobile-first). Mobile → premium green `ProfilePageHeader` ("Favourite", showBack:false) + a **MoonJoin segmented pill**
(Items / Stores·Restaurants) built by restyling the existing `TabBar` (rounded green selected segment on a soft-green primary@8%
track, `TabBarIndicatorSize.tab`, transparent divider) + the frozen `FavItemViewWidget → ItemsView` body. Reuses `ProfilePageHeader`,
`ItemsView` (frozen `MoonjoinStoreCard`/`ItemWidget`/`NoDataScreen`), `NotLoggedInScreen` (Guest Foundation). Preserved: `TabController`
(len 2, idx 0, NeverScrollable) / `TabBarView` semantics / `showRestaurantText` label / `getFavouriteList` on login / guest-guard
callback / pull-to-refresh / favourite toggle. No FavouriteController/SplashController/API/model/route/ItemsView change; no new i18n
keys. analyze clean; runtime verified on simulator (both segments, owner-approved). **Pattern:** for a bottom-nav tab needing tabs,
reuse `ProfilePageHeader(showBack:false)` + a restyled-`TabBar` segmented pill (keeps TabController wiring 1:1).

### 🧊 Address Experience — `add_address_screen.dart` + `pick_map_screen.dart` (FROZEN 2026-07-28, Physical-Device Verified)
Presentation-only mobile redesign of Add/Edit Address + Google Maps Pick Map to the MoonJoin Premium Design System;
**desktop preserved legacy** (mobile-first). Add/Edit form → `ProfilePageHeader` + premium floating map card (rounded/shadow,
floating pin w/ `IgnorePointer`, current-location FAB, fullscreen) + grouped `SectionHeader` cards (Delivery Address → Contact
Information → Address Details) + `MoonjoinFilterChip` types (Home/Office/Other) + pinned `BottomActionBar`. Pick Map → Uber/
Glovo-style full-screen picker (search+back, floating pin, current-location FAB, bottom address + zone-aware action). Preserved:
LocationController (getCurrentLocation/updatePosition/getZone/setUpdateAddress/setPickData + all map callbacks)/AddressController/
manual validation (no `Form`)/geocode/zone/permission/`Get.arguments`/all variants (fromCheckout/fromRide/forGuest/fromNavBar,
Add vs Edit). No controller/API/route/model/logic change; 2 i18n keys added (address_details, move_the_map_to_select).
**Device-QA regressions fixed (presentation only):** (1) full-cover loading Container swallowed map taps → removed + pin
IgnorePointer; (2) Pick Map onMapCreated guard/`fromLandingPage` restored to legacy; (3) Edit auto-load hang → removed the
`GlobalKey`s (they blocked the map recreation legacy used for a 2nd onCameraIdle that overcomes updatePosition's first-call
no-op) + seeded `_cameraPosition`. analyze clean; **runtime verified on physical iPhone (Add + Edit auto-load, no manual tap).**
**iOS Simulator is Google-Maps-limited (camera never settles) — not authoritative. Never re-add a GlobalKey to these maps or a
hit-testable full-cover overlay.**

### 🧊 New User Setup — `new_user_setup_screen.dart` (FROZEN 2026-07-28, Phase 9C-7)
Presentation-only migration of mobile New User Setup to the **frozen Auth Foundation**: `build` split into `_mobileBody`
(foundation) + `_desktopBody` (legacy preserved). Mobile → `AuthScaffold(onBack: Get.back, hero: AuthHero('just_one_step_away'),
child: AuthCard(Form(_formKeyInfo) → AuthInputGroup(Name + [Phone if social | Email if OTP] + Refer-code if refEarningStatus==1)
+ AuthPrimaryButton('done')))`. Mobile drops legacy logo/text for the shared hero; desktop keeps them. Preserved: `_formKeyInfo`
validation · `_isSocial`(`CentralizeLoginType.social`) branch + social name pre-fill · `widget.phone`-empty phone validation
(`CustomValidator.isPhoneValid`) · `_updatePersonalInfo`→`AuthController.updatePersonalInfo`→`navigateToLocationScreen` · refer-code
gate. No controller/API/route/validator/Firebase/OTP/OAuth/business-logic changes; no new i18n keys. analyze clean. Runtime =
verified-by-construction (same foundation as runtime-verified 9C-5/9C-6); fresh-onboarding trigger not reproduced (OTP block +
already-registered test account — infrastructure). **Social login (audit, unchanged, buttons in FROZEN social_login_widget.dart):
Google works · Apple fails = iOS config (applesignin entitlement missing from Debug/Release) · Facebook fails = Meta dashboard/
backend config. NOT frontend regressions → deferred to MoonJoin World Auth Hardening.**

### 🧊 Reset / New Password — `new_pass_screen.dart` (FROZEN 2026-07-28, Phase 9C-6)
Presentation-only migration of mobile Reset/New Password to the **frozen Auth Foundation**: `build` split into
`_mobileBody` (foundation) + `_desktopBody` (legacy preserved). Mobile → `AuthScaffold(onBack: Get.back, hero:
AuthHero(change_password | reset_password + enter_new_password subtitle), child: AuthCard(AuthInputGroup(New Password +
Confirm password) + AuthPrimaryButton))`. **Serves BOTH paths** via `fromPasswordChange`: **Change Password** (Profile →
Settings) and **Reset Password** (forgot-password OTP flow). Mobile drops legacy `Images.changePass` for the shared hero;
desktop keeps it; removed unused `custom_app_bar` import; **no `Form` added** (legacy manual validation kept verbatim).
Preserved: `_onPressedPasswordChange`/`_changeUserPassword`(`ProfileController.changePassword`)/`_resetUserPassword`
(`VerificationController.resetPassword` + `getSignInRoute`/`AuthDialogWidget` nav)/per-path `isLoading`. No controller/API/
route/validator/Firebase/OTP/business-logic changes. Real-app verified (Change Password path) on simulator; analyze clean.
Reset variant same widget/logic, preserved but not runtime-reachable (OTP/2Factor infrastructure block, not frontend).

### 🧊 Forgot Password — `forget_pass_screen.dart` (FROZEN 2026-07-28, Phase 9C-5)
Presentation-only migration of mobile Forgot Password to the **frozen Auth Foundation**: `build` split into
`_mobileBody` (foundation) + `_desktopBody` (legacy preserved). Mobile → `AuthScaffold(onBack: Get.back, hero:
AuthHero(forgot_your_password | sorry_something_went_wrong + subtitle), child: AuthCard(...))`. Both states preserved:
**request form** (`Form → AuthInputGroup(phone|email CustomTextField)` + `AuthPrimaryButton` "Request OTP" + "Or" +
`AuthFooter` "Back to Log In") and **channels-disabled fallback** (`AuthPrimaryButton` "Help & Support" + `AuthFooter`
"continue as guest"). Mobile drops the legacy `Images.forgot`/logo illustration for the shared hero; desktop keeps them;
removed unused `custom_app_bar` import. Preserved (verbatim): `_onPressedForgetPass` (phone validation/`forgetPassword`/
Firebase-vs-backend routing/`getVerificationRoute`)·`initState` config gating (`isSmsActive`/`firebaseOtpVerification`/
`isMailActive`)·validators·country picker. No controller/API/route/Firebase/OTP/business-logic changes. Real-app verified
on simulator; analyze clean (no new i18n keys). Fallback state preserved but not runtime-reproduced (needs SMS+email both
disabled in Admin); OTP delivery gated by the 9C-4 backend gateway (2Factor→+234), not this screen.

### 🧊 Sign Up — `sign_up_screen.dart` (+ `sign_up_widget.dart`) (FROZEN 2026-07-27, Phase 9C-3)
Presentation-only migration of mobile Sign Up to the **frozen Auth Foundation**: `AuthScaffold(hero: AuthHero(
create_your_moonjoin_account + subtitle), child: AuthCard(SignUpWidget))`; `SignUpWidget` mobile → `AuthPrimaryButton` +
`AuthFooter`; container width→`double.infinity` (fits AuthCard, no overflow). Desktop `_desktopBody`/`SignUpWidget` desktop
branch preserved. **UX consistency audit (Sign In ↔ Sign Up) passed** — hero/curve/breathing/logo-fill/card overlap/radius/
shadow/scroll/safe-area identical by shared foundation; aligned 4 mobile spacing drifts in Sign Up (top gap 10→0, button
surrounds 15→20, footer bottom 20→0). Preserved: `AuthController.registration`/`SignUpBodyModel`/all validation/
`ConditionCheckBoxWidget` terms gate/refer-code/verification routing/`getSignInRoute`. Real-app verified; analyze clean.

### 🧊 Live Chat — Conversation List — `conversation_screen.dart` (FROZEN 2026-07-26, Phase 8E)
Presentation-only redesign of the Conversation LIST to MoonJoin. `ProfilePageHeader` (mobile, showBack:
!fromNavBar) / `WebMenuBar` (desktop) + premium conversation cards (avatar w/ soft green ring · bold name ·
muted type · time · green unread badge, exact condition preserved) + `NoDataScreen` empty state. Reuses
`ProfilePageHeader`, `WebMenuBar`, `NoDataScreen`, `PaginatedListView`, `ChatSearchFieldWidget`, `CustomImage`,
`CustomInkWell`, `WebChatViewWidget`. All chat logic (ChatController/APIs/polling/pagination/search/unread/
send-message/image-attachment/getChatRoute/refresh/FAB) preserved. **Chat Thread (message screen) intentionally
untouched.** Card layout is generic (avatar·name·subtitle·time·unread) = official MoonJoin foundation for the
future MoonJoin World messaging platform; websocket/live-sync can plug in without a redesign.

### 🧊 Settings — `setting_page.dart` (FROZEN 2026-07-26, Phase 8G)
Presentation-only redesign to MoonJoin. `ProfilePageHeader` (mobile) / `WebMenuBar` (desktop); rows reuse the
FROZEN `ProfileButtonWidget` UNCHANGED (Language selector · Dark Mode · Notification [isLoggedIn-gated] ·
Version). Settings owns `LanguageBottomSheetWidget` (MoonJoin chrome; `LanguageCardWidget` reused unchanged;
Update logic preserved). `NotificationStatusChangeBottomSheet` gets an isolated `moonjoin` Settings-only
variant (default false → profile_screen + web_profile keep legacy). All logic (Localization/Theme/Auth
notification toggle + persistence) preserved.

### `NotificationStatusChangeBottomSheet` — isolated MoonJoin Settings variant (Phase 8G)
`lib/features/profile/widgets/notification_status_change_bottom_sheet.dart` — additive presentation-only
`moonjoin` flag (default false). `true` → MoonJoin sheet (icon chip · "Are you sure?" · Cancel + accent Confirm;
red=disable/green=enable). Callbacks unchanged (`setNotificationActive`/`notificationLoading`/`Get.back`). Only
Settings passes it; the other 2 call sites (profile_screen, web_profile_widget) stay legacy. Shared Widget
Protection enforced — no global change.
