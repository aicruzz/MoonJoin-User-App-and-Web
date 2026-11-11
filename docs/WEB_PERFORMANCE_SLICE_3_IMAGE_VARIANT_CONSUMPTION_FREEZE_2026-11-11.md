# Web Performance Slice 3 — Flutter Web Image Variant Consumption — LOCAL FREEZE

**Date:** 11 November 2026
**Codebase:** `/Users/francisadediran/User app and web` (MoonJoin User App & Web)
**Branch:** `main` · **HEAD:** `239b9dfeff725a2f95ada74517d76af4f46e8a44` (= `origin/main`)
**Toolchain:** Flutter 3.47.5 · Dart 3.13.4 · app version `1.0.26+37` · `appVersion` 3.8 (all unchanged)
**Status:** IMPLEMENTED / VALIDATED / **FROZEN LOCALLY — NOT COMMITTED, NOT BUILT, NOT DEPLOYED**

---

## 0. Purpose

Backend Web Performance Slice 2 (`admin.moonjoin.com/docs/WEB_PERFORMANCE_SLICE_2_IMAGE_VARIANT_PUBLISHING_FREEZE_2026-11-11.md`,
frozen locally, **not deployed**) publishes six additive variant fields. The deployed web bundle
`web-v1.0.26+37` reads `image_variants` only for products. Slice 3 makes Flutter Web read and
choose from the six new fields, reusing the existing product variant architecture.

This slice covers choosing the variant only (A). It does not change how images are fetched (B)
and does not remove `/image-proxy` (C).

## 1. Starting working-tree state (preserved, untouched by this slice)

| Path | State |
|---|---|
| `android/app/src/main/res/drawable/notification_icon.png` | owner's unrelated change — checksum verified unchanged |
| `docs/FROZEN_REGISTRY.md`, `docs/MIGRATION_LOG.md` | owner's unrelated change — unchanged |
| `docs/MOONJOIN_SHARED_DESIGN_LANGUAGE.md` (untracked) | owner's unrelated file — unchanged |
| `docs/USER_APP_PAGINATION_PROCESSING_TIME_COUNTDOWN_FREEZE.md` | pending release-record edit — unchanged |
| `lib/common/widgets/paginated_list_view.dart`, `test/store/store_product_pagination_test.dart` | uncommitted pagination fix — unchanged |
| `lib/features/store/screens/store_screen.dart` | uncommitted pagination fix (`limit:` / `preloadScreens: 3`). **Slice 3 adds 1 import + 1 cover-URL line in the same file; the two pagination lines are byte-identical** |

Nothing was staged, no stash existed, and none was created. Nothing was reset, cleaned, stashed or amended.

## 2. Architecture

```
API JSON ──► model.fromJson ──► *_full_url  +  *_variants (parseImageVariants)
                                    │
                                    ▼
             pickWebImageUrl(original, variants, rendered box, devicePixelRatio)
                 ├─ not web → original, exactly (mobile unchanged)
                 └─ web     → pickImageUrl(...)   ← the frozen product picker, unchanged
                                    │
                                    ▼
          CustomImage (unchanged) ─► web: ${baseUrl}/image-proxy?url=<chosen> ─► CachedNetworkImage
```

- **No second image system.** `pickImageUrl` stays the only size-selection logic.
  `pickWebImageUrl` is a 10-line wrapper: `if (!isWeb) return original; return pickImageUrl(...)`.
  `isWeb` defaults to the project's existing `kIsWeb`; only tests override it.
- **`parseImageVariants(dynamic)`** applies the same rules `Item.fromJson` uses for
  `image_variants`. Only non-empty String URLs under non-empty String keys are kept. Absent,
  `null`, `[]` (what the backend sends when no size exists), wrong types, or nothing usable all
  become `null`.
- **Item / Product untouched:** `item_model.dart` and `pickImageUrl` are byte-identical;
  `custom_image.dart` is byte-identical.

## 3. Model fields added (`fromJson` only; not in `toJson`, constructors unchanged)

