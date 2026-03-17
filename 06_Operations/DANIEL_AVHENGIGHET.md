---
title: Daniel-avhengighet — Analyse og plan
type: operational-analysis
updated: 2026-03-16
owner: Daniel
purpose: Oversikt over alle prosesser som per i dag krever Daniel. Mål: Martin kan drifte alene i én uke.
---

# Daniel-avhengighet — Hva krever deg, og hva kan vi fikse?

> **Bruk dette dokumentet til:** prioritere hva som bygges og dokumenteres for å gjøre Martin selvgående.
> Oppdater kolonnen "Status" etter hvert som ting løses.

---

## Oversikt

| # | Prosess | Hvorfor Daniel nå | Løsning | Estimat | Status |
|---|---------|------------------|---------|---------|--------|
| D-01 | Opprette leverandørbrukere | AdminSettings-invite er ødelagt | Bygg P0-2 (edge function) | 4t | 🔴 Blokkert |
| D-02 | Godkjenne produkter fra leverandør | Ingen i portalen kan gjøre dette unntatt admin | Gi Martin Admin-tilgang i portalen | 30 min | 🟡 Enkelt |
| D-03 | Godkjenne ordre > 50 000 NOK | Forretningsregel — ikke teknisk | Dokumentert nedenfor | — | ✅ Dokumentert |
| D-04 | Opprette ordre i systemet | Ingen ordre-UI i portalen | Bygg P0-1 (AdminOrders) | 8t | 🔴 Blokkert |
| D-05 | Eskalere forfalte betalinger | Ingen rutine for Martin | Se FEIL_OG_LØSNINGER punkt 6 | — | ✅ Dokumentert |
| D-06 | Fikse git-konflikter i vault | Martin ikke komfortabel med git | Se FEIL_OG_LØSNINGER punkt 7 | — | ✅ Dokumentert |
| D-07 | Godkjenne NDA-mal med advokat | Juridisk — ikke teknisk | Én handling fra Daniel | 1t | 🟡 Venter på Daniel |
| D-08 | Exchange-rate-oppdateringer | Hardkodet i kode | Bygg P1-2 (settings-tabell) | 3t | 🔴 Teknisk gjeld |
| D-09 | Generere proforma-faktura | Ingen UI, bare mal | Bygg P1-3 (fakturagenerator) | 8t | 🔴 Teknisk gjeld |
| D-10 | Varsle ved ny inquiry | Ingen notifikasjon | Bygg P1-1 (e-postvarsel) | 2t | 🔴 Teknisk gjeld |
| D-11 | Approve / avslå nye leverandørprofiler | Martin sender navn, Daniel bestemmer | Forretningsregel — beholder denne | — | ✅ Bevisst valg |

---

## Hva Martin kan gjøre i dag uten Daniel

Disse prosessene er fullt dokumentert og Martin kan gjøre dem alene:

- **Svare på buyer-henvendelser** → `_Templates/buyer-inquiry-reply.md` + SOP `2026-03-16_sop_behandle-buyer-inquiry.md`
- **Sende ordrebekreftelse til leverandør** → `_Templates/ordrebekreftelse-leverandor.md`
- **Sende proforma-faktura til buyer** → `_Templates/proforma-invoice.md`
- **Logge transaksjoner** → `05_Finance/transactions.csv` + instruksjoner i MARTIN_PLAYBOOK
- **Følge opp forsinkede leveranser** → FEIL_OG_LØSNINGER punkt 2
- **Følge opp forfalte betalinger (t.o.m. dag 10)** → FEIL_OG_LØSNINGER punkt 6
- **Løse git-konflikter i vault** → FEIL_OG_LØSNINGER punkt 7
- **Kontakte leverandør for status** → ingen særskilt SOP nødvendig
- **Oppdatere leverandørnotater** → malen i `_Templates/Leverandor-mal.md`

---

## Detaljert gjennomgang per prosess

