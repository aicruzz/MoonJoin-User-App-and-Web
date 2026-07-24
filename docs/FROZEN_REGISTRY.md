# MoonJoin — Frozen Registry

Screens and components listed here are **APPROVED and FROZEN**. Do not redesign,
refactor, restyle, or fork them. Reuse only. A frozen item may be revisited only
for: a production bug, a required API/backend change, or an explicit product-owner
redesign request.

---

## FROZEN SCREENS / SHELLS

### 🧊 Loyalty Points — `loyalty_screen.dart`
- **File:** `lib/features/loyalty/screens/loyalty_screen.dart` (+ `loyalty_card_widget.dart`, `loyalty_history_widget.dart`, `loyalty_bottom_sheet_widget.dart`)
- **Status:** FROZEN — Phase 5 (Profile Modernization) · **Frozen on:** 2026-07-25
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen MoonJoin Profile language. Presentation only.
- **What it is:** Mobile — `ProfilePageHeader` (`onBack` preserves `fromNotification`) + MoonJoin green points card + MoonJoin history + bottom `CustomButton` "Convert to Wallet Money". Desktop — 2-column (card+stepper | history) + `WebMenuBar`. Convert dialog = `LoyaltyBottomSheetWidget` (redesigned; validation/exchange/API preserved).
- **Reuses:** `ProfilePageHeader`, `CustomButton`, `CustomTextField`, `NoDataScreen`, `WalletShimmer`, shared `HistoryItemWidget` (loyalty variant).
- **Preserved:** LoyaltyController (pagination + `pointToWallet`) · ProfileController · SplashController · LoyaltyRepository · LoyaltyService · APIs (`/loyalty-point/transactions`, `/point-transfer`) · `TransactionModel` · validation + exchange rate · pagination · refresh · navigation (`getLoyaltyRoute`, `fromNotification`). No business logic changes.
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.

### 🧊 Transaction row — `HistoryItemWidget` (loyalty variant modernized)
- **File:** `lib/common/widgets/history_item_widget.dart`
- **Status:** FROZEN (loyalty variant) — Phase 5 · **Frozen on:** 2026-07-25
- **What is frozen:** the **`moonjoinLoyalty: true`** MoonJoin row (green icon chip · points · description · date · credit/debit pill), used by Loyalty history.
- **Untouched:** default (`moonjoinLoyalty:false`) row used by **Wallet history** (`fromWallet:true`) renders exactly as before — Wallet is a separate future phase. Do not modify without its own approval.

### 🧊 Coupon (list) — `coupon_screen.dart`
- **File:** `lib/features/coupon/screens/coupon_screen.dart`
- **Status:** FROZEN — Phase 4 (Profile Modernization) · **Frozen on:** 2026-07-24
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen MoonJoin Profile language. Presentation only.
- **What it is:** Mobile — green `ProfilePageHeader` + `RefreshIndicator` grid of MoonJoin coupon cards; desktop — grid kept, `WebMenuBar` app bar. Tap = copy code + "code copied" tooltip (unchanged).
- **Reuses:** `ProfilePageHeader`, shared `CouponCardWidget` (list variant), `NoDataScreen`, existing tooltip/clipboard interaction.
- **Preserved:** CouponController · CouponRepository · CouponService · API `/coupon/list` · `CouponModel` · copy-to-clipboard · tooltip · refresh · loading · empty state · navigation (`getCouponRoute`). No business logic changes.
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.

### 🧊 Coupon card — `CouponCardWidget` (list variant modernized)
- **File:** `lib/features/coupon/widgets/coupon_card_widget.dart`
- **Status:** FROZEN (list variant) — Phase 4 · **Frozen on:** 2026-07-24
- **What is frozen:** the **`fromCouponScreen: true`** MoonJoin variant (`_moonjoinCard`) — green ticket card (discount stub + perforation + dashed green code chip + copy + validity + min purchase). This is the ONE shared coupon card — no duplicate/fork.
- **Untouched:** the default (`fromCouponScreen: false`) legacy card used by the **Checkout coupon bottom sheet** (`checkout/widgets/coupon_bottom_sheet.dart`) renders exactly as before. Do not modify without its own approval.

