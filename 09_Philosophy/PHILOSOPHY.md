# Global Distribution AS — Filosofi og prinsipper

> Dette er et levende dokument. Oppdater det når vi tar en stor beslutning som avviker fra eller bekrefter disse prinsippene. Dato og begrunnelse skal alltid med.

_Sist oppdatert: 2026-03-16 — Daniel (etablert ved oppstart)_

---

## Hvorfor dette dokumentet finnes

Vi er et lite team som bygger noe stort. Det betyr at vi ikke har råd til å ta feil beslutninger om igjen, betale for ting vi ikke trenger, eller kaste bort tid på friksjon som kan elimineres. Disse prinsippene er ikke regler — de er en huskeliste for fremtidige oss når vi er usikre på hva vi skal velge.

Når vi er i tvil: les dette dokumentet.

---

## Prinsipp 1 — Billigst som skalerer

> *Velg alltid den billigste løsningen som kan håndtere ti ganger mer enn vi har i dag.*

Vi er ikke en enterprise. Vi betaler ikke for enterprise-løsninger. Gratisnivå er utgangspunktet — vi oppgraderer kun når vi treffer en konkret grense, ikke fordi en løsning «ser profesjonell ut».

**I praksis:**
- Vercel Hobby frem til vi har stabil inntekt og trenger Pro-funksjoner
- Supabase Free frem til vi passerer grensene
- Obsidian er gratis — hold det gratis
- Ingen SaaS-abonnementer uten at vi kan navngi hvilken konkret smerte det løser

**Når vi bryter dette prinsippet:** Dokumenter det her med dato og begrunnelse.

---

## Prinsipp 2 — Bygget for å skalere, ikke for å imponere

> *Start enkelt. Legg til kompleksitet kun når enkelheten stopper å fungere.*

Arkitekturvalg skal tåle vekst uten full ombygging, men vi skal ikke overbygge for hypotetiske fremtidsbehov. Vercel, Supabase og Obsidian er valgt fordi de er enkle å starte med og enkle å skalere — ikke fordi de er de mest avanserte alternativene.

**I praksis:**
- Manuell CSV-økonomi nå → Fiken/Tripletex når vi har bankkonto og volum
- Én Supabase-instans → sharding eller caching når vi faktisk treffer ytelsesgrenser
- Én Vercel-deployment → CDN eller edge-functions når vi faktisk trenger det
- Ikke bygg integrasjoner til systemer vi ikke har i dag

**Tegn på at vi overbygger:** Vi diskuterer løsninger på problemer vi ikke har hatt ennå.

---

## Prinsipp 3 — Null friksjon for Martin og Jessica

> *Hvis Martin eller Jessica må lese en manual for å gjøre en daglig oppgave, har vi designet det feil.*

Teknologi skal være usynlig for teamet. SOPs skal være sjekklister, ikke essays. Systemer skal ha ett inngangspunkt. Hvis noe er forvirrende, er det vi som har gjort det for komplisert — ikke de som ikke skjønner det.

**I praksis:**
- `00_START_HER.md` er den eneste filen Martin trenger å åpne om morgenen
- Supabase og Vercel er aldri Martin eller Jessicas ansvar
- Nye systemer innføres bare hvis de erstatter noe, ikke hvis de legges til
- Automatisering prioriteres når en manuell oppgave gjentas (se Prinsipp 4)

**Spørsmål å stille:** Kan Martin gjøre dette etter tre minutter med instruksjoner, uten å spørre Daniel?

---

## Prinsipp 4 — To ganger manuelt, én gang automatisk

> *Hvis noe gjøres manuelt mer enn to ganger, automatiserer vi det.*

Tid brukt på repetisjon er tid som ikke brukes på vekst. Automatisering er ikke en luksus — det er vedlikehold av teamets kapasitet. Mac mini er kjøpt nettopp for dette.

**I praksis:**
- Daglig rapport kjøres automatisk kl. 07:30 via Mac mini
- Vault synkroniseres til GitHub hvert 10. minutt automatisk
- Ordre-maler fylles ut fra mal, ikke fra scratch
- Hvis vi sender samme e-post tre ganger — lag en mal

**Grensen:** Vi automatiserer ikke noe som krever menneskelig vurdering. Automatisering er for mekanikk, ikke for beslutninger.

---

## Prinsipp 5 — Én kilde til sannhet

> *Informasjon lagres ett sted. Alle andre steder peker dit.*

Dobbeltlagring er kilden til feil. Hvis leverandørinfo finnes i Obsidian og i en Excel og i en e-post, er ingen av dem riktig. Vi velger ett system per informasjonstype og holder oss til det.

