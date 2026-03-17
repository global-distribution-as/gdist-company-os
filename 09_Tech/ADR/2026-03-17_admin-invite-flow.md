# ADR: Admin invite flow via Supabase Auth Admin API

**Date:** 2026-03-17
**Status:** Decided
**Priority:** 🟡 Medium — execute before first team member is added

---

## Context

`AdminSettings.tsx` collected an email + role and inserted `{ email, role }` into `user_roles`.
`user_roles` has no `email` column — it requires `user_id` (UUID, FK to profiles).
This insert always failed silently. The invite button showed success but did nothing.

After the 2026-03-17 fix, the form now inserts into `pending_invites` table, which records the intent. But a pending invite does not actually create an account or send an email.

---

## The real problem

Creating a Supabase Auth user requires either:
- The user self-signs-up (not appropriate for internal team invites)
- The Supabase Auth Admin API (`supabase.auth.admin.inviteUserByEmail()`) called with the **service role key**

The service role key must NEVER be in frontend code. It must live in a server-side context: a Supabase Edge Function or a server action.

---

## Options considered

**A. Supabase Edge Function `invite-user`**
- Edge function receives email + role from admin UI
- Calls `supabase.auth.admin.inviteUserByEmail(email)` using service role
- On success, inserts into `pending_invites.used_at = now()`
- Supabase sends the invite email automatically
- Pro: Clean, uses Supabase-native invite flow. Con: requires SUPABASE_SERVICE_ROLE_KEY in edge function secrets.

**B. Manual invite via Supabase dashboard**
- Admin goes to Authentication → Users → Invite User
- Then manually assigns role via SQL or Supabase table editor
- Pro: Zero code. Con: Manual, not scalable, error-prone.

**C. Magic link self-signup with role assignment**
- Create a signup link that pre-assigns role after auth
- Pro: No service role needed. Con: Anyone with the link can sign up.

---

## Decision

**Phase 1 (now):** Manual via Supabase dashboard. Good enough for 1-3 team members at launch.

**Phase 2 (before 5th team member):** Edge function `invite-user`.
```
supabase/functions/invite-user/index.ts
  → receive { email, role } from admin UI (authenticated admin only)
  → call supabase.auth.admin.inviteUserByEmail(email)
  → insert into user_roles { user_id: newUser.id, role }
  → mark pending_invites.used_at
```

---

## Consequences

- `pending_invites` table serves as an audit log of invite attempts
- AdminSettings now correctly saves the intent without breaking the DB
- Phase 2 edge function will complete the full invite-to-active flow
