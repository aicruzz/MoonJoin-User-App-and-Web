# Slice B — Search Suggestions Performance + Smart Autocomplete Freeze

**Status:** IMPLEMENTED / TESTED / DEVICE-VALIDATED / FROZEN (2026-09-30)

**Repository:** MoonJoin Customer User App & Web

**Base commit:** `c1090928c1714a6668545ea6c5bf19590484ec45` (Slice A — startup translation loading, already frozen)

**Scope:** Live autocomplete suggestion requests only
(`GET /api/v1/items/item-or-store-search?name=<query>` via
`SearchScreen → SearchController.getSearchSuggestions() → SearchService → SearchRepository → ApiClient`).

---

## Behaviour frozen

| Rule | Implementation |
|---|---|
| **3-character minimum** | Applies **only** to the suggestion network request. `"" / "a" / "ab"` never request. |
| **Search input unrestricted** | The field accepts any length; only the request is gated. |
| **300 ms debounce** | `CustomDebounceWidget(milliseconds: 300)` inside the scheduler. Rapid typing (`c → ch → chi → chic → chick`) sends only the final settled query. |
| **One shared scheduler** | `SearchScreenState` owns ONE `SearchSuggestionScheduler`; the mobile field, desktop field and `MoonjoinSearchBar` all call `_onSearchTextChanged` → `scheduler.onTextChanged`. No per-field timers. |
| **Duplicate suppression** | The last sent query is remembered; an unchanged query is not re-requested. |
| **Failed-request retry** | An empty answer (the existing controller reports "no matches" and a failed call identically) or a thrown error releases the remembered query, so the same query is always retryable. |
| **Stale-response protection** | Every sent request gets a generation number. An answer is applied only if its generation is still the newest **and** its query still equals the field text. A late `"chi"` can never overwrite `"chic"`. If the newest request's answer arrives after the field moved on, its query is released so returning to it asks again. An armed timer whose text was cleared programmatically (clear icon / voice — no `onChanged`) is skipped. |
| **Below-threshold reset** | Dropping below 3 characters cancels the pending debounce, resets duplicate state, invalidates in-flight answers and clears/hides stale suggestions. |
| **SearchScreen disposal** | New `dispose()`: `_suggestionScheduler.dispose()` (cancels timer, ignores in-flight answers) → `_tabController?.dispose()` → `_searchController.dispose()` → `super.dispose()`. Result/clear callbacks also check `mounted`. |

`CustomDebounceWidget` gained one additive method, `cancel()`, used by the scheduler. Its existing `run()` behaviour and the rental search debounce (500 ms, `search_vehicle_screen.dart`) are unchanged.

## Unchanged (explicitly)

- Existing full search (`_actionSearch`) — still immediate, not debounced
- Existing voice search
- Existing rental search
- Backend
- `ApiClient`
- `SearchRepository`
- `SearchService`
- `SearchController`
- Suggestion UI (presentation, item layout, highlighting), search results UI, navigation, popular categories, recent searches

## Files implemented

- `lib/common/widgets/custom_debounce_widget.dart` — additive `cancel()`
- `lib/features/search/screens/search_screen.dart` — shared scheduler, three `onChanged` paths routed to it, `dispose()`
- `lib/helper/search_suggestion_scheduler.dart` — NEW, plain-Dart gating/state machine (no UI, no network code; `fetch` is supplied by the screen)
- `test/common/search_suggestion_scheduler_test.dart` — NEW

## Testing

**Slice B tests: 16/16 passed** (`flutter test test/common/search_suggestion_scheduler_test.dart`, fake timers via `testWidgets`):
empty / 1 / 2 chars no request · exactly 3 eligible after 300 ms · below-threshold clears + drops pending · rapid typing → final query only · pause >300 ms → separate request · duplicate suppressed · clear + re-enter re-requests · empty answer retryable · thrown error retryable · late `"chi"` cannot overwrite `"chic"` · answer for text no longer in field dropped + released · programmatic clear skips armed request · dispose cancels pending debounce · answer after dispose ignored · `"chi"` partial autocomplete works · `CustomDebounceWidget.cancel`.

Full suite: all other tests pass except two pre-existing, unrelated failures — `test/widget_test.dart` (stock Flutter counter template) and the intermittently wall-clock-dependent `flash_countdown_test`.

## Analyzer

`flutter analyze`:
- 0 errors
- 2 existing warnings in `lib/helper/pusher_helper.dart`
- 29 existing infos
- **No Slice B analyzer issues**

## Device validation

- Physical iPhone, iOS 18.6
- Signed release build (`flutter build ios --release` + `devicectl` install)
- Owner-performed manual QA: **PASS**

Scenarios passed:
- 1–2 characters do not trigger suggestions.
- 3+ characters trigger autocomplete after the debounce.
- Partial autocomplete remains functional (`chi → chic → chicken`).
- Rapid typing does not expose stale suggestions.
- Changing the query updates suggestions correctly.
- Dropping below the threshold clears suggestions.
- Clearing and re-entering allows suggestions again.
- Full search remains immediate.

## Limitations

- Network request counts were not directly captured in the release build (ApiClient's GET `log()` is silent in release); the automated tests cover request scheduling/count behaviour.
- The iOS simulator cannot currently build because of the repository's simulator arm64 exclusion (`EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64`).
- Debug iPhone signing is unavailable in the current environment.
- Already-sent HTTP requests are not cancelled (package:http has no cancellation); stale responses are safely ignored.
- A debounce armed immediately before a full-search submit may still send one suggestion request — identical to pre-Slice-B behaviour; `_actionSearch` intentionally untouched.

## Declarations

- No backend changes.
- No API client changes.
- No deployment.
- No tag.
- No push.
- This freeze covers only Customer User App & Web Slice B.
