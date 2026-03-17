# ADR: Admin Invite Flow

**Date:** 2026-03-16
**Status:** Open — not yet implemented

## Context

`AdminSettings.tsx` has an invite form that inserts `{ email, role }` into the `user_roles` table. This silently fails because `user_roles` has a `user_id` (UUID) column, not an `email` column. A real Supabase user must exist before they can be assigned a role.

The admin user invitation flow is a security-critical operation — it controls who can access the portal.

## Options Considered

1. **Add an `email` column to `user_roles`** — stores email as a pending invite. Requires a background job or webhook to match the email to a `user_id` once the user signs up. Complex, fragile.

2. **Use Supabase Auth Admin API (`supabase.auth.admin.inviteUserByEmail()`)** — sends a magic-link invite email, creates the user in `auth.users`, then a trigger or Edge Function inserts the `user_id` + `role` into `user_roles`. This is the correct Supabase pattern.

3. **Manual flow** — admin creates user directly in Supabase dashboard, then assigns role. No code needed. Works for early operations.

## Decision

Use **option 3 (manual)** for early operations while we have fewer than 10 users. Implement **option 2** (Auth Admin API + Edge Function) when the team grows or when self-service onboarding is needed.

The invite button in `AdminSettings.tsx` should be disabled or removed until option 2 is implemented.

## Consequences

- No automated invite flow until Edge Function is built
- Admin must create users manually in Supabase dashboard
- `AdminSettings.tsx` invite form is currently broken — do not rely on it
- Edge Function needed: `invite-team-member` → calls `admin.inviteUserByEmail()` + inserts role
