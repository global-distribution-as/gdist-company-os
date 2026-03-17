# AI Stack — Global Distribution AS

> Oppdatert: 2026-03-16
> Filosofi: Claude tar beslutninger. Lokal modell tar mekanikk.

---

## Phase 1 — Klassifisering av alle AI-oppgaver

### TIER 1 — Krever Claude-kvalitet (beholdes i sky)

Disse oppgavene har reelle konsekvenser hvis output er feil: tapt relasjon, feil pris, feil beslutning.

| Oppgave | Script / verktøy | Begrunnelse |
|---------|-----------------|-------------|
| Månedlig vinn/tap-analyse | `monthly-analysis.sh` | Strategisk vurdering, ufullstendig data, krever forretningsdømmekraft |
| Ukentlig mønsteranalyse | `weekly-analysis.sh` | Identifiserer trender på tvers av kontekst, krever nyansert tolkning |
| Tilbudsgenerering og prisstrategi | QuoteGenerator (portal) | Feil pris koster penger og relasjoner |
| Kundekommunikasjon (e-post til buyers) | Manuelt via Claude.ai | Kulturell sensitivitet (Kina, Korea), tone og relasjonsbygging |
| Arkitekturbeslutninger og kodegjennomgang | Claude Code (Pro/Max) | En dårlig arkitekturavgjørelse koster dager å reversere |
| Onboardingskript for leverandører | `supplier_onboard.py` | Første inntrykk — e-posttonen settes her |
| NDA-utkast og kontraktsformuleringer | Manuelt via Claude.ai | Juridisk konsekvens ved feil |

---

### TIER 2 — Kan kjøre på lokal 8B–14B modell (flyttes til Mac mini)

Disse oppgavene er **strukturert input → strukturert output**. En lokal modell gjør dem godt nok.

| Oppgave | Nåværende løsning | Lokal erstatning | Estimert token-besparelse |
|---------|-------------------|------------------|---------------------------|
| Daglig rapport-narrativ (oppsummering av tall) | Ingen AI i dag — ren formatering | `local-daily-summary.sh` → Ollama | Ny oppgave, 0 baseline |
| Changelog-generering fra git diff | Manuell | `git-changelog.sh` → Ollama | ~2 000 tokens/commit |
| Feillogg-oppsummering og forklaring | Ingen AI | `log-summarize.sh` → Ollama | ~1 000 tokens/kjøring |
| Vault-fil klassifisering (tvilstilfeller) | `auto-route.sh` med regler | Ollama som fallback | ~500 tokens/fil |
| Template-fylling med kjente variabler | Manuelt | Ollama | ~800 tokens/dokument |
| Helse-sjekk-rapport (ukentlig systemstatus) | Ingen AI | Ollama | Ny oppgave |
| Oversettelse av korte leverandørtekster (NO→EN) | Manuelt eller Claude.ai | Ollama (qwen2.5 er sterk på oversettelse) | ~1 000 tokens/tekst |

---

### TIER 3 — Ingen AI nødvendig (erstattes med script eller er allerede script)

| Oppgave | Begrunnelse |
|---------|-------------|
| Vault-filantall og statistikk | Ren bash: `find | wc -l` ✅ allerede implementert |
| Git-sync av vault | Ren bash + cron ✅ allerede implementert |
| Supabase heartbeat-ping | Ren curl ✅ allerede implementert |
| Fil-routing (kjente typer) | Regex-basert ✅ allerede implementert i `auto-route.sh` |
| Datoformatering og filnavn-generering | Ren bash ✅ |
| Supabase-data til rapport (tall-formatering) | Python ✅ allerede i `daily-report.sh` |
| Heartbeat-sjekk for scripts | Timestamp-sammenligning ✅ allerede implementert |

---

## Phase 2 — Hybrid-arkitektur

```
┌─────────────────────────────────────────────────────┐
│                   OPPGAVE MOTTAS                    │
└──────────────────────┬──────────────────────────────┘
                       │
            ┌──────────▼──────────┐
            │   ai-router.sh      │
            │   task_type input   │
            └──────┬──────────────┘
                   │
        ┌──────────┴──────────────┐
        │                         │
   TIER 1                    TIER 2 / 3
        │                         │
        ▼                         ▼
┌──────────────┐         ┌────────────────────┐
│  Claude API  │         │  Ollama (Mac mini) │
│  sonnet-4-6  │         │  qwen2.5:14b       │
│  ~$3/MTok in │         │  $0.00/token       │
│  ~$15/MTok ut│         │  ~2W elektrisitet  │
└──────┬───────┘         └────────┬───────────┘
       │                          │
       └──────────┬───────────────┘
                  │
       ┌──────────▼──────────┐
       │  Resultat til vault  │
       │  Logg routing-valg   │
       └─────────────────────┘
```

### Lokal stack (Mac mini M4 16GB)

