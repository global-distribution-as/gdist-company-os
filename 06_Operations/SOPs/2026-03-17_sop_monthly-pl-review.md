---
name: SOP — Månedlig P&L-gjennomgang
type: sop
created: 2026-03-17
---

# SOP: Månedlig P&L-gjennomgang

## Når

Første mandag i måneden. Estimert tidsbruk: 30 minutter.

## Eier

**Martin** gjennomfører. **Daniel** godkjenner og tar beslutninger.

---

## Steg 1 — Oppdater transactions.csv (Martin, 10 min)

Åpne `05_Finance/transactions.csv` og sjekk at alle transaksjoner fra forrige måned er logget:

- Alle ordrebetalinger inn (fra buyers)
- Alle leverandørbetalinger ut
- Alle fraktkostnader
- Abonnementer og faste kostnader (Vercel, Supabase, etc.)

**Kontroller at CSV-filen har korrekte kolonner:**
```
Dato | ORD-nummer | Inntekt/Utgift | Kategori | Motpart | NOK | Valuta | Beløp | Valuta-kurs | Notat
```

---

## Steg 2 — Lag månedlig oppsummering (Martin, 10 min)

Opprett fil: `05_Finance/YYYY-MM_maaned.md` fra malen nedenfor.

```markdown
# P&L — [Måned] [År]

## Inntekter
| ORD-nummer | Buyer | Produkt | Beløp NOK | Beløp USD |
|------------|-------|---------|-----------|-----------|
| | | | | |
**Total inntekt:** X NOK

## Kostnader
| Kategori | Motpart | Beløp NOK |
|----------|---------|-----------|
| Varekjøp | | |
| Frakt | | |
| Toll | | |
| Abonnementer | | |
**Total kostnad:** X NOK

## Resultat
Bruttoresultat: X NOK
Margin: X %

## Aktive ordre ved månedsslutt
- [Antall] ordre totalt
- [Beløp] NOK i pipeline

## Merknad
[Hva skjedde denne måneden? Unntakssaker, forsinkelser, nye leverandører?]
```

---

## Steg 3 — Send til Daniel (Martin, 2 min)

Lim inn oppsummeringen som WhatsApp-melding til Daniel. Daniel bekrefter og svarer
med eventuelle spørsmål eller beslutninger innen 24 timer.

---

## Steg 4 — Daniel godkjenner og oppdaterer forecast (Daniel, 10 min)

Daniel sjekker:
- Er marginen over 15 %? (Advarsel under 15 % — se BUSINESS_HEALTH.md)
- Er det noen ubetalte fakturaer eldre enn 30 dager?
- Er det behov for å justere valutakurser i Supabase `settings`-tabellen?
- Oppdater `00_Dashboard/BUSINESS_HEALTH.md` → "Siste P&L-dato"

---

## Terskler og eskalering

| Situasjon | Tiltak |
|-----------|--------|
| Margin < 15 % | Daniel gjennomgår prisstrategien |
| Ingen inntekt i måneden | Undersøk pipeline — er det nok aktive leads? |
| Kostnader > 50 % av inntekt | Gjennomgå fraktkostnader og leverandørpriser |
| Ubetalt faktura > 30 dager | Daniel kontakter buyer direkte |
