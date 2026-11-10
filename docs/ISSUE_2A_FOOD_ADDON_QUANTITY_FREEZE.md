# Issue 2A — Food Extras Addon Quantity Control Freeze

**Status:** IMPLEMENTED / TESTED / SIMULATOR-VALIDATED BY OWNER / FROZEN (2026-11-05). **PHYSICAL-DEVICE QA NOT YET PERFORMED.**

**Repository:** MoonJoin Customer User App & Web

**Base commit:** `344f1a5a732b465945fa238c7af20d7e43df877e` (the fix is uncommitted on top of this commit, together with Issue 1)

**Toolchain:** Flutter 3.47.5 / Dart 3.13.4

**Scope:** restoring the existing addon quantity control on the Food Details Extras section. The optional "Apply to item quantity" enhancement is a separate issue and is not part of this freeze.

---

## Problem

On mobile, a customer could select an Extra on a Food item but could not change its quantity. The selected addon showed no `− 1 +` control and stayed at quantity 1. Admin and Vendor POS show this control correctly, and the User App had it before the redesign.

## Root cause

Commit `84fa9db` (2026-07-11) added `FoodDetailsScreen` and changed `ItemController.navigateToItemPage` so mobile Food browsing opened that page instead of `ItemBottomSheet`.

`ItemBottomSheet`'s `AddonView` contained the quantity control. The page's new `_ExtrasSection` copied only the selection logic (`addAddOn`): it never rendered the control or called `setAddOnQuantity`. The approved image `product_details_for_only_food.PNG` shows selected Extras with no stepper, and the page was built and frozen to match it.

Commit `7c0be07` (2026-08-01) then moved mobile cart editing to the same page, so a saved addon with quantity above 1 could not be changed or deselected there.

## Existing architecture preserved

All of this already existed and is unchanged:

- Addon selection state: `ItemController.addOnActiveList`
- Addon quantity state: `ItemController.addOnQtyList`
- `ItemController.setAddOnQuantity`
- Cart addon quantities: `AddOn.quantity`, `OnlineCart.addOnQtys`, `add_on_qtys`
- Pricing by addon price × addon quantity: `ItemCartHelper.compute`, `CartService.calculateAddonPrice`, backend `Helpers::calculate_addon_price`
- API and cart mapping: `item_cart_helper.dart`, `cart_service.dart`, `checkout_screen.dart`

## Fix

The existing control was restored to the Food Details Extras section through one shared implementation:

- `AddonView`'s control was moved, line for line apart from a `width` parameter, into a shared `AddonQuantityControl` widget in `item_bottom_sheet.dart`. `AddonView` still uses it at width 90.
- A selected card in `_ExtrasSection` renders `AddonQuantityControl` under the price.

## Behaviour frozen

| Rule | Implementation |
|---|---|
| **Unselected addon** | No quantity control |
| **Selected addon** | Shows `− qty +`, starting at 1 |
| **Independent quantities** | Each addon has its own entry in `addOnQtyList` |
| **Parent item quantity** | Separate; the footer stepper is unchanged |
| **Quantity 1** | `−` becomes a delete icon that deselects the addon. This is the User App's original behaviour; Admin's `−` stops at 1 |
| **Card tap** | Selects; deselects only at quantity 1; does nothing above 1 (unchanged) |
| **Cart edit** | Shows and sends the saved quantity |

## Unchanged (explicitly)

- Backend, APIs and merchant/admin settings
- Cart architecture, pricing and addon state management
- Dependencies, `pubspec.yaml`, `pubspec.lock`, version (`1.0.25+36`), signing
- Issue 1 stock logic, resume refresh and `isAddOnEnabled`

## Files implemented

- `lib/common/widgets/item_bottom_sheet.dart` — shared `AddonQuantityControl`; `AddonView` uses it
- `lib/features/item/screens/food_details_screen.dart` — renders it on selected Extras cards
- `test/item/item_food_addon_quantity_test.dart` — NEW

The first two files also carry Issue 1 changes, so they intentionally differ from the Issue 1 checkpoint worktree by this fix.

## Testing

**Addon quantity tests: 12/12 passed** (`flutter test test/item/item_food_addon_quantity_test.dart`, re-run at freeze).

**Issue 1 stock tests: 29/29 passed** (`test/item/item_stock_module_context_test.dart`, re-run at freeze).

**Issue 1 Food Extras tests: 15/15 passed** (`test/item/item_food_extras_module_context_test.dart`, re-run at freeze).

**Pre-fix reproduction:** on the code before the fix, the first 11 addon tests gave 3 passed / 8 failed, all from the missing control.

**Relevant suites: 347 passed, 0 failed**, run on this same code before the simulator validation: `test/item`, `splash`, `checkout`, `home`, `store`, `favourite`, `location`, `moonjoin`, `profile`, `order`. In one earlier run, `test/moonjoin/flash_countdown_test.dart` failed once and then passed on re-run; `SLICE_B_SEARCH_SUGGESTIONS_FREEZE.md` already records it as intermittent.

**Not run:** `test/api`, `auth`, `language`, `notification`, `rental` and `test/widget_test.dart`.

## Analyzer

`flutter analyze` on the 3 changed files: **no issues**, re-run at freeze. A whole-project analyze was not run.

## Simulator validation

- iPhone 16 simulator, iOS 18.2, debug run from the authoritative codebase
- Validated and reported by the product owner from screenshots of the running app

**Owner-confirmed on the simulator:**

- Unselected addon shows no quantity control
- Selecting an addon shows `− 1 +`
- Selected addons keep their own quantities
- Multiple selected addons have independent quantities
- The control is contained within the selected addon card
- The normal item quantity remains separate
- Existing addon selection behaviour remains intact
- Correct visual integration, with no obvious overlap, clipping or broken layout

**Covered by widget tests only, not named in the owner's simulator confirmation:**

- Decreasing to quantity 1 and deselecting with the delete icon
- A deselected addon no longer contributing its cost
- The cart payload and addon pricing after Add To Cart
- Cart edit with a saved addon quantity

## Not validated

- **No production API or order validation:** no order was verified end to end with addon quantities. Tests confirm the quantity reaches the cart payload (`OnlineCart`); the checkout mapping is existing code, read but not tested.
- **No physical device:** device QA happens once, after the issue queue is resolved.
- **Figma:** the Figma MCP was not authenticated, so frame `1:1226` was not read. The approved image shows no quantity control, so the control's position is an addition approved by the owner on the simulator.

## Checkpoint

There is no separate worktree for Issue 2A. The fix exists only as uncommitted changes in the authoritative tree. `/Users/francisadediran/moonjoin-issue1-qa` holds Issue 1 only.

## Deferred, not part of this freeze

- **"Apply to item quantity":** the next issue
- All items deferred in `ISSUE_1_MODULE_CONTEXT_STOCK_AND_EXTRAS_FREEZE.md`, including the Cart Addons row
