# ADR: Exchange Rate Management

**Date:** 2026-03-16
**Status:** Open — not yet implemented

## Context

Two hardcoded exchange rates exist in the frontend source code:

- `NOK_USD_RATE = 0.088` in `apps/portal/src/lib/quoteEngine.ts`
- `NOK_TO_CNY = 0.65` in `apps/portal/src/pages/supplier/SupplierUpload.tsx`

These rates are baked into the JS bundle at build time. When the NOK rate moves (as it does daily), every quote and every CNY price estimate in the supplier upload form is wrong until someone redeploys.

For a company where margin is the business model, stale rates are a direct financial risk.

## Options Considered

1. **Keep hardcoded** — simplest, requires redeployment to update. Acceptable only if rates are checked weekly and redeployment is fast.

2. **Admin-editable `settings` table row** — add a `settings` table with `nok_usd_rate` and `nok_cny_rate` columns. QuoteGenerator fetches the rate on open. SupplierUpload fetches on mount. Admin can update via a form in AdminSettings.

3. **Automatic rate fetching from a free FX API** — scheduled Supabase Edge Function fetches rates from e.g. frankfurter.app and writes to `settings` table. Fully automated.

## Decision

Implement **option 2** (admin-editable settings table) as the immediate fix. Add a `settings` table with `key` / `value` columns and a UI field in AdminSettings. This eliminates stale rates without introducing external API dependency.

Upgrade to **option 3** (automated) when trading volume justifies it.

## Consequences

- `quoteEngine.ts` must accept rate as a parameter instead of using the module-level constant
- `SupplierUpload.tsx` must fetch rate on mount (adds one DB read)
- AdminSettings needs a "Rates" section — two number inputs, save button
- Migration required: `CREATE TABLE settings (key text PRIMARY KEY, value text NOT NULL)`
- Initial seed: `INSERT INTO settings VALUES ('nok_usd_rate', '0.088'), ('nok_cny_rate', '0.65')`