| Model | File | Field ← JSON key |
|---|---|---|
| `Store` | `lib/features/store/domain/models/store_model.dart` | `logoVariants` ← `logo_variants`, `coverPhotoVariants` ← `cover_photo_variants` |
| `CategoryModel` | `lib/features/category/domain/models/category_model.dart` | `imageVariants` ← `image_variants` |
| `Banner` | `lib/features/banner/domain/models/banner_model.dart` | `imageVariants` ← `image_variants` |
| `ModuleModel` | `lib/common/models/module_model.dart` | `iconVariants` ← `icon_variants`, `thumbnailVariants` ← `thumbnail_variants` |

`*_full_url` parsing is unchanged, including `Store`'s existing `?? ''` defaults. A module
restored from saved settings (`splash_repository` stores `module.toJson()`) simply has no
variants and keeps its original URL.

## 4. Banner alignment strategy

`BannerController` still produces the same plain URL lists. It gains two additive,
index-aligned lists, `bannerVariantList` and `featuredBannerVariantList`:

- They are built in the **same iteration** as `_bannerImageList` / `_featuredBannerList`
  (`_prepareBanner`, `getFeaturedBanner`), with one entry per URL entry.
- Campaign entries get `null`. Banner entries get `banner.imageVariants` (often `null`).
- Duplicate-URL handling is unchanged: the suffixed entry (`url + index`) keeps its own
  banner's variants.
- The widgets pass **the existing list entry** as `original`, so every fallback is
  byte-identical to today, including the suffixed duplicate.
- `clearBanner()` also clears the variant list. The widgets index it defensively (`null` when
  the list is shorter).
- The taxi/rental banner list, promotional banners, advertisements and special criteria are
  untouched.

## 5. Display surfaces wired (image URL selection only)

Box dimensions are the ones each widget already renders. Where a dimension is
`double.infinity` or set by an `AspectRatio`, the real constraint is read with `LayoutBuilder`,
which is the same pattern as the frozen `item_card.dart`. No `Intrinsic*` ancestors exist in
any affected file or its callers. A box that is still unbounded makes the picker return the
original.

| Surface | File | Field | Box passed |
|---|---|---|---|
| Store card logo | `common/widgets/card_design/store_card.dart` | logo | 50×50 |
| Store card (distance) cover / logo | `common/widgets/card_design/store_card_with_distance.dart` | cover / logo | LayoutBuilder / 65×65 |
| Item card store branch | `common/widgets/item_widget.dart`, `web_item_widget.dart` | logo | existing `resolvedImageWidth/Height` |
| Store page desktop cover | `features/store/screens/store_screen.dart` | cover | 590×240 |
| Store description logo | `features/store/widgets/store_description_view_widget.dart` | logo | 140×140 desktop / 70×60 |
| Web store card cover | `features/home/widgets/web/widgets/store_card_widget.dart` | cover | LayoutBuilder width × 120 |
| Web recommended | `web_recomanded_store_view_widget.dart` | logo | LayoutBuilder width × 60 |
| Web best nearby | `web_best_store_nearby_view_widget.dart` | logo | 70×70 |
| Web new on mart / top offers | `web_new_on_mart_view_widget.dart`, `web_top_offers_near_me.dart` | logo | 90×90 |
| Popular store card | `home/widgets/components/popular_store_card_widget.dart` | cover / logo | LayoutBuilder width × 170 / 40×40 |
| Visit again | `common/widgets/card_design/visit_again_card.dart` | logo | 54×54 |
| MoonJoin store card | `features/store/widgets/moonjoin_store_card.dart` | cover / logo | LayoutBuilder (AspectRatio 2.55) / 42×42 |
| Store hero header | `features/store/widgets/store_hero_header.dart` | cover | 104×104 |
| Category screen / pop-up | `category/screens/category_screen.dart`, `home/widgets/category_pop_up.dart` | image | 50×50 |
| Web categories (×3) | `home/widgets/web/web_category_view_widget.dart` | image | LayoutBuilder width × 80 / 80 / 120 |
| Web module bar | `home/widgets/web/module_widget.dart` | icon | 30×30 |
| Web landing thumbnail / icon | `location/screens/web_landing_page.dart` | thumbnail / icon | 450×450 / 45×45 |
| Module dialog | `location/widgets/module_dialog_widget.dart` | icon | 80×80 |
| Web banner carousel | `home/widgets/web/web_new_banner_view_widget.dart` | banner | LayoutBuilder (carousel item) |
| Special offers | `home/widgets/special_offers_view.dart` | featured banner | existing `cardWidth × cardHeight` |

