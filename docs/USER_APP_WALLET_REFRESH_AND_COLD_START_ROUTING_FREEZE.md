# User App — Wallet Balance Refresh + Food Rapid-Tap (Cold-Start Routing) Freeze

**Status:** IMPLEMENTED / TESTED / CODE-FROZEN (2026-11-06). Wallet push race corrected 2026-11-10 (see *Correction* under Fix 1); the correction is verified by automated regression, and device push QA is blocked by the environment. **AWAITING FINAL RELEASE QA.**

**Repository:** MoonJoin Customer User App & Web

**Codebase:** `/Users/francisadediran/User app and web`

**Branch / HEAD:** `main` / `344f1a5a732b465945fa238c7af20d7e43df877e` (uncommitted, together with Issues 1, 2A and 2B)

**Toolchain:** Flutter 3.47.5 / Dart 3.13.4

**Backend:** no change. Issue 4 (9PSB, in `/Users/francisadediran/admin.moonjoin.com`) is separate and was not touched from this codebase.

---

## Fix 1 — Wallet balance reflects new credits

### Problem

After a wallet credit was confirmed on the backend (for example a bank transfer to the 9PSB virtual account), Checkout → Choose Payment Method kept showing the old balance (₦170) until the customer left and came back.

### Root cause

- The balance shown everywhere is `ProfileController.userInfoModel.walletBalance`, loaded from `customer/info`.
- Checkout fetched it **only when no profile was loaded yet** (`if (userInfoModel == null)`). After the first load at app start it was never re-fetched there.
- The payment sheet's wallet row was rebuilt only by `CheckoutController`, so even a fresh profile did not redraw it.
- The backend already sends an `add_fund` push on wallet credits (including 9PSB, `NinePsbPaymentController` → `Helpers::add_fund_push_notification`), but the app's foreground handler only showed it as a notification.
- Pusher is used only for delivery-driver location. There is no realtime wallet channel.

### Fix

| Trigger | Change |
|---|---|
| **Shared refresh** | `ProfileController.refreshUserInfo()`: one shared `customer/info` request for concurrent callers. A failed or thrown request keeps the last known profile |
| **Checkout entry** | Always refreshes, not only when the profile is missing |
| **Checkout resume** | `AppLifecycleListener` refreshes on app resume while Checkout is open |
| **Payment sheet open** | Refreshes when Choose Payment Method opens |
| **Payment sheet rebuild** | The wallet row is wrapped in `GetBuilder<ProfileController>`, and so is `PartialPayView`, so a new balance redraws them |
| **Existing `add_fund` push (foreground)** | `NotificationHelper.syncWalletOnFundNotification` refreshes for logged-in users |

### Financial safety

- The balance always comes from `customer/info`. The app never adds a funded amount locally.
- No change to the wallet ledger, credit/debit authorisation, transactions, provider verification, balance calculation, payment authorisation, checkout pricing or APIs.
- No polling.

### Files

- `lib/features/profile/controllers/profile_controller.dart`
- `lib/features/checkout/screens/checkout_screen.dart`
- `lib/features/checkout/widgets/payment_method_bottom_sheet.dart`
- `lib/features/checkout/widgets/partial_pay_view.dart`
- `lib/helper/notification_helper.dart`
- `test/checkout/wallet_balance_refresh_test.dart` — NEW

### Correction (2026-11-10): add_fund push during a running refresh

**Observed behaviour.** During release QA, with Checkout → Choose Payment Method open, the wallet balance did not always update when a ₦100 9PSB credit landed. Sometimes it stayed stale until the sheet was closed and reopened. On the release-mode QA build (without this correction) the open sheet went from ₦1,620 (5:51) to ₦1,720 (6:00) with no restart, but what triggered that refresh cannot be identified: the release build prints none of the app's own logs.

**Root cause.** The shared refresh gave every caller the request already in flight. An `add_fund` push that arrived while a request sent **before** the credit was still running received that pre-credit answer, and nothing fetched again. Examples are the sheet-open refresh and the resume refresh, which tend to run just as a transfer lands. The open sheet stayed on the old balance until the next trigger: reopening the sheet, or the app resuming.

