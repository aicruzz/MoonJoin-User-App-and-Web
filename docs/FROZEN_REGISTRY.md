# MoonJoin — Frozen Registry

Screens and components listed here are **APPROVED and FROZEN**. Do not redesign,
refactor, restyle, or fork them. Reuse only. A frozen item may be revisited only
for: a production bug, a required API/backend change, or an explicit product-owner
redesign request.

---

## FROZEN SCREENS / SHELLS

### 🧊 New User Setup — `new_user_setup_screen.dart`
- **Files:** `lib/features/auth/screens/new_user_setup_screen.dart` (no new i18n keys).
- **Status:** **Implemented · Runtime Verified · QA Passed · Owner Approved · FROZEN** — Phase 9C-7 (Premium Authentication) · **Frozen on:** 2026-07-28
- **Design authority:** No frame in the Active Figma / no ui-designs image → the frozen MoonJoin language (via the frozen **Auth Foundation**, Phase 9C-1). Presentation only.
- **What is frozen:** mobile `_mobileBody` rebuilt via `AuthScaffold(onBack: Get.back, hero: AuthHero('just_one_step_away'), child: AuthCard(Form(_formKeyInfo) → AuthInputGroup(Name + [Phone if social | Email if OTP] + Refer-code if refEarningStatus==1) → AuthPrimaryButton('done')))`. Mobile drops the legacy `Images.logo` + centered text for the shared hero; `_desktopBody` legacy preserved (500 card, top-right close, logo, `CustomButton` 250×50). The `_isSocial` branch (social → collect Phone; OTP → collect Email), social name pre-fill, and refer-code gate all preserved.
- **UX consistency:** hero/curve/breathing-logo/logo-fill, floating `AuthCard` overlap, radius+shadow, scroll, safe-area — **identical by shared foundation** across the whole auth cluster.
- **Reuses:** frozen `AuthHero`, `AuthScaffold`, `AuthCard`, `AuthInputGroup`, `AuthPrimaryButton`, `CustomTextField`, `CustomButton` (desktop).
- **Preserved (verbatim):** `_formKeyInfo` validation · `widget.phone`-empty phone-validation path (`CustomValidator.isPhoneValid`) · `_updatePersonalInfo` → `AuthController.updatePersonalInfo` (name/phone/email/referCode) → `LocationController.navigateToLocationScreen('sign-in', offNamed:true)` · `_isSocial`/`CentralizeLoginType.social` branch · validators. No controller/repo/service/API/model/route/Firebase/OTP/OAuth/business-logic changes.
- **Social login (audit, unchanged):** the login buttons live in the FROZEN `social_login_widget.dart` (9C-2); this screen only receives the social onboarding via `NewUserSetupScreen(loginType: social …)` — that entry point is **preserved**. **Google works.** **Apple** fails = **iOS Configuration** (`com.apple.developer.applesignin` present only in `RunnerProfile.entitlements`; ABSENT from `Runner.entitlements` Release + `RunnerDebug.entitlements` Debug). **Facebook** fails = **Provider/Platform Configuration** (iOS Info.plist complete: `FacebookAppID`/`FacebookClientToken`/`FacebookDisplayName`/URL scheme — issue sits in the Meta dashboard/backend). **Both are NOT frontend regressions**; deferred to the future MoonJoin World Authentication Hardening phase — do NOT repair here.
- **Verification:** `flutter analyze lib/features/auth/screens/new_user_setup_screen.dart` → **No issues found!** Runtime: composed entirely from the frozen foundation already runtime-verified in 9C-5/9C-6 (verified-by-construction); the fresh-onboarding trigger (new unregistered account) was not reproduced on-device because OTP onboarding is blocked by the 9C-4 SMS gateway and the test account is already registered — infrastructure, not frontend.
- **Rule:** Presentation frozen. Reuse the Auth Foundation; do not restyle without product-owner approval.

