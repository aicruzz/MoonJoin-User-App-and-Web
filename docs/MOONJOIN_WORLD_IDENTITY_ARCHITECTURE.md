# MoonJoin World — Identity & KYC Governance Architecture (Enterprise)

> **Chapter E of the [MoonJoin World Enterprise Architecture](MOONJOIN_WORLD_ENTERPRISE_ARCHITECTURE.md).** Identity Verification (KYC) is a Platform Services Layer (PSL, §2) service inheriting the Universal Provider Contract (§3). This chapter defines the **permanent Identity governance model** and **supersedes every previous Identity/KYC assumption**, including any notion of platform-wide or globally-required KYC.
>
> **Status:** Permanent enterprise architecture document for **MoonJoin World**. **Documentation only — NO code, NO Flutter, NO backend, NO migrations, NO freezes.** Core principle: **Identity is never platform-wide. Identity is configuration, resolved through a hierarchy, and every requirement is a feature toggle. MoonJoin World must operate in any country without changing code.**

---

## 1. The Governance Hierarchy (permanent)
Identity requirements are **resolved top-down** through five levels. Nothing is hardcoded; every level is Admin-configurable.

```
Platform
   ↓        (global defaults / allowed capability set)
Country
   ↓        (sets country-legal baselines; contains tenants & zones)
Tenant (optional)
   ↓        (white-label / enterprise / government partner — defines its OWN identity
            policy BEFORE zone policies apply; skipped for first-party MoonJoin)
Zone
   ↓        (each zone has its OWN Identity Policy)
Application   (User · Vendor · Delivery · Tenant — independent requirements)
   ↓
Feature       (ordering · wallet · large transaction · international transfer · virtual card · payout …)
```

- **Every Country contains multiple Tenants and Zones.**
- **Tenant (optional) sits between Country and Zone.** MoonJoin World is white-label: different tenants inside the **same country** may have **different compliance requirements** — e.g. **MoonJoin (first-party), ABC Logistics, XYZ Pharmacy, an Enterprise Customer, a Government Partner**. Each tenant defines its identity policy **independently, before Zone policies apply**. For first-party MoonJoin the Tenant level is simply skipped (no tenant override).
- **Every Zone has its own Identity Policy.**
- **Every Application inside a Zone has independent verification requirements.**
- **Every Feature inside an Application can carry its own additional requirement.**
- **Resolution:** the effective requirement for a given action = the composition of Platform default → Country baseline → **Tenant policy (if any)** → Zone policy → Application policy → Feature policy. The most specific level wins; a lower level can only tighten within what the platform's capability set and the country's legal baseline allow.

This **replaces** any earlier "module-based, fixed" phrasing with a fully **zone-and-feature-configurable** model. The previous canonical outcome (User-App customers = phone + email only, no KYC) is now expressed as the **default configured policy**, not a hardcoded universal — it remains the intended default everywhere, but is a toggle set, not code.

---

## 2. Configurable Identity Capabilities
Each is an independent **feature toggle** at the Zone/Application/Feature level (never global, never hardcoded):

`Phone Verification` · `Email Verification` · `Face Match` · `National ID` · `NIN` · `BVN` · `Passport` · `Driver License` · `Business Certificate` · `Business Address` · `Tax Documents` · `Vehicle Documents` · `Insurance` · `Wallet KYC` · `Background Check` · `AML` · `Sanctions Screening` · `Liveness` · `<future>`

Providers (Smile ID, Dojah, VerifyMe, Onfido, etc.) sit **behind the PSL Identity facade** (master §10 row 9) and are selected by country/zone routing — the requesting app never knows which provider ran the check.

---

## 3. Per-Application Policy (example — Zone A)
These are **example configured policies** for one zone, not hardcoded rules. Each cell is an Admin toggle.

### 3.1 User App (Zone A)
| Capability | Required |
|---|---|
| Email Verification | ✅ |
| Phone Verification | ✅ |
| Face Match | ❌ |
| National ID | ❌ |
| Passport | ❌ |
| Driver License | ❌ |
| Business Certificate | ❌ |
| BVN | ❌ |
| NIN | ❌ |
| Wallet KYC | ❌ |

> **Default customer experience (intended everywhere, permanent MoonJoin philosophy):** install → register → verify phone → order immediately. **Phone Verification = required; Email Verification = configurable; everything else optional.** Like Glovo/DoorDash/Uber Eats/Deliveroo/Bolt Food/Chowdeck. **No mandatory BVN, NIN, Passport, Face Match, Driver License, Liveness, or KYC before placing orders — ever.** A regulated zone/tenant *could* configure more, but the platform default keeps ordering friction-free.

