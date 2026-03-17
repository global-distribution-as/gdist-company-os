# ADR: Login Page Consolidation

**Date:** 2026-03-16
**Status:** Open — low priority

## Context

`apps/portal` has two nearly-identical login components:

- `Landing.tsx` — photorealistic outdoor background image (Unsplash), same auth logic
- `Login.tsx` — darker background, same auth logic

Both call `supabase.auth.signInWithPassword()`, fetch the user role, and navigate to the correct dashboard. They diverged visually but are functionally identical. Maintaining two login flows doubles the surface area for auth bugs.

Jessica's `LoginPage.tsx` is a clean, parameterised component (`portalName`, `dashboardPath`, `accentText`, `requireAuth` props) that handles both real auth and demo bypass — a better pattern.

## Options Considered

1. **Keep both** — no effort, growing divergence risk.

2. **Delete Login.tsx, keep Landing.tsx** — reduces duplication but Landing still has the same logical issues as the current LoginPage.

3. **Replace both with a single component modelled on jessica's `LoginPage.tsx`** — move `LoginPage.tsx` to `packages/shared` or replicate the parameterised pattern in portal. Route `/` and `/login` both render the same component with different visual props.

## Decision

Use **option 3** when the supplier portal gets its first real user. Until then, both pages are functional enough for internal use.

Priority: LOW — only two people use the portal, the UX difference is cosmetic.

## Consequences

- `Landing.tsx` and `Login.tsx` remain as tech debt until resolved
- Any auth logic changes must be applied to BOTH files until consolidation
- When implementing, consider moving `LoginPage.tsx` to `packages/shared` so both apps use the same component
