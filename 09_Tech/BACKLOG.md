# Daniel's Tech Backlog — Prioritized by Business Impact
_Updated: 2026-03-16. Maintained by Daniel. Reviewed weekly._

> **Rule:** P0 items block Martin and Jessica from operating. Fix these before any other feature work.

---

## 🔴 P0 — Business Blocked Without These

### P0-1: Order Creation UI
**Who is blocked:** Martin, every single order
**The problem:** `AdminOrders` is a stub. There is no form to create an order in the portal. Every confirmed order currently exists only in Obsidian — there is zero system-of-record for orders, payments, or fulfillment status.
**Workaround:** Martin tracks orders manually in `04_Orders/` Obsidian notes. This breaks entirely at more than 3 concurrent orders.
**What to build:** A form in AdminOrders: buyer, product(s), quantity, price, deposit %, payment terms, order date. Creates a row in the `orders` table.
**Estimated effort:** 8 hours
**Impact if unbuilt:** Martin cannot run more than 3 orders simultaneously without losing track.

---

### P0-2: Supplier User Account Creation
**Who is blocked:** Martin (every new supplier), Daniel (must do it manually)
**The problem:** `AdminSettings` invite form is broken — it inserts `{email, role}` into `user_roles` which has no email column. Creating a supplier requires Daniel to manually:
  1. Go to Supabase dashboard → Authentication → Invite user
  2. Copy the resulting UUID
  3. Insert into `user_roles`: `{user_id: UUID, role: 'supplier'}`
  4. Insert into `suppliers`: `{name, email, user_id: UUID, ...}`
**Workaround:** See `06_Operations/SOPs/2026-03-16_sop_opprett-leverandor-bruker.md`
**What to build:** Fix AdminSettings invite: call Supabase Auth Admin API (`admin.inviteUserByEmail`), then insert `user_roles` row with returned UUID. See ADR: `09_Tech/ADR/2026-03-16_admin-invite-flow.md`
**Estimated effort:** 4 hours
**Impact if unbuilt:** Every new supplier requires Daniel. Unacceptable at scale.

---

## 🟠 P1 — Daily Pain, Has Workaround

### P1-1: New Inquiry Email Notification
**Who is blocked:** Martin, Jessica
**The problem:** When a buyer submits an inquiry on jessicabrands.com, nobody is notified. Martin and Jessica only see it if they manually log into the admin portal and look. This means inquiries can sit unread for days.
**Workaround:** Martin checks admin portal every morning as part of his routine.
**What to build:** Supabase database webhook or Edge Function on `inquiries` INSERT → send email via Resend to martin@ and jessica@
**Estimated effort:** 2 hours
**Impact if unbuilt:** 24-hour response SLA is impossible to maintain reliably.

---

### P1-2: Exchange Rates in Settings Table
**Who is blocked:** Martin, Jessica (wrong prices on every quote and supplier upload)
**The problem:** `NOK_USD_RATE = 0.088` is hardcoded in `quoteEngine.ts`. `NOK_TO_CNY = 0.65` is hardcoded in `SupplierUpload.tsx`. These rates are baked into the JS bundle and cannot change without a code deploy.
**Current risk:** Every quote and CNY price estimate may be wrong. At 0.088 NOK/USD (as of 2026-03-16), being off by 5% on a $10,000 order means $500 of margin error.
**What to build:** Migration to add `settings` table. Admin form in AdminSettings to update rates. `quoteEngine.ts` accepts rate as parameter. See ADR: `09_Tech/ADR/2026-03-16_exchange-rates.md`
**Estimated effort:** 3 hours
**Impact if unbuilt:** Martin will quote wrong prices whenever the NOK rate moves.

---

### P1-3: Proforma Invoice Generator
**Who is blocked:** Martin, every confirmed order
**The problem:** After a buyer confirms an order, Martin must issue a proforma invoice so the buyer can wire the 30% deposit. There is no invoice generation in the portal. Martin currently does this manually (email or Word doc).
**Workaround:** Use the template at `_Templates/proforma-invoice.md`. Fill in manually, send as PDF.
**What to build:** A "Generate Proforma" button on the order detail page. Renders to a printable layout. Stores a record in the `invoices` table.
**Estimated effort:** 8 hours

---

## 🟡 P2 — Painful, Clear Workaround Exists

### P2-1: Payment Tracking UI
**The problem:** No way to record that a deposit was received in the portal. Martin logs to `05_Finance/transactions.csv` manually.
**Estimated effort:** 6 hours

### P2-2: Inventory Stage Management
**The problem:** AdminInventory has a Kanban board (At Supplier → Warehouse → In Transit → With Jessica) but there is no way to add items to it. The board is always empty.
**Estimated effort:** 4 hours

