---
updated: 2026-03-16
owner: Martin (oppdateres daglig)
---

# Global Distribution AS — Operasjonsdashboard

> Start her. Oppdater tabellene nedenfor hver morgen (5–10 min).
> Når du er ferdig med morgenrutinen: gå til din **Topp 3 i dag** og start på #1.

---

## ⚡ TOPP 3 I DAG

> Fyll inn hver morgen. Maks 3. Ingenting annet teller før disse er gjort.

| # | Oppgave | Frist | Status |
|---|---------|-------|--------|
| 1 | | | |
| 2 | | | |
| 3 | | | |

---

## 📦 AKTIVE ORDRE

> Oppdater status etter hver kontakt med leverandør eller buyer.
> Status: `Avventer bekreftelse` / `Bekreftet` / `Under produksjon` / `Sendt` / `Levert` / `Avsluttet`

| Ordre-nr | Produkt | Leverandør | Buyer | Beløp (NOK) | Status | Neste steg | Frist |
|----------|---------|------------|-------|-------------|--------|------------|-------|
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |

_Ingen aktive ordre enda. Legg til her når første ordre er bekreftet._

---

## 📬 ÅPNE HENVENDELSER (INQUIRIES)

> Mål: svar innen 24 timer. Følg opp etter 3 dager uten svar.
> Status: `Ny` / `Tilbud sendt` / `Følges opp` / `Kald` / `Vunnet` / `Tapt`

| Dato mottatt | Buyer | Produkt/Forespørsel | Kontakt | Status | Tilbud sendt | Neste oppfølging |
|-------------|-------|---------------------|---------|--------|-------------|-----------------|
| | | | | | | |
| | | | | | | |

_Se også: e-post innboks, WeChat, og portalen (gdist.no/admin/dashboard)_

---

## 💰 FORVENTEDE BETALINGER

> Hold dette oppdatert. En oversett betaling er en tapt likviditet.
> Status: `Venter` / `Mottatt` / `Forfalt` / `Eskalert`

| Ordre-nr | Fra/Til | Type | Beløp (NOK) | Forfallsdato | Status | Notat |
|----------|---------|------|-------------|-------------|--------|-------|
| | | Innbetaling fra buyer | | | | |
| | | Utbetaling til leverandør | | | | |

---

## 🔴 FORFALT / KREVER HANDLING I DAG

> Alt her skal håndteres **i dag**. Ingenting forblir her over natten.

| Hva | Hvem | Forfalt siden | Konsekvens hvis ikke gjort | Handling |
|-----|------|--------------|---------------------------|---------|
| | | | | |

---

## 📋 UKENTLIG SJEKKLISTE

> Gjør dette mandag morgen (30 min).

- [ ] Kontakt alle aktive leverandører — kort statusoppdatering på pågående ordre
- [ ] Oppdater `05_Finance/transactions.csv` med alle bevegelser siste uke
- [ ] Gå gjennom "Forventede betalinger"-tabellen — noen forfalt?
- [ ] Send ukesoppdatering til Daniel (2–3 setninger på WhatsApp holder)
- [ ] Rydd opp: arkiver ordre som er levert og bekreftet mottatt
- [ ] Se over "Åpne henvendelser" — noen som er kalde mer enn 30 dager? Arkiver.

---

## 🔗 HURTIGLENKER

| Hva | Lenke |
|-----|-------|
| Admin-portal | [gdist.no/admin/dashboard](https://gdist.no/admin/dashboard) |
| Leverandøroversikt | [[02_Suppliers/_Index]] |
| Kjøperoversikt | [[01_Buyers/_Index]] |
| Alle ordre | [[04_Orders/_Index]] |
| Finanslogg | [[05_Finance/transactions.csv]] |
| Forfalte betalinger | [[05_Finance/payables-receivables.csv]] |
| Maler (e-post, dokumenter) | [[_Templates/README]] |
| Martin-håndboken | [[06_Operations/MARTIN_PLAYBOOK]] |
| Feil og løsninger | [[06_Operations/FEIL_OG_LØSNINGER]] |
| Backlog (for Daniel) | [[09_Tech/BACKLOG]] |

---

## 📞 KONTAKTER — NØDSITUASJON

| Hvem | Kontakt | Når |
|------|---------|-----|
| Daniel | WhatsApp | Ordre > 50k NOK, juridiske spørsmål, brukerproblemer i systemet, betaling forfalt > 10 dager |
| Resend (e-post) | resend.com | Hvis leverandørinvitasjoner ikke sendes |
| Supabase | supabase.com → prosjekt `orsjlztclkiqntxznnyo` | Kun Daniel — ikke logg inn her uten å avtale med Daniel |

---

> **Husk:** Liten tvil → prøv selv. Stor tvil → ring Daniel.
> Dette dashboardet er din kilde til sannhet. Oppdateres det ikke, er det ubrukelig.

---

## ⚡ TOKEN-SPAREVANER (for Daniel — Claude Code)

> Disse fem vanene reduserer token-forbruk med ~35% per sesjon. Bruk dem.

1. **`/daily`** — én kommando for daglig status i stedet for å forklare konteksten på nytt
2. **`/compact`** ved 20+ meldinger — halverer context-overhead for resten av sesjonen
3. **`/clear`** når du bytter mellom urelaterte oppgaver — ingen context-lekkasje
4. **`@filnavn`** i stedet for å lime inn filinnhold — Claude leser kun det relevante
5. **Én feature per sesjon** — start ny sesjon for ny feature, ikke akkumuler context

_Slash commands tilgjengelig: `/daily` `/deploy` `/new-supplier` `/new-inquiry` `/audit` `/learn`_
