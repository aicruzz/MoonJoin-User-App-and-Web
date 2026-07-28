# MoonJoin World — Enterprise Platform Architecture

> **Status:** Permanent master architecture for **MoonJoin World** — the future global, multi-country, multi-tenant, white-label MoonJoin platform that supersedes the temporary 6amMart backend. **Documentation only. No Flutter code, no backend code, no API changes, no migrations, no freezes.** This is the single source of truth; the Communication, Payment, and OTP documents are **chapters** of this architecture (see §11).
>
> **Prime directive:** The MoonJoin **frontend never knows which provider is active**, and MoonJoin **backend business logic never depends directly** on Twilio, Termii, Flutterwave, PayPal, Google Maps, Firebase, etc. **Everything external is reached only through the MoonJoin Platform Services Layer.**

---

## 1. Vision
MoonJoin World is a **larger-than-6amMart**, provider-independent super-app platform supporting single-country, multi-country, multi-tenant, white-label, and enterprise deployments. Every external capability is a **swappable provider** behind a stable internal contract, switchable from the **Admin Panel with zero frontend changes**. **MoonJoin is NOT a 6amMart clone** — 6amMart is a *reference* for existing business capabilities only; MoonJoin World preserves useful business logic, redesigns weak architecture, removes old limitations, and builds a clean long-term ecosystem.

### 1.1 The MoonJoin Ecosystem (five products)
1. **MoonJoin User App & Web** — the main customer app. Modules: **Food, Grocery, Pharmacy, Market, Fashion, Fuel & Gas, Parcel/Messenger, Car Rental, Short Apartment Rental, Drinks**, + future services. Frictionless onboarding (install → register → verify phone/email → order immediately), Glovo/Uber Eats/Deliveroo/Bolt Food/DoorDash-class UX. **No customer KYC** except regulated modules (see §10.1). *Current build focus.*
2. **MoonJoin Vendor App** — vendor onboarding/management; cleaner redesign of 6amMart vendor concepts. Vendor **business** verification (restaurant/store info, business documents, payout requirements) — **never** customer-level KYC rules. *Document only; do not redesign now.*
3. **MoonJoin Delivery Man App** — delivery partners handle packages, access customer addresses, and represent MoonJoin physically → **stronger, modular, country-configurable identity verification** (National ID/BVN/NIN/Passport/Driver License/Face/Liveness/background+risk). *Document only; do not redesign now.*
4. **MoonJoin Tenant App & Web** — **a MoonJoin original product, NOT from 6amMart. Delivery-as-a-Service:** a B2B platform where an external business integrates the **MoonJoin Tenant API** into its own app/site to create delivery requests fulfilled by MoonJoin's delivery fleet — the end customer never needs the User App. Future Tenant capabilities: **API credentials, API-access management, delivery requests, delivery settings, delivery history, driver monitoring, billing, webhooks, analytics, team members.** Enterprise-ready and independent. **First-class future product — remember it exists; do NOT implement now.**
5. **MoonJoin World Backend Platform + Admin** — supersedes/expands 6amMart admin: **Authentication Provider Layer** (manual, OTP, social [Google/Facebook/Apple], email + phone verification, future **biometric & passkeys** — all config-controlled), separate **panel login portals** (Super Admin `admin.moonjoin.com/login`, Admin Employee `/employee/login`, Vendor `vendor.moonjoin.com/login`, Vendor Employee `/employee/login`), RBAC, multi-country, multi-tenant, white-label, audit logs, security policies, provider management, feature flags, config-driven behaviour.

### 1.2 MoonJoin Delivery Network (future study)
6amMart's per-store **"Store-Managed Delivery"** (a store delivers with its own personnel/adds delivery men from the store panel) is to be **studied and improved later** into a unified **MoonJoin Delivery Network** with four models: **MoonJoin-managed · Tenant-managed · Store-managed · Hybrid.** Future architecture — do not implement now.

