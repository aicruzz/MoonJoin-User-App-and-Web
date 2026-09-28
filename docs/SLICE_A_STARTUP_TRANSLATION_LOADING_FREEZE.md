# Slice A — Startup Translation Loading Optimization — Production Freeze

> **FROZEN (owner-approved 2026-09-28).** First performance slice from the MoonJoin Customer User App & Web performance audit.
> Frontend-only. **Reuse only — do not fork, duplicate or re-optimize.** Reopening requires a production bug, a measured
> regression, or an explicit owner request.

---

## 1. Slice Title

**Slice A — Startup Translation Loading Optimization** (MoonJoin Customer User App & Web).

## 2. Objective

Remove unnecessary work from the pre-`runApp()` startup path **without removing any language**. All four MoonJoin languages —
Arabic, Bengali, English, Spanish — remain fully supported and selectable. Only the work that a given session cannot use is
deferred.

## 3. Baseline Behaviour (before)

`get_di.init()` looped over every entry in `AppConstants.languages` and, for each, performed
`await rootBundle.loadString(...)` followed by `jsonDecode(...)` — **four sequential asset reads and four JSON decodes on the
UI isolate before the first frame**, regardless of which language the session used.

| Asset | Bytes |
|---|---|
| `ar.json` | 121,513 |
| `bn.json` | 171,780 |
| `en.json` | 95,009 |
| `es.json` | 104,489 |
| **Total** | **492,791** (7,676 keys) |

`LocalizationController.setLanguage()` was `void` and called `Get.updateLocale(locale)` immediately.

## 4. Implemented Behaviour (after)

Startup resolves the persisted language code against `AppConstants.languages` and loads a **set** of at most two languages:
English always, plus the active language when it differs. Using a set guarantees English is never loaded twice, because both
entries are the same `LanguageModel` instance from `AppConstants.languages`.

Every other language is loaded **on demand** when the user selects it, through the existing GetX API.

## 5. Startup Loading Matrix

| Session language | Loaded at startup | Bytes | vs 492,791 |
|---|---|---|---|
| **English** (also default / unknown / malformed) | `en` | 95,009 | **−81%** |
| **Arabic** | `en` + `ar` | 216,522 | −56% |
| **Bengali** | `en` + `bn` | 266,789 | −46% |
| **Spanish** | `en` + `es` | 199,498 | −60% |

The languages not listed for a session are **not read and not decoded** at startup. All four remain declared under
`assets/language/` in `pubspec.yaml`, and the language pickers read `AppConstants.languages`, so **all four stay visible and
selectable in every picker**.

## 6. GetX Fallback Preservation

`fallbackLocale` remains `en_US` (`main.dart`), unchanged. **English is therefore loaded in every session,
unconditionally** — this is non-negotiable, because `.tr` resolves a key missing from the active language through the
fallback locale before returning the raw key.

Nothing about GetX translation-key resolution, fallback semantics or the localization architecture was changed.

## 7. Runtime Lazy-Loading Behaviour

`LocalizationController.setLanguage()` is now `Future<void>`. Before the locale changes it calls
`_ensureTranslationsLoaded(locale)`, which:

1. Builds the translation key via the shared `localeTranslationKey(languageCode, countryCode)` → `en_US`, `ar_SA`, …
2. Returns immediately when `Get.translations` already contains that key — an already-loaded language costs nothing on
   subsequent switches.
3. Otherwise loads the asset and calls **`Get.appendTranslations({key: map})`** — the existing GetX 4.7.3 API.

`Get.translations` is itself the session cache. **No new cache was created.** Appended translations are deliberately not
persisted, so each cold start still loads only what that session needs.

## 8. Runtime Failure Safety

A switch is applied only when the language is usable. `_ensureTranslationsLoaded` returns a `bool`, and on `false`
`setLanguage` returns before anything is applied:

- `Get.updateLocale()` is **not** called for the failed locale.
- The failed language is **not persisted**, so it cannot survive a restart.
- No post-switch side effect runs (`updateHeader`, `HomeScreen.loadData`, `getModules`).
- The user remains on the language they already had, and no raw translation key is shown.

Startup applies the same discipline: an unknown, empty or malformed saved code resolves to English via
`firstWhere(..., orElse: fallback)`, and a missing or malformed asset is skipped rather than thrown — a bad language can
never stop the app reaching `runApp()`.

**Known limit:** if `en.json` itself were missing or corrupt there would be no translations and `.tr` would return raw keys.
That is a build-integrity failure with no in-app remedy; previously it would have thrown before `runApp()`, so the change
degrades instead of crashing.

## 9. Files Changed

| File | Role |
|---|---|
| `lib/util/messages.dart` | Shared `loadLanguageTranslations()` loader + `localeTranslationKey()`; returns `null` instead of throwing |
| `lib/helper/get_di.dart` | Startup loads English + the saved language only; removed the two imports that existed solely for the old loop |
| `lib/features/language/controllers/language_controller.dart` | `setLanguage` → `Future<void>`; `_ensureTranslationsLoaded` → `Future<bool>`; load-then-switch, abandon on failure |
| `lib/features/language/screens/language_screen.dart` | `_onNext` awaits before navigating (`if (!mounted) return;`) |
| `lib/features/language/screens/web_language_screen.dart` | `onPressed` awaits so the confirmation renders in the new language |
| `test/language/startup_translation_loading_test.dart` | New — 14 focused tests |

