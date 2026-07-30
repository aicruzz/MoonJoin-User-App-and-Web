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

## 6. Preservation guarantee
Presentation + additive scope orchestration only. No change to `SearchController` search/history/suggestions/filters/pagination/
voice logic, routes, APIs, models, or backend contracts. Application Context ⟂ Search Scope is a permanent invariant.