**Hvem eier hva:**

| Informasjonstype | Kilde til sannhet | Aldri i tillegg |
|---|---|---|
| Buyers og inquiries | Obsidian `01_Buyers/` | Ikke i Excel, ikke i e-post |
| Leverandører | Obsidian `02_Suppliers/` | Ikke i Excel, ikke i kontakter |
| Produkter | Supabase (database) | Ikke i Obsidian (kun lenker dit) |
| Ordre | Obsidian `04_Orders/` | Ikke i chat, ikke i e-post alene |
| Økonomi | `05_Finance/transactions.csv` | Ikke i regneark ved siden av |
| Kildekode | GitHub (`g-dist/aurora-trade-hub`) | Ikke lokalt uten push |
| Teknisk dokumentasjon | Obsidian `09_Tech/` | Ikke i kodekommentarer alene |

**Når vi bryter dette:** En kopi er alltid lov som backup — men den skal tydelig merkes som kopi og ha en dato.

---

## Beslutningslogg

> Logg her når et prinsipp ble testet av en konkret beslutning.

| Dato | Beslutning | Prinsipp | Utfall |
|---|---|---|---|
| 2026-03-16 | Valgte manuell CSV-økonomi fremfor Fiken nå | #1, #2 | Riktig — ingen bankkonto ennå |
| 2026-03-16 | Valgte Obsidian fremfor Notion for operasjonell styring | #3, #5 | Riktig — offline, gratis, ingen vendor lock-in |
| 2026-03-16 | Mac mini for automatisering fremfor betalt cloud-cron | #1, #4 | Riktig — engangskostnad vs. løpende |

---

---

## Økonomiske prinsipper

> Lagt til 2026-03-16 etter full CFO-gjennomgang. Disse prinsippene er utledet fra faktiske tidsmålinger og kostnadstall — ikke teori.

### ØP1 — Betal aldri for en tjeneste før gratisnivået er en dokumentert flaskehals

Gratisnivå er startpunktet, ikke et kompromiss. Oppgradering krever en skriftlig begrunnelse med konkrete tall (f.eks. «vi sendte 3 100 e-poster i mars og traff grensen på 3 000»). Uten dokumentert flaskehals: ingen oppgradering.

**I praksis:** Supabase Free, Vercel Hobby, Resend Free dekker alt frem til 50+ aktive leverandører. Se [[05_Finance/COST_MAP]] for nøyaktige terskler.

### ØP2 — Daniels tid er 4× dyrere enn Martins og 3,5× dyrere enn Jessicas — rut beslutninger til billigste kvalifiserte person

Estimert timepris: Daniel 1 500 NOK, Martin 400 NOK, Jessica 350 NOK. Enhver oppgave Daniel gjør som Martin eller Jessica kan gjøre med riktige verktøy, koster 3–4× mer enn nødvendig.

**I praksis:** Produktgodkjenning, daglig driftsoppfølging og transaksjon-logging skal aldri kreve Daniel. Automatisér, eller dokumentér slik at Martin kan overta.

### ØP3 — Enhver manuell dataregistrering som kan hentes fra Supabase er en feil, ikke en prosess

Hvis data allerede finnes i databasen (ordre, betalinger, leverandører), er det aldri Martins ansvar å skrive det inn i en CSV-fil for hånd. Manuelle CSV-oppdateringer er en symptom på manglende synk, ikke en rutine.

**I praksis:** `sync-finance.sh` (se [[09_Tech/BACKLOG]]) skal gjøre at transactions.csv aldri trenger manuell oppdatering.

### ØP4 — Quotehastighet er inntektshastighet — hver time Jessica venter på priser er en potensiell tapt ordre

Buyers i Asia sammenligner tilbud fra flere leverandører parallelt. Vår responstid på tilbud er en konkurranseparameter, ikke en intern rutine. Hvert steg som krever manuell pris-innhenting fra Martin er en risiko.

**I praksis:** Alle produktpriser skal ligge i Supabase og være tilgjengelige for Jessica uten å spørre Martin. `quote-assistant.sh` løser dette lokalt. Platform-integration løses via [[09_Tech/BACKLOG]].

### ØP5 — Automatisering er ansettelse uten lønn — invester i det tidlig

En automatisering som sparer 1 time/mnd ved 400 NOK/t betjener seg selv innen én måned hvis den tar under 1 time å bygge. Grensen for å automatisere er ikke «om det er verdt det» men «tar dette mer enn 15 minutter og gjentas mer enn én gang i uken?».

**I praksis:** Se [[05_Finance/TIME_COST_MAP]] for prioritert liste. De to høyest-rangerte automatiseringene (finance-sync og follow-up-tracker) er implementert 2026-03-16 og sparer ~kr 16 000/mnd.

