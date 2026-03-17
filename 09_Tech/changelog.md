# Changelog — Global Distribution AS

> Automatisk og manuelt loggede endringer på tvers av vault, scripts og portal.
> Nyeste endringer øverst.

---

## 2026-03-17 — Automatiseringsarkitektur: scripts, cron, konfig

### Nye scripts opprettet

**`scripts/keepalive-supabase.sh`**
Pinger Supabase settings-tabell daglig (kl 08:00). Logger OK/ADVARSEL til `08_Daily/keepalive.log`.
Sender e-post via Resend ved feil (forutsetter at Resend-nøkkel er konfigurert).
Trimmer logg til siste 90 linjer automatisk.

**`scripts/update-fx-rates.sh`**
Henter NOK/USD og NOK/CNY fra frankfurter.app (ECB, gratis, ingen nøkkel).
PATCHer Supabase settings-tabell hverdager kl 09:00. Logger til `08_Daily/fx-rates.log`.
Beholder eksisterende kurs ved API-feil — feiler aldri hardt.

**`aurora-trade-hub/scripts/pre-deploy-check.sh`**
Kjøres manuelt før `supabase db push` eller `vercel --prod`.
Sjekker: Docker-status, supabase db diff, RLS-aktivering på kritiske tabeller,
TypeScript-build, hardkodede hemmeligheter i kildekode, bundle-størrelse.
Blokkerer deploy ved feil, advarer ved potensielle problemer.

**`aurora-trade-hub/scripts/dev-status.sh`**
Ukentlig teknisk statusrapport: git-status, build-status, TypeScript-feil,
migrasjonshistorikk, utdaterte npm-pakker, keepalive-logg, FX-logg, bundle-størrelse.
Kan pipes til `pbcopy` for liming inn i Claude.

### crontab.conf oppdatert

Lagt til to nye cron-jobber:
- `0 8 * * *` — keepalive-supabase.sh (daglig kl 08:00)
- `0 9 * * 1-5` — update-fx-rates.sh (hverdager kl 09:00)

**HANDLING KREVES:** Aktiver crontab på Mac mini:
```bash
crontab ~/Documents/GlobalDistribution/scripts/crontab.conf
```

### config/margins.yaml opprettet (aurora-trade-hub)

Marginregler per produktkategori (20–25 %), godkjenningsgrenser for Martin og Jessica,
tilleggsprosenter for express og skreddersydde kontrakter.
Skal leses av quoteEngine.ts etter wiring (peker til Supabase for valutakurser).

---

## 2026-03-17 — Forretningsstrukturaudit: SOPer, playbooks, helse-dashboard

### Fase 3: Kritiske og høye funn implementert

**SOPer opprettet (06_Operations/SOPs/):**
- `2026-03-17_sop_keepalive-supabase.md` — KRITISK: Forhindrer automatisk DB-pause på Free tier. Steg-for-steg guide for daglig cron-oppsett.
- `2026-03-17_sop_quote-followup-ownership.md` — Tydeliggjør eierskap: den som sender tilbudet, eier oppfølgingen. Prosedyre for overføring ved fravær.
- `2026-03-17_sop_jessica-coverage.md` — Dekning for buyer-kommunikasjon når Jessica er utilgjengelig. Varslingsprotokoll og standardmelding.
- `2026-03-17_sop_monthly-pl-review.md` — Månedlig P&L-prosedyre: hvem gjør hva, maler, terskler.
- `2026-03-17_sop_config-env.md` — Steg-for-steg guide for å fylle ut config.env og låse opp Mac mini automatisering.

**ADR opprettet (09_Tech/ADR/):**
- `2026-03-17_fx-rate-api.md` — Frankfurter.app (ECB-data, gratis, ingen API-nøkkel) for daglig NOK/USD og NOK/CNY oppdatering via cron til Supabase settings-tabell.

**Playbooks oppdatert:**
- `MARTIN_PLAYBOOK.md` — La til: keepalive-sjekk i morgenrutinen, tilbudssjekk i ukentlig rutine, månedlig P&L-prosedyre, og eksplisitt liste over oppgaver som krever Daniel.

### Fase 4: Business Health Dashboard

- `00_Dashboard/BUSINESS_HEALTH.md` opprettet — 5 ukentlige nøkkeltall, 3 advarselssignaler med tiltaksplan, månedlig sjekkliste, kvartalsvis strategispørsmål, teknisk helsestatus.

### Fase 5: Stresstester og filosofidokument

- `09_Philosophy/STRESS_TESTS.md` — Tre scenarioer analysert med sviktpunkter og preventive tiltak: Daniel utilgjengelig 2 uker, Jessica slutter, 10× inquiries.
- `09_Philosophy/BUSINESS_STRUCTURE_BRIEF.md` — Én-sides brief: hva selskapet er, hvem gjør hva, hva er sant (ukensert), de 5 viktigste oppgavene neste 30 dager, og hva suksess ser ut som.

---

## 2026-03-16 — Kostnadsaudit: optimalisering og dokumentasjon

### vercel.json: smartere ignoreCommand (monorepo-bevisst)

**Problem:** Den gamle `ignoreCommand` (`[ "$VERCEL_GIT_COMMIT_REF" != "main" ]`) var redundant
med `deploymentEnabled: { main: true }` — den sjekket bare om vi var på main, noe som
`deploymentEnabled` allerede håndterer. Bygget ble alltid trigget ved push til main, uansett
hva som faktisk ble endret.

**Endring:**
```
Gammel: [ "$VERCEL_GIT_COMMIT_REF" != "main" ]
Ny:     git diff HEAD^ HEAD --quiet -- apps/portal/ packages/
```

