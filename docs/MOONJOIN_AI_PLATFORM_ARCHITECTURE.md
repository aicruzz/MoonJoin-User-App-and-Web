# MoonJoin AI Platform Architecture

> **Permanent enterprise architecture document for MoonJoin World — long-term roadmap, NOT an implementation document.**
> Documentation only (2026-07-30). **No code, no configuration, no UI, no AI implementation, no OpenAI enablement, no API keys.**
> Aligns with the [MoonJoin World Enterprise Architecture](MOONJOIN_WORLD_ENTERPRISE_ARCHITECTURE.md) (the AI Gateway is the
> AI capability of the Platform Services Layer, §2/§10 row 12) and the [Search Architecture](MOONJOIN_SEARCH_ARCHITECTURE.md)
> (AI Search orchestration & AI classification). All timing is governed by the **AI Activation Rule (§5)**.

---

## 1. AI Platform Principle — ONE centralized AI Gateway
**MoonJoin shall have a single, centralized AI Gateway. Applications must NEVER communicate directly with AI providers.**

```
User App · Vendor App · Delivery App · Admin Panel · Merchant Portal · Web Platform
                                   │
                                   ▼
                        ██  MoonJoin AI Gateway  ██   (provider-independent, Admin-controlled)
                                   │
     ┌───────────────┬────────────┼────────────┬──────────────────┐
   OpenAI        Anthropic     Google Gemini   Future Local LLMs   Future Enterprise Models
```

The AI Gateway will eventually provide: **Authentication · Rate limiting · Cost monitoring · Provider switching · Prompt
management · Analytics · Moderation · Logging · Security · Usage quotas** — and, per the Failover Principle (§8): **Provider
failover · Timeout handling · Retry policy · Error translation · Graceful degradation · Provider health monitoring.** No
application owns its own AI integration; the frontend never knows which AI provider is active (consistent with the PSL Prime
Directive — apps never reference a provider). **Applications never know whether an AI call succeeded or failed — they receive
either AI-enhanced results OR deterministic fallback results, and nothing else.**

## 2. Permanent AI Capability Classification (independent platform capabilities)
These are **four separate capabilities** — never conflated (extends `MOONJOIN_SEARCH_ARCHITECTURE.md` §9):

| Capability | Purpose | Examples | Status |
|---|---|---|---|
| **AI Search** | Customer discovery | "spicy rice under ₦3000", "nearby pharmacies", "best restaurants open now" | ❌ Not implemented |
| **AI Commerce Assistant** | Shopping assistance | product/meal recommendations, cart assistant, cross-sell, personalized suggestions | Future roadmap |
| **AI Business Assistant** | Vendor productivity | product descriptions, menu rewrite, SEO, marketing copy, titles, image-assisted content | **Infrastructure exists in Admin (AI Setup); not evaluated, not configured** |
| **AI Operations Assistant** | Administration | sales insights, fraud detection, customer support, business reporting, operational analytics | Future roadmap |

## 3. Voice Search Rule (permanent)
**Voice Search is NOT AI Search. Voice Search is only an input method.**

```
Voice  →  Speech-to-Text  →  Normal (keyword) Search
```

**AI Search is fundamentally different:**

```
Voice / Text  →  Intent Understanding  →  Semantic Search  →  Recommendations  →  Results
```

These two capabilities must always remain **independent**. Voice Search (`VoicePermissionHandler` + `speech_to_text`) is a
working, preserved input capability today and is unaffected by AI.

## 4. AI Reuse Rule (permanent)
Future AI Search — and every AI feature — must **always reuse the centralized MoonJoin AI Gateway.** **No application may create
a second AI subsystem. No duplicate AI integrations. No provider-specific implementations inside apps.** (Consistent with the
Legacy-Elimination mandate and the Search Orchestration Rule: extend one shared capability, never fork.)

## 5. AI Activation Rule (permanent — governs current phase)
During the current UI/UX migration:
- **AI Setup remains untouched.** **OpenAI Configuration remains disabled.** **No API keys. No provider activation. No AI
  implementation.**
- **Voice Search remains preserved exactly as implemented** (separate input capability — not AI).

**AI implementation begins ONLY after User App · Vendor App · Delivery App · Admin Panel are fully migrated and frozen.**

## 6. Project Roadmap — "MoonJoin AI Platform" (future project, sequential)
Each phase builds on the previous one; none begins until §5's precondition is met.

| Phase | Deliverable | Builds on |
|---|---|---|
| **Phase 1** | **AI Gateway** (auth, rate-limit, cost, provider-switching, prompt mgmt, analytics, moderation, logging, security, quotas) | The PSL / MoonJoin World platform |
| **Phase 2** | **AI Business Assistant** (vendor productivity — reuses the existing Admin AI Setup infrastructure via the Gateway) | Phase 1 |
| **Phase 3** | **AI Commerce Assistant** (customer shopping assistance) | Phases 1–2 |
| **Phase 4** | **AI Search** (semantic customer discovery — reuses the existing Search Scope architecture & AI Gateway; never a parallel AI subsystem) | Phases 1–3 |
| **Phase 5** | **AI Operations Assistant** (admin insights, fraud, support, reporting) | Phases 1–4 |

## 7. Guardrails (permanent)
- Provider-independent: apps call the **AI Gateway** capability, never a provider SDK; Admin switches providers with zero app change.
- AI Search reuses the **frozen Search Scope architecture** (`MOONJOIN_SEARCH_ARCHITECTURE.md`) — scope, filters, history,
  suggestions, voice — and only adds intent/semantic layers behind the Gateway.
- Secrets (AI keys) live in the vault by reference; never in apps/repos.
- Nothing in this document is enabled during the migration (§5).

## 8. AI Failover Principle (permanent) — AI enhances MoonJoin, it never controls it
**MoonJoin core commerce must NEVER depend on AI availability. AI is an enhancement layer, never a business-logic dependency.**
If any AI provider becomes unavailable for **any** reason — **provider outage · API quota exhausted · billing issues · network
failures · rate limiting · timeout · provider maintenance · provider migration · security shutdown · manual AI disablement** —
the platform must continue operating normally.

**Every AI capability MUST have a deterministic, non-AI fallback:**

| AI capability | If AI is unavailable → deterministic fallback |
|---|---|
| **AI Search** | Automatically fall back to the existing **keyword search engine** (the frozen Search Scope architecture). Users must still receive search results. |
| **AI Commerce Assistant** | Automatically fall back to the existing **recommendation engine** — **Recommended Items · Popular Items · Suggested Items · Trending** keep working. |
| **AI Business Assistant** | Vendors continue **manual editing exactly as today**. No business interruption. |
| **AI Operations Assistant** | Standard **reports and dashboards continue operating**. No administrative capability is lost. |

**Platform Rule (permanent):** **AI enhances MoonJoin. AI never controls MoonJoin.** Core commerce remains **deterministic**.
**AI is optional. Commerce is mandatory.**

**Gateway responsibility (§1):** the AI Gateway owns **Provider failover · Timeout handling · Retry policy · Error translation ·
Graceful degradation · Provider health monitoring**. Applications never learn whether an AI call succeeded or failed — they receive
either **AI-enhanced results** or **deterministic fallback results**, transparently.

---
**MoonJoin AI Platform Architecture is COMPLETE.** No additional AI architecture documents are to be created during the current
migration unless the overall platform architecture changes.