---

---

## AI-infrastruktur

> Lagt til 2026-03-16 etter arkitekturevaluering av hybrid lokal/sky AI-oppsett.

### AIR1 — Klassifiser oppgaven før du tildeler modell

Ikke alle AI-oppgaver er like. Før vi bruker AI til noe som helst, bestem tier:

| Tier | Kriterium | Backend |
|------|-----------|---------|
| **1 — Claude** | Forretningsbeslutning, kundevendt, juridisk, arkitektur — feil koster penger eller relasjoner | Claude API / Claude.ai |
| **2 — Lokal** | Strukturert input → strukturert output, mekanikk ikke vurdering | Ollama (qwen2.5:14b) |
| **3 — Script** | Deterministisk — samme input gir alltid samme output | Bash/Python, ingen AI |

**Spørsmål å stille:** "Hvis modellen svarer 20% feil — hva er konsekvensen?"
- Kostet penger eller relasjon → Tier 1
- Ukorrekt rapport som vi retter neste dag → Tier 2
- Kan ikke svare feil fordi det er ren logikk → Tier 3

### AIR2 — Lokal AI er for personvern og skalering, ikke for å spare penger i dag

Ved pre-launch og tidlig drift koster AI-automatisering ~kr 1/mnd via API. Å flytte til lokal Ollama for kostnadssparing nå er prematur optimalisering. Grunner til å bruke lokal AI som *er* gyldige:

- **Personvern:** ordre, betalinger, kjøperdata skal aldri forlate Mac mini
- **Latens:** <5s svar for interne verktøy, ingen nettverkskall
- **Ubegrenset kjøring:** kan kjøre 1 000 klassifiseringer/dag uten kostnad
- **Fremtidssikring:** etabler mønsteret nå, skaler gratis

### AIR3 — Abonnementet er kostnaden, ikke API-kallene

Vår AI-regning er primært Claude Pro/Max-abonnementet (~kr 220–2 200/mnd). API-automatiseringen koster <kr 5/mnd. Tiltak som sparer token-kostnader uten å endre abonnementet, er ikke kostnadssparing — de er latensoptimalisering.

**Når abonnementet justeres:**
- Pro → Max: kun hvis vi bruker opp Pro-kvoten *systematisk*, ikke sporadisk
- API-kostnader > kr 100/mnd: vurder å flytte én Tier 2-oppgave til lokal

### AIR4 — Ny AI-oppgave: evaluer tier før implementering

Når vi vil bruke AI til noe nytt, gjør dette i rekkefølge:

1. **Kan det gjøres uten AI?** (Tier 3 — foretrekkes alltid)
2. **Er det godt nok for lokal modell?** (Tier 2 — ingen tokenkostnad)
3. **Krever det forretningsdømmekraft?** (Tier 1 — bruk Claude)

Dokumenter valget i `09_Tech/AI_STACK.md`.

### AIR5 — Gjennomgå tier-klassifiseringen hvert 30. dag

Oppgaver som er Tier 1 i dag kan bli Tier 2 når:
- Lokal modellkvalitet forbedres
- Oppgaven er repetert nok til at vi vet nøyaktig hva riktig svar er
- Datavolum gjør sky-kall uøkonomisk

**Trigger for gjennomgang:** Månedlig analyse-rapport flagg med "tier-review" hvis noen Tier 1-oppgaver kjører mer enn 10× per uke.

### AIR6 — Kostnadsalarm

Hvis månedlig Claude API-kostnad (ikke abonnementet) overstiger kr 50:
1. Identifiser hvilken oppgave som driver kostnaden
2. Vurder om oppgaven kan flyttes til Tier 2
3. Dokumenter beslutning i beslutningsloggen under

**Beslutning i beslutningsloggen:**

| Dato | Beslutning | Prinsipp | Utfall |
|------|------------|---------|--------|
| 2026-03-16 | Valgte hybrid lokal/sky AI. Lokal for personvern og skalering, Claude for analyse og beslutninger | AIR1, AIR2 | Implementert: Ollama qwen2.5:14b på Mac mini M4 |

---

## Når filosofien skal oppdateres

Oppdater dette dokumentet når:
- Vi bytter et kjernesystem (f.eks. fra Obsidian til noe annet)
- Vi tar en beslutning som bevisst bryter et prinsipp
- Et prinsipp viser seg å være feil i praksis
- Selskapet vokser til et punkt der premissene endrer seg

Format: legg til en linje i beslutningsloggen, og oppdater selve prinsippet hvis det har endret seg.
