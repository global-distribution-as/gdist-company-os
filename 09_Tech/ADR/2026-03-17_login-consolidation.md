# ADR: Consolidate portal login pages

**Date:** 2026-03-17
**Status:** Decided
**Priority:** 🟢 Low — cosmetic debt, does not affect function

---

## Context

The portal app (`apps/portal`) has two login pages:
- `Landing.tsx` (142 lines) — full photorealistic background (Unsplash image), aurora effect, dark overlay, teal vignette
- `Login.tsx` (107 lines) — simpler white card, same auth logic

Both contain identical auth code: `signInWithPassword()` → query `user_roles` → `navigate()` to role dashboard.

Jessica already solved this correctly: `LoginPage.tsx` is a reusable component parameterized by `portalName`, `dashboardPath`, `accentText`. Portal's Login.tsx wraps it in 12 lines.

---

## Options considered

**A. Keep both (current)**
Pro: Zero work. Con: Auth logic change requires updating two files. Bug risk.

**B. Delete Login.tsx, keep Landing.tsx only**
Pro: One page. Con: Landing.tsx has fancy background — may not suit all use cases.

**C. Extract shared LoginPage component, delete both (chosen)**
Similar to what Jessica does. `Landing.tsx` becomes a thin wrapper passing `showAurora={true}`. `Login.tsx` deleted. Auth logic lives once.

---

## Decision

Extract auth logic from `Landing.tsx` into a `LoginPage.tsx` component (same as jessica's). Landing.tsx passes `showAurora={true}`. Login.tsx is deleted.

**Note:** Portal's `LoginPage.tsx` cannot simply copy jessica's because the post-auth role routing is different (admin vs supplier vs buyer). The component needs a `roles: Record<string, string>` prop mapping role → dashboard path, or the auth-then-navigate logic lives in a shared hook.

---

## Consequences

- Auth bug fixes apply to both portals at once
- Login.tsx (107 lines) deleted — less surface area
- Low urgency: both pages work correctly today
