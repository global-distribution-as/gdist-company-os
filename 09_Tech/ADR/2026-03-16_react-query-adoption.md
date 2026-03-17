# ADR: React Query — Adopt or Remove

**Date:** 2026-03-16
**Status:** Open — decision required

## Context

`@tanstack/react-query` is installed in both `apps/portal` and `apps/jessica` but used in neither. It adds ~43 kB to the bundle and wraps the entire app in `QueryClientProvider` (or does nothing if it was never wired up).

All data fetching is done with raw `useEffect` + `useState` + `supabase.*` calls. This works, but has well-known problems:
- No request deduplication (same query on two components = two round trips)
- No background refetch / stale-while-revalidate
- Manual loading/error state in every component
- `ProtectedRoute.tsx` queries `user_roles` on every route change with no caching

## Options Considered

1. **Remove React Query** — uninstall from both apps, delete `QueryClientProvider` wrappers. Keeps the codebase simpler. Manual fetch patterns stay as-is.

2. **Adopt React Query** — wrap Supabase calls in `useQuery` hooks. Immediate wins: caching eliminates the `ProtectedRoute` round-trip, deduplicates the product list queries, provides automatic background refresh.

3. **Use Supabase realtime instead** — replace polling with Supabase channel subscriptions. Orthogonal to React Query.

## Decision

**Adopt React Query** (option 2) — but do it properly, not as a half-measure. The `ProtectedRoute` round-trip is the most painful current issue; start there.

Implementation order:
1. Wire `QueryClientProvider` in both `main.tsx` files
2. Extract `useUserRole()` into a `useQuery` call with a 5-minute stale time
3. Migrate `SupplierProducts`, `AdminDashboard`, `AdminProducts` to `useQuery`
4. Migrate remaining pages as they get their live data implementations

Do not remove React Query — it was installed for a reason and the use case is real.

## Consequences

- `ProtectedRoute` DB round-trip eliminated for 5 minutes after first load
- `useUserRole.ts` becomes a thin wrapper around `useQuery`
- Gradual migration — existing `useEffect` patterns can coexist with `useQuery` during transition
- Bundle size unchanged (already installed)