### P2-3: Supplier Profile Save
**The problem:** SupplierProfile has input fields for company name, payment terms, bank details — but the Save button does nothing. Suppliers cannot enter their own details.
**Estimated effort:** 2 hours

### P2-4: Buyer Quote Viewing
**The problem:** `BuyerQuotes` in the buyer portal is a stub. Buyers cannot see their quotes online. All quotes are sent via email or WeChat.
**Estimated effort:** 6 hours

---

## 🟢 P3 — Nice to Have

### P3-1: React Query Adoption
Start with `ProtectedRoute` caching (eliminates DB round-trip on every nav). See ADR: `09_Tech/ADR/2026-03-16_react-query-adoption.md`
**Estimated effort:** 8 hours

### P3-2: Buyer Catalogue
`BuyerCatalogue` is a stub. Buyers cannot browse products in the portal.
**Estimated effort:** 4 hours

### P3-3: Login Page Consolidation
`Landing.tsx` and `Login.tsx` are near-identical. Low urgency.
**Estimated effort:** 2 hours

---

---

## ⚡ INFRA — Mac Mini / Automation (from CFO review 2026-03-16)

> These are not product features. They are operational hygiene items. Fix before launch.

### INFRA-1: Supabase pause mitigation ⚠️ KRITISK — 10 min
**Risk:** Free Supabase pauses after 7 days without DB activity. Platform goes down silently.
**Fix:** Add to crontab (Daniels Mac inntil Mac mini er operasjonell):
```
0 9 * * * curl -sf "https://orsjlztclkiqntxznnyo.supabase.co/rest/v1/profiles?select=id&limit=1" \
  -H "apikey: $(grep SUPABASE_ANON_KEY ~/.claude-env | cut -d= -f2)" > /dev/null
```

### INFRA-2: Fill in config.env placeholders ⚠️ KRITISK — 10 min
**Risk:** ALL Mac mini scripts are non-functional. `sync-finance.sh`, `follow-up-tracker.sh`, `monthly-analysis.sh`, `onboard-supplier.sh` all fail silently.
**Fix:** In `~/Documents/GlobalDistribution/scripts/config.env`, replace all `FYLL_INN` values:
- `SUPABASE_SERVICE_ROLE` — get from Supabase → Settings → API → service_role key
- `RESEND_API_KEY` — get from resend.com → API Keys
- `ANTHROPIC_API_KEY` — get from console.anthropic.com
- `EMAIL_JESSICA`, `EMAIL_MARTIN`, `EMAIL_DANIEL` — actual email addresses

### INFRA-3: Register launchd plists for new scripts — 30 min
**What:** `sync-finance.sh` (hourly) and `follow-up-tracker.sh` (07:45 daily) need launchd plists and `launchctl load`.
**Template:** Copy `launchd/com.gdist.daily-report.plist`, change Label + ProgramArguments + StartCalendarInterval.

### INFRA-4: chmod +x all scripts — 2 min
```zsh
chmod +x ~/Documents/GlobalDistribution/scripts/*.sh
```

### INFRA-5: Null product prices block all quotes — HØY — 2h
**Risk:** Jessica cannot quote if `products.price_nok` is NULL. Quote engine returns 0 or crashes.
**Fix:** Martin goes through each supplier's products in AdminPortal and sets price_nok. Add a validation in `quoteEngine.ts` that rejects products with null prices and surfaces a clear error.

### INFRA-6: Missing `quotes.exported_to_obsidian` column — HØY — 15 min
**Risk:** `follow-up-tracker.sh` queries `quotes` table. If schema differs from expected, queries fail.
**Fix:** Run migration:
```sql
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS exported_to_obsidian boolean DEFAULT false;
```

### INFRA-7: Two vaults consolidation — MEDIUM — 30 min
**Problem:** `~/Documents/Obsidian/Global Distribution/` exists with only empty folders. Active vault is `~/Documents/GlobalDistribution/`. Produktanalyse Template was saved to the wrong vault.
**Fix:** Delete `~/Documents/Obsidian/Global Distribution/`, move Produktanalyse Template to `~/Documents/GlobalDistribution/00_INBOX/`.

### INFRA-8: Hardcoded exchange rate in sync-finance.sh — LAV — 1h
**Problem:** `sync-finance.sh` uses `usd * 11.0` as NOK conversion. This is baked in and will drift.
**Fix:** After INFRA-2 is done and settings table exists (P1-2), fetch rate from Supabase `settings` table instead of hardcoding.

---

## Fixed Items (do not re-open)
- [x] SupplierProducts bug — wrong `supplier_id` filter (fixed 2026-03-16)
- [x] navItems duplication — admin and supplier nav now exported from dashboard (fixed 2026-03-16)
- [x] Quote number race condition documented in ADR (fix: SEQUENCE migration, ~1 hour)