The loader lives in the existing `messages.dart` rather than a new file: `get_di.dart` already imports
`LocalizationController`, so placing it in the controller would have created an import cycle.

Three call sites were reviewed and deliberately left unchanged because no UI depends on completion:
`language_card_widget.dart`, `web_menu_bar.dart`, `setting_page.dart`. `flutter_lints` enables neither
`unawaited_futures` nor `discarded_futures`, so fire-and-forget calls raise no analyzer issue.

## 10. Tests and Results

| Suite | Result |
|---|---|
| `flutter test test/language/` | **14/14 pass** |
| `flutter test test/profile/` | **20/20 pass** |
| `flutter test test/item/` | **pass** |

Coverage: all four languages still declared with English first; every bundled language decodes to a non-empty map; missing
and empty codes return `null` without throwing; locale-key format; saved-code resolution (`ar`/`bn`/`es`/`en` → themselves,
unknown/empty/null/garbage → English); English loaded exactly once for an English session; exactly English + X otherwise;
unused languages absent from the startup set; `appendTranslations` makes a language resolvable while English survives; a key
missing from the active language falls back to English rather than the raw key; an unknown key still returns itself; and a
failed switch changes nothing — locale unchanged, nothing persisted, no side effect, no raw keys.

## 11. Analyzer

- Scoped over all Slice A files: **No issues found.**
- Project-wide: **31 issues — 0 errors, 2 warnings, 29 infos**, the exact pre-existing baseline. The two warnings are
  `invalid_use_of_protected_member` in `lib/helper/pusher_helper.dart`, unrelated to this slice.

## 12. Performance Measurement — and its caveat

A temporary harness (deleted after the run) measured **only** the asset-read + JSON-decode work removed from the
pre-`runApp()` path:

| Load set | Cold (first run) | Warm (runs 2–5) |
|---|---|---|
| `en+ar+es+bn` (baseline) | ≈ **26.5 ms** | ≈ 5.1 – 6.7 ms |
| `en` (English session) | ≈ **1.4 ms** | ≈ 1.3 – 3.3 ms |
| `en+bn` (worst case) | ≈ 2.6 ms | ≈ 3.2 – 3.6 ms |

**These are NOT end-to-end time-to-first-frame measurements.** They were taken on the macOS host in the Dart VM under
`flutter_test`, not on a mobile device, and measure one component of startup — Firebase init, notification init and DI still
run. Absolute values on a mid-range device will be higher; the relative reduction is what transfers. **No time-to-first-frame
number has been claimed or fabricated.**

## 13. Web Network Verification — PENDING

Browser DevTools verification has **not** been performed. To verify: serve a web build, open DevTools → Network, filter
`language`, hard-reload, and confirm only `en.json` (plus the saved language) is requested; then switch languages and
confirm the newly selected file is fetched exactly once.

Static evidence in support: `assets/language/` remains a declared asset directory, and
`rootBundle.loadString('assets/language/$languageCode.json')` in `messages.dart` is now the **only** place in `lib/` that
reads a language asset.

## 14. Real-Device UI Verification — PENDING

On-device confirmation of Arabic/Bengali/Spanish rendering, RTL behaviour, and the
English → Arabic → Bengali → Spanish → English switch loop has not been performed. These are UI-rendering behaviours covered
at the logic level by the test suite but not yet observed running.

**Both §13 and §14 are validation limitations, not defects, and are not reasons to alter the implementation.**

## 15. No Backend / Dependency / Framework Change

- **No backend change** of any kind; no API contract touched.
- **No dependency added, removed or upgraded**; `pubspec.yaml` and `pubspec.lock` unchanged.
- **No localization framework change** — the existing GetX `Translations` + `Get.appendTranslations` + `Get.updateLocale`
  architecture is reused as-is.
- **No new cache** and **no concurrency architecture** introduced.
- SharedPreferences keys, persistence, default-language behaviour and picker behaviour are unchanged.

## 16. Unrelated Working-Tree Changes Excluded

Three pre-existing dirty files were present throughout and were **never** modified, staged, reverted, cleaned or formatted:
`docs/FROZEN_REGISTRY.md`, `docs/MIGRATION_LOG.md`, `docs/MOONJOIN_SHARED_DESIGN_LANGUAGE.md`. They remain outside this
slice's commit.

Verified unchanged by this slice: `HomeScreen.loadData()`, search, `GetBuilder` update behaviour, navigation transitions,
order tracking, `getUserInfo()`, API timeout, the Media 6N/6V image architecture, Firebase, Facebook, web renderer, service
worker, config loading, cart and checkout.

## 17. Commit

Frozen by the commit carrying subject **`perf(i18n): optimize startup translation loading`**, which contains this document
together with the six implementation and test files listed in §9. The hash is not recorded inline, since this document is
part of that commit.

## 18. Known Residual — recorded, deliberately not changed

Two rapid consecutive switches (for example en→ar then en→bn within the load window) could in principle settle on the
earlier request if its load resolves last. The window is ~1–3 ms warm, the outcome is always a valid loaded language, and it
is self-correcting by re-selecting. Concurrency handling was **explicitly excluded** from this slice. If it is ever wanted,
the minimal guard is to record the latest requested locale and apply only if it still matches after the await.
