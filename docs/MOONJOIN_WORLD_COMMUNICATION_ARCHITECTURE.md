# MoonJoin World — Communication Architecture (Enterprise)

> **Chapter A of the [MoonJoin World Enterprise Architecture](MOONJOIN_WORLD_ENTERPRISE_ARCHITECTURE.md).** This chapter sits inside the **MoonJoin Platform Services Layer (PSL, §2)** and inherits the **Universal Provider Contract (§3)** — provider abstraction, registry, priority, country/tenant routing, feature flags, health, failover, retry, timeout, circuit breaker, idempotency, logging, analytics, webhooks, secrets, admin config, extensibility. This chapter only adds Communication-specific detail.
>
> **Status:** Permanent enterprise architecture document for **MoonJoin World** (the future MoonJoin platform). **Documentation only — NO Flutter implementation, NO backend implementation, NO code, NO migrations.** Covers **every** communication service (not only SMS). Core principle: **the Flutter apps never know which provider is active — only the backend decides.** The current 6amMart backend is a temporary compatibility layer.

---

## 1. Scope & Principles
- **Provider-independent frontend.** Apps call MoonJoin World channel endpoints (`otp/send`, `otp/verify`, `notify`, `campaign`); the platform selects the provider. Adding/removing/reordering a provider is an **Admin + backend** action with **zero Flutter changes**.
- **Channels covered:** SMS, Email, Push Notifications, In-App Notifications, OTP, Verification, Marketing Campaigns, Broadcast, Scheduled Messages.
- **Enterprise-grade:** abstraction, priority, failover, country routing, health, retry, queue, analytics, delivery reports, webhooks, admin config, secrets. 

---

