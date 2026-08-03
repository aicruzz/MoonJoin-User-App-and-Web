# MoonJoin User App — Runtime Migration & Legacy Audit + Cleanup Roadmap
_Last revised: 2026-08-04 (architecture-review corrections applied). Documentation only — no production code changed, no freeze checkpoints modified, no cleanup performed._

This is the canonical, living audit. It replaces subjective completion metrics with objective, evidence-based status. **Legacy Cleanup must not begin until this document declares the project READY and the owner approves.**

---

## Roadmap (authoritative)
```
Phase 1  Frozen UI Migration                     ✅ complete (mobile scope; per FROZEN_REGISTRY)
   ↓
Phase 2  Architecture Freeze                     ✅ complete (frozen components + checkpoints)
   ↓
Phase 3  Backend-dependent items                 ◻ OPEN — Phase 3B (Update Cart, backend-blocked) + Language verification
   ↓
Phase 4  Runtime Reference Audit                 ◻ NOT STARTED — MANDATORY before any deletion (spec below)
   ↓
Phase 5  Legacy Cleanup (batch by batch)         ⛔ NOT STARTED — gated on Phase 4 + owner approval
   ↓
Phase 6  Final Architecture Freeze               ⛔ NOT STARTED
   ↓
MoonJoin Production Freeze                        ⛔ NOT STARTED
```

---

## PART 1 — Frozen Features
Owned by frozen checkpoints on `origin/main`: `dbf46dc` (Onboarding) → `c827af8`/`ac15350` (Item Identity) → `77f8006` (Brands + Headers) → `73a8e79` (Phase 3A) → `75d2a83` (Phase 3B blocker docs). Earlier work committed across `0fd2c79`…`b4519b4`; 54 frozen sections in `FROZEN_REGISTRY.md`.

Groups: Onboarding · Item Owner/Provider Identity · Brands (Ecommerce-only) + Module Headers · Phase 3A (Edit Unavailable Items "Add More") · Notification System (+ Production Release Baseline) · Motion/Status + Running Order popup · Cart Item Edit Journey · Checkout · Delivery Man Tips · Category Items / Sub-Category · Search · Favorites · Address/Map · full Profile/Account cluster · Auth Foundation · Parcel (3 screens) · Chat Thread · Registrations.

**Completion wording (objective — no percentages):**
> **Mobile migration is functionally complete for all frozen features, with only documented deferred work remaining: the Phase 3B backend dependency, Language verification, and future backend-dependent enhancements.**

Desktop/web is **intentionally preserved-legacy** across nearly all frozen features (mobile-first). "Complete" always means the approved **mobile** scope.

## PART 2 — Remaining Frontend Features (deferred / open)
| Feature | State | Dependency | Backend needed? |
|---|---|---|---|
| Phase 3B — Update Cart | **Blocked by backend contract** | `/api/v1/customer/order/update` cart validation | **YES** |
| Language screen (8F) | Implemented; **pending visual-verify + freeze** | none | No |
| My Trips "Pay Now" unification | Deferred (documented) | trips have no PaymentModel (`/rental/user/trip/*`) | **YES** |
| Rental brand *browse* (Car vs Apartment) | Future | per-module rental brand data | **YES** |

## PART 3 — Backend Blockers
| Blocker | Endpoint | Issue | Required backend fix | Frontend impact |
|---|---|---|---|---|
| Update Cart (Phase 3B) | `PUT /api/v1/customer/order/update/{id}` | validation requires `cart` **array** but controller `json_decode`s a **string** — contradicts itself + Place Order | `cart` validation `array → string/json` (match Place Order) | Update Cart blocked |
| Brands per non-Ecommerce module | `GET /api/v1/brand` | same brand for every module (no `moduleId` scoping) | scope by `moduleId` (or return empty) | Brands hidden off-Ecommerce until fixed |
| My Trips Pay Now | `/rental/user/trip/*` | trips carry no PaymentModel | expose/unify trip payment | Pay-Now unification deferred |
| Module header wording (optional) | module config | no `provider_label_plural` | add field | none (frontend fallback works) |

