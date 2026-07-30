# MoonJoin — Development Environment Notes

## iOS Simulator: native-assets `objective_c.framework` platform bug (Flutter #180603)

**Symptom:** on the **iOS Simulator**, after an **incremental build / hot reload**, **all network images break app-wide**
(Home module icons, banners, store/product/wishlist cards, etc.), with runtime errors like:
`Couldn't resolve native function 'DOBJC_initializeApi' in 'package:objective_c/objective_c.dylib' … Failed to load
dynamic library 'objective_c.framework/objective_c'`.

**Proven root cause (not a MoonJoin regression, not a package incompatibility):**
- `objective_c` (transitive via `path_provider_foundation` 2.6.0) is a Dart **native-assets** framework.
- On **incremental/hot-reload** builds, Flutter's `resident_runner.dart` `_environment` omits `kSdkRoot`, so the
  `native_assets` build step logs *"Target native_assets required define SdkRoot but it was not provided"* and the
  `objective_c` dylib is left built for the **iOS device platform (Mach-O platform 2)** instead of **iOS Simulator
  (platform 7)**. `dyld_info -platform` confirms `platform iOS` on the sim dylib while `Flutter.framework`/`App.framework`
  are `platform 7`. The simulator's dyld cannot load a device-platform dylib → `dlopen` fails → `path_provider` fails →
  `cached_network_image` (used by `CustomImage`) can't resolve its cache dir → **all images fail**.
- **Clean builds** provide `SDKROOT` → correct simulator dylib → images work. **Physical-device builds are unaffected**
  (device platform is correct there).
- Known **OPEN** upstream bug: **flutter/flutter #180603** (P2; stable 3.38.5 + master affected; iOS simulator,
  incremental/hot-reload only; `flutter build` full builds unaffected). No fix released yet.

**Approved project workflow (owner decision 2026-07-29 — do NOT pin/override or downgrade `path_provider_foundation`):**
1. Keep the project aligned with the **official dependency graph** while #180603 is open (no `dependency_overrides`).
2. Use **incremental builds during development**.
3. When a screen needs **final visual QA (especially images)**, do a **clean build first**
   (`flutter clean && flutter run`, or uninstall + `flutter run`).
4. **Verify all functional behavior on the physical iPhone before freezing each phase.**
5. **Monitor #180603**; once an official fix ships, remove this temporary workflow.
6. Do **not** spend further engineering time on this unless it starts affecting **physical-device builds or production
   releases**.

*(Quick simulator resets seen during QA: after a clean install the sim GPS defaults to Cupertino — set it with
`xcrun simctl location <device> set 8.1637573,4.2744448` for Ogbomoso. See `favorites-and-nav-toolchain` memory.)*
