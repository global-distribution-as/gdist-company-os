# Martin — Din arbeidsbok

_Alt du trenger for å drifte Global Distribution dag for dag._

---

## Morgenrutine (15 min — gjør dette først)

1. **Åpne [[00_Dashboard/Dashboard]]** — oppdater dato øverst
2. **Sjekk e-post** — svar på det haster innen kl 10
3. **Sjekk nye inquiries** — se [[04_Orders/_Index]] og sjekk om Jessica har flagget noe
4. **Oppdater aktive ordre** — endre status hvis noe har skjedd siden i går
5. **Noter dagens neste steg** i dashboardets sjekkliste
6. **Sjekk `08_Daily/keepalive.log`** — bekreft at siste linje sier "OK". Ser du "ADVARSEL": åpne Supabase-dashboardet og klikk "Resume project"

---

## Ukentlig (gjør dette mandag morgen, 30 min)

- [ ] Kontakt hver aktive leverandør — kort statussjekk på pågående ordre
- [ ] Oppdater `05_Finance/transactions.csv` med alle bevegelser fra forrige uke
- [ ] Sjekk om det er noen forfalte betalinger (se dashboardet)
- [ ] Send ukesoppdatering til Daniel (2–3 setninger i WhatsApp holder)
- [ ] **Tilbudssjekk:** Åpne `04_Orders/Quotes/` — bekreft med Jessica at alle tilbud eldre enn 2 dager har blitt fulgt opp (se [[06_Operations/SOPs/2026-03-17_sop_quote-followup-ownership]])

---

## Ny leverandørkontakt — slik gjør du det

1. Opprett notat: `02_Suppliers/Prospects/Firmanavn.md` (kopier malen fra `_Templates/Leverandor-mal.md`)
2. Fyll inn: kontaktperson, e-post, produkter, betalingsbetingelser
3. Send intro-e-post — bekreft at de kan laste opp produkter på portalen
4. Når Daniel har godkjent → flytt notat til `02_Suppliers/Active/`
5. Send leverandøren login til portalen: **gdist.no**

> Aldri flytt leverandør til Active uten at Daniel har sagt OK.

---

## Ny ordre — slik gjør du det

1. Opprett ordre-notat: `04_Orders/Active/ORD-2026-NNN.md` (kopier malen)
2. Sjekk tilgjengelighet hos leverandør — send e-post, vent på bekreftelse
3. Regnestykket: leverandørpris + frakt + 20 % margin = vår pris (spør Daniel hvis usikker)
4. Hvis ordre > 50 000 NOK → Daniel godkjenner pris før du sender tilbud
5. Oppdater statusfeltene i ordre-notatet etter hvert skritt

---

## Ny transaksjon — slik logger du det

Åpne `05_Finance/transactions.csv` og legg til én linje:

```
Dato | ORD-nummer | Inntekt/Utgift | Kategori | Motpart | NOK | Valuta | Beløp | J/N | Notat
```

**Kategori:** Salg / Varekjøp / Frakt / Toll / Annet

Usikker på kategori? Bruk "Annet" og skriv notat. Daniel avklarer.

---

## Obsidian og vault-synkronisering

- Vault synkes automatisk til GitHub hvert 10. minutt
- Lagrer du en fil? Den er trygg.
- Ser du en konfliktmelding i terminalen? Se [[06_Operations/FEIL_OG_LØSNINGER]] → punkt 7

---

## Månedlig (første mandag i måneden, 30 min)

Se [[06_Operations/SOPs/2026-03-17_sop_monthly-pl-review]] for fullstendig prosedyre.

Kort:
1. Sjekk at alle transaksjoner fra forrige måned er logget i `05_Finance/transactions.csv`
2. Opprett månedsfil: `05_Finance/YYYY-MM_maaned.md` fra malen i SOPen
3. Send oppsummering til Daniel på WhatsApp

---

## Oppgaver som krever Daniel

Martin kan IKKE gjøre dette uten Daniel:
- Opprette ny leverandørkonto i portalen (teknisk, krever Supabase-tilgang)
- Godkjenne og sende ordre over 50 000 NOK
- Sende tilbud over $5 000 USD
- Endre priser eller marginer

Hvis disse blokkerer deg: send melding til Daniel med hva som trengs og vent på svar.
Ikke gjett og ikke omgå — feil pris er verre enn forsinkelse.

---

## Tommelfingerregler

- Svar leverandører innen **24 timer** (de er i Europa — tidssoner spiller liten rolle)
- Aldri bekreft overfor buyer uten skriftlig OK fra leverandør
- Alle priser til buyers er **inkl. frakt** med mindre annet er eksplisitt avtalt
- Liten tvil → prøv selv. Stor tvil → ring Daniel.