Out of scope and unchanged: order and tracking store images (order payloads publish no variants),
campaign store logos, search suggestions, rental/taxi models, `OrganicModuleIcon` consumers,
`module_landing_view`, `parcel_app_bar_widget`, chat, and the mobile `all_store_screen` banner.

## 6. Size selection and fallback

Selection is the frozen picker's rule (`sm` 320 / `md` 720 / `lg` 1440, matching backend
`ImageVariants::VARIANTS`). The target is `max(width, height) × devicePixelRatio`. The picker
takes the smallest tier that covers the target and only ever steps upward. Examples, all tested:

- 40–90 px logos and icons → `sm`
- 50–120 px categories → `sm`
- 104 px hero cover at 3× → `sm`
- 300×170 cover at 2× → `md`
- 590×240 desktop cover → `md` at 1×, `lg` at 2×
- 450 px landing thumbnail → `md` at 1×, `lg` at 2×
- 1170 px desktop banner → `lg` if published, otherwise the original

**Fallback order:**
1. The tier that fits.
2. The next larger tier that exists.
3. The original `*_full_url` (or the existing banner list entry).
4. The existing `CustomImage` placeholder / error widget.

The picker never chooses a variant smaller than the box.

## 7. Transport and security

- `/image-proxy` is unchanged and still used. Every chosen URL goes through the unchanged
  `CustomImage` web wrapper.
- No storage URL is ever built in Dart. Only URLs published by the API are used.
- No CORS, nginx, storage-permission or direct-storage change was made.
- Why direct storage is not used (audit of 11 Nov 2026): both CanvasKit image paths need CORS:
  `<img crossOrigin=anonymous>` (`html_image_element_codec.dart:121`) and then `fetch`
  (`canvaskit/image.dart:378`). Direct `/storage` sends no `Access-Control-Allow-Origin`; the
  proxy sends `*`.
- The backend publishes variants only for its six public directories (`ImageVariants::PRIVATE_DIRECTORIES`
  is excluded). No delivery-man media is involved.
- The proxy itself is unchanged. Its existing acceptance of any `/storage/app/public/` file is a
  pre-existing property that this slice does not widen.

## 8. Validation

| Run | Result |
|---|---|
| Focused: `test/media/web_image_variant_consumption_test.dart` | **57 / 57 pass** (82 `expect` call sites; the delegation test alone checks 512 box/density/variant combinations) |
| Browser: `flutter test --platform chrome test/media/web_image_variant_transport_browser_test.dart` | **4 / 4 pass**: `kIsWeb` is true, the default helper selects the variant, and `CachedNetworkImage.imageUrl == '${baseUrl}/image-proxy?url=<variant>'` |
| Existing variant tests: `image_variant_helper_test.dart` (25) + `listing_card_variant_selection_test.dart` | **40 / 40 pass** |
| Regression: `test/{item,splash,checkout,home,store,favourite,location,moonjoin,profile,order,language,notification,api,auth,rental,common}` + focused | **561 passed, 0 failed** (the previous 504 baseline + 57) |
| `flutter analyze` on all 29 changed lib files + both test files | **0 new issues.** 2 `info`s (`unnecessary_underscores`, `web_landing_page.dart:258`) are pre-existing at HEAD line 257 (shifted one line by the import) |

**Deliberate-break checks** (each a temporary sabotage, then restored and verified by SHA-256; the
suite was re-run green afterwards):

| Sabotage | Failures detected |
|---|---|
| Mobile branch removed from `pickWebImageUrl` | 3 |
| Box halved before delegating to the picker | 13 |
| Parser keeps empty-string URLs | 3 |
| Campaign `null` dropped from the banner variant list | 2 |