### 3.2 Vendor App (Zone A)
| Capability | Setting |
|---|---|
| Phone Verification | ✅ |
| Email Verification | ✅ |
| Business Certificate | ✅ |
| Business Address | ✅ |
| Tax Documents | optional |
| Face Match | configurable |

### 3.3 Delivery App (Zone A)
| Capability | Setting |
|---|---|
| Phone Verification | ✅ |
| Email Verification | ✅ |
| Driver License | ✅ |
| National ID | configurable |
| Face Match | configurable |
| Liveness | configurable |
| Background Check | future |
| AML / Sanctions | configurable (future) |
| Vehicle Documents | configurable |
| Insurance | configurable |

> Delivery identity (stronger by design) stays **Country-, Tenant-, and Zone-configurable** — every item above is a toggle, not a hardcoded rule. **Vendor App onboarding is business-verification only and is NOT redesigned here — documented for future flexibility only.**

### 3.4 Tenant App (Delivery-as-a-Service B2B — master §1.1)
| Capability | Setting |
|---|---|
| Phone Verification | ✅ |
| Email Verification | ✅ |
| Business Certificate | ✅ |
| Business Address | ✅ |
| Tax Documents | configurable |
| Face Match | optional |

---

## 4. Wallet / Financial KYC Rules (feature-based, per Country / Zone / Tenant / Feature)
**Wallet KYC must NOT be globally required.** It is configured per **Country · Zone · Tenant · Feature**.

**Examples (configured policy, not hardcoded):**

| | Nigeria | Canada |
|---|---|---|
| Wallet Enabled | ✅ | ✅ |
| Wallet KYC | ❌ | ✅ |
| Phone Verification | ✅ | ✅ |
| Email | optional | — |
| Government ID | — | ✅ |
| Face Match | — | ✅ |
| Passport | — | ✅ |

*Nigeria rationale (example): Wallet KYC OFF is acceptable because **SIM registration already ties the phone number to NIN**, so phone verification carries identity weight; another country with no such linkage may require Wallet KYC + Passport + Face Match. All configurable — never hardcoded.*

**Feature-triggered escalation (configurable):** even where baseline Wallet KYC is off, a specific **Feature** may require it:
- **Large Transactions** → Wallet KYC may become mandatory (per threshold).
- **International Transfers** → Wallet KYC may become mandatory.
- **Virtual Cards** → Wallet KYC may become mandatory.

KYC is **tiered by risk/limit/feature**, applied only to the specific financial feature — **never** to ordinary ordering.

---

## 5. Admin Panel — Per-Zone Independent Configuration
The Admin Panel must let **every Zone** independently configure (all feature-toggle driven, nothing hardcoded):

`Phone Verification` · `Email Verification` · `Face Match` · `National ID` · `NIN` · `BVN` · `Passport` · `Driver License` · `Business Certificate` · `Wallet KYC` · `Background Check` · `AML` · `Sanctions` · `Liveness`

- Per **Application** (User / Vendor / Delivery / Tenant) within the zone.
- Per **Feature** (ordering / wallet / large-transaction / international-transfer / virtual-card / payout …).
- With **Sandbox / Production**, provider selection/routing, health, analytics, and audit — no redeploy, no Flutter change.

---

## 6. Data Protection & Compliance (applies wherever Identity is enabled)
- PII **minimized, encrypted at rest/in transit, consent-gated, region-resident** (master §13.3), **tiered** (KYC levels), **auditable**, and **re-verified per policy** (master §13.5).
- Verification runs **async via provider webhooks**; results cached with expiry; least-privilege access; immutable audit trail.
- Identity is **composed with, but separate from, Authentication (Chapter D)** — authentication proves control of a phone/email/social account; identity proves legal identity.

---

## 7. Invariants (Identity)
1. Identity is **never platform-wide** and **never hardcoded** — it is resolved through **Platform → Country → Tenant (optional) → Zone → Application → Feature**, with tenant policy applied before zone policy (white-label compliance independence).
2. Every Identity capability is an **independent Admin feature toggle**.
3. **Ordering never forces KYC**; the User App default stays phone + email.
4. **Wallet KYC is per Country/Zone/Tenant/Feature**, tiered — never global.
5. MoonJoin World can **launch in any country by configuration alone** — no code change to add/relax/tighten identity requirements.
6. This model **supersedes all earlier Identity/KYC assumptions**, including any global-KYC assumption.