### D-01 — Opprette leverandørbrukere 🔴
**Nå:** Martin ber Daniel via WhatsApp. Daniel gjør det manuelt i Supabase (5 min).
**Dokumentasjon:** `06_Operations/SOPs/2026-03-16_sop_opprett-leverandor-bruker.md`
**Løsning:** Implementer P0-2 — Supabase Auth Admin API edge function. Når den er bygget kan Martin gjøre dette selv direkte i AdminSettings.
**Risiko ved fravær:** Martin kan ikke onboarde nye leverandører uten Daniel. Maksimalt 1 ny leverandør per uke kan vente — men ved oppstartsperiode er dette en flaskehals.

### D-02 — Godkjenne produkter fra leverandør 🟡
**Nå:** Kun Daniel har admin-tilgang.
**Løsning:** Gi Martin admin-bruker i portalen (gdist.no/admin). Dette er én handling, tar 30 minutter.
**Viktig:** Martin skal ikke ha tilgang til QuoteGenerator-marginer. Vurder om "Supplier Manager"-rollen i portalen dekker behovet uten å eksponere sensitiv prisinformasjon.

### D-03 — Godkjenne ordre > 50 000 NOK ✅
**Bevisst forretningsregel.** Martin skal alltid kontakte Daniel før store ordre bekreftes.
**Ved Daniels fravær:** Daniel kan svare på WhatsApp innen rimelig tid. Ved lengre fravær: sett eksplisitt delegasjonsgrense i forkant.

### D-04 — Opprette ordre i systemet 🔴
**Nå:** Det finnes ingen ordre-UI. Systemet har en "Bestillinger"-side, men det er en stub uten funksjonalitet.
**Workaround:** Ordre dokumenteres i vault (`04_Orders/Active/ORD-XXXX.md`) og `05_Finance/transactions.csv`.
**Løsning:** Implementer P0-1 — AdminOrders med create/edit-funksjonalitet.
**Risiko:** Fullstendig operasjonell. Vault-dokumentasjon er tilstrekkelig workaround for oppstart.

### D-07 — Godkjenne NDA-mal med advokat 🟡
**Malen finnes:** `_Templates/nda-supplier.md`
**Handling kreves:** Daniel kontakter advokat, sender malen til gjennomgang, oppdaterer status-feltet fra `⚠️ KREVER GJENNOMGANG` til `GODKJENT [DATO]`.
**Inntil godkjent:** Send ikke NDA til leverandører uten Daniels eksplisitte OK på den aktuelle leverandøren.

### D-08 — Exchange-rate-oppdateringer 🔴
**Nå:** NOK/USD = 0.088, NOK/CNY = 0.65 hardkodet i kildekode. Feil kurs → feil tilbud.
**Løsning:** P1-2 — legg kursene i `settings`-tabellen i Supabase. Admin kan da oppdatere uten deploy.
**Risiko:** Hver dag med gammelt kurs er en potensiell feilpriset ordre.

---

## Hva som gjenstår for at Martin kan drifte alene i 1 uke

Minimumskrav (rekkefølge):

1. **D-02: Gi Martin admin-tilgang** (30 min, én gang) — Martin kan da godkjenne produkter selv
2. **D-01: Bygg P0-2** (4t koding) — Martin kan opprette leverandørbrukere selv
3. **D-04: Bygg P0-1** (8t koding) — Martin kan registrere ordre i systemet
4. **D-07: Advokatgjennomgang av NDA** (1t Daniels tid) — ferdig NDA-mal

Disse fire tiltakene dekker 90 % av Daniel-avhengigheten i normal drift.
Resterende 10 % (store ordre, eskalering, systemfeil) skal alltid involvere Daniel — det er en bevisst forretningsregel, ikke en teknisk mangel.

---

> Se `09_Tech/BACKLOG.md` for full prioritert oversikt med tidsestimater.
