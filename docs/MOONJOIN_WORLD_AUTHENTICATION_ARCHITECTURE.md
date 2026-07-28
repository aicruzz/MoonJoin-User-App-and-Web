# MoonJoin World — Authentication Architecture (Enterprise)

> **Chapter D of the [MoonJoin World Enterprise Architecture](MOONJOIN_WORLD_ENTERPRISE_ARCHITECTURE.md).** Authentication is a **first-class Platform Services Layer (PSL, §2) service**, exactly like Communication (Chapter A) and Payments (Chapter C). It inherits the **Universal Provider Contract (§3)** — abstraction, registry, priority, country/zone/tenant routing, feature flags, health, failover, retry, timeout, circuit breaker, idempotency, logging, analytics, secrets, admin config, extensibility. This chapter adds authentication-specific detail.
>
> **Status:** Permanent enterprise architecture document for **MoonJoin World**. **Documentation only — NO Flutter implementation, NO backend implementation, NO code, NO migrations, NO freezes.** Core principle: **the frontend never contains provider-specific authentication routing — it only requests an Authentication *Capability*; the backend Authentication Provider Layer decides which provider fulfils it.** The current 6amMart auth (manual / OTP / Google-Apple-Facebook, `centralizeLoginSetup`) is a temporary compatibility layer that this architecture supersedes.

---

## 1. Scope & Principle
- **Authentication = a PSL service.** Adding, removing, reprioritizing, enabling/disabling, or country/zone/tenant-scoping any authentication method is an **Admin + backend** action with **ZERO Flutter changes** — identical to how Payment Providers work today.
- **Frontend requests a capability, never a provider.** The app asks the backend "what authentication capabilities are available for this (app, country, zone, tenant, platform)?" and renders them; on selection it calls a **provider-agnostic** endpoint. It never knows whether Google, Firebase, an OTP gateway, a passkey authenticator, or a magic-link service fulfilled the request.
- **Adding a new Authentication Provider requires only:** (1) a **Provider Adapter**, (2) **Admin Configuration**, (3) **Credentials** (vault), (4) a **Feature Flag**. Never a Flutter change, never a redeploy of the apps. *(Exactly like Payment Providers — Chapter C §15.)*

---

## 2. Authentication Provider Abstraction (backend, conceptual)
```
interface AuthenticationProvider {
  id; capability;                 // MANUAL | PHONE_OTP | EMAIL_OTP | GOOGLE | APPLE | FACEBOOK |
                                  // MICROSOFT | LINKEDIN | GITHUB | X | TIKTOK | SNAPCHAT |
                                  // PASSKEY | MAGIC_LINK | BIOMETRIC | <future>
  capabilities();                 // platforms(mobile/web), countries, zones, tenants, scopes
  isEnabled(); priority();        // Admin toggle + Primary/Secondary ordering
  begin(AuthRequest)  -> AuthChallenge { challengeId, kind, redirectUrl|clientParams|nonce }
  complete(AuthResult)-> AuthOutcome  { identityRef, verified, isExistingUser, isPersonalInfo, tokens? }
  healthCheck()       -> Health
}
```
- **AuthRequest** normalized: `{ capability, platform, country, zone, tenant, app, locale, requestId }`.
- **AuthOutcome** normalized so the frontend flow is identical regardless of provider (existing-user sheet / new-user setup / proceed — mirrors the frozen 9C auth cluster). Provider quirks (Firebase reCAPTCHA/session, Apple `authorizationCode`, Google `serverClientId`, Facebook token, passkey WebAuthn ceremony, magic-link token) live **inside** each adapter.

### 2.1 Supported Authentication Providers / Capabilities
| Capability | Current (6amMart) | MoonJoin World | Notes |
|---|---|---|---|
| **Manual Login** (email/phone + password) | ✅ | ✅ | `centralizeLoginSetup.manualLoginStatus`. |
| **Phone OTP** | ✅ (Firebase / gateway) | ✅ | OTP sent via the **Communication/OTP** PSL service (Chapter A/B); country-routed (`+234 → Termii`). |
| **Email OTP** | partial | ✅ | Email code via Communication email providers. |
| **Google** | ✅ (works) | ✅ | `google_sign_in` / web popup. |
| **Apple** | ⚠️ config issue | ✅ | Sign in with Apple; needs `applesignin` entitlement per build config. |
| **Facebook** | ⚠️ config issue | ✅ | `flutter_facebook_auth`; needs valid Meta dashboard/app config. |
| **Microsoft** | — | ✅ | OIDC (Azure AD / MSAL). |
| **LinkedIn** | — | ✅ | OAuth2/OIDC. |
| **GitHub** | — | ✅ | OAuth2. |
| **X (Twitter)** | — | ✅ | OAuth2. |
| **TikTok** | — | ✅ | TikTok Login Kit. |
| **Snapchat** | — | ✅ | Snap Kit / Login Kit. |
| **Passkeys** | — | ✅ | WebAuthn / FIDO2 (platform + roaming authenticators). |
| **Magic Link** | — | ✅ | One-time email/SMS deep-link; delivered via Communication service. |
| **Biometrics** | — | ✅ | Face ID / Touch ID / Fingerprint via device **secure storage** (re-auth of a stored identity, not a first-factor identity source); ties to the 9C-2 documented biometric extension point. |
| **Future providers** | — | ✅ | New capability = adapter + config + credentials + flag. No Flutter change. |

---