### 🧊 My Address (list) — `address_screen.dart`
- **File:** `lib/features/address/screens/address_screen.dart`
- **Status:** FROZEN — Phase 3 (Profile Modernization) · **Frozen on:** 2026-07-24
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen MoonJoin Profile language. Presentation only.
- **Scope:** the **My Address LIST screen only**. Add / Edit / Map (GoogleMap + `LocationController`) are a SEPARATE future phase — untouched here.
- **What it is:** Mobile `_mobileBody` (green `ProfilePageHeader` + `RefreshIndicator` list of `AddressWidget` cards + bottom `CustomButton` "Add New Address") and desktop `_desktopBody` (grid preserved; city background removed; `WebMenuBar` app bar).
- **Reuses:** `ProfilePageHeader`, shared `AddressWidget` (list variant), `CustomButton`, `AddressConfirmDialogue`, `NoDataScreen`, `AddressController`.
- **Preserved:** AddressController · AddressRepository · AddressService · APIs (`address/list|add|update|delete`) · `AddressModel` · validation · Google Maps · geocoding/reverse-geocoding · zone/delivery validation · navigation (`getAddressRoute`, add/edit/map routes) · active-address logic. Presentation only.
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.

### 🧊 Address card — `AddressWidget` (list variant modernized)
- **File:** `lib/common/widgets/address_widget.dart`
- **Status:** FROZEN (list variant) — Phase 3 · **Frozen on:** 2026-07-24
- **What is frozen:** the **`fromAddress` (My Address list)** branch — MoonJoin card: soft-green type icon chip (home/office/other) + bold type label + address subtitle + soft-tinted edit/delete circular buttons. This is the ONE shared address card — no duplicate card widget exists.
- **Untouched (still owned by their own contexts):** `fromCheckout` branch (Checkout, already MoonJoin) and `fromDashBoard` branch (Dashboard address selection). Do not modify those without their own approval.

### 🧊 Personal Information (Edit Profile) — `update_profile_screen.dart`
- **File:** `lib/features/profile/screens/update_profile_screen.dart`
- **Status:** FROZEN — Phase 2 (Profile Modernization) · **Frozen on:** 2026-07-24
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen Stage-1 MoonJoin Profile language (green waved header, cards, shared fields/buttons). Presentation only.
- **What it is:** Mobile `_mobileView` + desktop `webView()`. Green waved header (`ProfilePageHeader`) with back + delete-account menu; premium avatar straddling the header/body with camera badge (reuses existing image picker); "Basic Information" card grouping the three shared `CustomTextField`s (name/email/phone + country code, email/phone verify affordances); frozen `ProfileButtonWidget` "Change Password" row; `CustomButton` "Update".
- **Reuses:** `ProfilePageHeader` (new shared), `CustomTextField` ×3, `CustomButton`, `ProfileButtonWidget` (frozen), `CustomPopupMenuButton`+`ConfirmationDialog`+`ProfileController.deleteUser`, existing `pickImage()`.
- **Preserved:** ProfileController · ProfileRepository · ProfileService · **API `POST /api/v1/customer/update-profile`** · `UpdateUserModel`/`UserInfoModel` contract · all validation · image-upload multipart · phone/email verification flows · navigation (`getUpdateProfileRoute`).
- **QA bugs fixed:** (1) title hidden behind avatar → header height increased; (2) camera badge un-tappable (avatar was in `Clip.none` overflow) → avatar moved inside Stack bounds via reserved padding.
- **Web:** desktop visual verification PENDING (does not block freeze; future desktop adjustments are refinements, not a reopen).
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.


### 🧊 Account (Profile) shell — `menu_screen.dart`
- **File:** `lib/features/menu/screens/menu_screen.dart`
- **Status:** FROZEN — Stage 1 (Profile Modernization)
- **Frozen on:** 2026-07-24
- **Design authority:** `ui-designs/Profile_Loction_Notification_OrderStatus_SelectAddress_VoiceSearch/profile.png` (+ `profile_scroll down.png`). Not in the Active Figma.
- **What it is:** The Account tab. Green header (user name + join date · avatar edit-badge → Edit Profile · notification bell → Notifications · dark-mode moon · `_HeaderWaveClipper` concave wave; top spacing from `MediaQuery.padding.top`). Three tappable stat cards (Loyalty/Orders/Wallet) with action pills. Grouped sections (General/Promotional/Earnings/Help) built from `PortionWidget`.
- **Reuses:** `VirtualAccountDetailsWidget` (frozen), `PortionWidget`, existing routes only.
- **Rule:** Presentation frozen. Navigation/controllers/business logic unchanged. Do not restyle without product-owner approval.

## FOUNDATION COMPONENTS

Foundation components are the single, canonical implementation of a pattern across
the **entire** MoonJoin User App. There must be exactly one of each. No alternate
version may be created without explicit architectural approval.

