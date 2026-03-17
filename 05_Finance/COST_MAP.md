---
type: rapport
updated: 2026-03-16
source: CFO audit
---

# Kostkart — Global Distribution AS

> Detaljert tjenesteoversikt: [[09_Tech/COSTS]] (oppdatert 2026-03-16)
> Dette dokumentet legger til: 100× projeksjoner, flaskehalser og kapitaleffektivitets-vurdering.

---

## Nåværende månedlig kostnad: ~9 NOK

| Tjeneste | Plan | Kostnad nå | Grense vi bryr oss om |
|----------|------|-----------|----------------------|
| Vercel | Hobby (gratis) | kr 0 | 100 GB båndbredde/mnd |
| Supabase | Free | kr 0 | 500 MB DB · 1 GB storage · 50K MAU · **pause etter 7 dager inaktivitet** |
| Resend | Free | kr 0 | 3 000 e-poster/mnd |
| Anthropic API | Pay-per-use | ~kr 0,30 | Ingen — skalerer lineært |
| GitHub | Free | kr 0 | 2 000 Actions-min/mnd |
| Domener (gdist.no) | Årsavgift | ~kr 8 | — |
| Tripletex | Ikke aktivert | kr 0 | Planlagt ~500 NOK/mnd |
| **TOTAL** | | **~kr 9/mnd** | |

---

## Projeksjoner

| Tjeneste | 1× nå | 10× bruk | 100× bruk | Flaskehals |
|----------|--------|----------|-----------|-----------|
| Vercel | kr 0 | kr 0 | kr 0–200 | Trenger Pro kun ved >100 GB/mnd eller team-features |
| Supabase | kr 0 | kr 0–260 | kr 260–520 | Storage: 1 GB fri → betalt ved ~50 leverandører med bilder |
| Resend | kr 0 | kr 0 | kr 200 | 3K fri → betalt ved >100 daily inquiries |
| Anthropic | kr 0,30 | kr 3 | kr 30 | Negligibelt — skalerer rent |
| Tripletex | kr 0 | kr 500 | kr 1 000+ | Nødvendig fra dag 1 etter bankkonto |
| **TOTAL** | **~kr 9** | **~kr 760** | **~kr 1 750** | |

**Konklusjon:** Kostnadsstrukturen er utmerket. Vi kan vokse til 10× uten å åpne lommeboken. Eneste reelle kostnad ved lansering er Tripletex (~500 NOK/mnd).

---

## Tidslinjer for oppgradering

```
Nå             Lansering      10 leverandører    50 leverandører   100+ leverandører
|              |              |                  |                 |
kr 9/mnd       kr 500         kr 760             kr 1 000          kr 1 750
(kun domene)   (+Tripletex)   (+Supabase Pro     (storage limit    (Vercel Pro?)
                               hvis bilder)       nådd)
```

---

## Kritisk risiko: Supabase-pause

**Status: UMITIGERT** ⚠️

Gratis Supabase pauser etter 7 dager uten databaseaktivitet. Hvis Mac mini ikke er konfigurert og operasjonell FØR lansering, kan databasen pause og plattformen gå ned.

**Fix (5 minutter):** Legg til i Daniels crontab inntil Mac mini er operasjonell:
```zsh
0 9 * * * curl -sf "https://orsjlztclkiqntxznnyo.supabase.co/rest/v1/profiles?select=id&limit=1" \
  -H "apikey: $(cat ~/.claude-env | grep SUPABASE_ANON_KEY | cut -d= -f2)" > /dev/null
```

---

## Skjulte kostnader (ikke i regnskapet)

| Kostnad | Type | Estimat/mnd |
|---------|------|-------------|
| Daniels utviklertid | Alternativkostnad | 1 500 NOK/time |
| Martins manuell finans-logging | Tidskostnad | ~3 200 NOK/mnd (se TIME_COST_MAP) |
| Jessicas manuelle quote-bygging | Tidskostnad | ~9 300 NOK/mnd (se TIME_COST_MAP) |
| **Total skjult tidskostnad** | | **~14 000 NOK/mnd** |

> De skjulte tidskostnadene er 1 500× større enn de faktiske pengekostnadene. Det er her vi skal spare.

---

→ Se [[05_Finance/TIME_COST_MAP]] for full tidsanalyse
→ Se [[09_Tech/COSTS]] for detaljert teknisk kostnadsoversikt