## PART 4 (audit view) — Runtime Widget Map (mobile)
| Screen | Active runtime widget | MoonJoin? | Reaches legacy at runtime? |
|---|---|---|---|
| Splash / Onboarding / Set-Location | splash · `MoonJoinOnboardingArt` · frozen Address/Map | ✅ | No |
| Home (all-modules) | `HomeScreen → ModuleLandingView` | ✅ | No |
| Food/Grocery/Pharmacy/Shop (+Market/Fuel/Drink via Grocery) home | module home screens; sections use `ItemCard`, `ReviewItemCard`, `ItemThatYouLoveCard`, `FlashProductCard` | production (alt surfaces) | These are **alternative production** cards, not legacy |
| All-Stores / item discovery | `AllStoreScreen → ItemsView → ItemWidget` (`_premiumStoreDishCard`) | ✅ | No |
| Product Details (tap item) | `FoodDetailsScreen`/`ItemDetailsScreen` | ✅ | No |
| **Quick "+" Add (food w/ variations)** | `CartCountView → itemDirectlyAddToCart → ItemBottomSheet` (mobile) | ❌ | **YES — legacy `ItemBottomSheet` still reached on mobile** |
| Search / Favorites | `ItemsView → ItemWidget` | ✅ | No |
| Cart / Checkout / Orders / Order Details / Running popup | frozen MoonJoin | ✅ | No (Update Cart backend-blocked) |
| Profile cluster, Wallet, Settings, Notifications, Coupon, Loyalty, Refer, Help, HTML, Chat, Auth, Parcel, Registrations | frozen MoonJoin | ✅ | No |
| **Any desktop/web view** | `WebMenuBar`, `CustomAppBar`, `WebItemWidget`, `StoreCard`, `ItemBottomSheet` dialogs | ❌ | **YES — desktop intentionally legacy** |

## PART 5 — Widget Inventory (classified — Legacy ≠ Alternative Production)
Four classes: **A. Production (active)** · **B. Legacy** · **C. Unknown (needs reference proof)** · **D. Candidate for future consolidation (design decision, NOT cleanup)**.

| Widget | Class | Notes |
|---|---|---|
| `ItemWidget` (+`_premiumStoreDishCard`) | **A** | The frozen owner-identity card (Search/Fav/Category/All-Store). |
| `ItemCard` (card_design) | **A** (alt surface) | Home "Most Popular" / "Special Offer" carousels. Production surface — **not** a cleanup candidate. |
| `ReviewItemCard` | **A** (alt surface) | "Best Reviewed" surface. Production. |
| `ItemThatYouLoveCard` | **A** (alt surface) | "Items You Love" surface. Production. |
| `FlashProductCard` | **A** (alt surface) | Flash Sale surface. Production. |
| `ItemCardWidget` | **A** (alt surface) | View-all grid surface. Production. |
| `FoodDetailsScreen` / `ItemDetailsScreen` | **A** | The two frozen Product Details. |
| `MoonjoinStoreCard` | **A** | Approved store/restaurant card (mobile lists). |
| MoonJoin headers (`MoonjoinCommerceHeader`, `ProfilePageHeader`, `MoonjoinModuleHeader`), `CartCountView`, `MoonjoinSearchBar`, `MoonJoinStatusAnimation`, notification stack | **A** | Frozen single-source components. |
| `ItemBottomSheet` | **B** (Legacy) | 6amMart bottom sheet; still reached on **mobile** (food-variation quick-add) + **desktop** — migration target, not yet deletable. |
| Legacy status GIFs | **B** (Legacy) | Superseded by `MoonJoinStatusAnimation`; keep until proven unreferenced. |
| `WebMenuBar`, `CustomAppBar`, `WebItemWidget` | **B** (Legacy, desktop) | Desktop-only, intentionally preserved (see Desktop Strategy). |
| `StoreCard` (card_design), `StoreCardWidget`, `home/widgets/web/*`, several `home/widgets/views/*` store widgets | **C** (Unknown) | Referenced by multiple views — **require per-file runtime reference proof** before any verdict. |
| The multiple **alternative item-card surfaces** as a set | **D** | MAY be consolidated toward `ItemWidget` **only if** a future design decision is made. This is a **design** decision, **not** cleanup, and not implied by mere difference. |

