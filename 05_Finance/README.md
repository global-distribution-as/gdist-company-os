---
title: Finance — Slik bruker vi systemet
updated: 2026-03-16
---

# Finance — Manuelt regnskapssystem

> **Status:** Midlertidig manuelt system inntil bankkonto og regnskapsverktøy er på plass.
> Erstatt med Fiken/Tripletex når selskapet er operativt.

---

## Filer

| Fil | Hva den inneholder | Oppdateres |
|---|---|---|
| `transactions.csv` | Alle inn- og utbetalinger per ordre | Ved hver transaksjon |
| `payables-receivables.csv` | Hvem som skylder hva til hvem | Ved faktura sendt/mottatt og ved betaling |
| `Reports/YYYY-MM-PL.md` | Månedlig P&L-oppsummering | Løpende, oppsummeres ved månedsslutt |

---

## Slik registrerer du en ny transaksjon

Åpne `transactions.csv` og legg til en linje:

```
Dato, Ordre-ID, Type, Kategori, Motpart, Beloep_NOK, Valuta_Orig, Beloep_Orig, Betalt, Notat
```

**Type:** `Inntekt` eller `Utgift`

**Kategori (velg én):**
- `Salg` — betaling fra buyer
- `Varekjøp` — betaling til leverandør
- `Frakt` — fraktkostnad
- `Toll` — tollkostnader
- `Annet` — alt annet

**Betalt:** `J` (bekreftet betalt) eller `N` (utestående)

**Valutakurs:** Bruk dagskurs fra Norges Bank. Skriv alltid beløp i NOK + original valuta.

---

## Slik oppdaterer du payables/receivables

**Når faktura sendes til buyer:**
→ Legg til linje: Type = `Skylder oss`, Status = `Aapen`

**Når betaling mottas fra buyer:**
→ Endre Status til `Betalt`, legg til dato i Notat

**Når leverandør sender faktura:**
→ Legg til linje: Type = `Vi skylder`, Status = `Aapen`

**Når leverandør er betalt:**
→ Endre Status til `Betalt`

---

## Månedlig P&L — rutine

1. Kopier `Reports/2026-03-PL.md` → gi ny måned som navn
2. Summer inntekter fra `transactions.csv` for måneden
3. Summer utgifter fra `transactions.csv` for måneden
4. Kopier utestående fra `payables-receivables.csv`
5. Oppdater "Daniel privat utlegg" hvis relevant

---

## Viktige regler

- **Alle beløp i NOK** — noter original valuta i egne kolonner
- **Daniel-utlegg** spores separat i P&L-filen — han skal refunderes
- **Aldri slett rader** — endre heller Status eller legg til notat
- Usikker på kategori? Bruk `Annet` og skriv notat — Daniel avklarer
