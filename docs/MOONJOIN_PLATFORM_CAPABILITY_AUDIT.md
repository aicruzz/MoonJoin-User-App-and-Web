# MoonJoin Platform Capability Audit — Phase 1 (Inventory)

> **Documentation & architecture audit only (2026-07-30). No code, no UI, no implementation.** Purpose: catalog every
> capability inherited from the temporary 6amMart platform so **MoonJoin never rebuilds a feature that already exists**.
> Each capability is classified **✅ Keep · 🔄 Improve · 🚀 Extend · 🗑️ Remove** as a *forward disposition* — this is not an
> implementation plan. The full **evaluate-and-decide** pass is the deferred **"MoonJoin Platform Capability Audit" project**
> (§ Future Phase below), which runs only AFTER User + Vendor + Delivery + Admin migrations are complete and frozen.

Scope note: this pass audits what is visible in the **Flutter User App codebase** plus **known Admin/backend infrastructure**.
Vendor/Admin-only capabilities are marked as such and evaluated in their own migration phases.

## AI capabilities (see `MOONJOIN_AI_PLATFORM_ARCHITECTURE.md` + `MOONJOIN_SEARCH_ARCHITECTURE.md` §9)
> **Enterprise AI architecture:** `MOONJOIN_AI_PLATFORM_ARCHITECTURE.md` — ONE centralized **MoonJoin AI Gateway** (apps never talk
> to AI providers directly); four independent capabilities (**AI Search · AI Commerce Assistant · AI Business Assistant · AI
> Operations Assistant**); future "MoonJoin AI Platform" project (Phase 1 Gateway → 2 Business → 3 Commerce → 4 Search → 5
> Operations). **AI is not activated during this migration** (no OpenAI config/keys/activation; Voice Search preserved).
| Capability | Where | Status | Disposition |
|---|---|---|---|
| **AI Setup / OpenAI Configuration** | Admin Panel (backend) — **NOT in the app** | Exists, unconfigured/unevaluated | ✅ Keep (untouched; evaluate later) |
| **AI Content Generation infrastructure** | Admin/backend | Exists | ✅ Keep (untouched) |
| **Vendor AI Assistant** | Vendor/Admin infra | Exists, not configured/evaluated | ✅ Keep (evaluate in Vendor/Admin phase) |
| **AI Search** | App | ❌ Not implemented | 🚀 Extend (future: reuse existing AI infra — never a parallel AI subsystem) |

## Search capabilities (detail in `MOONJOIN_SEARCH_ARCHITECTURE.md` §7)
| Capability | Status | Disposition |
|---|---|---|
| Voice Search (`VoicePermissionHandler` + `speech_to_text`) | Working (preserved, scope-gated) | ✅ Keep |
| Search Suggestions (`item-or-store-search`) | Working | ✅ Keep |
| Search History / Recent (SharedPref) | Working | ✅ Keep |
| Suggested Items (`customer/suggested-items`) | Working (logged-in) | ✅ Keep |
| Popular Categories (`categories/popular`) | Working | ✅ Keep |
| Search Filters (`FilterWidget`) / Sorting | Working (sort = ascending/descending only) | ✅ Keep |
| **Popular Items / Stores** (`items\|stores/popular`) | Endpoints exist, **unused by Search** | 🚀 Extend (into a future Trending/Popular scope) |
| **Recommended Items** (`items\|stores/recommended`, `items/suggested`) | Endpoints exist, **unused by Search** | 🚀 Extend (into a future AI/Recommended scope) |
| **Nearby** (`config/place-api-autocomplete` exists for address only) | ❌ Not implemented for item search | 🚀 Extend (future Nearby scope via existing location APIs) |
| **Trending** | ❌ Not implemented | 🚀 Extend (future, via popular/recommended endpoints) |

## Commerce / engagement capabilities (User App)
| Capability | Status | Disposition |
|---|---|---|
| Coupons (`coupon_screen` FROZEN) | Working | ✅ Keep |
| Wallet + history (FROZEN, fintech) | Working | 🚀 Extend (MoonJoin World wallet + feature-based KYC — see enterprise Chapter E) |
| Loyalty Points (FROZEN) | Working | ✅ Keep |
| Referral / Refer & Earn (FROZEN) | Working | ✅ Keep |
| Notifications (FROZEN; local unread only) | Working | 🚀 Extend (PSL Communication — server-authoritative read/seen) |
| Chat — Conversation list (FROZEN) / **Thread (pending)** | List working; thread still legacy | 🔄 Improve (migrate the thread; then Extend via MoonJoin World real-time messaging) |
| Scheduled Delivery (`scheduleOrder`/`scheduleAt`) | Working | ✅ Keep |
| Rental (Car + Apt, FROZEN) | Working (Apt = frontend placeholder) | 🚀 Extend (backend/vendor for Apt) |
| Parcel / Package Delivery (module present) | Working; **UI migration pending** | 🔄 Improve (UI migration in its own phase) |
| Recommendation engine (`items\|stores/recommended`) | Working in storefront/cart | 🚀 Extend (feed future Search AI/Recommended scope) |

## Platform / infrastructure capabilities
| Capability | Status | Disposition |
|---|---|---|
| Firebase (Messaging / Push) | Working (`notification_helper`, `main.dart`) | 🚀 Extend (PSL Communication provider abstraction — Chapter A) |
| Real-time (Pusher) (`pusher_helper`) | Working | 🚀 Extend (MoonJoin World real-time / websocket) |
| Analytics | Present via platform config | ✅ Keep (🚀 Extend via PSL Observability later) |
| **Rental (vehicle) search stack** (`rental/vehicle/search…`, `taxiSearchHistory`) | Working — **parallel to main Search** | 🔄 Improve (consolidate with the frozen Search architecture later) |
| Hidden/unused endpoints (popular items/stores, recommended, place-autocomplete) | Available, unused by Search | 🚀 Extend (reuse — never recreate) |
| Obsolete UI widgets (SocialLoginButton, ExpandableBottomSheet usage, profile_bg, etc.) | Retained, marked OBSOLETE | 🗑️ Remove (ONLY in the final legacy-cleanup phase with owner approval — see legacy-cleanup policy) |

**🗑️ Remove — none at the platform-capability level in this pass.** The only removals are obsolete *UI widgets*, deferred to the
final legacy-cleanup phase (owner-approved) per the legacy-cleanup policy — never a capability.

## Future Phase — "MoonJoin Platform Capability Audit" (deferred project)
A dedicated future project that runs **only after** the **User App · Vendor App · Delivery App · Admin Panel** migrations are all
complete and frozen. It will review **every** inherited 6amMart capability and formally decide **Keep / Improve / Extend / Remove**
**before any new platform features are introduced** — so MoonJoin World is built on a deliberately curated capability set, never a
blind copy of 6amMart. This Phase-1 inventory is its starting point.
