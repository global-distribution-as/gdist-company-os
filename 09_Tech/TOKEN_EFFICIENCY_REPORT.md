---
type: rapport
created: 2026-03-16
author: Token efficiency audit
---

# Token Efficiency Report — Global Distribution AS

> Formål: dokumentere token-kostnader per sesjon og besparelser etter optimalisering.

---

## Metode

Estimat: ~1.4 tokens per ord (engelsk/norsk blanding). Sesjon-overhead = tokens lastet ved sesjonstart som Claude ikke kan unngå å lese.

---

## Før optimalisering

| Fil | Linjer | Ord (est.) | Tokens (est.) | Lastes |
|-----|--------|-----------|---------------|--------|
| `~/.claude/CLAUDE.md` | 71 | 620 | 870 | Hver sesjon |
| `aurora-trade-hub/.claude/CLAUDE.md` | 112 | 1 080 | 1 510 | Hver repo-sesjon |
| `apps/gdist/src/auth/CLAUDE.md` | 2 | 28 | 39 | Ved auth-arbeid |
| `supabase/migrations/CLAUDE.md` | 3 | 38 | 53 | Ved migrasjon-arbeid |
| **Total** | **188** | **1 766** | **2 472** | |

### Største avfall identifisert

| Problem | Tokens sløst | Årsak |
|---------|-------------|-------|
| SYSTEM STATE-seksjonen (aurora-trade-hub CLAUDE.md) | ~280 | Historisk statusrapport, ikke regler. Eies av git-historikk. |
| ARCHITECTURE RULES verbose "Prevents:"-avsnitt | ~420 | 10 regler med 2–3-linjers forklaring. Én linje er nok. |
| Duplikat "Respond in Norwegian" | ~12 | Stod i QUICK REFERENCE (linje 8) og Communication style |
| META — Å skrive regler (8 linjer) | ~80 | Prosess-instruksjon Claude ikke trenger i full form |
| Active git context (6 linjer) | ~60 | Utdatert branch/status-info. Hentes fra `git status` ved behov. |
| auth/CLAUDE.md (duplikat) | ~39 | Fullstendig duplikat av regler i hovedfil |
| **Total avfall** | **~891** | |

---

## Etter optimalisering

| Fil | Linjer | Ord (est.) | Tokens (est.) | Endring |
|-----|--------|-----------|---------------|---------|
| `~/.claude/CLAUDE.md` | 51 | 440 | 616 | −254 tokens |
| `aurora-trade-hub/.claude/CLAUDE.md` | 79 | 680 | 952 | −558 tokens |
| `apps/gdist/src/auth/CLAUDE.md` | slettet | 0 | 0 | −39 tokens |
| `supabase/migrations/CLAUDE.md` | 1 | 32 | 45 | −8 tokens |
| **Total** | **131** | **1 152** | **1 613** | **−859 tokens** |

**Reduksjon: 35% færre tokens lastet per sesjon ved repo-arbeid.**

---

## Slash commands — token-besparelse per bruk

| Kommando | Erstattet prompt (ord est.) | Tokens spart per bruk |
|----------|-----------------------------|----------------------|
| `/daily` | ~200 ord | ~270 tokens |
| `/deploy portal` | ~150 ord | ~200 tokens |
| `/new-supplier [navn]` | ~300 ord | ~410 tokens |
| `/new-inquiry [buyer]` | ~250 ord | ~340 tokens |
| `/audit` | ~400 ord | ~550 tokens |
| `/learn` | ~180 ord | ~245 tokens |

---

## Månedlig besparelse

**Antakelse:** 5 sesjoner per dag, 30 dager = 150 sesjoner/mnd.
Alle sesjoner antas å åpne aurora-trade-hub (repo-sesjon).

### CLAUDE.md-overhead besparelse
- 859 tokens spart × 150 sesjoner = **128 850 tokens/mnd**

### Slash command-besparelse (konservativt estimat)
- `/daily` 1×/dag × 150 dager × 270 = 40 500 tokens
- `/new-supplier` 2×/uke × 8 uker × 410 = 6 560 tokens
- `/new-inquiry` 5×/uke × 4 uker × 340 = 6 800 tokens
- `/audit` 1×/uke × 4 uker × 550 = 2 200 tokens
- **Slash commands total: ~56 060 tokens/mnd**

### Totalt estimert besparelse
**~184 910 tokens/mnd** ≈ **185K input tokens spart**

---

## Plan-kostnader og anbefaling

| Plan | Månedspris | Token-grense (estimert) | Anbefaling |
|------|-----------|-------------------------|-----------|
| Pro | $20 | ~10M tokens/mnd (5× daglig limit) | Tilstrekkelig for pre-launch fase |
| Max 5× | $100 | ~50M tokens/mnd | Vurder ved aktiv utvikling (>5 sesjoner/dag) |
| Max 20× | $200 | ~200M tokens/mnd | Ikke nødvendig nå |

**Anbefaling: Pro-plan er tilstrekkelig** i nåværende fase (pre-launch, 1–2 utviklere).
Oppgrader til Max 5× når:
- Sessions per dag > 5 konsekvent
- Kontekst-komprimering skjer mer enn 2× per sesjon
- Lange kode-gjennomganger (hele repo-leser) er daglig rutine

---

## De 5 viktigste token-sparevanene

Se `00_Dashboard/00_START_HERE.md` for daglig påminnelse.

1. **Bruk `/compact` ved 20+ meldinger** — halverer context-overhead for resten av sesjonen
2. **Bruk `/clear` mellom urelaterte oppgaver** — starter friskt, ingen context-lekkasje
3. **Bruk slash commands** (`/daily`, `/audit`, `/new-supplier`) — erstatter 150–400-ords prompts med ett ord
4. **Referer filer med `@`** i stedet for å lime inn innhold — Claude leser kun det relevante
5. **Én feature per sesjon** — kortere sesjoner = lavere kumulativ token-bruk

---

→ Logg neste revisjon her med dato når vi treffer Max 5×-grensen.