**Principle:** cleanup removes **obsolete (B, proven)** implementations. It does **not** collapse alternative production surfaces into one widget. Consolidation (D) is a separate design track requiring its own approval.

## PART 6 — Legacy Inventory (SAFE TO DELETE / STILL REFERENCED / UNKNOWN)
- **SAFE TO DELETE:** **None proven.** Nothing enters this list without Phase-4 runtime-reference proof.
- **STILL REFERENCED:** `ItemBottomSheet` (mobile quick-add + desktop); desktop legacy (`WebMenuBar`/`CustomAppBar`/`WebItemWidget`); legacy status GIFs; the alternative production cards are referenced (and are production, not deletion targets).
- **UNKNOWN (why not deletable):** `StoreCard`/`StoreCardWidget` + `home/widgets/web/*` + legacy `views/*` — reachability not yet proven; need call-hierarchy + route + navigator + instantiation + dynamic + mobile + desktop reference proof.

## PART 7 — Cleanup Readiness
**Cleanup Status: NOT READY.**
Reasons:
1. **Phase 3B blocked** by backend contract.
2. **Language verification not frozen.**
3. **Desktop strategy undecided** (see Part 9).
4. **Runtime Reference Audit (Phase 4) not completed.**
5. **Active runtime legacy paths still exist** (mobile `ItemBottomSheet` quick-add; desktop legacy).

## PART 8 — Cleanup Plan (gated — do NOT start until READY)
Legacy Cleanup (Phase 5) runs **subsystem by subsystem**, one batch per PR. Each batch: candidate files → **Phase-4 proof of zero references** → `flutter analyze` → build → device test → commit → push → next. Never delete unrelated subsystems together. Suggested ordering (only after each item is proven **B/obsolete**):
1. Product-details legacy (`ItemBottomSheet`) — **after** migrating the mobile food-variation quick-add AND the desktop decision.
2. Store cards proven dead (`StoreCard`/`StoreCardWidget`).
3. Legacy status GIFs (once `MoonJoinStatusAnimation` is the sole consumer).
4. Desktop legacy — **only if Option B is chosen** (see Part 9).
Alternative production surfaces (A) are **out of scope** for cleanup; any consolidation (D) is a separate design decision.

## PART 9 — Desktop Strategy (ARCHITECTURAL DECISION PENDING)
Desktop cleanup is **PROHIBITED** until the owner officially decides:
- **Option A — Desktop remains supported:** legacy desktop widgets (`WebMenuBar`, `CustomAppBar`, `WebItemWidget`, web `views/*`, desktop `ItemBottomSheet` dialogs) **stay**. They are production for desktop.
- **Option B — Desktop receives the MoonJoin redesign:** migrate desktop to MoonJoin components, **then** remove the legacy desktop widgets.
Until this decision is made, **no desktop widget may be deleted or classified SAFE TO DELETE.**

---

## Phase 4 — Runtime Reference Audit (mandatory specification)
**Purpose:** prove every cleanup candidate is genuinely unreachable before it can enter any Phase-5 batch. **A file may move to SAFE TO DELETE only when ALL of the following show zero live references.**

For **each** candidate widget/file, produce documented evidence for:
1. **Call hierarchy** — every symbol import/usage across `lib/` (and generated code).
2. **Route references** — `RouteHelper`/`GetPage`/named-route `arguments:` usages.
3. **Navigator usage** — `Get.to`/`Get.toNamed`/`Get.bottomSheet`/`Get.dialog`/`showModalBottomSheet`/`showDialog`/`Navigator.push`.
4. **Widget instantiation** — direct constructor calls (`Widget(`), including inside builders/ternaries.
5. **Dynamic references** — reflection-like/string-keyed lookups, deep links, notification routing, config-driven widget selection.
6. **Mobile references** — any path reachable when `ResponsiveHelper.isMobile`.
7. **Desktop references** — any path reachable when `isDesktop`/`WebMenuBar` branches (blocked from deletion by Desktop Strategy regardless).

**Rules:** No file is deleted on "looks old." A single live reference (mobile OR desktop) keeps it out of SAFE TO DELETE. Alternative production surfaces (Class A) are never candidates. Keep a Git checkpoint before each batch. Runtime-verify on device after each batch.
