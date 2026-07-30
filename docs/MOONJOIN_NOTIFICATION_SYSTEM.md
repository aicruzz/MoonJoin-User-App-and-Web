# MoonJoin Notification System (Phase A1)

> **Platform standard — the single notification language for all of MoonJoin.** Implemented as a thin façade
> over existing, frozen primitives. **No new UI was created; no order-communication flow was redesigned.**
> Façade: `lib/common/widgets/moonjoin/notifications/moonjoin_notifications.dart` (`MoonJoinNotifications`).

---

## 1. Purpose

Prevent duplicate notification designs across MoonJoin. Before A1, the notification *primitives* existed
(`MoonjoinDialog`, `MoonjoinBottomSheet`, `SuccessBanner`, `StatusBadge`, `InformationCard`,
`ConfirmationDialog(moonjoin: true)`, `MoonjoinErrorState`, `MoonjoinEmptyState`, `showCustomSnackBar`) but there
was **no single entry point** telling a feature *which* primitive to use for *which* kind of message. Every new
feature risked inventing its own dialog/sheet/banner/toast.

A1 closes that gap with **one façade + this catalog**. Every current and future feature — customer, vendor,
delivery, admin, and **future AI messages** — resolves to the same notification language.

## 2. Architecture principle

- **Façade, not framework.** `MoonJoinNotifications` **orchestrates existing components**; it never draws its own
  visuals. The primitives remain the source of truth for appearance.
- **Pure presentation.** The façade holds no state, calls no API, and touches no controller / repository /
  service. All behaviour is wired through the caller's callbacks. **It must never be given business logic.**
- **Additive & non-invasive.** A1 introduced exactly one new file (the façade) + one barrel export line + this
  doc. **No existing screen, component, controller, model, route, or API changed.**
- **One toast only.** Transient feedback always routes through the app-wide `showCustomSnackBar`. No second
  snackbar/toast system may be created.

## 3. Notification categories (taxonomy)

| # | Category | When to use | Examples | Renders via (existing primitive) | Façade method |
|---|---|---|---|---|---|
| 1 | **Success** | Terminal positive outcome | Order placed · Payment successful · Account created | `SuccessBanner` | `MoonJoinNotifications.success(...)` (modal) · `successBlock(...)` (inline) |
| 2 | **Information** | Neutral status / progress / announcement | Order updates · Delivery progress · General notices | `InformationCard` · `StatusBadge` | `infoCard(...)` · `statusBadge(...)` |
| 3 | **Warning** | Attention required, user may act | Missing information · Attention needed | `MoonjoinBottomSheet` + `InformationCard` (+ optional `MoonjoinButton` actions) | `warningSheet(...)` |
| 4 | **Error** | Hard failure | Payment failed · Order failed | `MoonjoinDialog` · `ConfirmationDialog(moonjoin: true)` | `error(...)` · `confirm(...)` |
| 5 | **Transient feedback** | Minor confirmation, auto-dismiss | Saved · Updated · Copied | `showCustomSnackBar` **only** | `transient(...)` |

**Page-level states** (not popups, but part of the same system): full-area **error** (`MoonjoinErrorState`) and
**empty** (`MoonjoinEmptyState`) placeholders → `errorState(...)` / `emptyState(...)`.

## 4. Component mapping (source of truth)

The façade delegates 1:1 to these frozen/shared components — **do not fork them**:

- `SuccessBanner` — `common/widgets/moonjoin/success_banner.dart`
- `InformationCard` — `common/widgets/moonjoin/information_card.dart`
- `StatusBadge` — `common/widgets/moonjoin/status_badge.dart`
- `MoonjoinBottomSheet` — `common/widgets/moonjoin/moonjoin_bottom_sheet.dart`
- `MoonjoinButton` — `common/widgets/moonjoin/moonjoin_button.dart`
- `MoonjoinDialog` — `common/widgets/moonjoin/moonjoin_dialog.dart`
- `ConfirmationDialog(moonjoin: true)` — `common/widgets/confirmation_dialog.dart`
- `MoonjoinErrorState` — `common/widgets/moonjoin/error_state_widget.dart`
- `MoonjoinEmptyState` — `common/widgets/moonjoin/empty_state_widget.dart`
- `showCustomSnackBar` — `common/widgets/custom_snackbar.dart`

## 5. Reuse rules

1. **Need to tell the user something? Call `MoonJoinNotifications`.** Pick the category from §3.
2. Import via the barrel: `import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_components.dart';`.
3. Wire behaviour through callbacks only — never put logic in the façade.
4. If a genuinely new *primitive* is ever required, add it to `common/widgets/moonjoin/` **and** map it here so
   it stays inside the one system — never as a one-off inside a feature.

## 6. Forbidden duplicate patterns

- ❌ A new bespoke `Dialog` / `AlertDialog` for errors or confirmations → use `error(...)` / `confirm(...)`.
- ❌ A new bottom sheet for warnings/attention → use `warningSheet(...)`.
- ❌ A new success screen/banner style → use `success(...)` / `successBlock(...)`.
- ❌ A second snackbar/toast → use `transient(...)` (→ `showCustomSnackBar`).
- ❌ A new inline notice/status pill → use `infoCard(...)` / `statusBadge(...)`.
- ❌ Copying the frozen order-communication surfaces (Home "Some items are unavailable" card, Edit Unavailable
  Items) into a new notification — **those are frozen and remain the owners of that flow.**

## 7. Protected / not touched (frozen)

A1 did **not** modify any of these; they remain frozen and real-order verified:

- `module_landing_view.dart` `_UnavailableItemsCard` (Home "Some items are unavailable")
- `order_edit_screen.dart` (Edit Unavailable Items)
- `dashboard_screen.dart` Home chrome and the running-order bar (`running_order_view_widget.dart`)
- `OrderController`, `CartController`, `CheckoutController`, all APIs / models / routes
- every existing MoonJoin primitive

Running-order status-card polish (A2) and the unavailable-preference sheet restyle (A3) are **separate future
decisions**, explicitly out of A1 scope.

## 8. Future AI notification compatibility

AI messages, vendor messages, delivery messages, admin messages, and customer notifications **must use this same
system**. **AI must never create its own notification UI.** An AI-surfaced message maps to a category in §3
exactly like any other feature (an AI suggestion → `infoCard`; an AI action prompt → `warningSheet`; an AI error
→ `error` with a deterministic fallback message). This keeps the AI Failover Principle intact: whether a message
originates from AI or a deterministic path, the user sees **one** MoonJoin notification language. See
`docs/MOONJOIN_AI_PLATFORM_ARCHITECTURE.md`.

---

**Status:** MoonJoin Notification System — **Implemented · Analyzer Clean · Runtime Verified · Owner Approved ·
FROZEN (2026-07-30).** Façade + catalog only; no redesign, no business-logic change.
