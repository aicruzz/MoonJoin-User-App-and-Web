# User App — Product List Preload, Processing-Time Estimate, Flash Countdown

**Status:** IMPLEMENTED / TESTED / **DEVICE QA PASS (A, B, C)** / **FROZEN** (2026-11-10, owner-approved). No further A/B/C code changes. Release builds and device evidence are under *Release QA* below.

**Codebase:** `/Users/francisadediran/User app and web` · `main` / `344f1a5` (uncommitted, with Issues 1, 2A, 2B and the wallet and cold-start fixes) · Flutter 3.47.5 / Dart 3.13.4 · version `1.0.26+37`, `appVersion` 3.8

**Backend:** no change. The Admin/backend codebase was read only, to establish data semantics.

---

## Issue A — Product list pauses at each page boundary

### Cause

`PaginatedListView` (the shared pagination widget behind Store "All Products", store search, the home store list, orders, chat and the rental lists) requested the next page only when `position.pixels == position.maxScrollExtent`, the exact bottom. The list therefore always ran out first: scrolling stopped at the end as if no more products existed, the spinner appeared, the page loaded, and the customer had to swipe again. The request itself was fast. It started too late (causes 1–4 in the brief), and the spinner appearing at the end added to the impression of an end.

### Fix

The next page is requested once the remaining loaded content below the screen is at most one screen height (`position.extentAfter <= position.viewportDimension`). Unchanged: one request in flight (`_isLoading`), each page once (`_offsetList`), stop at the last page, the offset from the controller, the desktop "View more" button, the spinner, product order and the card design. `StoreController.getStoreItemList` still appends each page once, in server order. An existing precedent preloads early too (`item_view_all_screen.dart`, `maxScrollExtent - 300`).

Noted, not changed: the store items request uses `limit=13` while `PaginatedListView` assumes pages of 10, so the last scroll can request one extra, empty page. It cannot skip products. The category, brand, wallet and loyalty screens use their own exact-bottom listeners and are outside this scope.

### Files

`lib/common/widgets/paginated_list_view.dart`, `test/store/store_product_pagination_test.dart` (new, 7 tests)

**Before the fix:** 3 of the 7 failed (no request until the exact bottom). **After:** 7/7.

## Issue B — "Your food will delivered within 1 - 5 min" after Admin set Cooking to 30 min (Order #100010)

### Data flow