### 🧊 Reset / New Password — `new_pass_screen.dart`
- **Files:** `lib/features/verification/screens/new_pass_screen.dart` (no new i18n keys).
- **Status:** **Implemented · Runtime Verified · QA Passed · Owner Approved · FROZEN** — Phase 9C-6 (Premium Authentication) · **Frozen on:** 2026-07-28
- **Design authority:** No frame in the Active Figma / no ui-designs image → the frozen MoonJoin language (via the frozen **Auth Foundation**, Phase 9C-1). Presentation only.
- **What is frozen:** mobile `_mobileBody` rebuilt via `AuthScaffold(onBack: Get.back, hero: AuthHero(title: change_password | reset_password, subtitle: enter_new_password), child: AuthCard(AuthInputGroup(New Password + Confirm password) + AuthPrimaryButton))`. **Serves BOTH entry paths** keyed by `fromPasswordChange`: **Change Password** (from Profile → Settings) and **Reset Password** (from the forgot-password OTP flow). Mobile drops the legacy `Images.changePass` illustration for the shared hero; `_desktopBody` legacy preserved (700/475 card, top-right close, illustration, `CustomButton`); removed the unused `custom_app_bar` import. **No `Form` added** — legacy manual validation kept verbatim.
- **UX consistency:** hero/curve/breathing-logo/logo-fill, floating `AuthCard` overlap, radius+shadow, scroll, safe-area — **identical by shared foundation** to Sign In / Sign Up / Verification / Forgot Password.
- **Reuses:** frozen `AuthHero`, `AuthScaffold`, `AuthCard`, `AuthInputGroup`, `AuthPrimaryButton`, `CustomTextField`, `CustomButton` (desktop).
- **Preserved (verbatim):** `_onPressedPasswordChange` (empty / `<6` / mismatch checks) · `_changeUserPassword` → `ProfileController.changePassword` · `_resetUserPassword` → `VerificationController.resetPassword` (+ `getSignInRoute` mobile / `AuthDialogWidget` desktop navigation) · per-path `isLoading` source. No controller/repo/service/API/model/route/validator/Firebase/OTP/business-logic changes.
- **Verification:** `flutter analyze lib/features/verification/screens/new_pass_screen.dart` → **No issues found!** Real-app runtime verified on iPhone 16 Pro Max via the real flow (Account → Sign In → Settings → **Change Password**): green hero + breathing logo, floating card, New/Confirm password fields, Change Password button; 0 overflow/exceptions.
- **Limitation (not a defect):** the **Reset Password** variant is the same widget/logic, analyzer-clean + preserved, but **not runtime-reachable** now — it sits behind the OTP step blocked by the 9C-4 backend SMS gateway (2Factor→+234). Infrastructure issue, not frontend.
- **Rule:** Presentation frozen. Reuse the Auth Foundation; do not restyle without product-owner approval.

### 🧊 Forgot Password — `forget_pass_screen.dart`
- **Files:** `lib/features/verification/screens/forget_pass_screen.dart` (no new i18n keys — all strings pre-existed).
- **Status:** **Implemented · Runtime Verified · QA Passed · Owner Approved · FROZEN** — Phase 9C-5 (Premium Authentication) · **Frozen on:** 2026-07-28
- **Design authority:** No Forgot Password frame in the Active Figma / no image in ui-designs → the frozen MoonJoin language (via the frozen **Auth Foundation**, Phase 9C-1). Presentation only.
- **What is frozen:** mobile `_mobileBody` rebuilt by composing the frozen foundation — `AuthScaffold(onBack: Get.back, hero: AuthHero(title: forgot_your_password | sorry_something_went_wrong, subtitle: registered-phone/email | try-again), child: AuthCard(...))`. Both original states preserved: the **request form** (`Form → AuthInputGroup(CustomTextField phone|email)` + **`AuthPrimaryButton`** "Request OTP" + "Or" + **`AuthFooter`** "Back to Log In") and the **channels-disabled fallback** (`AuthPrimaryButton` "Help & Support" + `AuthFooter` "continue as guest"). Legacy `Images.forgot`/logo illustration replaced by the shared hero on mobile (consistent with Sign In/Sign Up/Verification). Desktop `_desktopBody` preserved verbatim (700/475 card, top-right close, `Images.forgot`, `CustomButton`, RichText links); removed the now-unused `custom_app_bar` import.
- **UX consistency:** hero height/curve/breathing-logo/logo-fill, floating `AuthCard` overlap, radius+shadow, scroll, safe-area — **identical by shared foundation** to Sign In / Sign Up / Verification (one continuous premium flow, runtime-confirmed).
- **Reuses:** frozen `AuthHero`, `AuthScaffold`, `AuthCard`, `AuthInputGroup`, `AuthPrimaryButton`, `AuthFooter`, `CustomTextField`, `CustomButton` (desktop).
- **Preserved (verbatim):** `_onPressedForgetPass` (phone build + `CustomValidator.isPhoneValid` + `_formKeyLogin.validate()` + `VerificationController.forgetPassword` + Firebase-vs-backend routing `phoneVerificationStatus && firebaseOtpVerification` + desktop-dialog / `RouteHelper.getVerificationRoute` navigation) · `initState` config gating (`isSmsActive`/`firebaseOtpVerification`/`isMailActive`) + non-web auto-focus · validators · country picker. No controller/repo/service/API/model/route/Firebase/OTP/business-logic changes.
- **Verification:** `flutter analyze lib/features/verification/screens/forget_pass_screen.dart` → **No issues found!** Real-app runtime verified on iPhone 16 Pro Max simulator (Forgot Password screen renders: green hero + breathing logo, floating card, +234 phone field, Request OTP, Or, Back to Log In; 0 overflow/exceptions).
- **Limitation (not a defect):** the channels-disabled fallback state is analyzer-clean + preserved but not runtime-reproduced (requires disabling both SMS+email in Admin config). Actual OTP delivery still gated by the 9C-4 backend SMS gateway (2Factor→+234), unrelated to this screen.
- **Rule:** Presentation frozen. Reuse the Auth Foundation; do not restyle without product-owner approval.

