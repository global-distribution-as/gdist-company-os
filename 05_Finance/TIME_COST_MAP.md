---
type: rapport
updated: 2026-03-16
source: CFO tidsaudit
---

# Tidskostkart — Global Distribution AS

> Formel: (minutter per oppgave ÷ 60) × timepris × oppgaver per måned = månedlig tidskostnad
>
> Timepris: Daniel 1 500 NOK · Martin 400 NOK · Jessica 350 NOK

---

## Oppgave-for-oppgave tidsmåling

### Jessica: Håndtere én inquiry fra start til tilbud sendt

| Steg | Tid |
|------|-----|
| Lese og logge inquiry i Obsidian | 5 min |
| Kvalifisere (3 spørsmål) | 10 min |
| Sende første svar | 10 min |
| Vente på og innhente pris fra Martin | 10 min *(venting, ikke aktiv)* |
| Bygge tilbud (manuell kalkulator / mal) | 20 min |
| Sende tilbud og logge det | 5 min |
| Sette oppfølgingspåminnelse manuelt | 5 min |
| **Total aktiv tid per inquiry** | **55 min** |

**Antakelse:** 10 inquiries/uke = 40/mnd
**Månedlig kostnad:** (55/60) × 350 × 40 = **kr 12 833/mnd**

---

### Martin: Logge én transaksjon i transactions.csv

| Steg | Tid |
|------|-----|
| Åpne fil og finne riktig format | 3 min |
| Slå opp valutakurs (Norges Bank) | 4 min |
| Skrive inn data korrekt | 5 min |
| Dobbelsjekke og lagre | 2 min |
| **Total per transaksjon** | **14 min** |

**Antakelse:** 40 transaksjoner/mnd (10 ordre × 4 linjer: innkjøp, frakt, toll, salg)
**Månedlig kostnad:** (14/60) × 400 × 40 = **kr 3 733/mnd**

---

### Martin: Onboarde én ny leverandør

| Steg | Tid |
|------|-----|
| Første kontakt og innhenting av info | 20 min |
| Opprette Obsidian-fil fra mal | 5 min |
| Kjøre onboarding-script (halvautomatisk) | 15 min |
| Rydde opp produktdata (bilder, beskrivelser) | 45 min |
| Koordinere med Daniel for godkjenning | 20 min |
| Sende velkomstepost og bekrefte tilgang | 10 min |
| **Total per leverandør** | **115 min** |

**Antakelse:** 4 leverandører/mnd (aggressiv lansering)
**Månedlig kostnad:** (115/60) × 400 × 4 = **kr 3 067/mnd**

---

### Daniel: Deploye én fix

| Steg | Tid |
|------|-----|
| Diagnose og reprodusere feilen | 20 min |
| Fikse koden | 45 min |
| Teste lokalt | 15 min |
| Deploy og verifisere prod | 10 min |
| **Total per deploy** | **90 min** |

**Antakelse:** 8 fixes/mnd (2/uke ved aktiv utvikling)
**Månedlig kostnad:** (90/60) × 1 500 × 8 = **kr 18 000/mnd**

---

### Daniel: Godkjenne ett produkt i plattformen

| Steg | Tid |
|------|-----|
| Logge inn på admin-dashboard | 2 min |
| Gjennomgå bilde, navn, pris, kategori | 5 min |
| Godkjenne eller returnere med merknad | 3 min |
| **Total per produkt** | **10 min** |

**Antakelse:** 20 produkter/mnd (5 leverandører × 4 produkter)
**Månedlig kostnad:** (10/60) × 1 500 × 20 = **kr 5 000/mnd**

---

### Martin: Ukentlig finansavstemmning

| Steg | Tid |
|------|-----|
| Oppdatere transactions.csv med ukens bevegelser | 25 min |
| Sjekke payables-receivables | 15 min |
| Oppdatere P&L-estimat | 15 min |
| **Total per uke** | **55 min** |

**Antakelse:** 4 ganger/mnd
**Månedlig kostnad:** (55/60) × 400 × 4 = **kr 1 467/mnd**

---

## Rangert etter månedlig tidskostnad

| # | Oppgave | Person | Kostnad/mnd | Automatiserbar? |
|---|---------|--------|-------------|-----------------|
| 1 | Inquiry → tilbud | Jessica | **kr 12 833** | Delvis — prisoppslag kan automatiseres |
| 2 | Deploye fix | Daniel | **kr 18 000** | Nei — men *antall* fixes kan reduseres med bedre testing |
| 3 | Produktgodkjenning | Daniel | **kr 5 000** | Ja — auto-godkjenn ved komplett produktdata |
| 4 | Transaksjon-logging | Martin | **kr 3 733** | Ja — sync fra Supabase til CSV |
| 5 | Leverandør-onboarding | Martin | **kr 3 067** | Delvis — allerede halvautomatisert |
| 6 | Finansavstemmning | Martin | **kr 1 467** | Delvis — auto-aggregering |
| | **TOTAL** | | **~kr 44 100/mnd** | |

---

## Viktigste funn

**Daniel er den dyreste ressursen (1 500 NOK/t) og er flaskehals for:**
- Produktgodkjenning (5 000 NOK/mnd for noe som kan automatiseres)
- Deploy-sykluser (18 000 NOK/mnd — reduseres med CI/CD og bedre testdekning)

**Jessicas inquiry-arbeid er den største operasjonelle tidskostnaden:**
- 55 min per inquiry er for høyt
- 20 min skyldes mangel på verktøy for prisoppslag → løses med `quote-assistant.sh`
- Mål: ned til 25 min per inquiry = halvering av kostnad

→ Se [[05_Finance/COST_MAP]] for pengekostnader
→ Se [[09_Tech/BACKLOG]] for tekniske tiltak
