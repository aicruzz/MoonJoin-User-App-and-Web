# Issue 2B — Apply Addon Quantity to Item Quantity Freeze

**Status:** IMPLEMENTED / TESTED / SIMULATOR-VALIDATED / FROZEN (2026-11-05). **PHYSICAL-DEVICE QA AND END-TO-END ORDER VALIDATION NOT YET PERFORMED.**

**Repository:** MoonJoin Customer User App & Web

**Codebase:** `/Users/francisadediran/User app and web`

**Branch / HEAD:** `main` / `344f1a5a732b465945fa238c7af20d7e43df877e` (the fix is uncommitted on top of this commit, together with Issues 1 and 2A)

**Toolchain:** Flutter 3.47.5 / Dart 3.13.4

**Scope:** an optional, per-addon "Apply to item quantity" option that makes a selected addon follow the parent item quantity. An addon without it stays manually controlled.

**Final approved wording:** "Apply to all item quantity" (copy correction, 2026-11-06; see the last section). The rest of this record shows the label as it was during the original review.

---

## Architecture

This is new behaviour built on existing state, not a repair.

- The parent quantity is `ItemController._quantity`. Besides the footer stepper, `initData` and `setExistInCart` write it: `setExistInCart` resets it to 1 on a variation change or reloads it from the cart. The follow rule therefore lives in the controller, not the widgets.
- Addon quantities stay in the existing `addOnQtyList`, which already feeds pricing (`ItemCartHelper.compute`) and `add_on_qtys`. Follow state only writes into that list.
- `_addOnsFollowingItemQuantity` is one set of addon indexes, the only new state.

## Behaviour frozen

| Situation | Behaviour |
|---|---|
| **Apply OFF** | Addon starts at 1, even if the parent is higher, and stays manual |
| **Apply ON** | Addon immediately takes the parent quantity |
| **Parent increases or decreases** | Marked addons follow, including down to 1 |
| **Parent reset by `setExistInCart`** | Marked addons follow to 1; unmarked addons do not change |
| **Multiple addons** | Set per addon; marked and unmarked addons coexist |
| **Turning Apply OFF** | Keeps the current quantity as the manual start and stops following |
| **Manual `−` `+` while ON** | Greyed out and blocked in the controller, with no delete icon. A tap on them does not reach the card behind |
| **Deselecting** | Clears Apply and resets to 1, so a later selection starts clean |
| **Card tap** | Selects; deselects at quantity 1 or while marked; does nothing on an unmarked addon above 1 |
| **Line found in the cart / cart edit** | Loads saved quantities with Apply off, and saved quantities are not overwritten |
| **Opening an item** | Clears Apply |

Available on `FoodDetailsScreen` and on `ItemBottomSheet` (mobile quick add and desktop) through the same shared widgets.

## Known limitations

- **Apply itself is not stored in the cart,** because the existing cart payload stores only numeric addon quantities. Reopening a cart line shows the saved quantity with Apply off.
- **Changing the parent quantity on the Cart screen does not update the addon.** A customer who adds parent 5 with addon 5, then raises the parent to 6 in the cart, keeps addon 5. Changing this would need a backend field and was not done.

## Unchanged (explicitly)

- Backend, APIs, the `add_on_qtys` payload and merchant/admin settings
- Addon pricing: addon price × addon quantity
- Dependencies, `pubspec.yaml`, `pubspec.lock`, version (`1.0.25+36`), signing
- Issue 1 stock logic. Issue 2A's control is extended only to disable itself while following

## Files changed

- `lib/features/item/controllers/item_controller.dart` — follow state, `setAddOnFollowsItemQuantity`, `isAddOnFollowingItemQuantity`, `canDeselectAddOn`, sync and clear points
- `lib/common/widgets/item_bottom_sheet.dart` — shared `AddonApplyToItemToggle`; `AddonQuantityControl` disables while following; `AddonView` shows the toggle
- `lib/features/item/screens/food_details_screen.dart` — toggle on selected cards; card tap uses `canDeselectAddOn`
- `assets/language/en.json`, `ar.json`, `es.json`, `bn.json` — `apply_to_item_quantity`
- `test/item/item_addon_apply_to_item_quantity_test.dart` — NEW

The Arabic, Spanish and Bengali labels have not been reviewed by a native speaker.

## Testing

**Re-run at freeze:**

- Issue 2B tests: **20/20 passed**
- Issue 2A tests: **12/12 passed**
- Issue 1 stock tests: **29/29 passed**
- Issue 1 Food Extras tests: **15/15 passed**

**Relevant suites: 381 passed, 0 failed,** run on this same code earlier the same day: `test/item`, `splash`, `checkout`, `home`, `store`, `favourite`, `location`, `moonjoin`, `profile`, `order`, `language`.

**Deliberate-break check:** 10 behaviours were temporarily broken one at a time, with files restored and checksum-verified. Tests caught 9. The miss was leaving the stepper enabled, which changes nothing because the controller guard still blocks it.

**Not run:** `test/api`, `auth`, `notification`, `rental` and `test/widget_test.dart`.

## Analyzer

`flutter analyze` on the 4 changed Dart files: **no issues**, re-run at freeze. A whole-project analyze was not run.

## Simulator validation

iPhone 16 simulator, iOS 18.2, debug run from the authoritative codebase, item **Fried/Jollof/Rice&Beans** at Perozona (item 10).

**Confirmed by the product owner from screenshots of finger testing:**