### 🧊 Sign Up — `sign_up_screen.dart` (+ `sign_up_widget.dart`)
- **Files:** `lib/features/auth/screens/sign_up_screen.dart`, `lib/features/auth/widgets/sign_up_widget.dart` (+ 1 i18n key `create_your_moonjoin_account`).
- **Status:** **Implemented · Runtime Verified · QA Passed · Owner Approved · FROZEN** — Phase 9C-3 (Premium Authentication) · **Frozen on:** 2026-07-27
- **Design authority:** the frozen MoonJoin Auth Foundation (9C-1). Presentation only.
- **What is frozen:** mobile Sign Up rebuilt by composing the frozen foundation — `AuthScaffold(showBack: !exitFromApp, onBack: Get.back, hero: AuthHero(title: create_your_moonjoin_account, subtitle: your_world_of_services_awaits), child: AuthCard(SignUpWidget))`. `SignUpWidget` mobile presentation uses **`AuthPrimaryButton`** (Sign Up) + **`AuthFooter`** ("Already have account? Sign In"); container width `context.width` → `double.infinity` so the form fits the `AuthCard` (no overflow). Desktop `_desktopBody` / `SignUpWidget` desktop branch preserved.
- **UX consistency (Sign In ↔ Sign Up):** hero height/curve/breathing-logo/logo-fill, floating `AuthCard` position+overlap, card radius+shadow, scroll, safe-area — **identical by shared foundation**. Aligned 4 mobile spacing drifts in Sign Up (top gap 10→0, primary-button surrounds 15→20, footer bottom 20→0) so input/button/footer spacing matches Sign In.
- **Reuses:** frozen `AuthHero`, `AuthScaffold`, `AuthCard`, `AuthPrimaryButton`, `AuthFooter`, `CustomTextField`, `ConditionCheckBoxWidget`, `CustomButton` (desktop).
- **Preserved (verbatim):** `AuthController.registration` · `SignUpBodyModel` · all validation (name/email/phone/password/confirm/refer) · `ConditionCheckBoxWidget` terms gate (`acceptTerms`) · verification routing (`firebaseVerifyPhoneNumber` / `VerificationScreen` / `getVerificationRoute`) · `CartController`/`ProfileController`/`LocationController` · `getSignInRoute` cross-link · desktop `AuthDialogWidget`. No controller/repo/service/API/model/route/business-logic changes.
- **Verification:** `flutter analyze lib/features/auth` → No issues found! Real-app runtime verified (guest → Sign In → Sign Up): logo fills the disc, all fields present, Full-Name auto-focus, terms + button + footer working, 0 overflow/exceptions/asset-errors.
- **Rule:** Presentation frozen. Reuse the Auth Foundation; do not restyle without product-owner approval.

### 🧊 Sign In — `sign_in_screen.dart` (+ SignInView / Manual / OTP / Social)
- **Files:** `lib/features/auth/screens/sign_in_screen.dart`, `lib/features/auth/widgets/sign_in/sign_in_view.dart`, `lib/features/auth/widgets/sign_in/manual_login_widget.dart`, `lib/features/auth/widgets/sign_in/otp_login_widget.dart`, `lib/features/auth/widgets/social_login_widget.dart` (+ 2 i18n keys in `assets/language/*.json`).
- **Status:** **Implemented · Runtime Verified · QA Passed · Owner Approved · FROZEN** — Phase 9C-2 (Premium Authentication) · **Frozen on:** 2026-07-27
- **Design authority:** No Sign In frame in the Active Figma / no login image in ui-designs → the frozen MoonJoin language (via the frozen **Auth Foundation**, Phase 9C-1). Presentation only.
- **What is frozen:** the mobile Sign In host rebuilt by **composing the frozen Auth Foundation** — `AuthScaffold(hero: AuthHero, child: AuthCard(SignInView))`. `SignInView` keeps its config-driven `CentralizeLoginType` switch and all `_login`/`_otpLogin`/`_processSuccessSetup`/`_processOtpSuccessSetup` orchestration. `ManualLoginWidget` + `OtpLoginWidget` composed from the foundation (`CustomTextField`s unchanged; `AuthPrimaryButton`; `AuthFooter`; welcome heading now lives in `AuthHero`). `SocialLoginWidget` presentation → `AuthDivider` + horizontal `AuthSocialButton` pills (Google · Apple · Facebook). Desktop `_desktopBody` / `AuthDialogWidget` path preserved.
- **Manual Login Persistence (implemented, owner-approved contract):** always auto-fill the last **email/phone**; **never** auto-store the password (`_processSuccessSetup` saves email/phone with an EMPTY password); on reopen auto-fill email/phone + **auto-focus the password field** (else focus email/phone); **no "Remember me" checkbox** anywhere (mobile + desktop, manual + OTP); biometric = documented future extension point.
- **Reuses:** frozen `AuthHero`, `AuthScaffold`, `AuthCard`, `AuthInputGroup`(via composition), `AuthPrimaryButton`, `AuthDivider`, `AuthSocialButton`, `AuthFooter`, `CustomTextField`, `CustomButton`.
- **Preserved (verbatim):** `AuthController` (`login`/`otpLogin`/`guestLogin`/`loginWithSocialMedia`/`enableOtpView`/country-code/`saveUserNumberAndPassword`) · `LocationController.navigateToLocationScreen` · Firebase phone verification · Google/Apple/Facebook SDK flows · `ExistingUserBottomSheet` · **admin Login Setup config gating** (`centralizeLoginSetup.*` via `CentralizeLoginHelper`, 7 layouts — never hardcoded) · `SignInScreen.PopScope` (exit-app / OTP-back / notification-reset) · `getSignInRoute` / `backFromThis` / `fromNotification` / `fromResetPassword` / return-after-login. No controller/repo/service/API/model/route/business-logic changes.
- **QA bug fixed:** `setState() after dispose()` from the delayed auto-focus → guarded with `if(!mounted) return` in `SignInView`. Re-verified on the real app: guest → Sign In (phone auto-filled, password empty + focused), 0 exceptions/overflow; `flutter analyze` clean.
- **Legacy (retained):** `SocialLoginButton` (declared in `login_suggestion_bottomsheet.dart`) superseded by `AuthSocialButton` on Sign In → **OBSOLETE-candidate — Pending Final Legacy Cleanup** (still used by the login-suggestion sheet; not removed).
- **Rule:** Presentation frozen. Reuse the Auth Foundation; do not restyle without product-owner approval.

