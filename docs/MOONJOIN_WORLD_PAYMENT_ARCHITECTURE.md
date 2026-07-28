# MoonJoin World — Payment Architecture (Enterprise)

> **Chapter C of the [MoonJoin World Enterprise Architecture](MOONJOIN_WORLD_ENTERPRISE_ARCHITECTURE.md).** Payments (and Virtual Accounts) are Platform Services Layer services (PSL, §2) inheriting the Universal Provider Contract (§3) — abstraction, registry, priority, country/currency/tenant routing, flags, health, failover, retry, timeout, circuit breaker, idempotency, logging, analytics, webhooks, secrets, admin config. This chapter adds payment-specific detail (settlement, refunds, reconciliation, fraud hooks).
>
> **Status:** Permanent enterprise architecture document for **MoonJoin World**. **Documentation only — NO Flutter implementation, NO backend implementation, NO code, NO migrations.** Core principle: **the Flutter frontend never depends on any payment provider — the backend controls everything.** The apps already render `configModel.activePaymentMethodList` and launch a generic flow (verified in Phase 7, no hardcoding/filtering). The current 6amMart backend is a temporary compatibility layer.

---

## 1. Scope & Principles
- **Provider-independent frontend.** Apps render the active method list + launch a generic flow (COD / Wallet / Virtual Account / card-redirect / SDK). Switching providers ON/OFF, reordering, or adding new ones is **Admin + backend** only — **zero Flutter changes**.
- **Enterprise-grade:** abstraction, routing (country + currency), failover, idempotency, settlement, webhooks, refunds, reconciliation, audit, fraud hooks, health, feature flags, multi-country.

---

## 2. Provider Abstraction
```
interface PaymentProvider {
  id; capabilities();            // countries, currencies, methods, min/max, refunds, VA, recurring
  isEnabled(); priority();
  createPayment(Order) -> PaymentIntent { providerRef, redirectUrl|clientSecret|vaDetails, status }
  verify(providerRef) -> PaymentResult { status, paidAmount, currency, fees, raw }
  refund(providerRef, amount) -> RefundResult
  handleWebhook(payload, signature) -> normalized event
  healthCheck() -> Health
}
```
- **Order/PaymentIntent** normalized: `{ amount, currency, country, customer, method, orderId, idempotencyKey }`.
- Provider quirks (Flutterwave tx_ref, Paystack reference, Monnify/Moniepoint VA, PayPal orders, Stripe PaymentIntents, LIQPAY signature, Payscribe) stay **inside** each adapter.

### 2.1 Current payment systems (exist in MoonJoin today)
| Method | Status |
|---|---|
| **Cash on Delivery (COD)** | Current |
| **Wallet** | Current (frozen fintech wallet + history) |
| **Virtual Account** | Current (frozen `VirtualAccountDetailsWidget`) |
| **9PSB** | Current (virtual bank provider) |
| **Existing Card Payment** | Current |
| Region set in `activePaymentMethodList` | Current |

### 2.2 Future providers
| Provider | Notes |
|---|---|
| **Flutterwave** | Africa + global; card/bank/USSD/mobile-money/VA |
| **Payscribe** | Nigeria fintech/VAS + payments |
| **LIQPAY** | Ukraine/EU cards |
| **PayPal** | Global wallet/card |
| **Stripe** | Global cards/wallets |
| **Moniepoint** | Nigeria; VA, POS, transfers |
| **Monnify** | Nigeria; VA, transfers |
| **Paystack** | Nigeria/Africa; card, bank, USSD |
| **Google Pay** | Wallet (Android) |
| **Apple Pay** | Wallet (iOS) |
| **Regional providers** | Per-market adapters |
| **Virtual Cards** | Issue/fund virtual cards |
| **Bank Transfer** | Direct/VA transfer |
| **Crypto-ready** | Pluggable crypto/stablecoin adapter (future, same interface) |

---

## 3. Routing (country + currency + method)
- **Routing table** (Admin-editable):
  - `NG / NGN` → `[flutterwave, paystack, monnify, moniepoint, virtual_account_9psb, wallet, cod]`
  - `Global / USD` → `[paypal, stripe]`
  - `UA / UAH` → `[liqpay]`
  - Wallets: `apple_pay (iOS)`, `google_pay (Android)` where enabled.
- Method-aware filtering (card → card-capable; VA → VA-capable; COD/Wallet internal).
- Selection: `filter(enabled && supports(country,currency,method)) → sort(priority, health) → Primary`.

