# Automation Roadmap — Global Distribution AS

> Oppdatert: 2026-03-16
> Filosofi: automatiser repetitivt arbeid, ikke menneskelig vurdering.

---

## NÅ (live 2026-03-16)

Fundamentet er på plass:

- ✅ Daglig rapport (Supabase → e-post + vault)
- ✅ Vault-sync (auto git push)
- ✅ Auto-routing (fil til riktig mappe)
- ✅ Månedlig analyse (Claude API → vault)
- ✅ Ukentlig mønsteranalyse (4 reviews → 3 mønstre)
- ✅ Månedlig plattformrapport (events view → vault)
- ✅ Inquiry-bekreftelse (Edge Function)
- ✅ Claude Code hooks (sikkerhetssjekker + regelekstraksjon)
- ✅ QuoteGenerator (tilbudsmotor i portal)
- ✅ `events`-tabell for plattformsporing

---

## 30 DAGER (pre-launch)

Prioritet: gjøre systemet klart for ekte bruk.

| # | Hva | Hvorfor | Estimat |
|---|-----|---------|---------|
| 1 | Fyll inn `config.env` (Supabase, Resend, Anthropic) | Alle scripts er nakne uten nøkler | 15 min |
| 2 | Registrer launchd-plister på Mac mini (`mac-mini-setup.sh`) | Ingen automatisering kjører uten dette | 10 min |
| 3 | Sett opp event-logging i portal (Inquiry + Order flows) | Uten logging er `monthly_patterns` tom | 2 timer |
| 4 | Ekschange rate til Supabase `settings`-tabell | Hardkodet kurs gir feil tilbud | 1 dag |
| 5 | Cache `useUserRole` (3 DB-kall per sesjon → 1) | Treg innlogging ved skala | 3 timer |
| 6 | Fjern 7 ubrukte npm-pakker | 120KB bundlereduksjon | 3 timer |

---

## 90 DAGER (tidlig drift)

Prioritet: systemet rapporterer på seg selv.

| # | Hva | Hvorfor | Estimat |
|---|-----|---------|---------|
| 7 | Prissjekk-script (Prisjakt API → vault) | Manuell sjekk 2×/uke → unødvendig | 1 dag |
| 8 | Betalingspurring (overdue → e-post til buyer via Resend) | Forfalte ordre krever manuell oppfølging nå | 1 dag |
| 9 | Deploy Jessica buyer-portal til Vercel | Buyer portal har ingen CI/CD | 4 timer |
| 10 | TypeScript strict mode | Fanger type-feil som nå feiler stille | 1 dag |
| 11 | Admin-invite-flyt (Supabase Auth Admin API) | Manuell Supabase-invitasjon er ikke skalérbar | 1 dag |
| 12 | Martin-facing dashboard (ukentlig tall i portal) | E-post er én-veis — Martin trenger selvbetjening | 2 dager |

---

## 6 MÅNEDER (skalering)

Prioritet: systemet tilpasser seg volum.

| # | Hva | Hvorfor | Estimat |
|---|-----|---------|---------|
| 13 | Produktbilde-komprimering ved opplasting (WebP, maks 400KB) | Supabase storage overskrider gratis tier ved ~50 leverandører | 1 dag |
| 14 | Flytt bilder til Cloudflare R2 | $0.015/GB vs Supabase $0.021/GB — billigere ved skala | 2 dager |
| 15 | WeChat-webhook for inquiry (hvis mulig) | Noen buyers foretrekker WeChat → manuell meldingslogging | Uklar |
| 16 | Automatisk margin-varsling (margin < 20% trigger e-post) | Unngå ulønnsomme ordre som sendes ut | 1 dag |
| 17 | Supabase Pro-oppgradering ($25/mnd) | Ingen inaktivitetspause, backup SLA | Når >50 aktive leverandører |
| 18 | Fraktintegrasjon (Bring/PostNord API → ordre) | Manuell fraktberegning i dag | 2 dager |

---

## Prinsipper

1. **Aldri automatiser beslutninger** — automatiser informasjonsinnhenting og formatering. Daniel og Martin tar beslutningene.
2. **Billigste løsning som skalerer** — gratis tier inntil det faktisk koster penger å ikke oppgradere.
3. **Systemer som forteller deg om seg selv** — heartbeat, error-log, og månedlig rapport betyr at ingen feil er stille.
4. **Én kilde til sannhet** — vault er sannheten om forretningen, Supabase er sannheten om plattformen.