**The payment sheet was not defective.** Its wallet row, and `PartialPayView`, are inside `GetBuilder<ProfileController>`. They read `userInfoModel.walletBalance` fresh on every build and copy nothing at open. `getUserInfo()` stores the server answer and calls `update()`, so every new answer redraws the open sheet. The fault was which answer arrived, not how it was shown.

**Backend ordering (read-only check, no change).** `NinePsbPaymentController::creditVerifiedPayin` commits the credit inside `DB::transaction` and sends the `add_fund` push only afterwards. It has no outer transaction on its webhook or reconciliation callers. A request sent after the push therefore reads the new balance. The hourly `moonjoin:reconcile-customer-9psb` runs dry and never credits. The push data carries `type: "add_fund"`.

**Fix.** `refreshUserInfo(afterServerChange: true)`, used only by the `add_fund` push. If a request is already running, exactly one more `customer/info` request follows it, however many pushes arrive. Requests stay sequential, so the newest answer is applied last. Ordinary triggers (entry, resume, sheet open) still share the running request. No timer, delay or polling, no local arithmetic, no second wallet API or wallet state.

**Files.** `lib/features/profile/controllers/profile_controller.dart`, `lib/helper/notification_helper.dart`, `test/checkout/wallet_balance_refresh_test.dart` (3 new tests, 12 in total).

**Before the fix.** On the unchanged code, 10 passed / 2 failed. The failures were the defect: no follow-up request after a mid-flight push, and an open sheet left at the old balance.

**After the fix (re-run 2026-11-10).**

| Check | Result |
|---|---|
| `test/checkout/wallet_balance_refresh_test.dart` | 12/12 passed |
| Relevant suites (`item`, `splash`, `checkout`, `home`, `store`, `favourite`, `location`, `moonjoin`, `profile`, `order`, `language`, `notification`, `api`, `auth`, `rental`) | 445 passed, 0 failed in one full run. Another run failed only `flash_countdown_test` |
| `test/moonjoin/flash_countdown_test.dart` alone | 4 passed / 1 failed, 3 of 3 runs. **Pre-existing**, depends on the real clock (the widget reads `DateTime.now()`); neither the test nor its widget is changed here |
| `flutter analyze` on the changed and wallet files | Clean, except the pre-existing `use_build_context_synchronously` info at `checkout_screen.dart:530` |

**Push environment limitation.** The debug iPhone build reported `apns-token-not-set`. The release-mode QA build gave no reliable evidence that the push reached the app in the foreground. Nothing shows the wallet changes affected push: the only push-related lines they touch add the balance refresh.

**Device verification: PENDING / UNAVAILABLE.** The installed release-mode build does not contain this correction, so the ₦1,620 → ₦1,720 observation does not validate it. For now the automated tests above are the verification of the race fix. On device, the open sheet updates within one server round trip of a delivered foreground `add_fund` push (two if a request was already running). Without the push, it updates on the next resume or sheet open.

**Backend:** no changes. The admin/backend codebase was only read.

## Fix 2 — Rapid tap in Food returns to Food home

### Problem

Opening the app, entering Food and quickly tapping a brand could open the store and then return to Food home. Waiting before tapping worked.

### Root cause

