# Business Health — Global Distribution AS

> Martin oppdaterer dette hver mandag. Daniel gjennomgår ved månedsslutt.
> Sist oppdatert: YYYY-MM-DD

---

## 5 ukentlige nøkkeltall

| # | Metrikk | Mål | Nåværende | Status |
|---|---------|-----|-----------|--------|
| 1 | Aktive ordrer (pågående) | ≥ 1 | — | — |
| 2 | Åpne inquiries uten tilbud | ≤ 3 | — | — |
| 3 | Tilbud sendt siste 7 dager | ≥ 1 | — | — |
| 4 | Dager siden siste inntekt | ≤ 30 | — | — |
| 5 | Bruttomarginen på siste avsluttede ordre | ≥ 15 % | — | — |

**Fyll inn "Nåværende" og "Status" (✅ / ⚠️ / 🔴) hver mandag.**

---

## 3 advarselssignaler

Disse skal reageres på umiddelbart — ikke vente til neste uke.

| Signal | Grense | Tiltak |
|--------|--------|--------|
| **Supabase keepalive feiler** | Én dag med "ADVARSEL" i log | Åpne dashboard.supabase.com → Resume project |
| **Ingen ny inquiry på 14+ dager** | 14 dager uten ny kontakt | Daniel vurderer om outreach/markedsføring trengs |
| **Leverandør svarer ikke på 48t** | Svar uteblir | Martin eskalerer til Daniel — ikke send bekreftelse til buyer uten svar |

---

## Månedlig sjekkliste

Gjøres av Martin første mandag i måneden (se SOP):

- [ ] `05_Finance/transactions.csv` er komplett for forrige måned
- [ ] Månedsfil `05_Finance/YYYY-MM_maaned.md` er opprettet
- [ ] Oppsummering sendt til Daniel
- [ ] Daniel har bekreftet margin og godkjent månedsstatus
- [ ] Siste P&L-dato oppdatert nedenfor: **YYYY-MM-DD**

---

## Kvartalsvis spørsmål (Daniel)

> *Stilles første mandag i januar, april, juli, oktober.*

**Er selskapsstrukturen fortsatt riktig?**

Vurder:
- Er Jessica sin rolle og kompensasjon i tråd med volum og ansvar?
- Er Martins kapasitet og kunnskap tilstrekkelig for nåværende ordreflyt?
- Er det nye leverandørmarkeder vi burde utforske?
- Er det noe i driften som koster uforholdsmessig mye tid vs. verdi?
- Hvilken enkelt endring ville hatt størst positiv effekt neste kvartal?

---

## Teknisk helse (Daniel oppdaterer ved endringer)

| Komponent | Status | Sist sjekket |
|-----------|--------|--------------|
| Supabase DB | ✅ Aktiv | — |
| Vercel deploy | ✅ OK | — |
| Keepalive cron | — Ikke satt opp | Se SOP |
| config.env | — Ufullstendig | Se SOP |
| Migrasjon 20260317000002 | — Ikke pushet til prod | Kjør `supabase db diff` → `db push` |
| Exchange rate cron | — Ikke satt opp | Se ADR |

---

## Historikk

| Måned | Inntekt NOK | Margin % | Antall ordre | Notat |
|-------|------------|----------|--------------|-------|
| 2026-03 | — | — | 0 | Oppstart |
