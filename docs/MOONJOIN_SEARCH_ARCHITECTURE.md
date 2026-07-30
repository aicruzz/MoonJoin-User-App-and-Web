# MoonJoin Context-Aware Scoped Search Architecture

> **Permanent MoonJoin Platform Architecture Decision (owner-approved 2026-07-30).** This is a platform-level standard, not a
> single screen implementation. Every current and future Search-related feature MUST follow it. The Search *screen* is
> **FROZEN pending physical-device verification** (then recorded in FROZEN_REGISTRY/COMPONENTS/MIGRATION_LOG).

---

## 1. Core principle — two permanently independent concepts
| Concept | Owns | Controls | Rule |
|---|---|---|---|
| **Application Context** | `SplashController.module` | Home, Categories, Stores, Products, Cart, Checkout, Navigation | **Never changed by a search.** |
| **Search Scope** | `SearchController._searchScope` (a `SearchScope`) | Which module the *current search query* targets | Temporary Search UI state; **independent** of Application Context. |

**Searching must never move the app from one module to another.** Searching Pharmacy while inside Food leaves the app in Food
(back-navigation proves it — verified on device/simulator).

## 2. Non-negotiable implementation rules
- **Search Scope is applied ONLY through a per-request `moduleId` header override.** `search_repository._getSearchData` clones
  the current headers (`apiClient.getHeader()`) and overrides only `moduleId` for that one request.
- **Search must NEVER change:** `setModule()`, `cacheModule` / `removeCacheModule()`, `SplashController.module`, or
  `ApiClient._mainHeaders` (the global headers).
- **No error, no arbitrary default:** scope resolution order on Search open = **inside a module → current module** → else
  **session Search Scope** → else **last-used module (`cacheModule`)** → else **present the Module Scope Sheet**. Never silently
  use `moduleList[0]`; never surface the backend "Module ID Required" error. Voice search and the search action are both
  scope-gated (no scope → Scope Sheet first).
- **Scope lifetime:** session-persistent (`SearchController` is a permanent singleton); resets on app close; never written to
  `cacheModule` / Application Context.

## 3. Frozen reusable platform components (reuse — never fork)
- **`SearchScope`** (`lib/features/search/domain/models/search_scope.dart`) — the scope abstraction. **Not hardcoded to
  `ModuleModel`**: only `SearchScopeType.module` is exposed today; future types slot in without redesign.
- **`MoonJoinScopeSelector`** (`lib/common/widgets/moonjoin/scope_selector.dart`) — the reusable Design-System scope pill
  (`[leadingText] (icon) label ▾`). Platform-level: reusable by Search, AI Assistant, Notifications, Offers, Coupons,
  Analytics, future Global Search.
