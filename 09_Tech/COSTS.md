# Kostnadslogg — Global Distribution AS

> Oppdatert: 2026-03-16
> Filosofi: billigste løsning som skalerer — aldri betal for noe vi ikke bruker fullt ut.

---

## Nåværende månedskostnad

| Tjeneste | Plan | Hva vi bruker | Grense (gratis) | Månedskostnad |
|----------|------|---------------|-----------------|---------------|
| **Vercel** | Hobby (gratis) | 1 app (portal), builds kun på `main` | 100 GB båndbredde, ubegrenset builds | **kr 0** |
| **Supabase** | Free tier | DB (~5 MB), 1 storage-bøtte, 1 Edge Function | 500 MB DB, 1 GB storage, 2 GB båndbredde | **kr 0** |
| **Resend** | Free tier | ~70 e-poster/mnd (daglig rapport ×2 + sporadisk) | 3 000 e-poster/mnd, 1 domene | **kr 0** |
| **Anthropic (Claude)** | Pay-as-you-go | 1 kjøring/mnd (månedlig analyse) + sjeldne onboardinger | Ingen gratis tier | **~kr 0.30** |
| **GitHub** | Free | 2 private repos, ingen Actions-workflows | Ubegrenset public, 2 000 min/mnd private Actions | **kr 0** |
| **Domene (gdist.no)** | Årsavgift | DNS, e-postdomene | — | **~kr 8** |
| | | | **TOTAL** | **~kr 8–9/mnd** |

---

## Etter gjennomførte endringer (2026-03-16)

Ingen tjenestekostnader endret — systemet var allerede optimalisert for gratisnivå.

Tekniske forbedringer implementert:
- `vercel.json` ignoreCommand erstattet: bygger nå kun når `apps/portal/` eller `packages/` er endret — sparer build-minutter ved push som kun berører jessica-appen eller vault-scripts.
- Realtime ikke aktivert på noen tabeller (ingen `supabase_realtime` publication-oppføringer i migrasjoner).
- Preview-deployments: deaktivert via `"deploymentEnabled": { "main": true }`.

**Total etter endringer: ~kr 8–9/mnd** (uendret — allerede optimalt)

---

## Ved 10× nåværende bruk (tidlig skalering)

| Tjeneste | Estimert bruk | Kost |
|----------|--------------|------|
| Vercel | Mer trafikk, samme bygg-frekvens | kr 0 (godt under 100 GB/mnd) |
| Supabase DB | ~50 MB (10× data) | kr 0 (grense: 500 MB) |
| Supabase Storage | ~3 GB produktbilder (100 leverandører × 50 produkter × ~600 KB) | **⚠️ Over gratisnivå** → ~$25/mnd |
| Resend | ~700 e-poster/mnd | kr 0 (grense: 3 000/mnd) |
| Anthropic | ~$0.30/mnd | ~kr 3 |
| **TOTAL** | | **~kr 260/mnd** (drevet av Supabase storage) |

---

## De tre største kostnadsrisikoene ved vekst

### 1. Supabase storage — produktbilder
**Risiko:** Gratisnivå gir 1 GB storage. 100 leverandører × 50 produkter × 1 MB = 5 GB → betaler $25/mnd.

**Mitigering:**
- Komprimer alle produktbilder til WebP, maks 400 KB ved opplasting (legg til i `SupplierUpload.tsx` — Canvas API + `toBlob('image/webp', 0.82)`)
- Alternativ: flytt bilder til **Cloudflare R2** (gratis inntil 10 GB, $0.015/GB deretter) — langt billigere enn Supabase storage ved skala
- Ikke hast: hander ikke før ~50 aktive leverandører

### 2. Supabase inaktivitetspause (kritisk pre-launch)
**Risiko:** Gratis Supabase-prosjekter pauses etter 7 dager uten aktivitet. Pre-launch, hvis `daily-report.sh` ikke har API-nøkler konfigurert (SUPABASE_SERVICE_ROLE mangler i `config.env`), gjør scriptet ingen Supabase-kall → databasen kan pause.

