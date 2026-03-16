---
title: SOP — Håndtere ordre (inquiry → levering)
type: SOP
audience: Martin, Jessica
updated: 2026-03-16
---

# SOP: Håndtere ordre

**Mål:** Ryddig flyt fra buyer-forespørsel til betalt og levert vare — ingen overraskelser.

---

## Steg 1 — Motta og bekreft forespørsel

- [ ] Opprett ordre-notat i `04_Orders/` med: buyer, produkt, volum, ønsket leveringsdato
- [ ] Sjekk tilgjengelighet hos leverandør (e-post eller portal)
- [ ] Svar buyer med estimert pris og leveringstid — **ikke bekreft ennå**

## Steg 2 — Innhent tilbud fra leverandør

- [ ] Send formell forespørsel (RFQ) til leverandør
- [ ] Inkluder: produkt, antall, leveringsadresse, ønsket dato
- [ ] Frist for svar: 48 timer (minner etter 24 timer hvis ikke svar)

## Steg 3 — Pris og godkjenning

- [ ] Regn ut salgspris: leverandørpris + frakt + margin (se `05_Finance/margin-kalkulator.md`)
- [ ] Hvis ordre > 50 000 kr: Daniel godkjenner pris før tilbud sendes
- [ ] Send formelt tilbud (Quotation) til buyer — mal: `_Templates/quotation.md`

## Steg 4 — Ordrebekreftelse

- [ ] Buyer bekrefter skriftlig (e-post holder)
- [ ] Utsted faktura eller proforma (avhengig av betalingsvilkår)
- [ ] Bekreft ordre hos leverandør skriftlig
- [ ] Oppdater ordre-status: `Bekreftet`

## Steg 5 — Oppfølging og levering

- [ ] Følg opp produksjon/forsendelse mot avtalt dato
- [ ] Motta sporingsinfo — videresend til buyer
- [ ] Ved forsinkelse: informer buyer umiddelbart med ny dato
- [ ] Oppdater ordre-status: `Levert` ved bekreftelse fra buyer

## Steg 6 — Lukk orden

- [ ] Bekreft betaling mottatt i `05_Finance/`
- [ ] Be om tilbakemelding fra buyer (kort e-post)
- [ ] Arkiver ordre-notat med status: `Fullført`

---

**Viktige regler**
- Aldri bekreft overfor buyer uten skriftlig bekreftelse fra leverandør
- Alle priser til buyer er inkl. frakt med mindre annet er avtalt
- Dokumenter alle avvik (forsinkelser, feil, klager) i ordre-notatet
