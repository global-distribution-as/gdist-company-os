# Global Distribution AS — Business Structure Brief

*Én side. Hva dette selskapet er, hvordan det fungerer, og hva som er sant.*

---

## Hva er dette

Global Distribution AS er et norsk B2B-handelshus som kobler norske leverandører med asiatiske
kjøpere. Selskapet eier ingen produkter. Det eier relasjoner, tillit og logistisk kompetanse.

Marginene hentes fra informasjonsasymmetri: norske leverandører kjenner ikke asiatiske kjøpere,
asiatiske kjøpere kjenner ikke norske leverandører. Global Distribution er broen.

---

## Hvem gjør hva

**Daniel (eier og arkitekt)** — strategi, teknologi, leverandørgodkjenning, store salgsbeslutninger.
Han er flaskehalsen for alt som krever tilgang eller autoritet.

**Martin (daglig drift)** — leverandørkontakt, ordreoppfølging, transaksjonslogging, ukentlig rapportering.
Han er selskapet når Daniel ikke er der.

**Jessica (buyer relations)** — all direkte kommunikasjon med asiatiske kjøpere. Hun bærer relasjonskapitalen
på buyer-siden. Dersom hun forsvinner, forsvinner buyer-tilgangen.

---

## Teknologien

To separate portaler på én monorepo:
- **gdist.no** — leverandørportal (NOR)
- **jessicabrands.com** — kjøperportal (Asia)

De to verdenene skal **aldri se hverandre**. Norske priser er ikke asiatiske priser.
Leverandøridentitet er ikke kjøperens sak.

Supabase håndterer data, autentisering og tilgangskontroll. Vercel serverer frontendsene.
Mac mini kjører automatisering (daglig rapport, valutakurs, keepalive-cron).

---

## Hva er sant (ukensert)

1. **Selskapet er sårbart for tap av nøkkelpersoner.** Jessica = buyer-relasjoner. Daniel = teknologi og autoritet. Begge er enkeltpunkter for svikt.

2. **Automatiseringen fungerer ikke ennå.** `config.env` er ikke fylt ut. Ingen cron kjører. Mac mini gjør ingenting automatisk.

3. **Databasen vil pause.** Supabase Free tier pauser etter 7 dager inaktivitet. Keepalive-cron er ikke satt opp. Plattformen kan gå ned uten forvarsel.

4. **Produktopplasting har vært stille feil siden starten.** Migrasjon 20260317000002 fikser dette, men er ikke pushet til produksjon ennå.

5. **Marginer og valutakurser er hardkodet.** De oppdateres ikke automatisk. Feil kurs = feil pris.

---

## Hva selskapet trenger å gjøre de neste 30 dagene

| Prioritet | Hva | Hvem |
|-----------|-----|------|
| 1 | Fyll ut `config.env` og sett opp keepalive-cron | Daniel |
| 2 | Push migrasjon 20260317000002 til produksjon | Daniel |
| 3 | Jessica begynner å logge buyer-kontekst løpende | Jessica |
| 4 | Martin verifiserer at keepalive-loggen er OK daglig | Martin |
| 5 | Daniel introduserer seg selv i minst én buyer-relasjon | Daniel |

---

## Hva suksess ser ut som

Etter 6 måneder:
- Minst 3 gjentakende buyers med ordre > $2 000 per kvartal
- Keepalive og FX-oppdatering kjører automatisk uten manuell inngripen
- Martin kan håndtere en uke uten Daniel uten at noe stopper
- Alle tilbud følges opp systematisk — ingen leads går tapt av glemsel

---

*Oppdater dette dokumentet når selskapet endrer seg fundamentalt — ikke oftere.*
*Sist oppdatert: 2026-03-17*