### 1.3 Architecture principles (permanent)
Frontends stay **clean and independent**; **do not blindly copy 6amMart structures**; **reuse business knowledge, not technical limitations**; all providers/services **configurable**; **no hardcoded business rules**; preserve **modularity**; **Tenant is a first-class product**; **delivery infrastructure is a core MoonJoin advantage**; build for **multi-country and enterprise scale**.

**Current task priority:** complete the **Flutter User App frontend** only. Do **not** start MoonJoin World backend redesign, Tenant, Vendor, or Delivery redesign — those follow after the User App codebase is complete. 6amMart source may be reviewed *only where necessary* during the MoonJoin World phase. The goal is **not migration — it is building MoonJoin World.**

---

## 2. The MoonJoin Platform Services Layer (PSL)

```
┌──────────────────────────────────────────────────────────────┐
│  MoonJoin Apps (User · Vendor · Delivery · Tenant · Web)       │  ← never sees a provider
└───────────────▲──────────────────────────────────────────────┘
                │ stable, provider-agnostic API (versioned)
┌───────────────┴──────────────────────────────────────────────┐
│  MoonJoin Backend Business Modules                             │  ← never imports Twilio/Flutterwave/…
│  (orders, wallet, rental, chat, catalog, users, vendors …)     │
└───────────────▲──────────────────────────────────────────────┘
                │ calls ONLY the Platform Services Layer
┌───────────────┴──────────────────────────────────────────────┐
│  █  MOONJOIN PLATFORM SERVICES LAYER (PSL)  █                  │
│  Service Facades → Provider Registry → Router (country/tenant) │
│  → Adapter → Provider.  Shared: health · failover · retry ·    │
│  timeout · circuit-breaker · idempotency · logging · analytics │
│  · webhooks · secrets · feature-flags · admin-config           │
└───────────────▲──────────────────────────────────────────────┘
                │ adapters (one per provider)
┌───────────────┴──────────────────────────────────────────────┐
│  Third-party providers (SMS, Email, Payments, Maps, KYC, AI …) │
└──────────────────────────────────────────────────────────────┘
```

The PSL is the **only** place third-party SDKs/keys exist. Business modules call **Service Facades** (e.g. `Sms.send`, `Payments.create`, `Identity.verifyBVN`, `Maps.geocode`); the PSL selects and calls the right provider.

---

## 3. Universal Provider Contract (defined ONCE, applies to EVERY service)
Every service in the catalog (§10) inherits **all** of the following from the PSL. Service chapters only note *service-specific* deviations.

1. **Service abstraction** — a facade (`ServiceName.operation`) that business logic calls; provider-agnostic request/response DTOs.
2. **Provider interface** — every provider implements the same operations for its service (`send/verify/create/query/healthCheck/handleWebhook`), normalizing provider quirks internally.
3. **Provider registry** — runtime catalog of available providers per service (id, capabilities, enabled, priority, credentials-ref), hot-reloadable.
4. **Provider priority** — ordered list; priority 0 = Primary; the rest are ordered fallbacks.
5. **Country routing** — route by destination country / number-prefix / region (e.g. `+234 → Termii`; `NG/NGN → Flutterwave`).
6. **Tenant routing** — per-tenant provider selection & credentials (multi-tenant / white-label); a tenant may pin its own provider set.
7. **Feature flags** — every provider and capability behind an Admin flag; dark-launch, gradual rollout, kill-switch.
8. **Health monitoring** — per-provider health score (success/latency/error-rate/balance); feeds routing + alerts.
9. **Failover strategy** — on failure/timeout, advance to next healthy provider; bounded attempts; idempotency-protected.
10. **Retry policy** — transient errors: exponential backoff + jitter, bounded, same provider → then failover; permanent errors: no retry.
11. **Timeout policy** — per-provider request timeout + global request budget; slow = soft failure → failover.
12. **Circuit breaker** — open after N failures in a window → cool-down → half-open probe → close.
13. **Idempotency rules** — every operation carries an `idempotencyKey`/`requestId`; dedup end-to-end; exactly-once effects (no double-charge/double-send).
14. **Logging** — structured record per call: `{service, provider, tenant, country, requestId, status, latency, cost, errorCode, rawResponse, retryCount, failoverChain, timestamps}`; secrets/PII masked.
15. **Analytics** — success/delivery/settlement rates, latency percentiles, cost, failover frequency, per provider/country/tenant.
16. **Webhook handling** — signed, verified, idempotent (dedup by event id); normalized to common events; source of truth over client callbacks.
17. **Secret management** — provider keys in a **vault/secrets manager**, referenced by key-name; per-environment; rotated without code change; encrypted, least-privilege, audited. **Never in app or repo.**
18. **Admin configuration** — enable/disable, priority, country/tenant routing tables, sender IDs/templates, rate limits, timeouts, retry/breaker thresholds, health/analytics dashboards — no redeploy, no frontend change.
19. **Future extensibility** — new provider = write one adapter + register + add routing row + enable flag. New service = new facade following this same contract. No app release.