## 4. Provider Failover
- Failover applies to **initiation** (`createPayment`) only — before the user is charged.
- **Never** silently retry after a possible charge — reconcile via webhook/verify.
- **Idempotency key** per order → no double-charge across retries/failover.
- **Circuit breaker** per provider.

## 5. Currency Routing & FX
- Currency as first-class dimension; per-currency provider sets; FX conversion + display currency vs settlement currency tracked; multi-currency wallets (future).

## 6. Settlement Engine
- Separate **authorization/capture** from **settlement**: `capturedAt`, `settlementBatch`, `settledAmount`, `providerFees`, `payoutDate`, FX.
- Reconcile provider settlement reports vs internal ledger; vendor payouts from **settled** funds; mismatch flags.

## 7. Webhook Engine
- Every provider registers a **signed webhook**; MoonJoin World **verifies signatures** and normalizes to `PAYMENT_SUCCEEDED | FAILED | PENDING | REFUNDED | CHARGEBACK | SETTLED`.
- **Idempotent** (dedup by event id); webhook is the **source of truth** over client redirects; drives order release.

## 8. Idempotency
- `idempotencyKey` per order-attempt end-to-end (create/verify/refund); providers dedup on their reference; safe retries and exactly-once order fulfilment.

## 9. Refund Engine
- Unified `refund(providerRef, amount)` (full/partial); status tracked (`REQUESTED → PROCESSING → REFUNDED | FAILED`); reconciled via webhook; wallet auto-credit option; audit trail.

## 10. Reconciliation
- Scheduled jobs match provider reports (payments, refunds, settlements, fees) against the internal ledger; surface discrepancies; support dispute/chargeback workflows.

## 11. Transaction Audit
- Structured record per attempt: `{orderId, idempotencyKey, provider, method, country, currency, amount, status, providerRef, fees, latency, errorCode, rawResponse, webhookEvents[], retryCount, failoverChain, timestamps}`.
- **PCI-safe:** never store PAN/CVV; only provider tokens/refs; mask sensitive fields; immutable audit log for disputes.

## 12. Fraud Detection Hooks
- Pluggable pre-authorization hooks: velocity/limits, device/IP risk, blocklists, 3-D Secure enforcement, anomaly scoring; hooks can allow/deny/challenge; provider-agnostic.

## 13. Provider Health Monitoring
- Health from success rate, latency, webhook delivery, error mix; feeds routing (deprioritize degraded) + Admin alerts (e.g. "Flutterwave 5xx spike").

## 14. Retry Strategy
- **Transient** (5xx, network, `429`): backoff + jitter, bounded, only for **idempotent** ops (verify, webhook, refund status).
- **Permanent** (declined, invalid, unsupported): no retry; failover for creation or surface. Reconciliation retries until terminal/expiry.

## 15. Admin Configuration & Feature Flags (no Flutter change)
- Enable/disable each provider; Primary/Secondary + priority per country/currency; edit routing table, fees, min/max, allowed methods.
- Everything behind **feature flags**; new provider = adapter + routing row + flag.
- View health, settlement, transaction analytics, disputes.

## 16. API Key & Secrets Management
- Provider keys/secrets **never** in the app or repo; stored in secrets manager/vault by reference; per-environment; rotation without code change; encrypted; audited.

## 17. Future Multi-Country Expansion
- Country + currency + local methods (USSD, mobile money, bank transfer, VA, wallets) as first-class; per-country provider sets; local compliance; new market = adapter + Admin routing row, **no app release**.

## 18. Frontend Contract (already in place, preserved)
- App fetches `configModel.activePaymentMethodList` (no hardcoding/filtering — verified Phase 7).
- On **Place Order** → launch the generic flow for the chosen method (COD direct, Wallet, Virtual Account sheet, card/redirect, or SDK) → show Order Success only after confirmation.
- Adding Flutterwave/Payscribe/LIQPAY/PayPal/Stripe/Moniepoint/Monnify/Paystack/Apple Pay/Google Pay or switching any ON/OFF is **backend + Admin only**.

## 19. Migration Note (from today's 6amMart backend)
The app already renders the active gateway list correctly; remaining inconsistencies ("only 9PSB shows") are documented backend/config-cache/hosting (Imunify360) limitations, not frontend. MoonJoin World replaces the legacy gateway/config layer with this provider-abstracted, Admin-driven, webhook-reconciled, settlement-aware architecture.