**Mitigering:**
- Fyll inn `SUPABASE_SERVICE_ROLE` i `config.env` umiddelbart → `daily-report.sh` holder databasen aktiv med daglige spørringer
- Hvis Mac mini ikke er klar: legg til en enkel cron på Daniel sin Mac som pinger Supabase én gang daglig (se nedenfor)
- Oppgrader til Supabase Pro ($25/mnd) ved lansering — ingen pause, men ikke nødvendig ennå

```zsh
# Legg til i crontab (crontab -e) midlertidig til Mac mini er klar:
0 9 * * * curl -sf "https://orsjlztclkiqntxznnyo.supabase.co/rest/v1/profiles?select=id&limit=1" -H "apikey: DIN_ANON_KEY" > /dev/null
```

### 3. Resend e-postvolum ved skalert inquiry-flyt
**Risiko:** Hver inquiry med e-post trigger én e-post via Edge Function + to e-poster i daglig rapport. Ved 100+ inquiries/dag → over 3 000/mnd grense → $20/mnd Resend Pro.

**Mitigering:**
- Gratisnivå holder til ~3 000 inquiries/mnd (langt over pre-launch behov)
- `inquiry-confirmation/index.ts` sender allerede kun til e-postadresser (WeChat hoppes over) ✓
- Daglig rapport: vurder å sende kun ukentlig til Martin for å halvere e-postvolum

---

## Tjenestestatus — gratisnivå brukt fullt?

| Tjeneste | Gratisnivå brukt fullt? | Neste betalnivå | Når vi treffer det |
|----------|------------------------|-----------------|-------------------|
| Vercel Hobby | ✅ Ja — ingen Pro-funksjoner i bruk | Pro $20/mnd | Aldri (SPA trenger ikke Pro) |
| Supabase Free | ✅ Ja — realtime av, minimal data | Pro $25/mnd | Ved ~50+ leverandører med bilder |
| Resend Free | ✅ Ja — ~70/3 000 e-poster brukt | Pro $20/mnd | Ved ~3 000 inquiries/mnd |
| Anthropic | N/A (ingen gratis tier) | Pay-as-you-go | Skalerer lineært, billig |
| GitHub Free | ✅ Ja — ingen Actions, ingen overskudd | Team $4/bruker/mnd | Aldri nødvendig |

---

## Mac mini — hva flyttes lokalt, hva forblir i skyen

### Flyttes til Mac mini (reduserer skyavhengighet)
| Hva | Hvorfor lokalt |
|-----|---------------|
| Daglig rapport (daglig-report.sh) | Kjøres allerede via launchd, ingen skykostnad |
| Vault-sync (sync-all.sh) | Git-push fra lokal maskin, ingen skykostnad |
| Quote-eksport (export-quotes-to-obsidian.sh) | Lokal skriving til vault, ingen skykostnad |
| Månedlig analyse (monthly-analysis.sh) | Lokal lesing + Anthropic API-kall, billigst lokalt |
| Auto-routing (auto-route.sh) | Fil-operasjoner, 100% lokalt |

### Forblir i skyen (uansett Mac mini)
| Hva | Hvorfor sky |
|-----|------------|
| Supabase database | Eksternt tilgjengelig for portal + Jessica |
| Vercel (portal-app) | Global CDN, zero-config TLS, ingen kostnad |
| GitHub repos | Versjonskontroll + backup |
| Resend e-post | Transaksjons-e-post krever dedikert avsenderdomene |
| inquiry-confirmation Edge Function | Trigges av public portal, må svare uavhengig av Mac mini uptime |

**Konklusjon:** Mac mini erstatter alle *planlagte/periodiske* jobs. Skyen håndterer kun *reaktive* jobs (bruker-triggede requests via portal).

---

## Sist oppdatert
2026-03-16 — Systemaudit, kostnadsgjennomgang
