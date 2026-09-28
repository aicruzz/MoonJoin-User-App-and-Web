# 9PSB Checkout Virtual Account Generation — Production Freeze

> **FROZEN (owner-approved 2026-09-28).** Implementation commit **`bdf05ce5ae7f066a7dd9c8bb18dd20a3abb48b2d`**, parent
> **`4d836ce64c1296f47447bafe08545a95b56078c2`**. Frontend-only Checkout entry point for the already-frozen 9PSB customer
> virtual-account generation flow. **Reuse only — do not fork, duplicate or redesign.** Reopening requires a production bug,
> a backend contract change, or an explicit owner request.

---

## 1. Purpose

A customer with 9PSB enabled but **no virtual account yet** previously had to leave Checkout, navigate to Account/Menu,
generate the account there, and come back to finish paying. This slice removes that detour.

The affordance already existed. It was simply suppressed on Checkout: `VirtualAccountDetailsWidget` renders its
"Generate Virtual Account" button in the null-account state only when `detailsOnly == false` (Profile / Menu), and Checkout
passes `detailsOnly: true`, which rendered the funding placeholder text instead.

**Nothing new was built.** One additive opt-in flag now lets a `detailsOnly` surface keep the existing button, and it is set
only on the Checkout sheet.

## 2. What was reused (single implementation, zero duplication)

| Concern | Reused implementation |
|---|---|
| The card + the button | **`VirtualAccountDetailsWidget`** — the one master "Your Virtual Account Details" component |
| The generation action | **`ProfileController.generateVirtualAccount()`** — the same method Account/Menu invokes |
| Loading state | `ProfileController.isGeneratingAccount` → the widget's existing `_loadingShell` |
| Success / error messaging | The existing `showCustomSnackBar` calls inside `generateVirtualAccount()` |
| State refresh | The existing `getUserInfo()` + `update()` inside `generateVirtualAccount()` |
| Gateway visibility | The frozen `is9PSBActive()` gating (`lib/helper/payment_gateway_helper.dart`) |

**No new widget, action, controller, repository, service, helper or endpoint. No second generation flow. No duplicated API call.**

## 3. Files changed (implementation commit `bdf05ce`)

```
lib/features/checkout/widgets/virtual_account_details_widget.dart   +11/-2
lib/features/checkout/widgets/payment_method_bottom_sheet.dart       +1/-1
test/profile/nine_psb_gateway_visibility_test.dart                  +91/-1
```

The entire production change:

- `virtual_account_details_widget.dart` — added `final bool allowGenerate` (**defaults to `false`**) and changed one
  condition from `else if (detailsOnly)` to `else if (detailsOnly && !allowGenerate)`.
- `payment_method_bottom_sheet.dart` — `VirtualAccountDetailsWidget(detailsOnly: true, allowGenerate: true)`.

Because the flag defaults to `false`, **every pre-existing call site renders exactly as before**.

## 4. Architecture — frontend to provider

```
Flutter User App / Web
  ProfileController.generateVirtualAccount()
    → ProfileRepository → ApiClient(appBaseUrl: AppConstants.baseUrl)
    → POST https://admin.moonjoin.com/api/v1/wallet/virtual-account
        → MoonJoin backend
        → NinePsbPaymentController::createVirtualAccount
        → NinePsbService
        → https://api-backend.airpero.com        (current production provider host)
```

**Exact frontend endpoint:** `POST /api/v1/wallet/virtual-account` on `AppConstants.baseUrl`
(`https://admin.moonjoin.com`), declared as `AppConstants.generateVirtualAccountUri`.

**The Flutter app never contacts the provider.** The provider hop is entirely server-side.

## 5. Provider URL reconciliation (recorded so it is not re-litigated)

An earlier audit reported `sandbox.v1.airpero.com` returning HTTP 503. That finding is **stale and does not apply to this
slice**:

- It described the **backend's** then-configured provider host, never frontend configuration.
- All observed 503 responses predate the production provider migration.
- Production backend configuration and the deployed `NinePsbService` default now both point at the current production
  Airpero business API host, and the frontend is unaffected either way.

**Verified at freeze time:** the User App & Web repository contains **zero** Airpero references — no provider host, SDK,
credential or configuration in any source, config, asset or platform manifest file. Commit `bdf05ce` introduces **no** URL,
endpoint, key or provider configuration: 104 changed code lines, zero matches for `airpero`, `http(s)://`, `base_url`,
`api_key`, `secret` or `endpoint`.

The obsolete shape *Flutter → sandbox provider API* has never existed and cannot exist: the app has no code path to any
provider.

## 6. Gating — the admin/payment configuration stays authoritative