## 2. Provider Abstraction (all channels)
One interface per channel; all providers implement it (backend, conceptual):
```
interface CommunicationProvider {
  id; channel;                    // SMS | EMAIL | PUSH | IN_APP | WHATSAPP(future)
  capabilities();                 // countries, senderIds, templates, unicode, size, cost
  isEnabled(); priority();        // Admin toggle + ordering
  send(Message) -> SendResult { providerMessageId, status, cost, latency, raw }
  status(providerMessageId) -> DeliveryStatus
  handleWebhook(payload, sig) -> normalized DLR/event
  healthCheck() -> Health
}
```
- **Message** normalized: `{ to, channel, template, variables, country, senderId?, priority, requestId }`.
- Provider quirks (2Factor DLT, MSG91 flow IDs, Termii sender IDs, Infobip, Africa's Talking, AWS SNS, ZeptoMail/SendGrid/SES/Mailgun/Postmark templates) live **inside** each adapter.

### 2.1 SMS Providers
| Provider | Status | Best fit |
|---|---|---|
| **Twilio** | Current | Global, high deliverability |
| **Nexmo (Vonage)** | Current | Global |
| **MSG91** | Current | India + intl (flow/template IDs) |
| **AlphaNet SMS** | Current | Regional |
| **2Factor** | Current (active) | **India/DLT-centric** — weak for `+234` (see OTP diagnosis) |
| **Termii** | **Future — recommended NG/Africa** | Native `+234`, sender IDs, OTP/token APIs |
| **Infobip** | Future | Global omnichannel |
| **Africa's Talking** | Future | Africa-first (SMS, USSD, voice) |
| **AWS SNS** | Future | Global, cloud-native |

### 2.2 Email Providers
| Provider | Status |
|---|---|
| **Existing SMTP / Mail Config** (6amMart) | Current |
| **ZeptoMail** | Future |
| **SendGrid** | Future |
| **Amazon SES** | Future |
| **Mailgun** | Future |
| **Postmark** | Future |

### 2.3 Push & In-App
- **Push — Current:** FCM (`firebase_messaging`) for order/status notifications.
- **Push — Future:** APNs direct, OneSignal, web push; unified `PushProvider` abstraction; topic + token targeting.
- **In-App Notifications:** platform-owned notification store (already a MoonJoin foundation via the frozen notification card), real-time via websocket/live-sync (MoonJoin World), read/seen state server-authoritative.

---

## 3. Message Types (unified pipeline)
- **OTP / Verification:** transactional, highest priority, code + expiry + attempts; see `MOONJOIN_WORLD_OTP_FLOW_ARCHITECTURE.md`.
- **Transactional notifications:** order placed/updated, delivery, payment.
- **Marketing Campaigns:** segmented, consent-aware, throttled; A/B; suppression lists.
- **Broadcast Messages:** zone/module/all-users; rate-limited.
- **Scheduled Messages:** future-dated / recurring (cron); timezone-aware.
- All flow through the **same** provider abstraction, routing, retry, logging, and analytics.

---

## 4. Provider Priority, Primary/Secondary & Country Routing
- Per channel + country, an **ordered provider list** (Admin-editable).
- **Primary** = priority 0; secondaries are ordered fallbacks.
- **Country routing table** examples:
  - `NG (+234)` → `[termii, africas_talking, twilio]`
  - `IN (+91)` → `[2factor, msg91, twilio]`
  - `default` → `[twilio, nexmo, infobip]`
  - Email: `default` → `[zeptomail, ses, smtp]`
- Selection: `filter(enabled && channel && supports(country)) → sort(priority, health) → Primary`.

---

## 5. Provider Failover
- On failure/timeout on Primary → auto-advance to next enabled/healthy provider.
- **Circuit breaker** per provider (open after N failures in a window → cool-down → half-open probe).
- **Capped** attempts across providers (bounded latency).
- **Idempotency** by `requestId` so failover never double-sends/double-charges.

## 6. Retry Policies
- **Transient** (5xx, network, `429`): exponential backoff + jitter, bounded, same provider → then failover.
- **Permanent** (invalid number, no credit, unsupported country, unapproved template): **no retry** → failover or surface.
- OTP resend remains user-initiated with countdown; background delivery uses the retry engine.

## 7. Timeout Policy
- Per-provider submit timeout (SMS ~8–10s, email ~15s); slow provider = soft failure → failover. Global request budget bounds total time.

---

## 8. Queue Architecture
- **Async, queue-based** send pipeline: `Enqueue → Route → Provider Adapter → Provider → DLR/Webhook → Status update`.
- Priority queues (OTP/transactional > marketing/broadcast); rate-limiting per provider/country; dead-letter queue for exhausted retries; backpressure and horizontal workers for scale/scheduled bursts.

## 9. Provider Health Monitoring
- Health score per provider from success/delivery rate, latency, error mix, and balance/credit (where exposed).
- Passive (live traffic) + active (probe/test sends). Feeds routing (deprioritize degraded) + Admin alerts (e.g. "2Factor balance low", "Termii error rate high").

## 10. Delivery Reports & Webhook Handling
- Lifecycle: `QUEUED → SUBMITTED → SENT → DELIVERED | FAILED | EXPIRED`.
- Ingest **DLR/webhooks** (Twilio status callback, Termii DLR, Infobip, MSG91, SES/SendGrid events); **verify signatures**; **idempotent** by event id.
- Where no webhook, poll `status()`. OTP correlates send↔verify by `requestId` so the UI shows accurate state.

## 11. Communication Analytics
- Delivery rate, cost/message, latency percentiles, failover frequency, country/provider/channel breakdown, OTP verify-success rate, campaign open/click (email/push), suppression/bounce/complaint rates. Drives provider Primary/Secondary decisions.

## 12. Admin Dashboard Configuration (no redeploy, no Flutter change)
- Enable/disable each provider per channel.
- Priority / Primary-Secondary per country; edit routing table.
- Manage sender IDs, templates/DLT/flow IDs.
- Rate limits, timeouts, retry counts, circuit-breaker thresholds.
- View health, balance, delivery analytics, alerts; campaign scheduling; suppression lists.

## 13. API Key & Secrets Management
- Provider secrets **never** in the app or repo. Stored in MoonJoin World's **secrets manager/vault**, referenced by provider `id` + key name.
- Per-environment (dev/staging/prod); rotation without code change; encrypted at rest; least-privilege; audited access. Admin stores only **non-secret** config + a key reference.

## 14. Provider Enable/Disable & Feature Flags
- Every provider and channel behind an **Admin toggle / feature flag**. New provider = adapter + routing-table row + enable flag. No app release.

## 15. Future Multi-Country Support
- Country + number-prefix + locale as first-class routing dimensions; per-country provider sets, sender-ID/template compliance (DLT for India, sender-ID registration for NG, etc.), localized content, currency-independent (comms), consent/regulatory per region.

## 16. Frontend Contract (fixed forever)
Apps only call:
- `POST /communication/otp/send` → `{requestId, status}`
- `POST /communication/otp/verify` → `{verified}`
- `POST /communication/notify` / `/campaign` (email/push/in-app)

Provider selection, routing, failover, retries, health, queueing are **entirely server-side** → enabling Termii, disabling 2Factor, or reprioritizing is an **Admin action with zero Flutter changes**.

## 17. Migration Note (from today's 6amMart backend)
Today OTP is sent synchronously inside `/auth/login` with **no delivery status** and swallowed gateway errors (200 even on failure). MoonJoin World returns a real `requestId` + status, routes by country, fails over, and reconciles via DLR — making silent failures (the current 2Factor→`+234` issue) visible and auto-recoverable.

## 18. Production OTP / SMS Status (as of 2026-07-28) — infrastructure, not frontend
This records the **current live state** after the User App authentication migration (Phases 9C-2…9C-5). It is an **infrastructure limitation, NOT a Flutter/frontend defect** — the frontend migration is COMPLETE and verified.
- **Firebase Phone Verification:** **intentionally DISABLED.**
- **Active verification path:** **backend SMS gateway** (provider **2Factor**).
- **Observed behaviour:** OTP request **succeeds** → backend returns **success** → Verification screen **opens correctly** → **SMS is not delivered**, because **2Factor is not configured/funded for production** (and is India/DLT-centric — see `MOONJOIN_WORLD_OTP_FLOW_ARCHITECTURE.md` Part 5).
- **Production stance:** **Phone Verification may remain DISABLED in production** until MoonJoin World is completed. When re-enabled, the **future production SMS provider is Termii** (Nigeria/Africa-native `+234`, sender IDs, OTP APIs — see §2.1 and §4 country routing `NG (+234) → [termii, …]`).
- **No frontend action required.** Do not modify OTP code; the remaining work (provider funding/config, country routing to Termii) is backend/Admin/infrastructure under the PSL, delivered with zero Flutter changes.