### 🧊 Guest Foundation — `NotLoggedInScreen`
- **File:** `lib/common/widgets/not_logged_in_screen.dart`
- **Status:** FROZEN — Phase 9B (Guest User Experience) · **Frozen on:** 2026-07-26
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen MoonJoin language. Presentation only.
- **What it is:** THE single, permanent **MoonJoin Guest Foundation** — the one shared not-logged-in guard rendered by ALL ~14 protected user surfaces (Wallet, Coupon, My Address, Loyalty, Refer & Earn, Notifications, Chat, Edit Profile, Checkout, Parcel, …). Redesigned **in place, Option A — one shared implementation, NO isolated variants.** Layout: soft-green MoonJoin halo (168px, `primaryColor` @ 8% alpha) around `Images.guest` (110px) → bold `you_are_not_logged_in` → hint `please_login_to_continue` → green `CustomButton` "login" (width 240, `radiusLarge`, `Icons.login_rounded`). `Dimensions.*` tokens replace the old MediaQuery-fraction sizing; `SingleChildScrollView + FooterView` host wrapper kept. **No secondary CTA.**
- **Reuses:** `CustomButton`, `FooterView`, `Images.guest`, existing i18n keys (`you_are_not_logged_in`, `please_login_to_continue`, `login`).
- **Shared Widget Protection:** this IS the shared foundation — the redesign is intentionally global. The single param `callBack(bool success)` is unchanged, so all ~14 call sites compile untouched. Future modifications MUST preserve: the **callback contract**, the **navigation contract**, the **desktop dialog flow**, and the **mobile login flow**. No isolated variants. No business-logic changes.
- **Preserved (verbatim):** Login `onPressed` — mobile `Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute))` · desktop `AuthDialogWidget(exitFromApp:false, backFromThis:true)` then `callBack(true)` · `OrderController.showRunningOrders()` guard · trailing `callBack(true)` (return-after-login refresh). Untouched: `AuthController` · session · token · Firebase · OTP · guest login · social login · `RouteHelper` · navigation · repositories · APIs · models · services.
- **Runtime verification:** `flutter analyze` clean · guest **Wallet** verified · guest **My Address** verified · 0 exceptions/overflow on guest surfaces. (The unrelated `CachedNetworkImage` "null host" log = pre-existing null-avatar on the logged-in profile, NOT caused by Guest UX — this screen uses a bundled `Image.asset`.)
- **Rule:** Presentation frozen. Do not restyle, fork, or add variants without product-owner approval.

### 🧊 Settings — `setting_page.dart`
- **File:** `lib/features/profile/screens/setting_page.dart` (+ isolated variants in `notification_status_change_bottom_sheet.dart` and chrome polish in `language_bottom_sheet_widget.dart`)
- **Status:** FROZEN — Phase 8G (Profile Modernization) · **Frozen on:** 2026-07-26
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen MoonJoin Profile language. Presentation only.
- **What is frozen:** `CustomAppBar` → **`ProfilePageHeader`** (mobile) / `WebMenuBar` (desktop); MoonJoin surface. **Rows reuse the FROZEN `ProfileButtonWidget` unchanged** (Language selector · Dark Mode toggle · Notification toggle [gated by `isLoggedIn`, pre-existing] · Version). **Settings now owns the `LanguageBottomSheetWidget` experience** (MoonJoin chrome polish; only call site). The **`NotificationStatusChangeBottomSheet`** gets an **isolated `moonjoin` Settings-only variant** (icon chip · "Are you sure?" · Cancel + accent Confirm; red=disable/green=enable).
- **Reuses:** `ProfilePageHeader`, `WebMenuBar`, `ProfileButtonWidget` (frozen, unchanged), `LanguageCardWidget` (shared, unchanged), `CustomButton`.
- **Isolation (Shared Widget Protection):** `NotificationStatusChangeBottomSheet.moonjoin` defaults `false` → `profile_screen.dart` + `web_profile_widget.dart` keep the legacy sheet unchanged; only Settings passes `moonjoin: true`.
- **Preserved:** `LocalizationController` · `ThemeController` · `AuthController` (notification toggle + `notificationLoading` + persistence) · `setLanguage`/`saveCacheLanguage`/`searchSelectedLanguage` · dark-mode toggle · navigation · version. **No controller/repo/service/API/model/persistence/business-logic changes. No Guest/Auth entanglement.**
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.

