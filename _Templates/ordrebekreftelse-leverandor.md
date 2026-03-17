---
type: email-template
use: Send to supplier after buyer has confirmed and deposit is received (or at order confirmation)
language: Norwegian (use English version for suppliers who prefer English)
---

# Ordrebekreftelse til leverandør

> Send dette til leverandøren etter at kjøper har bekreftet og depositum er mottatt.
> Aldri bekreft ordre til leverandør uten at kjøper har bekreftet skriftlig.

---

**Emne:** Ordrebekreftelse — [PRODUKT] — [ANTALL] enheter — ORD-[YEAR]-[NR]

---

Hei [KONTAKTPERSON HOS LEVERANDØR],

Vi bekrefter herved følgende ordre fra Global Distribution AS:

**Ordrenummer:** ORD-[YEAR]-[NR]
**Dato:** [YYYY-MM-DD]

---

**PRODUKTDETALJER:**

| Produkt | Art.nr | Antall | Enhetspris (NOK) | Totalt (NOK) |
|---------|--------|--------|-----------------|-------------|
| [PRODUKTNAVN] | [SKU/ART.NR] | [ANTALL] | [PRIS] | [TOTAL] |

**Totalt:** NOK [TOTALBELØP]

---

**LEVERINGSINFORMASJON:**

- **Leveringsadresse:** [Global Distribution AS lager / Sandefjord / annen adresse]
- **Ønsket levering:** [DATO ELLER UKE]
- **Fraktsett av:** ☐ Oss  ☐ Dere  ☐ Avtales separat
- **Merknad:** [eventuelle spesielle krav til pakking, merking, etc.]

---

**BETALINGSBETINGELSER:**

[Sett inn avtalte betalingsbetingelser, f.eks.:]
- 30 dager netto fra fakturadato
- 50% forskudd, 50% ved levering
- [Annet etter avtale]

---

**VIKTIG — Vennligst bekreft:**

1. At du kan levere som angitt ovenfor
2. Forventet leveringsdato
3. Eventuell ordrebekreftelse / ordrenummer fra din side

Svar gjerne på denne e-posten eller kontakt meg direkte.

Med vennlig hilsen,

Martin [ETTERNAVN]
Global Distribution AS
martin@globaldistribution.no | [TELEFON]

---

## English version

**Subject:** Purchase Order Confirmation — [PRODUCT] — [QTY] units — ORD-[YEAR]-[NR]

---

Dear [SUPPLIER CONTACT NAME],

Please find below our Purchase Order confirmation:

**Order number:** ORD-[YEAR]-[NR]
**Date:** [YYYY-MM-DD]

**Order details:**

| Product | SKU | Qty | Unit Price (NOK) | Total (NOK) |
|---------|-----|-----|-----------------|-------------|
| [PRODUCT NAME] | [SKU] | [QTY] | [PRICE] | [TOTAL] |

**Delivery address:** [ADDRESS]
**Required delivery date:** [DATE]

**Payment terms:** [TERMS AS AGREED]

Please confirm:
1. You can fulfill this order as specified
2. Your expected delivery date
3. Your order confirmation number (if applicable)

Best regards,
Martin [SURNAME]
Global Distribution AS

---

**INTERNAL CHECKLIST (delete before sending):**
- [ ] Buyer has confirmed the order in writing (email or WeChat)
- [ ] Deposit received or explicitly waived by Daniel
- [ ] Order note created in `04_Orders/ORD-[YEAR]-[NR].md`
- [ ] Status updated to "Bekreftet" / "Confirmed" in order note
- [ ] Copy of this email saved in order note under "Kommunikasjonslogg"
- [ ] Set reminder for delivery date (–7 days: check status with supplier)
