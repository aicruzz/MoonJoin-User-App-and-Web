# MoonJoin User App

This is the official instruction file for Claude.

This project is a production Flutter application.

The backend already exists and is fully functional.

The website already uses the backend successfully.

This Flutter project is ONLY the frontend.

The goal is to redesign the UI without breaking any existing functionality.

Always preserve:

- API endpoints
- Controllers
- Providers
- Bloc/Cubit
- Repository layer
- Services
- Models
- Navigation
- Authentication
- Business logic

Never modify backend APIs.

Never invent backend endpoints.

If a feature is not implemented in Flutter but already exists on the website, identify and reuse the required Flutter integration.

If a feature exists only as a UI design (for example Short Apartment Rent), build a complete production-ready frontend using mock repositories until backend APIs become available.

Always follow:

- docs/DESIGN_SYSTEM.md
- docs/UI_INDEX.md
- docs/COMPONENTS.md
- docs/SCREEN_FLOW.md
- ui-designs/

Never invent UI.

Always reproduce the provided UI exactly.

Always search the existing codebase first before creating new widgets.

If an existing widget, controller, repository, service, model or component can be reused, reuse it.

Only create new components when no suitable implementation already exists.

Never duplicate existing functionality.

---

# 🎨 DESIGN AUTHORITY (HIGHEST PRIORITY)

MoonJoin has TWO official design authorities.

---

## Active Figma Configuration

Before starting ANY UI task, ALWAYS read:

docs/ACTIVE_FIGMA.md

This file contains:

- The currently active Figma project.
- The active Figma link.
- The application currently being redesigned (User App, Vendor App, Delivery App, etc.).
- Any notes specific to the active redesign.

Never hardcode Figma links anywhere else.

Always use the Active Figma defined inside:

docs/ACTIVE_FIGMA.md

---

## 1. Active Figma (Implementation Authority)

The Active Figma is the implementation source whenever the requested screen exists.

IMPORTANT

The Figma MCP is the official and permanent method for accessing Figma.

Never use WebFetch to inspect Figma.

Never implement directly from a Figma URL.

Always open the design through the Figma MCP.

Whenever a matching Figma frame exists:

- Read the actual Figma frame through the MCP.
- Reuse the Figma implementation exactly.
- Treat the Figma frame as the source of truth for implementation.

Only fall back to /ui-designs/ if the requested screen genuinely does not exist in the Active Figma.

Do not ask whether Figma is available.

Do not stop the task waiting for Figma access.

Assume the Figma MCP is configured and use it automatically.

Match exactly:

- Auto Layout
- Layout
- Component hierarchy
- Constraints
- Padding
- Margins
- Spacing
- Typography
- Font sizes
- Font weights
- Colors
- Border radius
- Shadows
- Elevation
- Icon sizes
- Icon positioning
- Images
- Visual proportions

Never redesign.

Never simplify.

Never estimate.

Never approximate.

Never "improve" the design.

Reuse the Figma implementation exactly.

---

## 2. ui-designs (Visual Authority)

Location:

ui-designs/

Every image inside ui-designs is an approved production reference.

If the screen exists in the Active Figma:

1. Implement directly from Figma.
2. Compare against the matching image inside ui-designs.
3. Continue refining until there is no meaningful visual difference.

If the screen does NOT exist inside the Active Figma:

Use ONLY the matching design inside ui-designs.

Never invent layouts.

Never estimate spacing.

Never redesign.

Never approximate.

---

## Active Figma Workflow

The Active Figma intentionally contains ONLY the screens currently being redesigned.

Examples:

Current:

- User App

Later:

- Vendor App

Later:

- Delivery App

Old pages may be removed.

Always use ONLY the pages inside the current Active Figma.

Never depend on deleted pages.

If a screen is missing from the Active Figma, immediately fall back to ui-designs.

Do NOT stop the task.

Do NOT repeatedly ask for Figma access.

---

## Pixel Perfect Rule

Every implementation must be visually indistinguishable from the official design.

Implementation order:

1. Active Figma (when available)
2. ui-designs verification

The implementation is NOT complete until both match.

---

## Organic Module Icons (Mandatory)

