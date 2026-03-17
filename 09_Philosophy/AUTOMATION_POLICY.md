---
title: Automation Policy — Global Distribution AS
created: 2026-03-17
owner: Daniel
review_trigger: When we reach 10 orders per week, revisit every classification in this document.
---

# Automation Policy

> This document is the permanent reference for what we automate, what we semi-automate,
> and what we deliberately keep manual — and why.
>
> **Read this before building any new automation.**
> If a process is not classified here, classify it first using the framework below.

---

## The Decision Framework

Apply this filter to every process you find.

### KEEP MANUAL if any of these are true

- Requires relationship judgment (how to respond to a specific buyer or supplier)
- Requires cultural nuance — especially China-facing communication
- Happens less than once per week
- We have not done it enough times to know the full edge case space
- A mistake here damages a relationship or costs significant money
- The process is still evolving and will change in the next 90 days

### MAKE SEMI-AUTOMATIC if all of these are true

- Has a clear repeatable structure but variable content
- A human reviews the output before anything is sent or committed
- A mistake is recoverable within 24 hours
- Saves more than 15 minutes per occurrence

Examples: quote generation (portal drafts, Jessica approves), supplier onboarding email (template auto-filled, Martin sends manually).

### MAKE FULLY AUTOMATIC if all of these are true

- Zero judgment required — purely mechanical
- A mistake is immediately detectable and easily reversed
- Happens more than 3 times per week
- Has been done manually enough times to know every edge case

Examples: file routing to correct Obsidian folder, daily status report, git sync, quote expiration.

---

## Process Classification — Complete List

### FULLY AUTOMATIC

| Process | Mechanism | Frequency | Time saved/week |
|---------|-----------|-----------|----------------|
| Vault git sync | `sync-all.sh` via launchd (every 10 min) | Continuous | ~30 min |
| File auto-routing from inbox | `auto-route.sh` via launchd (every 5 min) | Per file | ~20 min |
| Daily operations report | `daily-report.sh` at 07:30 | Daily | ~1 hr |
| Follow-up tracker email | `follow-up-tracker.sh` at 07:45 | Daily | ~45 min |
| Monthly platform report | `monthly-report.sh` on 1st of month | Monthly | ~30 min |
| Buyer inquiry confirmation email | `inquiry-confirmation` edge function | Per inquiry | ~5 min |
| Internal inquiry alert to Jessica | `inquiry-confirmation` edge function | Per inquiry | ~10 min |
| WeChat inquiry alert to Martin | `inquiry-confirmation` edge function | Per WeChat inquiry | ~5 min |
| Quote expiration (sent → expired) | `daily-report.sh` → `expire_stale_quotes()` RPC | Daily | ~10 min |
| Pending product count in daily report | `daily-report.sh` query | Daily | ~5 min |
| Supplier intake pipeline | `auto-route.sh` + `supplier-onboard.sh` | Per intake file | ~30 min |
| Error logging to vault | `daily-report.sh` error trap | Per error | ~5 min |

### SEMI-AUTOMATIC

| Process | Tool | Human action | What to verify before proceeding |
|---------|------|-------------|----------------------------------|
| Buyer first reply | `_Templates/buyer-inquiry-reply.md` | Jessica fills, reviews, sends | Checklist at bottom of template |
| Supplier welcome email | `_Templates/leverandor-velkomst-epost.md` | Martin fills, sends | Name, portal URL, tone correct |
| Order confirmation to supplier | `_Templates/ordrebekreftelse-leverandor.md` | Martin fills, sends | Buyer confirmed in writing; deposit received or waived |
| Proforma invoice to buyer | `_Templates/proforma-invoice.md` | Martin fills, Daniel approves if >50K NOK, sends | Internal checklist at bottom of template |
| Quote generation | Portal: `gdist.no/admin/quotes/new` | Jessica/admin sets margin, exports | Margin correct; supplier cost confirmed |
| Quote export to Obsidian | `export-quotes-to-obsidian.sh` | Run after finalization | Quote number assigned; file appears in `04_Orders/` |
| New supplier user creation | `SOPs/2026-03-16_sop_opprett-leverandor-bruker.md` | Daniel does 5 steps in Supabase | UUID copied; role set; profile created; Martin confirmed |
| NDA for new supplier | `_Templates/nda-supplier.md` | Daniel gets lawyer approval, sends | Lawyer has reviewed and approved the specific version |
| Supplier evaluation | Daniel reviews, documents decision | Daniel decides go/no-go | Decision logged in supplier note with reasons |