---

## 4. Shared PSL Capabilities (cross-cutting)
- **Router:** resolves `(service, operation, country, currency, tenant, method)` → ordered provider list → picks Primary by priority + health.
- **Orchestrator:** executes with timeout, retry, circuit-breaker, failover, idempotency.
- **Event/Webhook bus:** normalizes provider callbacks → internal domain events.
- **Observability:** unified logging, metrics, tracing, analytics.
- **Config service:** Admin-driven registry, flags, routing, thresholds (see §9 Remote Config).
- **Secrets service:** vault-backed key resolution.

---

## 5. Deployment Models
- **Single-country:** one country routing set; minimal provider list.
- **Multi-country:** country-keyed routing tables; per-country provider sets, compliance, currency, sender-ID/DLT rules.
- **Multi-tenant:** tenant-keyed registry/credentials/flags; strict data + config isolation; per-tenant provider choice.
- **White-label:** tenant branding + its own provider accounts/keys, domains, sender IDs; PSL contract unchanged.
- **Enterprise:** dedicated instances, private networking, SLAs, audit/compliance, custom providers via the same adapter contract.

All five are the **same** PSL with different registry/routing/flag scopes — no code fork.

---

## 6. Frontend Contract (fixed forever)
Apps call stable, provider-agnostic endpoints only (e.g. `otp/send`, `otp/verify`, `payments/create`, `identity/verify`, `maps/geocode`, `storage/upload`). Provider selection, routing, failover, retries, health, webhooks, and secrets are **entirely server-side**. Enabling/disabling/switching any provider is an **Admin action** — the Flutter apps require **no change and no release**.

---

## 7. Admin Panel Control
The Admin Panel is the control plane for the PSL: per service, per country, per tenant — enable/disable providers, set priority/Primary-Secondary, edit routing tables, manage sender IDs/templates/keys-by-reference, tune rate-limits/timeouts/retry/breaker, and view health/analytics/delivery/settlement. Providers switch **ON/OFF without frontend changes**.

---

## 8. Governance & Migration (from 6amMart)
- 6amMart is a **temporary compatibility backend**; MoonJoin World replaces its provider/config layer with the PSL.
- Today's gaps this fixes: OTP sent inside `/auth/login` with **no delivery status** and swallowed gateway errors (see OTP chapter); payment gateway list rendered but config-cache/hosting (Imunify360) limited; direct provider coupling.
- Migration is incremental: wrap each existing integration in an adapter behind its facade, then add alternates + routing.

---

## 9. Platform Config: Feature Flags & Remote Config
- **Feature Flags:** boolean/multivariate flags per provider/capability/tenant/country; kill-switch; gradual rollout; A/B.
- **Remote Config:** Admin-driven runtime config (routing tables, thresholds, sender IDs, UI toggles) delivered to backend (and, where relevant, to apps via the existing config endpoint) without redeploy. Both inherit the Universal Contract's registry/logging/secrets rules.

---

## 10. Service Catalog (chapters)
Each service is a facade over interchangeable providers, inheriting the **entire** Universal Provider Contract (§3). Only service-specific notes are listed.