Every module icon MUST use the reusable OrganicModuleIcon component.

Rules:

- Fixed outer green ring.
- Stable organic white inner blob.
- Organic blob selected deterministically from the module ID.
- Never random.
- Never identical circles.
- Every module always keeps the same organic shape.
- New modules automatically receive their own stable organic shape.
- The visual language must remain identical across every module.

---

## Design Verification (Mandatory)

Before declaring ANY UI task complete:

1. Run the application.
2. Launch the iOS Simulator.
3. Navigate to the implemented screen.
4. Capture screenshots.
5. Compare side-by-side with:
   - Active Figma (when available)
   - Matching ui-designs image
6. Fix every mismatch.
7. Repeat until there is NO meaningful visual difference.
8. Run flutter analyze.
9. Never mark a UI task complete based only on code review.

Only stop when the implementation is effectively a 100% visual match.

If a matching Figma frame exists, it is the mandatory implementation source.

The /ui-designs/ image is used only to verify the final rendered appearance.

Implementation priority is always:

1. Active Figma (via the Figma MCP)
2. /ui-designs/ visual verification

Only when a screen genuinely does not exist in the Active Figma may Claude use /ui-designs/ as the implementation source.

Claude must never ignore an available Figma frame, never implement directly from the PNG when a Figma frame exists, and never use WebFetch for Figma.

## Component Reuse Policy

Before creating any new UI component, search the existing codebase for an equivalent component. If one already exists and matches the MoonJoin design language, reuse and extend it instead of creating another implementation.

Shared components (such as banners, category chips, cards, carousels, search bars, buttons, bottom action bars, quantity selectors, product cards, restaurant cards, filter chips, and section headers) must have a single visual implementation throughout the application unless explicitly instructed otherwise.

## End-to-End Navigation Verification (Mandatory)

Every newly redesigned screen must be reached through the real application flow whenever practical.

Example:

Home → Restaurants → Product Details → Cart → Checkout → Payment → Order Success

Requirements:

- Always navigate to the screen through the real user journey.
- Verify that navigation, state management, transitions and backend integration work correctly.
- Only use temporary debug navigation when there is no practical way to reach the screen through the application.
- Remove every temporary debug route, hook or navigation override before marking the task complete.
- Never leave debugging code in production.
- Before freezing a screen, verify it works correctly when reached through the real application flow.

A screen is not considered complete until it has been verified through the real user journey whenever possible.

## Payment Flow Authority

The Checkout screen is the single order-review screen.

It is responsible for:

- Delivery Type
- Delivery Address
- Delivery Instructions
- Delivery Time
- Promo Code
- Tips
- Additional Note
- Order Summary
- Terms & Conditions

Checkout finishes with **Place Order**.

Payment experiences are NOT separate checkout screens.

After Place Order is pressed:

- Validate the checkout.
- Validate the selected payment method.
- Launch the appropriate payment flow for that payment method.

Examples:

- Cash on Delivery → place order directly.
- Wallet → wallet verification/payment flow.
- Virtual Account → Virtual Account payment dialog/sheet.
- Card → card payment flow.
- Other payment methods → their own existing production flow.

Only after payment succeeds should the Order Success screen be displayed.

Never redesign or replace an existing production payment flow unless a matching design is provided.

## UI vs Business Logic Authority

UI redesigns must never change production business logic.

Claude may redesign:

- Layout
- Styling
- Animations
- Component arrangement
- Navigation presentation

Claude must not change without explicit approval:

- APIs
- Backend contracts
- Controllers
- Payment verification
- Wallet logic
- Checkout validation
- Order processing
- Cart calculations
- Taxes
- Discounts
- Timers
- Business rules

The existing production logic should be reused whenever possible, with only the presentation layer redesigned.

## Screen Freeze Policy

Once a screen has been approved by the product owner:

- Mark it as Frozen.
- Do not revisit, refactor, redesign, or restyle it unless explicitly instructed.
- Only return to a Frozen screen if:
  - a production bug is discovered,
  - an API/backend change requires it,
  - or the product owner requests a redesign.

This prevents regression and keeps the migration moving forward.