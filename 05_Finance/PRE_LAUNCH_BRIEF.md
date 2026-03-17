---
type: brief
updated: 2026-03-16
author: CFO review (automated)
---

# Pre-Launch Financial Brief — Global Distribution AS

_One page. For Daniel only. Review before first buyer goes live._

---

## Current Burn Rate

**Cash cost today: ~9 NOK/month**

| Item | Cost |
|------|------|
| Domene gdist.no | ~8 NOK/mnd |
| Vercel Hobby | kr 0 |
| Supabase Free | kr 0 |
| Resend Free | kr 0 |
| GitHub Free | kr 0 |
| Anthropic API (idle) | ~kr 1 |
| **Total** | **~kr 9/mnd** |

This is not a burn rate. It is a rounding error. The company costs less per month than a cup of coffee.

---

## Projected Cost at Launch

**Cash cost at launch: ~509 NOK/month**

The only real cost that activates at launch is **Tripletex** (~500 NOK/mnd), required once we have a Norwegian bank account and need to file MVA. Everything else stays on free tier through the first 10–15 active suppliers.

| Milestone | Monthly cash cost |
|-----------|-------------------|
| Today (pre-launch) | ~kr 9 |
| Launch (day 1, with Tripletex) | ~kr 509 |
| 10 suppliers, 40 orders/mnd | ~kr 760 |
| 50 suppliers (Supabase storage limit) | ~kr 1 000 |
| 100+ suppliers | ~kr 1 750 |

**Conclusion:** The cost structure is exceptional. We can operate for 12 months at launch-level costs for less than kr 6 100 total in software.

---

## Hidden Time Costs (the real numbers)

| Task | Person | Cost/mnd |
|------|--------|----------|
| Inquiry → quote (55 min × 40/mnd) | Jessica | kr 12 833 |
| Code deploys (90 min × 8/mnd) | Daniel | kr 18 000 |
| Product approval (10 min × 20/mnd) | Daniel | kr 5 000 |
| Transaction logging (14 min × 40/mnd) | Martin | kr 3 733 |
| Supplier onboarding | Martin | kr 3 067 |
| Finance reconciliation | Martin | kr 1 467 |
| **Total hidden time cost** | | **~kr 44 100/mnd** |

**The hidden costs are 4 900× the cash costs.** Every hour saved on operations is worth 1 500 NOK if it frees Daniel, 400 NOK if it frees Martin.

The two automations built 2026-03-16 (`sync-finance.sh` + `follow-up-tracker.sh`) eliminate ~kr 5 200/mnd in time costs once `config.env` is filled in.

---

## Three Financial Risks in the First 90 Days

### Risk 1 — Supabase database pause (KRITISK, unmitigated)
**What:** Free Supabase pauses after 7 days of zero activity. The platform goes down with no warning.
**When it hits:** The first time we go a week without a DB write (e.g., between launch prep and first real order).
**Financial impact:** Full platform outage. Every buyer, supplier, and order inaccessible. First impression destroyed.
**Fix:** Add a daily keepalive curl to crontab. Takes 10 minutes. See BACKLOG INFRA-1.
**Status:** ⚠️ Unmitigated. Fix today.

### Risk 2 — config.env placeholders disable all automation (KRITISK, unmitigated)
**What:** All four Mac mini scripts (`sync-finance.sh`, `follow-up-tracker.sh`, `monthly-analysis.sh`, `onboard-supplier.sh`) call Supabase and Resend using placeholder API keys (`FYLL_INN`). They silently fail or are skipped.
**When it hits:** Day one of operations. Martin will get no follow-up emails. Finances won't sync. No onboarding emails go out.
**Financial impact:** The 16 000 NOK/mnd in automation savings disappears. Martin and Jessica go back to fully manual operations.
**Fix:** Fill in 5 values in `config.env`. Takes 10 minutes. See BACKLOG INFRA-2.
**Status:** ⚠️ Unmitigated. Fix today.

### Risk 3 — Null product prices block quote generation (HØY, unmitigated)
**What:** If `products.price_nok` is NULL for any product, `quoteEngine.ts` cannot generate a price. Jessica cannot send a quote. The buyer goes elsewhere.
**When it hits:** First time Jessica tries to quote a product Martin hasn't priced yet.
**Financial impact:** ØP4 — quote speed is revenue speed. A blocked quote is a lost order. At 10 inquiries/week, even a 20% conversion loss is significant margin.
**Fix (short term):** Martin sets prices on all existing products before launch.
**Fix (long term):** Add validation that rejects quote if any line item has null price. Surface clear error to Jessica. See BACKLOG INFRA-5.
**Status:** ⚠️ Unmitigated.

---

## 90-Day Financial Targets

| Target | Metric | How to measure |
|--------|--------|----------------|
| Breakeven on Tripletex | 1 confirmed order at ~kr 500 margin | `transactions.csv` Inntekt > Utgift |
| Automation ROI positive | `sync-finance.sh` + `follow-up-tracker.sh` running daily | Check log `/tmp/gdist-*.log` |
| Quote response time ≤ 48h | All stale_quotes = 0 in follow-up report | `00_Dashboard/YYYY-MM-DD_oppfølging.md` |
| Zero Supabase pauses | DB active every day | Supabase dashboard → Usage |

---

## One Decision Before Launch

**Tripletex — activate before or after first order?**

Activate before. Getting the bank account and accounting system live before the first invoice means no retroactive cleanup. Cost: ~500 NOK/mnd. Risk of not doing it: VAT filing errors on the first transaction.

---

_→ For cost projections: [[05_Finance/COST_MAP]]_
_→ For time costs: [[05_Finance/TIME_COST_MAP]]_
_→ For technical fixes: [[09_Tech/BACKLOG]]_