Visibility is decided **before** this slice is reached, by the frozen 9PSB gateway gating that reads the existing
`ConfigModel.activePaymentMethodList` through `is9PSBActive()`. This slice changes **nothing** about that.

| Admin 9PSB | Checkout result |
|---|---|
| **Enabled** | The virtual-account section renders; the generate affordance is available when the customer has no account |
| **Disabled** | The whole section is absent — **no card and no generate affordance** |

Gateway configuration reaches the app through the existing cache-first config lifecycle (refreshed on cold launch). That
lifecycle is unchanged by this slice.

## 7. Behaviour matrix

| Customer state (9PSB enabled) | Checkout behaviour |
|---|---|
| **No virtual account** | The existing "Generate Virtual Account" button is offered inline — no navigation away from Checkout |
| **Generation in progress** | The existing loading shell **replaces** the button, so a second tap is impossible |
| **Virtual account exists** | The existing details card renders; **no redundant generate action** is shown |
| **Generation fails** | The existing error snackbar is shown; no local state is invented |
| **Generation succeeds** | `getUserInfo()` refreshes profile state and `update()` rebuilds the surrounding `GetBuilder`, so Checkout shows the new account **immediately — no logout, no app restart** |

Wallet "+" (Add Fund) keeps its funding placeholder, because `allowGenerate` defaults to `false` there. Account/Menu and
Profile are untouched — they already showed the button via `detailsOnly == false`.

## 8. Duplicate-tap protection

`generateVirtualAccount()` sets `isGeneratingAccount = true` and calls `update()` before the request. The widget's branch
order places the loading state **above** the generate branch, so while a request is in flight the button is not rendered at
all. The backend additionally guards with `userAlreadyHasVirtualAccount()`, returning the existing account rather than
creating a second one. Both protections are pre-existing and were reused, not re-implemented.

## 9. Testing at freeze

| Check | Result |
|---|---|
| `flutter test test/profile/` | **20/20 pass** (16 existing + 4 new) |
| `flutter test test/item/` | **pass** — Media 6 regression clean |
| Scoped `flutter analyze` on the changed files | **No issues found** |
| Project-wide `flutter analyze` | **31 issues — 0 errors, 2 warnings, 29 infos** (the pre-existing baseline; the 2 warnings are `invalid_use_of_protected_member` in `lib/helper/pusher_helper.dart`, unrelated to this slice) |

New test coverage for the Checkout entry point:

1. No account + `allowGenerate` → the existing generate affordance is offered.
2. No account **without** `allowGenerate` → the existing placeholder is preserved (Wallet "+").
3. Existing account → details card, **no** redundant generate action, no `N/A`.
4. While generating → the loading shell replaces the button, so a second tap is impossible.

One pre-existing structural guard was relaxed from pinning the exact argument list
(`VirtualAccountDetailsWidget(detailsOnly: true)`) to asserting the shared widget is still rendered under the 9PSB flag
(`VirtualAccountDetailsWidget(detailsOnly: true`). The guard's purpose is intact and the four behavioural tests above cover
the added argument.

## 10. Explicitly out of scope

- **Backend** — no change of any kind. Slice 1 (customer VA generation) and Slice 2 (webhook security) remain frozen and
  were not reopened.
- **Provider integration** — no Airpero URL, credential, environment or configuration change; no provider call was made
  while producing this slice.
- **API contracts** — no new endpoint, no change to `POST /api/v1/wallet/virtual-account` or its `{message, data}` envelope.
- **9PSB gateway gating** — unchanged; `nonPSBMethods` still excludes 9PSB from the normal selectable gateway rows, and the
  virtual-account card remains independent of wallet balance.
- **Checkout layout** — not redesigned. No label, style, spacing, navigation or workflow change; the card stays where it was.
- **Account/Menu, Profile, Wallet "+"** — behaviour unchanged.
- **Provider reliability** — whether a given generation attempt succeeds depends on the backend and the provider. This slice
  makes the entry point available; it cannot make generation succeed.

## 11. Reuse rules (permanent)

- **Never** add a second "Generate Virtual Account" button — reuse `VirtualAccountDetailsWidget`.
- **Never** call the generation endpoint from a new controller/service — reuse `ProfileController.generateVirtualAccount()`.
- **Never** hardcode 9PSB visibility — reuse `is9PSBActive()` and the existing `activePaymentMethodList`.
- **Never** place a provider host, key or SDK in the User App & Web repository. The app talks only to the MoonJoin backend.
- A future surface that needs the inline generate affordance sets `allowGenerate: true` on the existing widget. It does not
  fork it.