**Production (read-only GETs only, 11 Nov 2026):**
- `/api/v1/module`, `/api/v1/banners` and `/api/v1/categories` return 200 with **0** variant
  keys. This is expected, because Slice 2 is not deployed.
- `/image-proxy` serves `module/sm/2026-09-22-6ab27289736c3.webp` as 200, `image/webp`, 8,676 B
  (original 135,229 B).
- `https://moonjoin.com/` returns 200.

**Known pre-existing failures:** none in the suites run.

## 9. Files changed by Slice 3 (SHA-256 after freeze)

29 lib files: 185 insertions and 49 deletions (excluding the two pre-existing pagination lines in `store_screen.dart`). All deletions are image-URL expressions,
`CustomImage(` lines that were rewrapped, or two comments made stale by this slice.

```
be804ad35a1d888481b2a72cd34072fafb9fdad3de555e4611f8b7b98c8ffb04  lib/common/models/module_model.dart
aef6dbf6d2d6fc296bf4fa9d491769fe996003c9fad1961137cd41edd5b26c59  lib/common/widgets/card_design/store_card.dart
93c616f5a5e2a9ee0a4525ef302e080aee0377e4455496a3598301f3efa9183c  lib/common/widgets/card_design/store_card_with_distance.dart
647e7d6cf1de67b1efb811e5f82104087251513ab8a8a7894f76b69a3dd886dd  lib/common/widgets/card_design/visit_again_card.dart
df1e1913a1ad81fabc7fe41325498a8880a14892d95ad87ed77644c7a028a7b0  lib/common/widgets/item_widget.dart
0ccca798617cb7bd4e3634f56f53e0d29e1631cd3cd26d8c0c3ef1bbc1e004a0  lib/common/widgets/web_item_widget.dart
b9c4ea899323c2a4af7acaef412753e80db9ed14a95db6c7a76b7ad1dd7d212c  lib/features/banner/controllers/banner_controller.dart
c04b2d96423dcb8acef1767627a97b89db4395072824318713510caaa27c9031  lib/features/banner/domain/models/banner_model.dart
a729d4fb5ebef9a294773fc0d05958b30edb259cab45ffb75325487cf0b34b8f  lib/features/category/domain/models/category_model.dart
345c7107602a3b2652807e5b0007abdd272344d827fb873475dc42d5e2d9f3cf  lib/features/category/screens/category_screen.dart
f8dab5c6516ed6a62287bce42bd957f6a6edc46ffab3c7a79984f4cbe4da4664  lib/features/home/widgets/category_pop_up.dart
8d7e34dd3fd1b39476105895c0a1eb821f9500d9311afa4ba1f29a1f77324ccf  lib/features/home/widgets/components/popular_store_card_widget.dart
3a021093763fc40d82ba9fb5e07cf256bbf6865488fa482a424be05433b35e0a  lib/features/home/widgets/special_offers_view.dart
c14aa733da6cef418b7b7773199779dc7970241518aaf815edb60e81deb73f59  lib/features/home/widgets/web/module_widget.dart
98fccc94dcc674ed696f9a9a09a97122c8ec99b5d7eea9b7c63cac24397be9c2  lib/features/home/widgets/web/web_best_store_nearby_view_widget.dart
cae5eb9de52c90a6ca0e245ca4525e908c7d8ba9a52b89c8bab9cadeff8006b0  lib/features/home/widgets/web/web_category_view_widget.dart
fc0c87d47e4e7161612b827d16b0a6cff1d2f3284ed089e4e6e19d42def018b5  lib/features/home/widgets/web/web_new_banner_view_widget.dart
8584efabf45ec38b1bdcbc46866339ef97322b82381d994b26f71b719528e3b3  lib/features/home/widgets/web/web_new_on_mart_view_widget.dart
b635f4ad53f2c3357a71fd9261ee0865168e06986cebc27feaf0275559ad1bfe  lib/features/home/widgets/web/web_recomanded_store_view_widget.dart
fafd0c3defe8b614d647226a85781184b66f82f33bf2a5abb65849fa0369b491  lib/features/home/widgets/web/web_top_offers_near_me.dart
f24a7b407a52ff36328242008fdc1df3d6ac03c043117f47da4c7d6864611591  lib/features/home/widgets/web/widgets/store_card_widget.dart
693ae65a7bb103e003b82f4d95e9792629bb028f7522f29b738746b42547a878  lib/features/location/screens/web_landing_page.dart
22182d4d0e1c74456df8462aa5a5d9734ac147e7c5114fe7d12b0f3ec5e03af2  lib/features/location/widgets/module_dialog_widget.dart
c4650cc3a6f85374255b28736a3422e747e885000e2ea838df38b786566ac67c  lib/features/store/domain/models/store_model.dart
178b4657402da54e2a759495af51db1ff5c378b4e371b1971fdef78457ba02da  lib/features/store/screens/store_screen.dart   (also carries the pagination fix)
fd95e2433a2802cd19b14c5e96b2b47287e5467da31ca8a9851cc34d9d9a5aea  lib/features/store/widgets/moonjoin_store_card.dart
ff843f9152462a218a67e559bc87f22e1b486ff98519344f924d0ba1c5a1775b  lib/features/store/widgets/store_description_view_widget.dart
f01393301a526290520214553a0f912c5739d4d4c31095b0742208564ac13355  lib/features/store/widgets/store_hero_header.dart
30e009fe01d96742aa50bfaf5310d605f20df5572a824f51b61c612c8e6a756a  lib/helper/image_variant_helper.dart
51785afffb487c33cd1c51949b89324f7b542a42d7649286038c00270f6a7e3a  test/media/web_image_variant_consumption_test.dart   (new)
b4a699a40b4d2bfdc807efd8b31577718a6f6a6931b2a1c887b4b5fb6a076aa5  test/media/web_image_variant_transport_browser_test.dart   (new)
```