### MANUAL — never automate

| Process | Owner | Why it must stay manual |
|---------|-------|------------------------|
| Buyer inquiry qualification | Jessica | Requires cultural reading of the buyer — country, company type, language register, intent signals. A wrong qualification wastes everyone's time or kills a real opportunity. We have not run enough inquiries to know the pattern. |
| Quote pricing | Jessica + Daniel | Financial judgment. Supplier cost is only part of it — market conditions, buyer relationship, competitor awareness, and risk tolerance all factor in. Automating this would output a correct calculation but a wrong business decision. |
| Supplier evaluation and approval | Daniel | Long-term strategic decision. A bad supplier costs months of fixing, not hours. |
| NDA and legal review | Daniel + lawyer | One wrong clause creates legal exposure. Non-negotiable. |
| Order approval > 50,000 NOK | Daniel | Business rule. Not a technical limitation. Financial threshold is deliberate. |
| Payment escalation day 10+ | Daniel | Relationship at stake. Wrong tone = lost buyer. The SOP handles days 1–9; day 10+ is judgment. |
| Delivery delay communication to buyer | Jessica | Cultural nuance. Chinese and Korean buyers interpret delay communication differently. Timing, framing, and channel choice must be human-decided. |
| Supplier relationship management | Martin | Trust-based. Frequency and tone must match the individual supplier. |
| Buyer cancellation negotiation | Daniel | Financial and legal exposure. May involve cancellation fees. |
| Product approval (pending → active) | Daniel/admin | Quality gate. Wrong products live = brand and trust damage. |
| Feature development | Daniel | Technical and architectural judgment. |
| Strategic supplier selection | Daniel | Market and capacity planning. |

---

## What "semi-automatic" means in practice

Every semi-automatic template has a **human review checklist** at the bottom.
The rule is: **delete the checklist before sending, but only after checking every box.**

A semi-automatic process where the human stops reading the checklist is now a fully automatic process with a human rubber-stamp — which is worse than either alternative.

If the checklist items are consistently all-green, the process may be ready for full automation.
Document that observation and revisit at the next review.

---

## Review trigger

**Revisit this entire document when we reach 10 orders per week.**

At that volume:
- Some manual processes will have enough repetition to classify their edge cases
- Some semi-automatic processes will have consistent enough outputs to automate
- Some fully automatic processes may need human oversight added back

Do not automate ahead of this trigger — we do not yet know the edge cases.

---

## What to do when a new process is identified

1. Name the process
2. Apply the decision framework above
3. Classify it in this document
4. If semi-automatic: create or improve the template, add a review checklist
5. If fully automatic: build it, document it in `09_Tech/AUTOMATION_MAP.md`
6. If manual: add a note in `06_Operations/SOPs/` explaining WHY it is manual, and add a "Never automate [X] because [Y]" line to `CLAUDE.md`

---

## History

| Date | Change | Reason |
|------|--------|--------|
| 2026-03-17 | Initial version — all processes classified | Full process audit, COO/systems design review |
| 2026-03-17 | Added: inquiry alert to Jessica, WeChat alert to Martin | Gap: inquiries arrived with no internal notification |
| 2026-03-17 | Added: quote expiration via RPC | Gap: stale 'sent' quotes never transitioned to 'expired' |
| 2026-03-17 | Added: pending product count in daily report | Gap: supplier uploads sat in pending without admin knowing |