- Unselected addons have no quantity control
- Selecting an addon shows quantity 1
- Selected addons can have independent quantities
- Apply can be enabled for one addon
- An Apply-enabled addon follows the parent quantity
- A selected addon with Apply off can remain at a different quantity
- The parent quantity is independent of manual addon quantity
- Apply is shown only for selected addons

**Reviewed in rendered frames, with state driven through the real `ItemController` methods over the Dart VM service.** These were not finger taps, because synthetic clicks did not reach the simulator. Tap handling for these steps is covered by widget tests.

| State | Parent | Chicken (Apply) | Plantains | Rice | Total shown |
|---|---|---|---|---|---|
| Start | 3 | 3 (on) | 2 | off | ₦29,300 |
| Parent up | 4 | 4 (on) | 2 | off | ₦38,400 |
| Parent down to 1 | 1 | 1 (on) | 2 | off | ₦11,100 |
| Plantains deselected | 2 | 2 (on) | off | off | ₦18,200 |
| Chicken deselected, Rice selected | 4 | off | off | 1 | ₦23,900 |

Controller state was also read back for Apply off (parent 2→4, Chicken stays 2) and for deselecting then reselecting (Chicken returns to 1 with Apply off). Each frame's total matches the arithmetic. The run log contains only 4 `apns-token-not-set` entries, which is a simulator push-token limitation, and no overflow errors.

## Visual review

**Result: acceptable. No code change was needed.**

| Check | Finding |
|---|---|
| Two-line Apply label | Wraps cleanly to "Apply to item / quantity", with no clipping |
| Selected card height | About 117pt against about 54pt unselected. Reads as an expanded card, not a broken one |
| Quantity control | Full width of the name column, with about 10pt below it |
| Hierarchy | Name, price, Apply and stepper share one left edge. The Apply checkbox is smaller than the addon checkbox |
| Two selected cards side by side | Equal height and balanced |
| Selected beside unselected | Top-aligned, with empty space under the shorter card. Columns stay aligned, so the grid is uneven but not broken |
| Footer | Stays fixed, with no movement across all reviewed states |
| Clipping, overflow, overlap | None seen |

**Not visually reviewed:** long addon names, narrow phones, Arabic, Spanish or Bengali, the quick-add sheet, and scrolling.

## Not validated

- **No end-to-end order.** Add To Cart and the Cart screen were not observed on the simulator for this issue. Tests confirm the quantity reaches the cart payload (`OnlineCart`).
- **No physical device.** Device QA happens once, after the issue queue is resolved.
- **No approved design for this control.** The approved image has no Apply option or stepper, and the Figma frame was not read. The layout rests on this simulator review.

## Delivery and checkpoints

- No commit, push or deployment. Issue 2B exists only as uncommitted changes in the authoritative tree.
- `/Users/francisadediran/moonjoin-issue2a-qa` holds the Issue 2A state and does not contain Issue 2B. `/Users/francisadediran/moonjoin-issue1-qa` holds Issue 1.
- Unrelated changes preserved: `notification_icon.png`, `docs/FROZEN_REGISTRY.md`, `docs/MIGRATION_LOG.md`, `docs/MOONJOIN_SHARED_DESIGN_LANGUAGE.md`.

## Deferred, not part of this freeze

- All items deferred in `ISSUE_1_MODULE_CONTEXT_STOCK_AND_EXTRAS_FREEZE.md`, including the Cart Addons row

## Copy correction (2026-11-06)

**Final approved wording:** "Apply to all item quantity"

**Why:** after the simulator review, the owner judged that "Apply to item quantity" could suggest the option is required for an addon's quantity to work. The new wording makes clear it is optional and, when on, applies the addon to every unit of the item.

**Copy only.** No change to behaviour, controller logic, pricing, cart payloads, API, backend or the card layout. The translation key `apply_to_item_quantity` is unchanged, and its only consumer is `AddonApplyToItemToggle` in `item_bottom_sheet.dart`, so the label changes on Food Details and on `ItemBottomSheet`.

| Language | Before | After |
|---|---|---|
| `en` | Apply to item quantity | Apply to all item quantity |
| `ar` | تطبيق على كمية المنتج | تطبيق على جميع وحدات المنتج |
| `es` | Aplicar a la cantidad del artículo | Aplicar a toda la cantidad del artículo |
| `bn` | আইটেমের পরিমাণে প্রয়োগ করুন | আইটেমের সম্পূর্ণ পরিমাণে প্রয়োগ করুন |

The Arabic, Spanish and Bengali wording has not been reviewed by a native speaker. Two code comments still quote the old English phrase; they are not displayed.

**Validation:**

- JSON valid in all 4 files. In each file only this one value changed
- Issue 2B tests: 20/20 passed
- Issue 2A tests: 12/12 passed
- Issue 1 stock tests: 29/29 passed
- Issue 1 Food Extras tests: 15/15 passed
- Relevant suites: 381 passed, 0 failed (same suites as above)
- `flutter analyze` on the 4 Dart files that consume or test the key: no issues
- All test runs were repeated after an unexpected Mac shutdown, on the same code

**Simulator (iPhone 16, iOS 18.2, debug run, no release build):** the owner navigated to Fried/Jollof/Rice&Beans and confirmed the new wording. A screenshot of that screen shows "Apply to all item quantity" on both selected cards, wrapping to two lines like the original label. It also shows Plantains with the option on following the parent at 3, Chicken manual at 2, and a total of ₦27,000. That matches 5,800×3 + 3,300×2 + 1,000×3, so behaviour is unchanged.

**Interruption:** the production server (`admin.moonjoin.com`, DigitalOcean) was briefly unreachable during this step because its subscription had lapsed. The on-screen check waited until it was restored.