Byte-identical to HEAD / baseline: `lib/common/widgets/custom_image.dart`,
`lib/features/item/domain/models/item_model.dart`, `pubspec.yaml`, `pubspec.lock`.

## 10. Mobile preservation

- `pickWebImageUrl` returns the original object (`same()`) on every non-web call. This is
  proven over every surface box and density, and with the compile-time default (`kIsWeb` is
  false in the VM).
- A rendered `SpecialOffersView` with variants present hands `CustomImage` and
  `CachedNetworkImage` exactly the existing URL entries.
- The `LayoutBuilder` wrappers are layout-transparent: they size to their child and pass
  constraints through. This is the same construct the frozen product `item_card.dart` already
  uses on both platforms.
- The frozen product `pickImageUrl` remains platform-agnostic, as before.

## 11. Deployment status and sequencing

- **Slice 2 (backend) remains NOT deployed.**
- **Slice 3 is NOT committed, NOT built, NOT archived, NOT deployed.** Live web is still
  `web-v1.0.26+37`.
- Slice 3 is a no-op against today's production API: there are no variant fields, so every
  surface falls back to its original URL. Shipping it alone is therefore harmless, but it saves
  bytes only once Slice 2 is live.
- Recommended order: commit Slices 2 and 3 → deploy backend Slice 2 → build and deploy web from
  the tag (existing release procedure) → measure.

## 12. Rollback / reversion

- **Before commit:** the Slice 3 change is the 29 lib files and 2 test files above. Reverting
  them restores today's behaviour. `store_screen.dart` must be reverted *only* at its cover
  line and helper import, because it also carries the pagination fix.
- **After a web deploy:** use the existing release procedure. Point `current` back at
  `releases/web-v1.0.26+37`; no backend action is needed.
- **Backend independence:** Slice 3 tolerates absent fields, and Slice 2 is additive, so either
  side can be rolled back alone without breaking the other.

**Final state:** `WEB PERFORMANCE SLICE 3 — IMPLEMENTED / VALIDATED / FROZEN LOCALLY — NO BUILD / NO DEPLOYMENT`