## 3. Per-Provider Controls (Universal Provider Contract, applied to auth)
Every authentication provider supports, from the Admin Panel, with **zero frontend change**:
- **Enable / Disable** (feature flag).
- **Primary / Secondary** (priority ordering — e.g. Passkey primary, Password secondary).
- **Country Availability** — allowed/blocked per country.
- **Zone Availability** — allowed/blocked per zone (a country contains many zones).
- **Tenant Availability** — allowed/blocked per tenant (white-label/enterprise).
- **Mobile Support** / **Web Support** — platform-scoped (some providers mobile-only or web-only).
- **API Credentials** — client IDs/secrets/keys, in the **secrets vault by reference** (never in app/repo).
- **Sandbox / Production** — per-environment credentials + endpoints.
- **Health Monitoring** — success rate, latency, error mix, provider outages.
- **Feature Flags** — granular on/off (incl. gradual rollout / canary).
- **Failover** — on provider failure/timeout, advance to the next healthy provider for the *same capability* where semantically safe (e.g. OTP gateway A → gateway B). Identity-provider failover (Google↔Apple) is **not** silent — the user chooses; failover applies to the **delivery mechanism** (e.g. which OTP/SMS gateway) and to transient infrastructure.
- **Retry** — bounded, exponential backoff + jitter, only for transient/idempotent steps.
- **Timeout** — per-provider request budget; slow provider → soft failure.
- **Circuit Breaker** — open after N failures in a window → cool-down → half-open probe.
- **Analytics** — attempts, success rate, method mix, drop-off, per country/zone/tenant/provider.
- **Logging** — structured, correlation by `requestId`; **never log secrets, OTP codes, tokens, or passwords**.
- **Admin Hot Switching** — swap Primary provider, enable/disable, reprioritize **live**, no redeploy, no Flutter change (guarded — see §5).

---

## 4. Capability-Request Flow (frontend ↔ backend)
1. **Discover:** app requests available capabilities for `{app, platform, country, zone, tenant}` → backend returns an ordered, provider-anonymous capability list (e.g. `[passkey, phone_otp, google, apple, manual]`). *(Today this is the `centralizeLoginSetup` config; MoonJoin World generalizes it to the Auth Provider Layer.)*
2. **Render:** the app renders the returned capabilities using the **frozen MoonJoin Auth Foundation** (9C-1) — `AuthSocialButton` pills, OTP field, manual form. **No provider-specific branching in the UI.**
3. **Begin:** on selection → `POST /auth/begin { capability, requestId }` → `{ challengeId, kind, params }` (redirect URL, client params, nonce, or "await OTP").
4. **Complete:** `POST /auth/complete { challengeId, proof }` → normalized `AuthOutcome`.
5. **Route to the same normalized post-auth flow** (existing-user / new-user-setup / proceed) — identical to the frozen 9C cluster, regardless of provider.

**Frontend contract (fixed forever):** the app calls only `auth/capabilities`, `auth/begin`, `auth/complete` (+ the existing OTP send/verify facades). Provider selection, routing, failover, retry, health, credentials are **entirely server-side**. Enabling Passkeys, disabling Facebook, adding Microsoft, or reprioritizing is an **Admin action** — no Flutter change.

---

## 5. Admin Configuration, Hot-Switching & Safety
- Admin manages, per capability: enable/disable, Primary/Secondary, country/zone/tenant scope, mobile/web scope, sandbox/prod credentials (vault ref), rate limits, timeouts, retry/breaker thresholds; and views health + analytics.
- **Guarded hot-switching:** validate + canary a provider before promoting it to Primary; auto-rollback on health regression (mirrors §13.10 of the master).
- Panel login portals (Super Admin, Admin Employee, Vendor, Vendor Employee — master §1.1) are themselves consumers of this Authentication service.

---

## 6. Secrets, Compliance & Security
- All provider credentials (OAuth client secrets, service keys, Apple keys, WebAuthn RP config) live in the **secrets vault by reference**, per-environment, rotated without code change, least-privilege, audited (master §13.5, §16-equivalent).
- Tokens/sessions follow platform IAM (master §13.6): OAuth2/OIDC, short-lived access + refresh, MFA/step-up, session lifecycle. **Customer authentication (this chapter) is distinct from customer Identity/KYC** — see **Chapter E (Identity)**.
- **PII/secret hygiene:** OTP codes, passwords, tokens, and authorization codes are **never** logged; analytics are aggregated.

---

## 7. Relationship to Identity (Chapter E)
Authentication (**who is signing in / proving control of a phone, email, or social account**) is **separate** from Identity/KYC (**proving legal identity: ID docs, face match, liveness, BVN/NIN**). A capability like Phone/Email verification belongs to **Authentication**; National ID / Passport / Face Match / Wallet-KYC belong to **Identity** and are governed by the hierarchical **Platform → Country → Zone → Application → Feature** model in **Chapter E**. The two compose: an app in a given zone may require *phone + email authentication* (this chapter) and *zero identity verification* (Chapter E) — e.g. the User App — while the Delivery App requires the same authentication **plus** configured identity checks.

---

## 8. Migration Note (from today's 6amMart auth)
Today the app reads `configModel.centralizeLoginSetup.*` + per-provider flags and branches in `CentralizeLoginHelper` (7 layouts); social SDKs live in the frozen `social_login_widget.dart`; OTP is sent inside `/auth/login`. The frontend is **already largely capability-driven** (it renders whatever the config enables, no hardcoded provider list) — MoonJoin World formalizes this into a first-class **Authentication Provider Layer**: provider-anonymous capabilities, country/zone/tenant routing, failover, health, analytics, and Admin hot-switching, so new providers (Microsoft, LinkedIn, GitHub, X, TikTok, Snapchat, Passkeys, Magic Link, Biometrics) plug in with **only** adapter + admin config + credentials + flag.