### 🧊 Live Chat — Conversation List — `conversation_screen.dart`
- **File:** `lib/features/chat/screens/conversation_screen.dart`
- **Status:** FROZEN — Phase 8E (Profile Modernization) · **Frozen on:** 2026-07-26
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen MoonJoin language. Presentation only.
- **Scope:** the **Conversation List only**. The **Chat Thread (message screen, `ChatScreen` via `getChatRoute`)** remains intentionally **untouched** — its own future phase.
- **What is frozen:** `CustomAppBar` → **`ProfilePageHeader`** (mobile, `showBack: !fromNavBar`) / `WebMenuBar` (desktop); **MoonJoin premium conversation card** (avatar with soft green ring · bold name · muted type subtitle · time · modernized green unread badge — exact unread condition preserved); empty state → **`NoDataScreen`**; desktop `WebChatViewWidget` untouched. Card layout is intentionally **generic** (avatar · name · subtitle · time · unread count) — the official MoonJoin visual foundation for the future MoonJoin World messaging platform; a future websocket/live-sync can plug in without a redesign.
- **Reuses:** `ProfilePageHeader`, `WebMenuBar`, `NoDataScreen`, `PaginatedListView`, `RefreshIndicator`, `ChatSearchFieldWidget`, `CustomImage`, `CustomInkWell`, `WebChatViewWidget`.
- **Preserved:** ChatController · repositories · services · APIs · polling · pagination · search · unread logic · message/conversation loading · send-message · image-attachment · `NotificationBodyModel` · `getChatRoute` · refresh · FAB · navigation. **No business-logic/backend changes.**
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.