Admin (or Vendor) sets the status to processing with a processing time → `Admin/OrderController` (and `Vendor/OrderController`, `Api/V1/Vendor/VendorController`) saves `processing_time` (minutes; the store's minimum delivery time if none is entered) **and stamps `processing = now()`** (`$order[$request->order_status] = now()`) → the customer track API returns the full order row (`processing_time`, `processing`, `created_at`, `schedule_at`, all as `Y-m-d H:i:s` business-timezone text) → `OrderModel` already parses all of them → `OrderBannerViewWidget` → `DateConverter.differenceInMinute`.

### Cause

The estimate is `(schedule_at ?? created_at) + processing_time − now`, and anything under 5 minutes shows "1 - 5". Instant orders store `schedule_at = now()` at placement (`PlaceNewOrder`), so the 30 minutes were counted from when the order was **placed**, not from when Cooking was set. For an order placed 25+ minutes before Admin set 30 minutes, the estimate was already past, giving "1 - 5". `processing_time` is set only on the processing transition, at the same moment as `processing`, and nothing else consumes it. So the intended meaning is minutes from that moment. The cause is not timezone (both timestamps use the same format and timezone), stale data, persistence or parsing.

### Fix

When a processing time and a `processing` timestamp exist, the estimate counts from the `processing` timestamp. Every other case is unchanged: no processing time → store minimum delivery time from the schedule/order time; a missing or unparseable timestamp → the previous base. No API, status or delivery-calculation change, and no redesign. The banner computes the value once per build instead of three times.

### Files

`lib/helper/date_converter.dart` (optional `processingStartedAt`), `lib/features/order/widgets/order_banner_view_widget.dart`, `test/order/order_processing_estimate_test.dart` (new, 11 tests)

**Before the fix:** the Order #100010 scenario rendered "1 - 5", and handover after processing was also wrong (2 failed). **After:** 11/11.

**Order #100010 evidence:** not queried. Production was not touched, and the order's exact `created_at`/`processing` times are visible only in Admin. The outcome is consistent with the order having been placed 25 or more minutes before Cooking was set.

## Issue C — Flash countdown

### Findings

1. **Visible countdown (`MoonjoinFlashCountdown`): correct.** Each second it recomputes `endTime − now` from the absolute campaign end. It does not drift, corrects itself after background/resume, clamps at zero and stops there.
2. **The test was intrinsically timing-dependent.** `tester.pump(1s)` advances only the test clock, while the widget reads the real `DateTime.now()`. The digits changed only if a real second boundary happened to pass during the test, so the outcome depended on machine timing. It now waits ≥1.1 s of real time (`sleep`) before the tick. Same assertion, now deterministic. It passes on the old and the new code.
3. **No recent regression.** The relative countdown below has been in `FlashSaleController` since the initial import (`e11679b`).
4. **Real user-facing defects, fixed:**
   - `FlashSaleController` counted down by subtracting 1 s per tick. Timers stop while the iOS app is in the background or a browser tab is throttled. After that, `duration` was too long by the time away, so the web home timer (`FlashSaleTimerWebHomeView`, which displays `duration`) showed too much time left, and the mobile home section (hidden when `duration ≤ 1 s`) stayed up past the real end with 00:00:00:00. The timer also never stopped and went negative. Now every tick recomputes from the same absolute end time, clamps at zero and stops.
   - `MoonjoinFlashCountdown` cancelled its timer at zero, and a later new `endTime` (the next campaign on a still-mounted section, e.g. Rental Flash Rent) never restarted it, so the countdown froze. A new end time now restarts it.

### Files

`lib/features/flash_sale/controllers/flash_sale_controller.dart`, `lib/common/widgets/moonjoin/moonjoin_flash_deals_section.dart`, `test/moonjoin/flash_countdown_test.dart` (ticking test made deterministic; 4 tests added, 9 in total)

**Before the fix:** 4 of the new tests failed. **After:** 9/9, 3 runs in a row.

## Automated validation (2026-11-10)

| Suite | Result |
|---|---|
| `item`, `splash`, `checkout`, `home`, `store`, `favourite`, `location`, `moonjoin`, `profile`, `order`, `language`, `notification`, `api`, `auth`, `rental` | **467 passed, 0 failed** |
| `test/common` | 29 passed |
| Issue A / B / C focused | 7 / 11 / 9 |
| Issue 1 stock / Food Extras / 2A / 2B / wallet / cold start | 29 / 15 / 12 / 20 / 12 / 6 |
| `flutter analyze`, changed files | No issues |
| `flutter analyze`, whole project | 0 errors. 3 warnings, all in unchanged files (`marker_helper.dart`, `pusher_helper.dart`). 30 infos; the only one in a changed file is the known `checkout_screen.dart:530` |
| `test/widget_test.dart` | Not run: the pre-existing Flutter counter template |

## Release QA

**Release worktree:** `/Users/francisadediran/moonjoin-release-1.0.26-37`, detached at `344f1a5`, holding the 41 approved files, byte-identical to the main tree. The owner's unrelated files (`notification_icon.png`, `FROZEN_REGISTRY.md`, `MIGRATION_LOG.md`, `MOONJOIN_SHARED_DESIGN_LANGUAGE.md`) are excluded. The git-ignored `android/key.properties` and Gradle wrapper files are copied unchanged.

| Build | Result |
|---|---|
| iOS `flutter build ios --release` (main tree) | Exit 0. `Runner.app` 89.3MB, `com.moonjoin.com` 1.0.26 (37), automatic signing with team 4W65FX4ZFH. Only warning: the existing Swift Package Manager plugin notice. No archive or upload |
| Android `flutter build appbundle --release` (release worktree) | Exit 0. `build/app/outputs/bundle/release/app-release.aab`, 101,786,141 bytes, SHA-256 `42fd1842cf34ecec93f270dde56b12959d6f0a6af3ac8e7cbc018bd6322563fa`. `jar verified`, upload key CN=francis adediran / OU=moonjoin. Warnings are advance notices only (AGP 8.11.1, Gradle 8.14, Kotlin 2.2.20; Java 8 options). Not uploaded |
| Web `pub get --enforce-lockfile` + `flutter build web --release` (release worktree) | Exit 0. 672 files, `version.json` 1.0.26 / 37, `base href="/"`, SPA `.htaccess` present, API `https://admin.moonjoin.com`, no `.DS_Store`. Compared with live `web-v1.0.23+34`: +6 CanvasKit variant files from the Flutter 3.47 toolchain. Not deployed: the web release process requires a tag built from a clean checkout, pending the owner's decision |

### Device QA — PASS (owner, iPhone 15 Plus, iOS release build 1.0.26 (37), 2026-11-10)

| Item | Result | Owner evidence |
|---|---|---|
| A — Product pagination | **PASS** | Long All Products list scrolls on continuously. No premature stop, duplicates or missing products |
| B — Order #100010 estimate | **PASS** | Processing time set to 40 min, then 30 min. Both correct; no "1 - 5" right after setting. Screenshots: 8:35 → 34–39 min, 8:37 (after the 30 min change) → 24–29 min, i.e. counted from the Processing/Cooking event, not from order placement |
| C — Flash Sale countdown | **PASS** | Ticks correctly. After several minutes in the background it resumed at the correct remaining time, with no restart or drift |

### Final validation before commit (re-run 2026-11-10)

| Check | Result |
|---|---|
| Relevant regression suites + `test/common` | **496 passed, 0 failed** |
| A / B / C focused | 7 / 11 / 9 |
| Wallet / cold start / Issue 1 stock / Food Extras / 2A / 2B | 12 / 6 / 29 / 15 / 12 / 20 |
| `flutter analyze`, all 26 changed Dart files | Only the pre-existing `checkout_screen.dart:530` info |
| Change set | 41 approved files, byte-identical to the release worktree; the owner's 4 unrelated files are excluded |

### Web deploy — HELD (owner decision b)

Not deployed from the untagged build. Order: approved commit → tag → clean checkout of the tag → `pub get --enforce-lockfile` + `flutter build web --release` → deterministic archive + SHA256SUMS in `~/MoonJoin/release-artifacts/<tag>/` → new `releases/<tag>` on the droplet → switch `current` → `nginx -t` + `systemctl reload`. Live before this release: `web-v1.0.23+34`.
