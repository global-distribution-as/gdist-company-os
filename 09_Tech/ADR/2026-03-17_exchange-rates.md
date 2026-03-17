# ADR: Move exchange rates to settings table

**Date:** 2026-03-17
**Status:** Decided
**Priority:** 🔴 High — execute before first real quote

---

## Context

`quoteEngine.ts` has `NOK_USD_RATE = 0.088` hardcoded at line 26.
`SupplierUpload.tsx` has `NOK_TO_CNY = 0.65` hardcoded at line 8.

The NOK/USD rate has moved from 0.088 to as low as 0.082 and as high as 0.097 in the past 12 months. A 10% rate difference on a 100-unit jacket order at NOK 2,000 each = USD 1,760 → USD 1,940. That's a USD 180 margin error per order baked silently into every quote until the next code deploy.

The `settings` table was created in migration `20260317000002_schema_alignment.sql` and is seeded with initial values.

---

## Options considered

**A. Environment variable (`VITE_NOK_USD_RATE`)**
Pro: Simple. Con: Requires Vercel redeploy to change. Same problem as hardcoded.

**B. Settings table in Supabase (chosen)**
Pro: Admin can update via UI without deploy. Authenticated users can read. Audit trail via `updated_by`. Con: One extra DB call on QuoteGenerator load.

**C. External FX API (e.g. Frankfurter.app, free)**
Pro: Always current. Con: External dependency, rate precision overkill for quoting purposes, needs caching.

---

## Decision

Use the `settings` table. Fetch on QuoteGenerator mount. Fall back to `NOK_USD_RATE` constant if the fetch fails.

---

## Implementation steps

1. **QuoteGenerator.tsx**: On mount, fetch `settings` where key in `('nok_usd_rate', 'nok_cny_rate')`. Store in component state. Pass rate to `nokToUsd()` / `applyMargin()` explicitly.

2. **AdminSettings.tsx**: Add a "Business Settings" section showing current rates. Allow admin to update them (`supabase.from('settings').upsert({ key, value, updated_by })`).

3. **SupplierUpload.tsx**: Fetch `nok_cny_rate` from settings on mount. Use it for the live CNY preview instead of the hardcoded constant.

4. **quoteEngine.ts**: The `NOK_USD_RATE` constant becomes a fallback only (already labeled as such after 2026-03-17 fix).

---

## Consequences

- Rate changes take effect immediately for all new quotes with zero deploys
- Admin is responsible for keeping rates current (suggested: update when spot rate moves >2%)
- Old quotes stored in `quotes.nok_usd_rate` column already capture the rate used — no historical data loss