### 🧊 Logout confirmation — `ConfirmationDialog` (MoonJoin variant, Phase 8D)
- **File:** `lib/common/widgets/confirmation_dialog.dart` (isolated variant); triggered from `menu_screen.dart` logout.
- **Status:** FROZEN — Phase 8D (Profile Modernization) · **Frozen on:** 2026-07-25
- **What is frozen:** an isolated presentation-only **`moonjoin`** variant (`_moonjoinDialog`) of the shared `ConfirmationDialog` — premium rounded card, red logout icon chip, "Logout" heading, description, **Cancel** (clean outlined secondary) + **green primary "Logout"** (#2C9C44). Used ONLY by the logout call (`menu_screen.dart` → `ConfirmationDialog(... moonjoin: true)`).
- **Isolation:** `moonjoin` defaults `false` → the **other 20 `ConfirmationDialog` call sites** (Delete Account, orders, registration, rental, items, subscription…) keep the legacy dialog, unchanged. No duplicate dialog created.
- **Preserved:** `AuthController.socialLogout` · token/session · cart/favourite/profile/shared-data cleanup · snackbar · navigation. Green "Logout" → same `onYesPressed` (full cleanup + close); Cancel → `Get.back()`. **No auth/business-logic changes.**
- **Note:** the inline "Logout" trigger row in the frozen `menu_screen` shell was NOT restyled (scope = confirmation dialog only).
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.

### 🧊 HTML Container — `html_viewer_screen.dart`
- **File:** `lib/features/html/screens/html_viewer_screen.dart`
- **Status:** FROZEN — Phase 8C (Profile Modernization) · **Frozen on:** 2026-07-25
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen MoonJoin Profile language. Presentation only.
- **What is frozen:** ONE reusable MoonJoin HTML container serving **all** `HtmlType` policy routes — **About Us · Terms & Conditions · Privacy Policy · Refund Policy · Shipping Policy · Cancellation Policy** (and any future `HtmlType` page on the same route). `CustomAppBar` → **`ProfilePageHeader`** (mobile, title per `HtmlType` via `_title`) / `WebMenuBar` (desktop). Server HTML (`HtmlWidget`) wrapped in a **MoonJoin card** (radiusLarge · soft border/shadow · readable typography). Loading = spinner; empty = `NoDataScreen`.
- **Reuses:** `ProfilePageHeader`, `WebMenuBar`, `FooterView`, `MenuDrawer`, `WebScreenTitleWidget`, `NoDataScreen`. One screen — no per-page widget, no duplication.
- **Preserved:** `HtmlController.getHtmlText` · `HtmlService` · HTML content API/endpoints · `HtmlType` mapping · `flutter_widget_from_html_core` renderer (`textStyle`/`key`/`onTapUrl`→`launchUrlString`) · navigation · loading logic. **No controller/repository/service/API/model changes.**
- **Content note:** page content (and any legacy "6amMart" wording) is **backend HTML** → MoonJoin World / CMS concern; frontend controls chrome only.
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.

### 🧊 Help & Support — `support_screen.dart`
- **File:** `lib/features/support/screens/support_screen.dart`
- **Status:** FROZEN — Phase 8B (Profile Modernization) · **Frozen on:** 2026-07-25
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen MoonJoin Profile language. Presentation only.
- **What is frozen:** `CustomAppBar` → **`ProfilePageHeader`** (mobile) / `WebMenuBar` (desktop) · support illustration hero + "We're here to help" · **MoonJoin contact cards** (`_contactCard`: brand-green icon chip · title · info · chevron) for **Email / Call / Address**.
- **Reuses:** `ProfilePageHeader`, `FooterView`, `WebMenuBar`, `MenuDrawer`, existing support illustration.
- **Preserved:** `SplashController` config values (email/phone/address) · `tel:` call launch · `mailto:` email launch (made robust: `canLaunchUrlString` + `LaunchMode.externalApplication` + graceful fallback, same intent) · desktop `WebSupportScreen` · navigation. **No controller/repository/service/API/model changes. No FAQ/ticket/live-chat/support-API added.**
- **Obsolete (retained):** `support/widgets/support_button_widget.dart` → **OBSOLETE — Pending Final Legacy Cleanup** (superseded by the MoonJoin contact cards; zero call sites; not deleted).
- **Note:** on the iOS Simulator `mailto:` has no handler (no Mail app) → graceful fallback; opens the mail composer on real devices.
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.

### 🧊 Notifications — `notification_screen.dart`
- **File:** `lib/features/notification/screens/notification_screen.dart`
- **Status:** FROZEN — Phase 8A (Profile Modernization) · **Frozen on:** 2026-07-25
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen MoonJoin Profile language. Presentation only.
- **What is frozen:** `CustomAppBar` → **`ProfilePageHeader`** migration (`onBack` preserves `fromNotification` deep-link) / `WebMenuBar` desktop · **MoonJoin notification card** (`_notificationCard`: green type-icon chip · title · 2-line body · time · optional push image) · **unread visual system** (unread = green dot + bold title + soft green tint + border + shadow; read = flat/muted) built **only** from the existing local `notificationIdList`.
- **Reuses:** `ProfilePageHeader`, `NoDataScreen`, `CustomImage`, `CustomAssetImageWidget`, `FooterView`, `WebScreenTitleWidget`.
- **Preserved:** `NotificationController` · `NotificationService` · `GET /customer/notifications` · `NotificationModel` · local unread tracking (`getSeenNotificationIdList`/`addSeenNotificationId`/`saveSeenNotificationCount`) · date sorting/grouping · refresh · empty state · `NotLoggedInScreen` · detail flows (`NotificationBottomSheet` mobile / `NotificationDialogWidget` desktop) · `PopScope`+`fromNotification` navigation. **No backend unread system added; no controller/repo/service/API/model changes.**
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.

### 🧊 My Wallet + Wallet History — `wallet_screen.dart`
- **Files:** `lib/features/wallet/screens/wallet_screen.dart` (+ `wallet_card_widget.dart`, `wallet_history_widget.dart`, `add_fund_dialogue_widget.dart`)
- **Status:** FROZEN — Phase 7 (Profile Modernization) · **Frozen on:** 2026-07-25
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen MoonJoin Profile language. Presentation only.
- **What is frozen:** My Wallet screen (`ProfilePageHeader`, `onBack` preserves `fromNotification`; `WebMenuBar` desktop) · **premium balance card** (gradient fintech card + "Add Fund") · **Wallet History** (MoonJoin) · **Wallet filter** chip · **premium Add Fund dialog** (header icon, selectable bordered payment cards, **"9PSB Virtual Account"** label, amount hidden for VA / shown for online gateways) · **`HistoryItemWidget` isolated `moonjoinWallet` variant** · **`VirtualAccountDetailsWidget` improvements** (full account number via scaleDown; premium inline "Copied" fade) · **`ProfilePageHeader` reuse**.
- **Reuses:** `ProfilePageHeader`, `CustomButton`, `CustomTextField`, `NoDataScreen`, `WalletShimmer`, shared `HistoryItemWidget` (wallet variant), frozen `VirtualAccountDetailsWidget`.
- **Preserved:** WalletController · ProfileController · SplashController lifecycle · WalletRepository · WalletService · APIs (`/wallet/transactions|add-fund|bonuses|virtual-account`) · models · validation · **add-fund + payment/gateway flow** · **payment-return snackbar + `walletAccessToken` idempotency** · pagination · filters · refresh · navigation · currency/transaction calculations. No business-logic changes.
- **Payment architecture (recorded):** Wallet & Checkout consume `SplashController.configModel.activePaymentMethodList` correctly — **no frontend hardcoding, no filtering**; rendering production-ready. Remaining inconsistency = documented **Legacy Backend / config-cache / hosting (Imunify360) limitation**, to be replaced by MoonJoin World.
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.

### 🧊 Transaction row — `HistoryItemWidget` (wallet variant modernized)
- **File:** `lib/common/widgets/history_item_widget.dart`
- **Status:** FROZEN (wallet variant) — Phase 7 · **Frozen on:** 2026-07-25
- **What is frozen:** the **`moonjoinWallet: true`** MoonJoin row (green/red icon chip · debit/credit + adminBonus · description · date · credit/debit pill). Loyalty variant (`moonjoinLoyalty`) stays frozen; legacy default retained for Final Legacy Cleanup. One shared row — no duplicate/fork.

### 🧊 `VirtualAccountDetailsWidget` — Phase 7 improvements (foundation component, still frozen)
- **File:** `lib/features/checkout/widgets/virtual_account_details_widget.dart`
- **Changes (2026-07-25):** value fields use `FittedBox(scaleDown)` so the **full account number** never truncates in narrow contexts (Add Fund); the copy button (`_CopyButton`) replaces the top snackbar with a **premium inline "Copied" fade** — clipboard content/behavior unchanged. Applies everywhere it's reused (Checkout, Profile ×3, Wallet). No other change; remains the single approved Virtual Account UI.

### 🧊 Refer & Earn — `refer_and_earn_screen.dart`
- **File:** `lib/features/refer_and_earn/screens/refer_and_earn_screen.dart`
- **Status:** FROZEN — Phase 6 (Profile Modernization) · **Frozen on:** 2026-07-25
- **Design authority:** No dedicated Figma/ui-designs image → reproduces the frozen MoonJoin Profile language. Presentation only.
- **What it is:** Mobile — `ProfilePageHeader` (info icon in `trailing` → `BottomSheetForMobile`) + illustration + MoonJoin reward card (green rate chip · "Invite friends & businesses" · green dashed code box + green Copy · Share button). Desktop — `WebMenuBar` + inline `BottomSheetViewWidget` "how it works" panel.
- **Reuses:** `ProfilePageHeader`, `CustomButton`, `ProfileController.refCode`, `SharePlus`, `Clipboard`, `NotLoggedInScreen`, `FooterView`, `WebScreenTitleWidget`, `BottomSheetForMobile`/`BottomSheetViewWidget`.
- **Preserved:** `ProfileController.refCode` (only referral data source) + `getUserInfo` · exact `SharePlus` share text (app name + code + download link) · `Clipboard` copy + snackbar · `SplashController.refEarningExchangeRate` display · auth handling · navigation · both info-sheet flows. No controller/API/model/validation/business-logic changes.
- **Obsolete (retained):** the `ExpandableBottomSheet` wrapper is no longer used on this page → **OBSOLETE — Pending Final Legacy Cleanup** (the `expandable_bottom_sheet` package is still used by 3 other files; nothing deleted).
- **Rule:** Presentation frozen. Do not restyle without product-owner approval.

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

### 🧊 MoonJoin Auth Foundation — `lib/features/auth/widgets/foundation/`
- **Files:** `auth_scaffold.dart`, `auth_hero.dart`, `auth_header.dart`, `auth_card.dart`, `auth_input_group.dart`, `auth_otp_field.dart`, `auth_social_button.dart`, `auth_divider.dart`, `auth_footer.dart`, `auth_primary_button.dart` (+ `auth_foundation.dart` barrel; `auth_foundation_gallery.dart` + `auth_foundation_demo_main.dart` = isolated demo, run ONLY via `flutter run -t …/auth_foundation_demo_main.dart`, never wired to production).
- **Status:** **Implemented · QA Passed · Design Approved · FROZEN** — Phase 9C-1 (Premium Authentication) · **Frozen on:** 2026-07-27
- **Design authority:** No Sign In frame in the Active Figma and no login image in ui-designs → the frozen MoonJoin design language is the authority (as with the Guest Foundation 9B).
- **What is frozen (the 10 canonical auth presentation components):**
  1. **`AuthScaffold`** — the single auth shell for BOTH hosts (mobile full-screen / desktop dialog-body via `isDialog`). Owns responsive body layout, dialog-safe spacing, full-bleed hero + floating overlapping card, and back/close affordance rendering. **Never** creates `Dialog()`, controls `barrierDismissible`, or calls `Navigator`/`Get.back()` — only invokes the `onBack` it is given (host owns the dialog + navigation).
  2. **`AuthHero`** — premium full-bleed green hero (~36% height, 48px curved bottom) + softly **breathing** haloed logo (ease-in-out scale+glow; no spin/bounce) + white title + trust subtitle. **Owner revision 2026-07-27:** the logo now **fills the white circular disc 100%** — `Image.asset(fit: BoxFit.cover)` inside a fixed circular disc (`discSize = logoWidth + 2·paddingSizeLarge`, `clipBehavior: antiAlias`, `shape: circle`), replacing the padded `ClipRRect(width: logoWidth)`. Breathing scale+glow kept; `logoCornerRadius` retained for API stability (now unused). **Asset note:** `logo.png` must be lowercase `.png` (iOS is case-sensitive); a tightly-cropped square logo fills edge-to-edge, one with internal transparent margin shows some white. Callers pass already-translated strings (no `.tr`).
  3. **`AuthHeader`** — titled top bar for verification/forgot/new-password (auth-scoped replacement for `CustomAppBar`; a plain widget, not a `PreferredSizeWidget`).
  4. **`AuthCard`** — floating form surface: fixed `radiusExtraLarge` + soft premium shadow + `cardColor`; only `padding`/`margin`/`widthConstraint` configurable (Dimensions only).
  5. **`AuthInputGroup`** — labeled cluster that **wraps** the caller's existing `CustomTextField`s (never owns controllers/focus/validators); `crossAxisAlignment` (default start).
  6. **`AuthOtpField`** — MoonJoin **theme** wrapper over `PinCodeTextField` (`pin_code_fields`); behavior/verify untouched; `autoFocus` passthrough.
  7. **`AuthSocialButton`** — **provider-blind** social/OTP pill (icon/label/onTap/`fullWidth` only; no SDK, no provider `if`s). Supersedes the legacy `SocialLoginButton` (staged migration — verify both consumers before marking the old one obsolete).
  8. **`AuthDivider`** — "or / or continue with" separator; caller supplies the (translated) label.
  9. **`AuthFooter`** — cross-link row; `enabled` is visual-only, never routes.
  10. **`AuthPrimaryButton`** — thin preset over the frozen `CustomButton` (green, `radiusLarge`, `isLoading`, default height 54); never reimplements button internals; loading text stays `CustomButton`'s.
- **Contract (Shared Widget Protection):** all 10 are **pure presentation** — no controllers, navigation, validation, API/repository/service calls, SDK calls, or `Get.find<...Controller>()`; behavior enters via constructor params/callbacks; theme via `Theme.of(context)`, spacing/radius via `Dimensions.*`, no hardcoded hex. `flutter analyze` → 0 issues.
- **MANDATE:** every MoonJoin authentication surface (Sign In, Sign Up, OTP/Verification, Forgot/Reset Password, New User Setup, and the desktop `AuthDialogWidget`) MUST be built by reusing these components. No alternate auth-shell/hero/card/social widgets. **Do not change any component's visuals, structure, animation, spacing, typography, or API without an explicit owner revision request.**
- **Rule:** Frozen. Reuse only.

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

---

## PERMANENT ARCHITECTURE DECISIONS (recorded 2026-07-25)

1. **Legacy Backend Principle.** The legacy 6amMart backend is a **temporary compatibility backend only**.
   Do NOT redesign/modernize it or add new infrastructure to it (no ConfigSyncService, TTL cache, versioned
   config, lifecycle redesign, push invalidation, config-architecture improvements). Only critical bug fixes
   when absolutely necessary; keep the frontend compatible until MoonJoin World is complete. All future
   backend architecture belongs to **MoonJoin World**; all future tenant architecture to **MoonJoin Cloud**.

2. **MoonJoin Platform Naming (official).** Frontend: Flutter User App & Web · Flutter Vendor App · Flutter
   Delivery App · Vendor Website. Backend: **MoonJoin World**. Tenant platform: **MoonJoin Cloud**. Never call
   the backend "6amMart".

3. **Shared Widget Protection.** Frozen foundations — never casually modify: `ProfilePageHeader`,
   `HistoryItemWidget`, `VirtualAccountDetailsWidget`, `CustomButton`. Any future visual redesign using these
   must be an **additive isolated variant** (like AddressWidget `fromAddress`, CouponCardWidget
   `fromCouponScreen`, HistoryItemWidget `moonjoinLoyalty`/`moonjoinWallet`). Never break frozen pages.

4. **Frozen Migration Workflow (no step skipped).** Architecture Audit → Reuse Audit → Design Audit → Owner
   Approval → Implementation → flutter analyze → Runtime Verification → QA Report → Owner Approval →
   Documentation Update → Freeze.

5. **Legacy Cleanup Policy.** Never delete unused legacy widgets/packages immediately → mark
   `OBSOLETE — Pending Final Legacy Cleanup`. Final cleanup happens only after the entire frontend redesign is
   complete and frozen.

6. **Payment Architecture Decision.** Wallet & Checkout correctly consume
   `SplashController.configModel.activePaymentMethodList`; no frontend hardcoding, no filtering; rendering is
   production-ready. Remaining inconsistency = documented legacy backend/config-cache/hosting limitation;
   MoonJoin World will replace the legacy configuration architecture.

7. **Frontend Ownership.** The MoonJoin frontend is the primary product. Future effort targets UX,
   architecture quality, component reuse, scalability, maintainability — NOT redesigning legacy backend
   architecture that MoonJoin World will replace.