**Anbefalt modell: `qwen2.5:14b`**

| Kriterium | Verdi |
|-----------|-------|
| RAM-bruk | ~8.7GB (Q4_K_M kvantisering) |
| Tilgjengelig RAM (16GB - 5GB OS) | ~11GB — passer med god margin |
| Styrker | Sterk på norsk, utmerket strukturert output, god kodegenerering |
| Hastighet (M4 Metal) | ~35 tokens/sekund — 800-token respons ≈ 23 sekunder |
| Alternativ (raskere, mindre) | `llama3.2:3b` — 2GB, 120 tok/s, for enkel klassifisering |

**Triggere:**
- Cron (launchd) for planlagte oppgaver
- Filendring (launchd `WatchPaths`) for auto-routing fallback
- Direkte kall fra andre scripts

**Månedskostnad lokal:** kr 0 (+ ~kr 15-20 elektrisitet/mnd, M4 bruker ~6W idle/20W belastet)

### Sky-stack (Anthropic API + Claude.ai)

**Gjenstående Claude-oppgaver:**

| Oppgave | Frekvens | Est. tokens/kjøring | Est. kr/mnd |
|---------|----------|---------------------|-------------|
| Månedlig vinn/tap-analyse | 1×/mnd | 8 000 in + 2 000 ut | ~kr 0.35 |
| Ukentlig mønsteranalyse | 4×/mnd | 4 000 in + 800 ut | ~kr 0.60 |
| Leverandør-onboarding | ~2×/mnd | 2 000 in + 500 ut | ~kr 0.10 |
| **Subtotal API-automatisering** | | | **~kr 1/mnd** |
| Claude Pro/Max (Claude Code) | Daglig | Inkludert i plan | **kr 220–2 200/mnd** |

**→ Den dominerende kostnaden er abonnementet, ikke API-kallene.**

**Ved 10× bruk (automatisering):**
| Oppgave | Tokens/mnd 10× | Kr/mnd |
|---------|----------------|--------|
| Alle Tier 1 automatiseringsoppgaver | ~300 000 tokens | ~kr 50 |
| Claude Code (10× mer utvikling) | Inkludert i plan | uendret |

---

## Routing-logikk

Se `scripts/ai-router.sh` for implementasjon.

**Beslutningstreet:**

```
task_type ==?

  "analysis"          → CLAUDE  (forretningsvurdering)
  "win_loss"          → CLAUDE  (strategisk, historisk kontekst)
  "customer_email"    → CLAUDE  (relasjonsbygging)
  "architecture"      → CLAUDE  (kodekonsekvenser)
  "code_review"       → CLAUDE  (kvalitet og sikkerhet)
  "onboarding"        → CLAUDE  (første inntrykk)
  "contract"          → CLAUDE  (juridisk risiko)

  "daily_summary"     → LOCAL   (strukturert data → narrativ)
  "changelog"         → LOCAL   (git diff → tekst)
  "log_summary"       → LOCAL   (feillogg → forklaring)
  "translation_short" → LOCAL   (NO/EN under 500 ord)
  "template_fill"     → LOCAL   (kjente variabler → dokument)
  "classification"    → LOCAL   (fil/tekst → kategori)
  "health_check"      → LOCAL   (system-tall → status-setning)

  *                   → CLAUDE  (ukjent type: sikker fallback)
```

---

## Anbefaling

**I dag** er det rette AI-stacken for Global Distribution AS enkelt: Claude Pro-abonnement for alt utviklingsarbeid og forretningsmessig tenkning, kombinert med Ollama (qwen2.5:14b) på Mac mini for interne automatiseringsoppgaver der dataene ikke skal forlate systemet. API-automatiseringen koster under kr 5 per måned og trenger ingen optimalisering. Det viktigste arkitekturvalget er ikke lokal vs. sky — det er å etablere tier-klassifiseringen som vane nå, slik at vi ikke bruker Claude til å telle filer og ikke bruker bash til å skrive kundebrev.

**Om 12 måneder**, ved planlagt vekst (50+ leverandører, 100+ inquiries/mnd, Martin og Jessica som daglige brukere av portalen), vil stacken se slik ut: Ollama håndterer all intern dataprosessering (klassifisering, oppsummeringer, oversettelse av leverandørtekster, onboarding-e-poster), Claude API håndterer all analyse, strategi og kundevendt kommunikasjon, og abonnementet er fortsatt Claude Pro med mindre intensiv daglig Claude Code-bruk tilsier Max. Den lokale modellen blir gradvis mer kritisk — ikke fordi den er billigst, men fordi kjøperdata, ordredata og leverandørkontrakter etter hvert inneholder informasjon som ikke tilhører Anthropics servere.

---

## Sist oppdatert
2026-03-16 — Initial hybrid-arkitektur, M4 Mac mini 16GB
