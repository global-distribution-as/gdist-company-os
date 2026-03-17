# Automation Map — Global Distribution AS

> Oppdatert: 2026-03-17
> Oversikt over alle automatiserte prosesser, triggere, output og status.
> **For klassifisering og beslutningsrammeverk: se `09_Philosophy/AUTOMATION_POLICY.md`**

---

## Kjørende automatiseringer

| Prosess | Trigger | Script | Output | Status | Timer spart/mnd |
|---------|---------|--------|--------|--------|-----------------|
| **Daglig rapport** | Kl 07:30 daglig (launchd) | `daily-report.sh` | E-post til Daniel + Martin, `08_Daily/YYYY-MM-DD_rapport_daglig.md` | ✅ Aktiv | ~1t |
| **Vault-sync** | Kl 08:00 daglig (launchd) | `sync-all.sh` | Git push til GitHub | ✅ Aktiv | ~30 min |
| **Auto-routing** | Ved filendring i `00_INBOX/` (launchd) | `auto-route.sh` | Fil flyttet til riktig mappe + desktop-notifikasjon | ✅ Aktiv | ~20 min |
| **Månedlig analyse** | 1. i måneden kl 08:15 (launchd) | `monthly-analysis.sh` | Rapport via Anthropic API, lagret i vault | ✅ Aktiv | ~2t |
| **Ukentlig mønsteranalyse** | Mandag kl 08:45 (launchd) | `weekly-analysis.sh` | `08_Daily/YYYY-MM_weekly_patterns.md` | ✅ Aktiv | ~45 min |
| **Månedlig plattformrapport** | 1. i måneden kl 08:30 (launchd) | `monthly-report.sh` | `08_Daily/YYYY-MM_platform_report.md` | ✅ Aktiv | ~30 min |
| **Tilbudseksport** | Manuelt (on demand) | `export-quotes-to-obsidian.sh` | `.md`-filer i `04_Orders/Quotes/` | ✅ Aktiv | ~15 min |
| **Leverandør-onboarding** | Manuelt | `supplier_onboard.py` | Supabase-oppføring + velkomst-e-post | ✅ Aktiv | ~30 min |

---

## Portal-automatiseringer (Supabase Edge Functions)

| Prosess | Trigger | Function | Output | Status |
|---------|---------|----------|--------|--------|
| **Inquiry-bekreftelse til buyer** | Ny inquiry i portal | `inquiry-confirmation/index.ts` | Bekreftelses-e-post til buyer (ikke WeChat) | ✅ Aktiv |
| **Intern varsling til Jessica** | Ny inquiry i portal (alle typer) | `inquiry-confirmation/index.ts` | Alert-e-post til jessica@gdist.no med buyer-detaljer | ✅ Lagt til 2026-03-17 |
| **WeChat-varsling til Martin** | Ny inquiry med WeChat-kontakt | `inquiry-confirmation/index.ts` | Alert-e-post til martin@gdist.no (WeChat-kontakt = ingen auto-bekreftelse til buyer) | ✅ Lagt til 2026-03-17 |

---

## Claude Code-automatiseringer (hooks)

| Hook | Trigger | Script | Hensikt |
|------|---------|--------|---------|
| PreToolUse (Bash) | Før hvert bash-kall | `pre-commit-env-check.sh` | Blokkerer commit av hemmeligheter |
| PreToolUse (Bash) | Før hvert bash-kall | `pre-bash-drop-delete.sh` | Blokkerer DROP/DELETE SQL |
| PostToolUse (Bash) | Etter `vercel --prod` | `post-deploy-ping.sh` | Pinger gdist.no + jessicabrands.com |
| PostToolUse (Write/Edit) | Etter SQL-fil lagret | `post-edit-migration-log.sh` | Logger migrasjoner til `09_Tech/migration-log.md` |
| PostToolUse (Write/Edit) | Etter edit i `apps/jessica` | `post-edit-buyer-warning.sh` | Advarer om kjøperportal-endringer |
| Stop | Sesjonsslutt | `stop-session-review.sh` | Ber Claude ekstrahere regler til CLAUDE.md |

---

## Resiliens

| Script | Error log | Heartbeat-fil | Sjekket av |
|--------|-----------|---------------|------------|
| `daily-report.sh` | `09_Tech/error-log.md` | `/tmp/gdist-daily-report.heartbeat` | — |
| `weekly-analysis.sh` | `09_Tech/error-log.md` | `/tmp/gdist-weekly-analysis.heartbeat` | `daily-report.sh` |
| `monthly-report.sh` | `09_Tech/error-log.md` | `/tmp/gdist-monthly-report.heartbeat` | `daily-report.sh` |
| `vault-sync.sh` | — | `/tmp/gdist-vault-sync.heartbeat` | `daily-report.sh` |
| `monthly-analysis.sh` | — | `/tmp/gdist-monthly-analysis.heartbeat` | `daily-report.sh` |

---

## Databaser og views for selvforbedring

| Objekt | Type | Hensikt |
|--------|------|---------|
| `events` | Tabell | Logger plattformhendelser (inquiry, order, error, onboard) |
| `monthly_patterns` | View | Aggregerer events per måned for trendsanalyse |

---

## Totalt estimert tid spart per måned

| Kategori | Timer/mnd |
|----------|-----------|
| Rapportering og e-post | ~1,5t |
| Vault-organisering | ~1t |
| Mønsteranalyse (ville vært manuelt) | ~3t |
| Git-synkronisering | ~30 min |
| **Totalt** | **~6 timer/mnd** |

---

## Nye automatiseringer lagt til 2026-03-17

| Prosess | Mekanisme | Hva det løser |
|---------|-----------|---------------|
| **Quote expiration** | `daily-report.sh` → Supabase RPC `expire_stale_quotes()` | Tilbud med `valid_until < today` og status=sent → status=expired automatisk. Antall vises i dagsrapporten. |
| **Produkter til godkjenning i dagsrapport** | `daily-report.sh` → query `products?status=eq.pending` | Daniel ser daglig i rapporten at leverandøropplastinger venter — ingen produkter glemmes i pending-limbo. |
| **Intern inquiry-varsling** | `inquiry-confirmation` edge function utvidet | Jessica varsles umiddelbart ved ny inquiry. WeChat-henvendelser varsler også Martin. |

---

## Manuelle prosesser — aldri automatiser disse

> Se `09_Philosophy/AUTOMATION_POLICY.md` for fullstendig begrunnelse.

| Prosess | Eier | Hvorfor manuell |
|---------|------|-----------------|
| Kvalifisering av buyer-henvendelser | Jessica | Kulturell vurdering, relasjonslesing — krever menneskelig dømmekraft |
| Prissetting på tilbud | Jessica + Daniel | Finansiell vurdering, leverandørrelasjon, markedsforståelse |
| Godkjenning av nye leverandører | Daniel | Strategisk beslutning — langvarig konsekvens |
| Ordre > 50 000 NOK | Daniel | Finansiell terskelregel — bevisst valg, ikke teknisk begrensning |
| Betalingsoppfølging dag 10+ | Daniel | Relasjonsrisiko — feil tone avslutter forholdet |
| Kommunikasjon om leveringsforsinkelser til buyer | Jessica | Kulturell nyanse — timing og formulering avgjørende med asiatiske kjøpere |
| Leverandørgodkjenning av produkter (pending → active) | Daniel/admin | Kvalitetssjekk — feil produkter live = merkevarerisiko |
| Avbestillingsforhandlinger | Daniel | Juridisk og finansiell eksponering |
