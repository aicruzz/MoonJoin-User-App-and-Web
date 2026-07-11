# MoonJoin User App Design System

This document defines the official design language for the MoonJoin User App. It is derived from the UI
reference images in `ui-designs/` and the existing design tokens in `lib/util/dimensions.dart` and
`lib/util/styles.dart`. Do not invent new styles. If a style is not found in the reference images, ask
before creating one.

---

## Brand Color

**Primary — `#2C9C44`** (RGB 44,156,68). This is the authoritative MoonJoin brand color, used app-wide:
theme `primaryColor`, `ColorScheme.primary/secondary`, primary buttons, app bars, the wavy header,
selected/active states, active bottom-nav icon, prices, badges, switches, chips, and progress indicators.

The previous `#039D55` is retired. Do not sample greens from the images — `#2C9C44` is the single source
of truth. Set it in `lib/theme/light_theme.dart` and `dark_theme.dart` (both call `light({color})` /
`dark({color})`, so the default color argument must become `#2C9C44`).

Supporting colors (from theme + images):
- Body background: near-white `#F5F6F5` / `surface #FCFCFC`.
- Card: `#FFFFFF`.
- Error / "Required" accent: `#E84D4F`.
- Disabled / hint / secondary text: `#9F9F9F`.
- Selected-card fill (option groups): primary at ~8–10% alpha.

---

## Signature Motif — Wavy Green Header

The most identifiable MoonJoin element is a **green header block with a curved/wavy bottom edge** that
dips into the near-white body. It appears on Home and both Product Details screens. Implement once as a
reusable widget (`WavyHeader`, see `COMPONENTS.md`) and share across screens. Status-bar icons sit on the
green; content (greeting, location, search bar, or product image) overlaps the curve.

---

## Theme Attributes

Modern · Premium · Minimal · Soft shadow · Rounded cards · Rounded buttons · White background · High contrast.

## Spacing & Radius (reuse `Dimensions`)

- Padding ramp: `paddingSizeExtraSmall 5 · Small 10 · Default 15 · Large 20 · ExtraLarge 25 · ExtremeLarge 30`.
- Radius ramp: `radiusSmall 5 · radiusMedium 8 · radiusDefault 10 · radiusLarge 15 · radiusExtraLarge 20`.
  Cards ≈ `radiusLarge`, buttons ≈ `radiusDefault`, pills/chips fully rounded.
- Soft shadows: `shadowColor` = black @ 3% alpha (already in theme).

## Typography (reuse `styles.dart`)

Roboto ramp: `robotoRegular (400) · robotoMedium (500) · robotoSemiBold (600) · robotoBold (700) ·
robotoBlack (900)`. Font sizes from `Dimensions.fontSize*` (responsive: larger ≥1300px). Section titles
and prices are bold; prices render in the primary green.

## Currency

Naira `₦`, driven by backend/`SplashController` config and `PriceConverter` — never hardcode the symbol or
amount formatting.

## Key component patterns (from images)

- **Category tile**: circular icon inside a green ring, label beneath (Home module grid).
- **Details footer bar**: fixed bottom bar — "Total Amount" (green) + quantity stepper + full-width
  **Add To Cart** button.
- **Food option groups**: radio cards (Food Type, Size) + checkbox cards (Extras), each with a
  "Required"/"Optional" tag; selected card gets a green border + tinted fill.
- **Grocery/others details**: image carousel with dots, variation **chip toggles** (Size/Type), In-Stock
  badge, favourite button as a card, quantity stepper.
- **Bottom navigation**: 4 tabs — Home · Orders · Favorites · Account — white bar, active icon/label green.
  Cart is a **header icon** with a count badge, not a tab.

---

## Component conventions (established in Phase 2)

These rules were fixed while building the `lib/common/widgets/moonjoin/` library and govern every future
MoonJoin widget and screen:

- **Pure presentation.** Design-system components hold no business logic: no `Get.find`, no API calls, no
  controllers/providers/services/repositories, no `PriceConverter`. Data comes in as plain values
  (pre-formatted price/rating **strings**), and behaviour comes in as callbacks (`VoidCallback`,
  `ValueChanged`). State (selected index, quantity, favourite) is owned by the caller.
- **Compose, never duplicate.** Build larger widgets from smaller ones — `CategoryTile`/`ModuleCard` →
  `ModuleIcon`; `FloatingCheckoutBar` → `QuantityStepper` + `BottomActionBar`; `CartSummaryCard` →
  `PriceRow`; `MoonjoinDialog` → `MoonjoinButton`. Reuse existing infrastructure (`CustomImage` for network
  images, the `shimmer_animation` package for skeletons) rather than re-implementing it.
- **Colour from theme.** Use `Theme.of(context).primaryColor` / `colorScheme` / `hintColor` /
  `disabledColor` / `cardColor` — never hardcode the brand green in a widget, so `#2C9C44` stays the single
  source of truth in the theme files.
- **Tokens only.** All spacing, radius, and font sizes come from `Dimensions`; all text styles from
  `styles.dart` (`robotoRegular/Medium/SemiBold/Bold`). No magic numbers for these.
- **Card recipe.** White `cardColor` surface, `radiusLarge` corners, soft shadow
  `Colors.black @ 5% alpha, blur 8, offset (0,2)`. Pinned bars use a top-facing shadow and `SafeArea(top:false)`.
- **Selected state recipe.** Selected controls/cards use a `primaryColor` border + `primaryColor @ 8%`
  tinted fill (option groups), or a solid `primaryColor` fill with white text (chips, filled badges).
- **Badges.** `StatusBadge` filled = solid colour + white text; unfilled = colour @ 12% tint + coloured
  text. "Required" uses `colorScheme.error`; "Optional" uses `disabledColor`.
- **Header actions.** Notification and cart live as translucent-white rounded icon buttons on the green
  header (`MoonjoinModuleHeader`), each with a white count badge showing the primary green number.
- **Barrel import.** Screens import the whole library via `moonjoin/moonjoin_components.dart`.
- **Edge-to-edge green header.** Screens whose top is the green wavy header extend it *behind* the system
  status bar: drop only the top `SafeArea` inset for that screen (`SafeArea(top: false, …)`) and let the
  header apply `MediaQuery.padding.top` itself, and wrap the screen in an
  `AnnotatedRegion<SystemUiOverlayStyle>` with **light** status-bar icons + transparent status-bar colour.
  Screens with a light/white header keep the normal top inset. There must be no white strip above the
  header.
- **Localization — no hardcoded strings.** Every user-facing string goes through GetX `.tr`. When a key is
  missing, add it to **all** language files (`assets/language/en.json`, `ar.json`, `es.json`, `bn.json`)
  with real translations — never postpone localization and never ship literal display text.

---

## Rules

- Always reuse existing components. Never duplicate widgets. Keep spacing, typography, shadows, icon sizes,
  and animations consistent. Every new screen must follow this design language.

## Shared Module Design Rule

The following modules intentionally use identical UI layouts: **Grocery, Fuel, Fashion, Pharmacy, Market,
Drink Distributor, Solar & Power**. **Food** follows the same language too. The only exception is
**Food Product Details**, which uses `product_details_for_only_food.png`; all other modules use
`product_details_for_grocery_and_others_module.png`.

Fuel, Fashion, Market, Drink Distributor, and Solar & Power are admin-configured modules that render
through the shared **ecommerce ("shop")** UI variant selected at runtime by `moduleType`
(`lib/features/home/screens/home_screen.dart`). Do not fork UI per business name. Whenever two screens are
visually identical, build ONE reusable, data-driven widget. Only business logic (API, models, controllers)
differs between modules.