| # | Service | Current providers | Future providers | Key routing / notes |
|---|---|---|---|---|
| 1 | **SMS** | Twilio, Nexmo, MSG91, AlphaNet, 2Factor | Termii, Infobip, Africa's Talking, AWS SNS | Country/prefix routing; DLR webhooks; sender-ID/DLT per region. **See Communication chapter.** |
| 2 | **Email** | SMTP/Mail Config | ZeptoMail, SendGrid, SES, Mailgun, Postmark | Bounce/complaint webhooks; templates; suppression lists. **Communication chapter.** |
| 3 | **Push Notifications** | FCM | APNs direct, OneSignal, Web Push | Token/topic targeting; delivery receipts. **Communication chapter.** |
| 4 | **In-App Notifications** | Platform notification store | Real-time websocket/live-sync | Server-authoritative read/seen state. |
| 5 | **OTP** | Firebase Phone, backend gateway (2Factor) | Country-routed (Termii for `+234`) | `requestId` + delivery status; central attempts/expiry/lockout. **See OTP chapter.** |
| 6 | **Verification (message)** | verify-phone / verify-email / verify-token | Unified verify facade | Correlate send↔verify by requestId. |
| 7 | **Payments** | COD, Wallet, Card, existing gateways | Flutterwave, Paystack, Stripe, PayPal, LIQPAY, Payscribe, Moniepoint, Monnify, Apple/Google Pay, crypto-ready | Country+currency+method routing; signed idempotent webhooks; settlement. **See Payment chapter.** |
| 8 | **Virtual Accounts** | 9PSB | Moniepoint, Monnify, Flutterwave VA | Provision/assign VA; funding webhooks; reuse frozen `VirtualAccountDetailsWidget`. **Payment chapter.** |
| 9 | **Identity Verification (KYC)** | — | BVN, NIN, Passport, driver's license, liveness/face-match (e.g. Smile ID, Dojah, VerifyMe, Onfido) | PII-sensitive: encrypt, minimize, audit, consent; async webhooks; per-country ID types. |
| 10 | **Maps & Geocoding** | Google Maps (`google_maps_flutter`, geocoding) | Mapbox, HERE, OpenStreetMap/Nominatim | Geocode/reverse/routing/distance; cache; per-country provider. |
| 11 | **Address Validation** | Reverse-geocode/zone check | Dedicated validation providers | Normalize + validate; zone/delivery-area checks. |
| 12 | **AI Services** | — | Claude (Anthropic), OpenAI, Gemini, on-device | Prompt/response abstraction; provider-agnostic; cost/latency routing; PII redaction; rate limits. |
| 13 | **Storage** | Local/6amMart storage | S3, GCS, Azure Blob, Cloudinary | Signed URLs; lifecycle; per-tenant buckets. |
| 14 | **CDN** | Existing image host | Cloudflare, CloudFront, Fastly | Cache/purge; signed assets. |
| 15 | **Analytics** | — | GA4, Mixpanel, Amplitude, Segment | Event schema abstraction; consent; multi-sink fan-out. |
| 16 | **Logging** | Debug prints (app) | Structured centralized (ELK, Datadog, Loki) | PII masking; correlation IDs. |
| 17 | **Monitoring** | — | Datadog, New Relic, Prometheus/Grafana, Sentry | Health, alerting, tracing, error tracking. |
| 18 | **Fraud Detection** | — | Sift, custom rules, device/IP risk, 3-DS | Pre-authorization hooks (allow/deny/challenge); velocity/anomaly. **Payment chapter §12.** |
| 19 | **Tax Services** | Inline tax calc | Avalara, TaxJar, regional | Per-country tax rules; invoicing; VAT/GST. |
| 20 | **Currency & FX** | Static/config currency | Live FX (OpenExchange, Fixer, provider FX) | Display vs settlement currency; multi-currency wallet (future). **Payment chapter §5.** |
| 21 | **Messaging (chat transport)** | Backend chat + FCM | Websocket/live-sync, Pusher, Ably | Real-time delivery; reuse frozen conversation/chat foundation. |
| 22 | **Voice Calls** | — | Twilio Voice, Vonage, Africa's Talking Voice | Masked calling (customer↔rider); recording/consent. |
| 23 | **Video** | — | Agora, Twilio Video, Daily | Support/consult calls; TURN/relay. |
| 24 | **Chat (support)** | Live Chat list (frozen) | Provider chat / in-house | Thread transport pluggable; websocket. |
| 25 | **Search** | Backend search | Algolia, Elasticsearch, Typesense, Meilisearch | Index abstraction; relevance; per-tenant indices. |
| 26 | **Authentication** | Manual, Phone OTP, Google/Apple/Facebook (`centralizeLoginSetup`) | Email OTP, Microsoft, LinkedIn, GitHub, X, TikTok, Snapchat, Passkeys, Magic Link, Biometrics | **First-class PSL service.** Frontend requests a *capability*, never a provider; country/zone/tenant + mobile/web routing; Admin hot-switching; new provider = adapter + config + credentials + flag (no Flutter change). **See Authentication chapter (D).** |