A cold start runs `getConfigData` twice: the cached config routes the user to Home at once, then the network config arrives and ran the same user routing again: `Get.offNamed(Home)`. `offNamed` replaces the **top** route, so a page opened in that window (a brand's store) was replaced by Home, with the Food module still active. When Home was on top, GetX ignored the duplicate push, which hid the double routing. Waiting avoided the bug because the network pass had already finished. Slow networks widen the window.

### Fix

The network pass skips user routing when the cached pass already routed the user. `route()` now reports whether it redirected to the update/maintenance screen, so:

- the network pass still applies a maintenance/update redirect;
- after a stale cached update/maintenance redirect, the network pass still routes the user;
- with no usable cache, the network pass routes as before;
- the existing startup-notification rule is unchanged.

No debounce, no route or design change.

### Files

- `lib/helper/splash_route_helper.dart` — `route()` returns whether it redirected
- `lib/features/splash/controllers/splash_controller.dart` — network pass routing rule. This file also carries Issue 1's config restore, which is unchanged
- `test/splash/cold_start_network_reroute_test.dart` — NEW
- `test/splash/notification_cold_start_routing_test.dart` and `test/location/address_save_routing_test.dart` — one assertion each changed from 2 to 1 `updateToken` calls. They had codified the double user routing this fix removes; their navigation assertions are unchanged

## Testing

**Pre-fix reproduction (Fix 2):** on the unchanged code, `cold_start_network_reroute_test.dart` gave 4 passed / 2 failed. The failures were the bug: the open store replaced by Home (`/?from-splash=true`), and user routing running twice.

**Deliberate-break check:** 9 parts of the two fixes were undone one at a time, with files restored and checksum-verified. Tests caught 9 of 9.

| Suite | Result |
|---|---|
| Wallet refresh tests (new) | 9/9 passed |
| Cold-start rerouting tests (new) | 6/6 passed |
| Existing cold-start notification routing | 3/3 passed |
| Existing address-save routing | 7/7 passed |
| `test/profile` | 20 passed |
| `test/checkout/dm_tip_most_tapped_test.dart` | 12 passed |
| Issue 1 stock / Food Extras | 29 / 15 passed |
| Issue 2A / 2B | 12 / 20 passed |
| Relevant suites (`item`, `splash`, `checkout`, `home`, `store`, `favourite`, `location`, `moonjoin`, `profile`, `order`, `language`) | **396 passed, 0 failed** |
| `test/notification`, `api`, `auth`, `rental` | 7, 5, 10, 24 passed |
| `test/widget_test.dart` | Fails, **pre-existing**: the unmodified Flutter counter template, already recorded in `SLICE_B_SEARCH_SUGGESTIONS_FREEZE.md` |

## Analyzer

`flutter analyze` on every changed file: no issues, except one pre-existing `use_build_context_synchronously` info at `checkout_screen.dart:530` in the existing Place Order handler. That code is identical to HEAD, shifted 7 lines by this change. A whole-project analyze was not run.

## Not verified, for release QA

- **Wallet on a device:** fund the wallet by bank transfer, then open Checkout → Choose Payment Method. Repeat with the app in the background during the transfer, and with Checkout already open.
- **Push dependency:** the foreground `add_fund` refresh needs the push to reach the device. iOS push delivery has known pre-existing gaps, so on iOS the checkout entry, sheet open and resume refreshes are the reliable path.
- **Checkout entry and resume refresh:** covered by code review, not by a widget test (`CheckoutScreen` is too heavy to pump); the payment sheet path is tested.
- **Food on a device:** cold start, enter Food, tap a brand immediately, ideally on a slow network.
- **Totals while partial payment is on:** checkout totals that read the balance redraw on their next `CheckoutController` update, not on the profile refresh itself.

## Checkpoint

`/Users/francisadediran/moonjoin-wallet-fix-qa` (2026-11-10, linked worktree, detached at `344f1a5`). It holds Issues 1, 2A and 2B, both fixes in this document including the wallet correction, all freeze records, and version `1.0.26+37` / `appVersion` 3.8. Earlier: `/Users/francisadediran/moonjoin-final-release-qa` (before the wallet correction) and `/Users/francisadediran/moonjoin-issue2b-qa` (Issues 1, 2A and 2B only).

## Unchanged

- Backend and admin code, APIs, payloads, wallet and payment logic, pricing, design, routes
- Owner's unrelated files: `notification_icon.png`, `docs/FROZEN_REGISTRY.md`, `docs/MIGRATION_LOG.md`, `docs/MOONJOIN_SHARED_DESIGN_LANGUAGE.md`