- **`SearchScopeSheet`** (`lib/features/search/widgets/search_scope_sheet.dart`) — the Module Scope Sheet ("Search in… /
  Recent / All Modules"), built on the frozen `MoonjoinBottomSheet` + `OrganicModuleIcon` + existing module data.

## 4. Permanent reuse rules (one design system, one implementation)
- **Never** create another scope selector — reuse **`MoonJoinScopeSelector`**.
- **Never** create another module-selection sheet for Search — reuse **`SearchScopeSheet`**.
- **Never** create another Items/Stores segmented control — always reuse the **frozen Favorites segmented pill** (restyled
  `TabBar` in a soft-green track; see `favorites-and-nav-toolchain`).
- **Never** fork the search input / result cards — reuse `MoonjoinSearchBar`, `_searchHeroHeader`, `SearchFieldWidget` logic,
  `ItemsView` / `MoonjoinStoreCard` / `ItemWidget` / `NoDataScreen`, `BottomCartWidget`.

## 5. Future expansion (prepared, NOT implemented)
The `SearchScope` abstraction + `MoonJoinScopeSelector` + `SearchScopeSheet` are intentionally designed so these future scope
types can be added **with no redesign** (only new `SearchScopeType` values + sheet entries):
🌍 **All Modules** · 📍 **Nearby** · ❤️ **Favorites** · 🔥 **Trending** · 🏷 **Promotions** · 🤖 **AI Search**.
These are **not** exposed today (the backend supports module-scoped search only).

**Future backend roadmap (separate, no contract change now):** a module-agnostic **Global Search** endpoint would unlock the
"🌍 All Modules" scope in the same selector — a MoonJoin World enhancement (see `MOONJOIN_WORLD_ENTERPRISE_ARCHITECTURE.md`).

## 6. Search Orchestration Rule (permanent)
**Search is an ORCHESTRATION LAYER, not a business-logic owner.** Search coordinates: **Search Scope · `SearchController` ·
Filters · History · Suggestions · Voice Search · AI Search · Nearby Search · future Search Providers.** Search must **never own
business logic**: module logic, pricing/availability rules, catalog rules, and backend rules live in the appropriate
controllers / repositories / services / backend APIs. Search must **never duplicate** module logic, controller logic, or backend
rules — it composes existing capabilities. Future search features **extend existing capabilities**; they never recreate them.

## 7. Capability Inventory (audit 2026-07-30 — extend these, never duplicate)
| Capability | Status | Where |
|---|---|---|
| **Search (items/stores)** | Working | `search_repository` → `/api/v1/{items\|stores}/search?name=` (now scope-aware) |
| **Search suggestions** (type-ahead) | Working | `getSearchSuggestions` → `/api/v1/items/item-or-store-search`, `SearchSuggestionModel` |
| **Search history / Recent searches** | Working | `SearchController._historyList` persisted in SharedPref (`6ammart_search_history`); add/remove/clear |
| **Suggested items** (landing) | Working (logged-in) | `getSuggestedItems` → `/api/v1/customer/suggested-items` |
| **Popular Categories** | Working | `getPopularCategories` → `/api/v1/categories/popular`, `PopularCategoryModel` |
| **Search filters** | Working | `FilterWidget` — sort, veg/non-veg (config-gated), available, discounted, price range, rating |
| **Search sorting** | Working (minimal) | `sortList = [ascending, descending]`, `sortIndex`/`storeSortIndex` |
| **Voice Search** | Working | `VoicePermissionHandler.openVoiceSearch` + `speech_to_text` (`SearchController._speech`); scope-gated |
| **Popular items / stores** | Implemented but UNUSED by Search | `/api/v1/items/popular`, `/api/v1/stores/popular` (used by storefront) — available for a future Trending/Popular scope |
| **Recommendations** | Implemented but UNUSED by Search | `/api/v1/items/recommended`, `/api/v1/stores/recommended`, `/api/v1/items/suggested` — available for a future AI/Recommended scope |
| **Place autocomplete** | Implemented but UNUSED by item Search | `/api/v1/config/place-api-autocomplete` (address/map only) — could feed a future Nearby scope |
| **Rental (vehicle) search** | Working — SEPARATE stack | `/api/v1/rental/vehicle/search`, `…/suggestion`, `…/popular-suggestion`, `taxiSearchHistory` — a parallel search to consolidate later |
| **AI Search / AI Setup** | Not implemented | no config, endpoint, or code |
| **Trending searches** | Not implemented | no code/endpoint |
| **Nearby search** | Not implemented | no item/store nearby endpoint |
**Future-expansion assets already present:** `SearchScope` abstraction + scope-aware `SearchService`/`Repository`; recommendation &
popular endpoints (data for Trending/Popular/AI scopes); place-autocomplete (Nearby). New scopes REUSE these — never recreate.

## 8. Preservation guarantee
Presentation + additive scope orchestration only. No change to `SearchController` search/history/suggestions/filters/pagination/
voice logic, routes, APIs, models, or backend contracts. Application Context ⟂ Search Scope is a permanent invariant.

## 9. AI Capability Classification (permanent) — AI Search ≠ AI Content Generation
**These are two completely separate platform systems and must NEVER be treated as the same feature:**
- **AI Search** — a customer-facing search capability. **Status: NOT implemented** (no app code, no endpoint).
- **AI Content Generation infrastructure** — Admin-Panel/backend infra (**AI Setup / OpenAI Configuration, vendor AI limits**).
  **Status: already EXISTS in the Admin Panel** (not in the Flutter app), currently unconfigured/unevaluated.
- **Vendor AI Assistant** — vendor productivity infra. **Status: infrastructure exists but is not configured or evaluated.**

**Future AI Rule (permanent):** future **AI Search must REUSE and EXTEND the existing AI infrastructure** wherever appropriate.
MoonJoin must **never create a second, parallel AI subsystem** when an existing platform capability can be extended. (Consistent
with the Search Orchestration Rule §6 and the Legacy-Elimination mandate: extend, never duplicate.)

**Migration Rule (current UI/UX migration — permanent for this phase):**
- **AI Setup is OUT OF SCOPE.** Existing AI infrastructure remains **untouched**.
- **Voice Search remains preserved** (it is a separate, working capability — not AI Content Generation).
- **No OpenAI configuration enabled, no API keys added, no AI feature activated** during the migration.
- AI is evaluated **only after** User App · Vendor App · Delivery App · Admin Panel migrations are complete and frozen — as part
  of the deferred **MoonJoin Platform Capability Audit** project (see `MOONJOIN_PLATFORM_CAPABILITY_AUDIT.md`).