Vercel hopper nå over bygg når bare jessica-appen, vault-scripts eller dokumentasjon
endres — kun endringer i `apps/portal/` eller `packages/` trigger et nytt bygg.

**Besparelse:** Sparer ~2 min per "stille" push til main. Viktigere ved frekvent vault-sync.

**Fil:** `vercel.json`

### Ny fil: 09_Tech/COSTS.md

Full kostnadslogg opprettet med:
- Nåværende månedskostnad per tjeneste (~kr 8–9/mnd totalt)
- Projeksjon ved 10× bruk (~kr 260/mnd, drevet av Supabase storage)
- De tre største kostnadsrisikoene ved vekst og mitigeringsstrategier
- Supabase inaktivitetspause-advarsel (kritisk pre-launch)
- Mac mini vs. sky — hva flyttes lokalt, hva forblir

---

## 2026-03-16 — Systemaudit: auto-fiks (6 stk)

Gjennomført full systemaudit på tvers av kodebase, infrastruktur og vault.
Alle endringer med HIGH impact og ≤30 min innsats ble implementert automatisk.

### Fix 1 — `daily-report.sh`: feil mappestier for vault-telling

**Problem:** Scriptet søkte i `03_Orders/` og `01_Customers/` — mapper som ikke finnes.
Ordre- og inquiry-tellingen viste alltid `0`.

**Endring:**
- `03_Orders` → `04_Orders` (korrekt ordrekatalog)
- `01_Customers` → `01_Buyers/Active` (korrekt buyer-katalog)

**Fil:** `scripts/daily-report.sh`

---

### Fix 2 — `com.gdist.monthly-analysis.plist`: hardkodet `/Users/daniel/`

**Problem:** Alle andre launchd-plister bruker `/Users/gdist/` som plassholder
(erstattes av `setup-mac-mini.sh` ved installasjon). Denne plisten hadde `/Users/daniel/`
og ville feilet stille på Mac mini.

**Endring:** Alle forekomster av `/Users/daniel` → `/Users/gdist` i plist-filen.

**Fil:** `scripts/launchd/com.gdist.monthly-analysis.plist`

---

### Fix 3 — Slettet 7.4MB ubrukt bildefil fra portal

**Problem:** `apps/portal/public/northern-lights-bg.jpg` (7.4 MB, 5120×3408px) lå i
git-historikken og ble lastet opp til Vercel ved hvert deploy. Ingen steder i koden
refererte til denne filen — bakgrunnsbildet hentes fra Unsplash CDN.

**Endring:** Fil slettet fra `apps/portal/public/`.

**Besparelse:** ~7 sekunder raskere Vercel-upload per deploy.

---

### Fix 4 — Fjernet ubrukt `QueryClientProvider` fra `App.tsx`

**Problem:** `@tanstack/react-query` var installert og `QueryClientProvider` wrapte
hele applikasjonen, men ikke ett eneste `useQuery`- eller `useMutation`-kall finnes
noe sted i kodebasen. Rent boilerplate som aldri ble tatt i bruk.

**Endring:** Fjernet import, `const queryClient`, og `<QueryClientProvider>` wrapper.

**Besparelse:** 40KB fra bundle (668KB → 610KB gzip-komprimert: 191KB → 176KB).

---

### Fix 5 — Fjernet duplikat toast-system fra `App.tsx`

**Problem:** To separate toast-biblioteker var montert i roten:
- `<Toaster>` fra `@radix-ui/react-toast` (via shadcn-wrapper)
- `<Sonner>` fra `sonner`-pakken

Kun Sonner ble faktisk brukt i kodebasen. Radix Toaster var aldri kalt.

**Endring:** Fjernet `import { Toaster } from "@/components/ui/toaster"` og `<Toaster />`.
Beholdt Sonner som eneste toast-system.

---

### Fix 6 — Opprettet manglende vault-mapper

**Problem:** To mapper som automatiseringsskript avhenger av eksisterte ikke i git:
- `08_Daily/` — brukes av `daily-report.sh` for å lagre daglige rapporter
- `04_Orders/Quotes/` — brukes av `export-quotes-to-obsidian.sh` for tilbudsfiler

Skriptene hadde `mkdir -p` som fallback, men mappene burde finnes i git fra starten.

**Endring:** Opprettet begge mapper med `.gitkeep` og lagt til i git.

---

## Backlog (ikke implementert automatisk)

Disse krever beslutning fra Daniel:

| # | Hva | Hvorfor ikke auto-fikset |
|---|-----|--------------------------|
| 7 | Flytt marginer/valutakurs/landpremier fra `quoteEngine.ts` til Supabase | Full dag — krever ny migrasjons + admin-UI |
| 8 | Fjern 7 ubrukte npm-pakker (~120KB) | Half dag — krever testing av alle sider etterpå |
| 9 | Cache `useUserRole` (fetches 3× per sesjon) | Half dag — krever auth context refaktor |
| 10 | Deploy Jessica buyer-portal til Vercel | Half dag — mangler `vercel.json` for jessica-appen |
| 11 | Konsolider duplikat SOP: `05_SOPs/JESSICA_PLAYBOOK.md` vs `06_Operations/SOPs/` | 30 min — men krever bekreftelse fra Daniel |
| 12 | Aktiver TypeScript strict mode | Half dag — vil avdekke type-feil som må fikses |
| 13 | `config.env`: fyll inn 3 API-nøkler (Supabase, Resend, Anthropic) | Manuelt — hemmeligheter kan ikke auto-genereres |
