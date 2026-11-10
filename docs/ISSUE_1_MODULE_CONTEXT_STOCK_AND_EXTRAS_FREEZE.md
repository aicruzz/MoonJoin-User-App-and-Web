# Issue 1 — False Out-of-Stock + Food Extras Module Context Freeze

**Status:** IMPLEMENTED / TESTED / CODE-FROZEN (2026-11-05). **DEVICE QA NOT YET PERFORMED.**

**Repository:** MoonJoin Customer User App & Web

**Base commit:** `344f1a5a732b465945fa238c7af20d7e43df877e` (the fix is uncommitted on top of this commit)

**Toolchain:** Flutter 3.47.5 / Dart 3.13.4

**Device build:** intentionally deferred until the complete User App & Web issue queue is resolved. This freeze is a code freeze only; it is not a device validation.

---

## Problem

**A. False Out-of-Stock.** A customer opening an item, typically after the app had been idle, saw a disabled **Out of Stock** button although the item had not been marked out of stock. Closing and reopening the app sometimes restored **Add To Cart**. Reported on CatFish Barbecue (item 617, Chruzz, ₦10,000).

**B. Food Extras hidden.** A Food item opened while another module, or no module, was active could be ordered with its Extras hidden.

## Root cause

Stock is tracked per module. Production `module_config` has `grocery`, `pharmacy` and `ecommerce` at `stock=true` and `food` at `stock=false`, and Food items are stored with `stock=0` by design. Item 617 returns `module_type=food`, `stock=0`, which is correct.

The stock and Extras checks read `configModel.moduleConfig.module`, one mutable value that is not tied to the item on screen:

1. **Config reload race.** `ModuleConfig.fromJson` defaults `module` to `module_type[0]` (`grocery`). On cold start the cached config routes to Home and the network config is still loading. If the customer opens Food first, the network response resets the value to Grocery's config and it stays wrong for that session. Whether a relaunch "fixes" it depends on which finishes first.
2. **No active module.** The value keeps the Grocery default or the last-used module.
3. **Different active module.** For example, a Food item opened from a Food-scoped search while Grocery is active.

The reverse also occurred: a sold-out grocery item showed **Add To Cart** while Food was active.

The backend was not at fault. The details API sends `Cache-Control: no-cache` and correct data, and a failed details request already showed the error state, not Out of Stock. Which of the three triggers affected the reporting customer was not established from device logs; all three are fixed.

## Behaviour frozen

| Rule | Implementation |
|---|---|
| **Stock follows the item's module** | `SplashController.isStockManaged(moduleType)`; all 13 stock checks use it. An unknown type falls back to the active module's config. |
| **Extras follow the item's module** | `SplashController.isAddOnEnabled(moduleType)`; used by the Extras gate on the Food page and both gates on the quick-add sheet. |
| **Config reload keeps the active module** | `_handleConfigResponse` restores the active module's config, without repeating module side effects. |
| **Resume refresh** | `ItemController.refreshItemAvailability()` runs on app resume on the details pages, only when data is over 5 minutes old, with one request in flight. It updates stock only, keeping quantity and selections. |
| **Failed refresh** | Keeps the last known stock, is never treated as zero, and retries on the next resume. |
| **Wrong-item protection** | A refresh response is ignored if the customer has moved to another item. |
| **Non-JSON 200** | `ItemRepository` treats it as a failed request, not an item. |
| **Genuine out of stock** | Still disables **Add To Cart**. Final enforcement remains the backend at order placement. |

## Unchanged (explicitly)

- Backend, APIs and merchant/admin settings
- Dependencies, `pubspec.yaml`, `pubspec.lock`, version (`1.0.25+36`), signing
- UI design: only conditions and non-visual lifecycle listeners changed
- Cart calculations

## Files implemented

- `lib/features/splash/controllers/splash_controller.dart` — `isStockManaged`, `isAddOnEnabled`, config restore
- `lib/features/item/controllers/item_controller.dart` — stock checks, `refreshItemAvailability`
- `lib/features/item/screens/food_details_screen.dart` — stock check, Extras gate, resume listener
- `lib/features/item/screens/item_details_screen.dart` — stock checks, resume listener
- `lib/common/widgets/item_bottom_sheet.dart` — stock checks, add-on gates
- `lib/features/item/widgets/details_web_view_widget.dart` — stock checks
- `lib/features/cart/controllers/cart_controller.dart` — stock check
- `lib/features/item/domain/repositories/item_repository.dart` — non-JSON guard
- `test/item/item_stock_module_context_test.dart` — NEW
- `test/item/item_food_extras_module_context_test.dart` — NEW

## Testing

**Stock tests: 29/29 passed** (`flutter test test/item/item_stock_module_context_test.dart`, re-run at freeze).

**Food Extras tests: 15/15 passed** (`flutter test test/item/item_food_extras_module_context_test.dart`, re-run at freeze).

**Pre-fix reproduction:** on the code before each fix, the first 11 stock tests gave 6 passed / 5 failed, and the first 11 Extras tests gave 5 passed / 6 failed.

**Combined relevant suites: 331 passed**, established after the final code change: `test/item`, `splash`, `checkout`, `home`, `store`, `favourite`, `location`, `moonjoin`, `profile`.

**Not run:** `test/api`, `auth`, `language`, `notification`, `order`, `rental` and `test/widget_test.dart`.

## Analyzer

`flutter analyze` on the changed files: **no issues**, run after the final change to each file. A whole-project analyze was not run.

## Device validation

**Not performed.** No simulator run, physical-device run, or iOS/Android/web compile has been done for this issue. Device QA and the full regression happen once, after the issue queue is resolved.

## Checkpoint

An isolated worktree holds this implementation for later release-candidate reproduction or rollback:

- **Path:** `/Users/francisadediran/moonjoin-issue1-qa` (detached HEAD at the base commit)
- **Contents:** the 8 production files and 2 test files above, byte-identical to the authoritative tree at freeze, and no other changes
- **Keep it** until a permanent Git checkpoint exists. Its changes are uncommitted.

## Deferred, not part of this freeze

Known and intentionally left open; some may be addressed by later issues:

- **Cart Addons row:** `cart_screen.dart` still reads the global `addOn` flag, so the row can be hidden while the total includes add-ons
- **Veg indicator:** `food_details_screen.dart` and the quick-add sheet still read global flags
- **Food deep link:** `/item-details?id=` opens `ItemDetailsScreen`, which has no Extras section
- **Reconnection:** regaining network without leaving the app does not refresh; only resume does
- **D2:** a refresh cannot tell a removed item from a temporary failure, and may show a snackbar on each stale resume
- **D3:** a 200 response with no `stock` field overwrites the last known stock
- **D4:** only stock is refreshed, so a price can be stale after a flash sale ends
- **D5:** an unexpected parsing error during refresh is uncaught
- **D6:** the config restore has no guard if the active module type is missing from config
- **T1:** the failed-refresh widget test's `requests > 0` assertion also counts the page load
- **T2:** a misleading comment in the race screen test, which also passes from the item-module change alone
- **T3:** the "grocery item while Food is active" test opens `ItemDetailsScreen`, but the real route opens `FoodDetailsScreen`
- **T4:** `_addToCart`, `QuantityButton`, `itemDirectlyAddToCart`, the bottom sheet stock checks, the web stock checks and resume on `FoodDetailsScreen` have no direct tests
