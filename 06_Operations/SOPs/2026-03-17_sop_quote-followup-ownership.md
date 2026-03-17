---
name: SOP — Tilbudseierskap og oppfølgingsansvar
type: sop
created: 2026-03-17
---

# SOP: Hvem eier et tilbud — og hvem følger opp?

## Problem denne SOPen løser

Tidligere var det uklart hvem som hadde ansvar for å følge opp tilbud som ikke fikk svar.
Resultatet: tilbud ble liggende uten oppfølging, og deals gikk tapt av glemsel.

---

## Regel: Den som sender tilbudet, eier det

Den som sender et tilbud til en buyer er ansvarlig for oppfølging frem til:
- Buyer bekrefter eller avslår, **eller**
- Tilbudet er markert som "Ingen respons" (etter 5 virkedager), **eller**
- Ansvaret er eksplisitt overført (se nedenfor)

**Standardsituasjon:** Jessica sender tilbudet → Jessica eier oppfølgingen.

---

## Tidslinjer

| Hendelse | Ansvar | Tidsfrist |
|----------|--------|-----------|
| Tilbud sendt | Jessica | — |
| Ingen svar etter 48 timer | Jessica sender én oppfølging | 48t etter sending |
| Fremdeles ingen svar | Jessica markerer "Ingen respons" og avslutter | 5 virkedager etter tilbud |
| Buyer ber om mer tid | Jessica noterer dato og setter ny oppfølging | Den datoen buyer oppga |
| Tilbud > $5 000 USD | Eskalér til Martin eller Daniel før sending | Før sending |

---

## Overføring av eierskap

Dersom Jessica er utilgjengelig (ferie, syk, annet):

1. Jessica varsler Martin på WhatsApp: "ORD/INQ-XXX — følg opp innen [dato]"
2. Martin overtar oppfølging og logger hvem som har ansvaret i inquiry-filen:
   ```
   Oppfølgingsansvar overført til: Martin
   Dato: YYYY-MM-DD
   Årsak: Jessica utilgjengelig
   ```
3. Når Jessica er tilbake: Martin briefer henne og tilbakefører ansvaret

---

## Ukentlig gjennomgang (Martin — mandag morgen)

Under ukentlig rutine: åpne `04_Orders/Quotes/` og se etter tilbud med status `sent`
som er eldre enn 2 dager uten aktivitet. Kontakt Jessica og bekreft at hun er på saken.

Tilbud eldre enn 10 dager uten aktivitet → flagg til Daniel.

---

## Loggkrav

Inquiry-filen (`00_INBOX/` eller `04_Orders/`) skal til enhver tid vise:
- Dato tilbud ble sendt
- Dato oppfølging ble sendt (hvis aktuelt)
- Nåværende status: `sent` / `followed_up` / `confirmed` / `no_response` / `closed`
- Hvem som har oppfølgingsansvaret

---

## Eier

**Jessica** (daglig oppfølging). **Martin** (ukentlig kontroll). **Daniel** (eskalering).