### 🧊 Account navigation row — `PortionWidget`
- **File:** `lib/features/menu/widgets/portion_widget.dart`
- **Status:** FROZEN — FOUNDATION COMPONENT · **Frozen on:** 2026-07-24
- **What it is:** THE single MoonJoin list-navigation row: 46px soft-green icon chip · bold title (`fontSizeLarge`) · optional grey subtitle · trailing chevron (or count `suffix`) · inset divider · `isDanger` red variant.
- **API:** `icon, title, route` (required) + `subtitle?, hideDivider, suffix?, isDanger, onTap?`. Navigation via `route`/`onTap` unchanged.
- **MANDATE:** every Account/Menu/Profile list row must use this. No alternate menu-row widget. `menu_button_widget.dart` is OBSOLETE (zero usages; retained for final cleanup).

### 🧊 Profile page header — `ProfilePageHeader`
- **File:** `lib/features/profile/widgets/profile_page_header.dart`
- **Status:** FROZEN — FOUNDATION COMPONENT · **Frozen on:** 2026-07-24
- **What it is:** THE official shared MoonJoin green waved header for ALL Profile child pages: primary-green fill, concave wave bottom (mirrors the Stage-1 Account header), status-bar-aware top spacing (`MediaQuery.padding.top`), centred white title, optional back button, optional trailing action, `bottomExtra` for avatar overlap.
- **API:** `title` (required) + `showBack, trailing?, bottomExtra, onBack?`. (`onBack` added Phase 5 — additive optional; defaults to `Get.back()`, so all prior callers are unchanged; lets pages with special back logic, e.g. notification deep-links, override it.)
- **MANDATE:** every remaining Profile screen (My Address, Wallet, Notifications, Coupons, Loyalty, Refer & Earn, Language, Settings, Help, Live Chat, HTML, Delete/Logout) MUST reuse this header. No duplicate header implementations allowed.
- **Note:** wave geometry currently duplicates the frozen `_HeaderWaveClipper` in `menu_screen.dart` (not imported, to avoid touching the frozen Account shell) — unify into one clipper when Stage 1 is next intentionally reopened.

### 🧊 Setting / toggle / action row — `ProfileButtonWidget`
- **File:** `lib/features/profile/widgets/profile_button_widget.dart`
- **Status:** FROZEN — FOUNDATION COMPONENT · **Frozen on:** 2026-07-24
- **What it is:** THE single MoonJoin standalone-card row: soft-accent icon chip · title (+ optional subtitle) · adaptive trailing — Cupertino toggle (`isButtonActive`), language selector (`languageName`), or chevron; red danger treatment (`color`/`isDanger`).
- **API preserved:** `icon, title, onTap` + `subtitle?, isButtonActive?, color?, iconImage?, languageName?, isDanger`. Toggle/onTap behavior unchanged.
- **MANDATE:** every Profile toggle/action/setting row must use this.

### 🧊 Virtual Account Details — `VirtualAccountDetailsWidget`
- **File:** `lib/features/checkout/widgets/virtual_account_details_widget.dart`
- **Status:** FROZEN — FOUNDATION COMPONENT
- **Frozen on:** 2026-07-24
- **What it is:** The ONE and ONLY approved "Your Virtual Account Details" UI in
  MoonJoin. Extracted verbatim from the approved Choose Payment Method card.
- **States (single premium shell):** details · loading · generate/no-account.
- **Flags:** `detailsOnly` (null → placeholder text instead of Generate),
  `showTitle`, `showInstructions` (Profile hides the instructions box), `margin`.
- **Data/logic:** reuses `ProfileController.virtualAccountData` /
  `isGeneratingAccount` / `generateVirtualAccount()`. No new business logic.
- **Currently reused by:** Checkout (Choose Payment Method), Profile (profile_screen,
  web_profile_widget, menu_screen), Wallet "+" (add_fund_dialogue_widget).
- **MANDATE — must be reused by any current or future surface showing a virtual
  account,** including but not limited to: Checkout · Wallet · Deposit · Fund
  Wallet · Bank Account · Profile · Payment pages · Financial pages.
- **Rule:** No future Virtual Account UI may be created without explicit
  architectural approval. `virtual_account_card_widget.dart` is OBSOLETE (zero call
  sites; retained only for the final dead-code cleanup pass).

---

## OBSOLETE — Pending Final Legacy Cleanup
Retained on disk (recoverable) per the Legacy Cleanup Protection Rule. Zero active
references. May be removed ONLY in the final cleanup phase, after a dead-code audit
+ owner approval. DO NOT delete now.
- `lib/features/profile/widgets/profile_bg_widget.dart` — superseded by `ProfilePageHeader` (Personal Information redesign).
- `lib/features/profile/widgets/virtual_account_card_widget.dart` — superseded by `VirtualAccountDetailsWidget`.
- `lib/features/menu/widgets/menu_button_widget.dart` — superseded by `PortionWidget`.
