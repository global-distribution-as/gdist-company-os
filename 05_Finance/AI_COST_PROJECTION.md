# AI Cost Projection — Global Distribution AS

> Oppdatert: 2026-03-16
> Analyse av nåværende og fremtidig AI-kostnader, inkludert hybrid lokal/sky-arkitektur.

---

## Nåværende tilstand

### Hva koster AI i dag?

| Komponent | Plan | Månedspris | Hva dekkes |
|-----------|------|-----------|------------|
| **Claude Pro** (estimert) | Pro $20/mnd | ~kr 220 | Claude.ai, Claude Code for utvikling |
| **Anthropic API** (automatisering) | Pay-as-you-go | ~kr 1 | `monthly-analysis.sh`, `weekly-analysis.sh` |
| **TOTAL** | | **~kr 221/mnd** | |

> **Viktig:** 99,5% av AI-kostnaden er abonnementet (Pro/Max), ikke API-kallene.
> API-automatiseringen koster knapt noe — det er *utviklingstiden med Claude Code* som er kostnadsdriveren.

### Token-forbruk per dag (automatisering)

| Script | Frekvens | Input tokens | Output tokens | $/kjøring |
|--------|----------|-------------|---------------|-----------|
| `monthly-analysis.sh` | 1×/mnd | ~8 000 | ~2 000 | ~$0.054 |
| `weekly-analysis.sh` | 4×/mnd | ~4 000 | ~800 | ~$0.024 |
| `supplier_onboard.py` | ~2×/mnd | ~2 000 | ~500 | ~$0.014 |
| **Subtotal API/mnd** | | ~32 000 | ~8 000 | **~$0.10** |

Priser: Claude Sonnet 4.6: $3.00/MTok input, $15.00/MTok output

---

## Etter hybrid-oppsett (lokal Ollama + sky Claude)

### Oppgaver som flyttes til lokal Ollama

| Oppgave | Fra | Til | Token-besparelse/mnd |
|---------|-----|-----|----------------------|
| Daglig rapport-narrativ | (ikke eksisterende) | Ollama gratis | 0 (ny oppgave) |
| Changelog-generering | Manuelt/Claude.ai | Ollama | ~4 000 tokens/mnd |
| Feillogg-oppsummering | Ingen AI | Ollama | Ny oppgave |
| Fil-klassifisering (tvilstilfeller) | `auto-route.sh` | Ollama fallback | ~1 000 tokens/mnd |
| Korte oversettelser (NO→EN) | Claude.ai | Ollama | ~2 000 tokens/mnd |
| **Sum flyttes** | | | **~7 000 tokens/mnd** |

### API-besparelse etter hybridisering

| | Nåværende | Etter hybrid | Besparelse |
|---|---------|-------------|------------|
| API-tokens/mnd | ~40 000 | ~33 000 | ~7 000 tokens |
| API-kostnad/mnd | ~$0.10 | ~$0.08 | **$0.02/mnd (~kr 0.20)** |
| Abonnement (Pro) | ~kr 220 | ~kr 220 | kr 0 |
| **Total** | **~kr 221** | **~kr 220** | **kr 1/mnd** |

### Ærlig konklusjon

> Ollama sparer nær ingenting på API-kostnader ved dagens skala.
> Den reelle verdien av lokal AI er **personvern, latens, og gratis skalering** — ikke kronesparing nå.

---

## Mac mini break-even-analyse

| Scenario | Beregning | Break-even |
|----------|-----------|------------|
| **AI-kostnad alene** (kr 1/mnd spart) | kr 8 500 ÷ kr 1/mnd | **708 år** — aldri |
| **Automatisering (6t/mnd spart × 1 500 kr/t Daniel)** | kr 8 500 ÷ kr 9 000/mnd | **~1 måned** |
| **Inkl. Martin (400 kr/t, 2t/mnd spart)** | kr 8 500 ÷ kr 9 800/mnd | **~1 måned** |

**Mac mini ble ikke kjøpt for AI-besparelser. Den betjener seg innen 1 måned på tid alene.**
AI-lokalt er en bonus, ikke begrunnelsen.

---

## Ved 10× bruk

### Ville Claude Pro ($20/mnd) holde?

| Bruksscenario | Tokens/mnd | API-kostnad | Abonnement |
|---------------|------------|-------------|------------|
| 10× automatisering | ~400 000 | ~$1.20/mnd | Pro $20 |
| 10× utvikling (Claude Code) | Inkludert i Pro | — | **Pro holder** |

**Konklusjon:** Claude Pro holder lenge etter 10×. Max ($200/mnd) trenger vi bare ved:
- Daglig intens Claude Code-bruk (>2 timer/dag)
- Store kontekstvinduer per sesjon (>200K tokens)
- Parallelle Claude Code-instanser

### Når er lokal AI kritisk?

| Terskel | Handling |
|---------|---------|
| >50 leverandører onboardet | Lokal Ollama for onboarding-e-poster |
| >500 inquiries/mnd | Lokal Ollama for første klassifisering |
| Claude Pro utbrent daglig | Flytt Tier 2-oppgaver til lokal |
| GDPR-krav om datasolidaritet | Lokalt for alle kunderelaterte data |

### Worst case: Max-plan nødvendig?

Ja, hvis:
- Daniel + Martin begge bruker Claude Code daglig
- Systemet behandler 1 000+ Supabase-rows/dag med AI-analyse
- Estimert: ved ~200 aktive leverandører + 50 ordre/mnd

**Tidslinje:** ikke før 12–18 måneder etter lansering ved normal vekst.

---

## Sammendrag

| Metrikk | Nå | 6 måneder | 12 måneder |
|---------|-----|-----------|------------|
| Månedlig AI-kostnad | kr 221 | kr 221–400 | kr 400–2 200 |
| API-automatiseringskostnad | kr 1 | kr 5 | kr 20 |
| Lokal AI-verdi | Lav (spare tid) | Middels (personvern) | Høy (kritisk volum) |
| Anbefalt plan | Claude Pro | Claude Pro | Pro → vurder Max |

---

_Neste gjennomgang: 2026-06-16 (3 måneder etter lansering, med faktisk bruksdata)_