Every row above is a **facade + registry of interchangeable adapters** governed by §3–§4. New services follow the identical pattern.

### 10.1 Identity / KYC Governance — PERMANENT MODEL (hierarchical, NEVER platform-wide, NEVER hardcoded)
> **This section supersedes every previous Identity/KYC assumption, including any notion of platform-wide or globally-required KYC.** Full detail in **Chapter E — Identity (`MOONJOIN_WORLD_IDENTITY_ARCHITECTURE.md`).**

**Identity is configuration, not code.** It is resolved top-down through **Platform → Country → Tenant (optional) → Zone → Application → Feature**: every Country contains many Tenants and Zones; a **Tenant (white-label / enterprise / government partner)** may define its **own** identity policy **before Zone policies apply** (skipped for first-party MoonJoin); **every Zone has its own Identity Policy**; every Application (User / Vendor / Delivery / Tenant) in a Zone has **independent** requirements; every Feature (ordering / wallet / large transaction / international transfer / virtual card / payout …) can add its own. The most specific level wins (within the platform capability set and the country's legal baseline). **Every capability is an Admin feature toggle — nothing is hardcoded — so MoonJoin World can launch in any country by configuration alone.**

**Default (intended everywhere, now expressed as a toggle set, not a hardcoded universal): User App customers = phone + email only.** Install → register → verify phone/email → order immediately (Glovo/Uber Eats/DoorDash/Deliveroo/Bolt Food-class). **Ordering never forces KYC.** A regulated zone *may* configure more, but the platform default keeps ordering friction-free.

**Configurable per Zone/Application/Feature (independent toggles):** Phone Verification · Email Verification · Face Match · National ID · NIN · BVN · Passport · Driver License · Business Certificate · Business Address · Tax Documents · Vehicle Documents · Insurance · Wallet KYC · Background Check · AML · Sanctions · Liveness. **Wallet KYC is per Country/Zone/Tenant/Feature and tiered — never global** (e.g. NG: wallet on, KYC off; CA: wallet on, KYC on; large transfers/international/virtual-cards may escalate to mandatory).

Identity providers (Smile ID, Dojah, VerifyMe, Onfido, …) sit behind the PSL Identity facade (row 9), selected by country/zone routing. PII is **minimized, encrypted, consent-gated, region-resident (§13.3), tiered, auditable, re-verified per policy (§13.5)**; verification is **async via webhooks**. Identity is **composed with but separate from Authentication (Chapter D)**.

---

## 11. Document Set (chapters of this architecture)
This master document is the umbrella. The following are its **detailed chapters** (kept as separate files for depth, governed by this master):
- **Chapter A — Communication:** `MOONJOIN_WORLD_COMMUNICATION_ARCHITECTURE.md` (SMS, Email, Push, In-App, Marketing, Broadcast, Scheduled).
- **Chapter B — OTP & Verification:** `MOONJOIN_WORLD_OTP_FLOW_ARCHITECTURE.md` (current-vs-future flow + root-cause diagnosis).
- **Chapter C — Payments:** `MOONJOIN_WORLD_PAYMENT_ARCHITECTURE.md` (gateways, Virtual Accounts, settlement, webhooks, refunds, fraud hooks, multi-country).
- **Chapter D — Authentication:** `MOONJOIN_WORLD_AUTHENTICATION_ARCHITECTURE.md` (Authentication as a first-class PSL service — capability-request model, provider list, per-provider controls, country/zone/tenant routing, Admin hot-switching).
- **Chapter E — Identity & KYC Governance:** `MOONJOIN_WORLD_IDENTITY_ARCHITECTURE.md` (hierarchical Platform→Country→Zone→Application→Feature model; per-app/per-feature toggles; wallet KYC rules; supersedes global-KYC assumptions).
- **Future chapters (to be authored when scheduled):** Maps/Geocoding/Address, AI, Storage/CDN, Observability (Analytics/Logging/Monitoring), Platform Config (Flags/Remote Config), Tax, Currency/FX, Real-time (Messaging/Voice/Video/Chat), Search.

All chapters conform to the **Universal Provider Contract (§3)** and the **PSL (§2)**; they must not restate it, only extend with service-specific detail.

---

## 12. Non-negotiable Invariants
1. Frontend never references a provider.
2. Backend business modules never import a provider SDK — only PSL facades.
3. All third-party keys live in the secrets vault, referenced by name.
4. Every provider is Admin-toggleable, priority-ordered, country/tenant-routable.
5. Every external call is observable (log + metric + trace) and idempotent where it has side effects.
6. Adding/removing/switching a provider requires **no app release and no frontend change** — for **Authentication** providers too (Chapter D): frontend requests a *capability*, never a provider.
7. **Identity/KYC is hierarchical & toggle-driven** (§10.1, Chapter E) — resolved through Platform→Country→**Tenant (optional)**→Zone→Application→Feature, **never platform-wide, never hardcoded**; ordering never forces KYC and the User App default stays phone (required) + email (configurable); wallet KYC is per Country/Zone/Tenant/Feature.
8. **Authentication is a first-class PSL service** (Chapter D) — capability-request model; new provider = adapter + admin config + credentials + flag.

---

## 13. Cross-Cutting Enterprise Concerns (Non-Functional)
These platform-wide capabilities underpin every PSL service and are required for a global, multi-country, multi-tenant, millions-of-users platform. Documentation only; each becomes its own chapter (§ suggested-docs).

### 13.1 API Gateway & BFF
- A single **API Gateway** (auth, rate-limit, WAF, request routing, versioning) fronts all backend services.
- **Backend-for-Frontend (BFF)** per client (User/Vendor/Delivery/Web) shapes responses so the apps stay thin and provider-agnostic. Versioned, backward-compatible contracts; deprecation policy.

### 13.2 Event-Driven Backbone
- Internal **event bus / message broker** (e.g. Kafka/NATS/SQS) with the **transactional outbox** pattern for reliable publish; **CQRS/event-sourcing** where it helps (ledger, notifications, analytics).
- Enables async workflows, decoupling, and the PSL queue architecture; every side-effecting event idempotent + traceable.

### 13.3 Multi-Region, Data Residency & Tenancy Isolation
- **Multi-region** deployment (NG/Africa, EU, US/Canada, Middle East, Asia) with region-pinned data for **residency/compliance** (GDPR/NDPR/regional).
- **Tenancy isolation model:** logical (row-level, tenant_id everywhere) → schema → dedicated DB/instance for enterprise/white-label; per-tenant encryption keys, config, providers, branding, domains.
- Routing keys everywhere: `(tenant, country, currency, region)`.

### 13.4 Resilience, DR & Business Continuity
- Beyond per-provider circuit breakers/failover (§3): **service-level** health, graceful degradation, bulkheads, backpressure.
- **DR/BCP:** RPO/RTO targets, cross-region backups, automated failover, chaos testing, run-books.

### 13.5 Security, Zero-Trust & Compliance
- **Zero-trust:** mTLS between services, least-privilege, short-lived credentials, per-tenant key isolation.
- **Data protection:** encryption at rest/in transit, PII tokenization/minimization, field-level encryption for identity/payment data.
- **Compliance program:** **PCI-DSS** (payments — never store PAN/CVV), **GDPR/NDPR** (privacy, consent, right-to-erasure), **AML/KYC** data handling, SOC2 posture, per-country regulatory rules.
- **Security services (PSL):** rate limiting, secrets/vault, fraud detection, device trust, risk engine, WAF, bot protection, audit logs, SIEM/alerting.

### 13.6 Identity & Access Management (platform)
- Central **AuthN/AuthZ**: OAuth2/OIDC, RBAC/ABAC, per-tenant roles, service-to-service auth, session/token lifecycle, MFA/biometric (future). Distinct from *customer* Identity/KYC (§10.1, Chapter E). **Customer-facing authentication methods** (manual, OTP, social, passkeys, magic link, biometrics) are governed as a first-class PSL service in **Chapter D — Authentication**.

### 13.7 Observability & SLOs
- Unified **logging, metrics, distributed tracing** (correlation IDs across gateway→service→PSL→provider), health/heartbeats, **SLOs/error budgets**, dashboards, alerting, synthetic monitoring.

### 13.8 Capacity, Scaling & Cost Governance (FinOps)
- Horizontal autoscaling, load/scale testing, capacity planning for millions of users / thousands of vendors.
- **Cost governance:** per-provider cost tracking (SMS/email/payment fees, AI tokens, storage/CDN), budget alerts, cost-aware routing (cheapest healthy provider), per-tenant cost attribution.

### 13.9 Data Platform & Analytics
- Operational DB vs **analytics/warehouse** (ELT), event pipeline, ML feature store (fraud/AI), privacy-preserving analytics, consent-aware.

### 13.10 Release Engineering & Config Safety
- CI/CD, blue-green/canary, migration discipline, config as data (Remote Config §9), safe hot-switching of providers with guardrails (validation before Primary promotion, automatic rollback on health regression).

### 13.11 PSL at Scale (100 → 1,000 → 10,000 tenants; millions of users; hundreds of providers)
- **Registry/router must be data-driven, cached, and O(1)**, not code/config-file based — routing tables in a fast store (Redis/edge cache) keyed by `(service, tenant, country, currency)`; never linear scans across providers/tenants.
- **Config fan-out at scale:** Admin changes propagate via the event bus + versioned config snapshots (not per-request DB reads); per-tenant config isolation with tenant-scoped cache keys to prevent noisy-neighbour and cross-tenant leakage.
- **No shared global rate-limit / circuit-breaker state** across tenants — breaker + limits are per `(provider, tenant/region)` so one tenant's failing provider never trips another's.
- **Provider connection pooling & quotas** per provider account; back-pressure and DLQ per queue; horizontal, stateless PSL workers.
- **Hot path budget:** the PSL adds bounded latency (target single-digit ms routing overhead); heavy work (retries, DLR, analytics) is async off the hot path.
- **10k-tenant reality:** logical isolation with `tenant_id` everywhere + row-level security is the default; large/enterprise tenants graduate to schema- or DB-per-tenant (§13.3). Onboarding a tenant = data + config, not deploy.

### 13.12 Provider Lifecycle, Versioning & Deprecation
- **Provider lifecycle states:** `Proposed → Sandbox → Canary → Active(Primary/Secondary) → Deprecated → Retired`; each transition guarded by health + Admin approval.
- **Adapter versioning:** provider adapters and the PSL facade contracts are **independently versioned**; facade contracts are backward-compatible (additive) so business modules and apps never break when an adapter changes.
- **Deprecation strategy:** deprecate a provider by demoting priority → drain traffic → mark deprecated → retire; keys revoked from vault on retirement; audit trail retained.
- **API/contract versioning:** app-facing PSL endpoints are versioned (`/v1`, `/v2`) with a published deprecation window; the Universal Contract (§3) evolves additively only.
