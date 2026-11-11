# Web Safari Black Image Fix Freeze — 2026-11-11

## Scope

- User App & Web only (`/Users/francisadediran/User app and web`), **web build only**.
- Every `CustomImage` on the web: categories, Top Brands/store logos, store covers,
  banners, Highlights/advertisements and other image cards.
- Mobile (iOS/Android) image rendering is unchanged.

## Symptom

On a physical iPhone 15 Plus (Safari, iOS 18.6), on https://moonjoin.com, images first
show correctly. After **Home → Store → back to Home**, several families turn **solid
black** or back to the placeholder at the same moment. The URL is unchanged, nothing is
requested again, `img.decode()` succeeds, there is no WebGL context loss and the backend
returns 200.

Not caused by Slice 3: images that don't use variants (categories, Top Brands) fail the
same way. **1.0.26+37 has the same defect.**

## Root cause (proven)

- Flutter 3.47.5 CanvasKit on browsers without WebCodecs `ImageDecoder` (iOS Safari)
  decodes **every** network/byte image through a browser `<img>`: by URL
  (`CkImageElementCodec`), or bytes through a `blob:` URL (`CkImageBlobCodec`). It draws
  the image as a lazy texture that reads from that element
  (`MakeLazyImageFromTextureSourceWithInfo`).
- When the image's reference count reaches 0, `ImageElementImageSource._doClose()` runs
  `img.src = ''`. A recorded picture can still draw the image afterwards. The next
  texture upload then reads the emptied element and draws black.
- Navigation triggers it: the image cache is at its 100 MB limit, so the home images are
  evicted while a store page is open.

Evidence:
- On the device, the engine cleared exactly the `<img>` elements behind the images that
  went black (8 categories + 28 store images) at the moment of returning Home.
- The same production files with only `img.src = ''` blocked kept every image real on
  the same flow.

`ImageRenderMethodForWeb.HttpGet` does **not** fix it: on Safari the downloaded bytes
are still decoded through a `blob:` `<img>`. That experiment was reverted.

## Implementation

| File | Change |
|---|---|
| `lib/common/widgets/custom_image.dart` | Web: `OctoImage` + `WebRasterImage` with the same `/image-proxy` URL, placeholder, error widget and fades (1000 ms out, 500 ms in) as before. Mobile: the original `CachedNetworkImage` block, unchanged. |
| `lib/common/widgets/web_raster_image.dart` | New `ImageProvider`. Keyed by URL; evicts a failed load so a later request retries. |
| `lib/common/widgets/web_raster_image_decoder_web.dart` | `fetch` → `createImageBitmap` → `OffscreenCanvas` pixels → premultiply → `ui.decodeImageFromPixels`. The result is a raster image owned by CanvasKit, with no `<img>`/bitmap source to clear. |
| `lib/common/widgets/web_raster_image_decoder_stub.dart` | Non-web stub (never reached in the apps). |
| `pubspec.yaml` / `pubspec.lock` | `octo_image: ^2.1.0` and `web: ^1.1.1` declared direct. Both were already locked as transitive dependencies, at the same versions and hashes. |
| `test/media/web_raster_image_browser_test.dart` | New browser regression test (below). |
| `test/media/web_image_variant_transport_browser_test.dart` | Reads the proxied URL from `WebRasterImage` instead of `CachedNetworkImage`. The expected URLs are unchanged. |

Unchanged: URL and variant selection (`image_variant_helper.dart`), `/image-proxy`, sizes,
fit, color, placeholder, error widget and the scale animation. No backend change.

## Validation

- **Browser regression test, 3/3 pass.** It records a picture that draws the image,
  releases every reference, rasterises the picture and checks the pixels:
  - the raster image keeps them;
  - load → evict → reload stays renderable;
  - a control shows the old `<img>` path losing them.
  - Deliberate break (decode forced through `<img>`): fails with `[0, 0, 0, 255]`, the
    black symptom.
- Chrome transport + raster tests 7/7. `test/media` (VM) 57/57. Broad suites
  (`test/{item,splash,checkout,home,store,favourite,location,moonjoin,profile,order,language,notification,api,auth,rental,common}`) 504/504.
  `flutter analyze` on the changed files: no issues.
- **Physical iPhone 15 Plus, Safari 18.6**, clean non-instrumented release build
  (QA copy `moonjoin-qa-imagefix-raster`):
  - Flow: Food home, stores 50/22/56/50/22 with a return Home after each, then
    categories and back; 3.6 min with the banners cycling.
  - Result: categories, banners, Top Brands and store images stayed real. No black
    image, no placeholder regression, no reload needed.

## Version / state

- Flutter 3.47.5, Dart 3.13.4. App `1.0.27+38`, `appVersion` 3.9 (unchanged).
- Base: `main` @ `6244de2`. Not pushed, tagged or deployed at freeze time.
- Production at freeze time: `web-v1.0.27+38`, which does not contain this fix.
