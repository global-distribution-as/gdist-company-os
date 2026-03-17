# Stresstest — Global Distribution AS

> Gjennomført: 2026-03-17
> Formål: Identifisere sviktpunkter og implementere preventive tiltak.

---

## Scenario 1: Daniel er utilgjengelig i 2 uker

**Forutsetning:** Daniel reiser, er syk, eller er utkoblet uten varsling.

### Hva stopper umiddelbart

| Blokkert oppgave | Årsak | Konsekvens |
|-----------------|-------|------------|
| Nye leverandørkontoer | Krever Supabase-tilgang (kun Daniel) | Ny leverandør kan ikke onboardes |
| Ordre > 50 000 NOK | Krever Daniels godkjenning | Stor ordre settes på vent |
| Tilbud > $5 000 USD | Krever Daniels godkjenning | Store buyers venter |
| Tekniske feil i portal | Kun Daniel kan deploye fikser | Feil kan forbli ufikset |
| Valutakurs-oppdatering | Manuell eller ikke satt opp | Quotes baseres på utdatert kurs |

### Hva fortsetter uten Daniel

- Martin: daglig drift, leverandørkontakt, transaksjonslogging
- Jessica: inquiry-mottak, tilbud under $5 000, oppfølging
- Keepalive-cron: holder DB i live (forutsetter at den er satt opp)

### Preventive tiltak implementert

1. **Delegasjonsprotokoll** — legg til i MARTIN_PLAYBOOK: "Dersom Daniel er utilgjengelig > 2 dager, send liste over blokkerte saker til [backup-kontakt]."
2. **Supabase keepalive SOP** — automatiserer det viktigste tekniske vedlikeholdet uten Daniel
3. **Pre-godkjente marginer** — Martin kan bruke standard 20 % margin for ordre ≤ 50 000 NOK uten å spørre

### Gjenstående risiko (krever ytterligere tiltak)

- **Leverandør-onboarding** er 100 % blokkert uten Daniel. Løsning langsiktig: Martin lærer Supabase-dashboardet for manuell brukeropprettelse, eller edge function bygges.
- **Teknisk produksjon** er 100 % blokkert. Løsning: Daniel dokumenterer deploy-prosedyre i en SOP og gir Martin lesetilgang til Vercel.

---

## Scenario 2: Jessica slutter eller er utilgjengelig permanent

**Forutsetning:** Jessica slutter, blir alvorlig syk, eller forholdet avsluttes.

### Hva vi mister

| Tap | Konsekvens |
|----|------------|
| WeChat-tilgang til kinesiske buyers | All etablert kontakt er utilgjengelig |
| Buyer-relasjoner og tillit | Buyers kjenner Jessica, ikke Global Distribution |
| Kulturell kompetanse (CN kommunikasjon) | Feil tone/timing er vanlig feil for europeere |
| Uformell kontekst (preferanser, status per buyer) | Ikke dokumentert noe sted |

### Preventive tiltak implementert

1. **Jessica-coverage SOP opprettet** — prosedyre for kortsiktig fravær
2. **Løpende kontekst-logging** — Jessica logger buyer-status i inquiry-filer ved avslutning av hver samtale
3. **WeChat-tilgang** — Daniel sørger for tilgang til forretnings-relaterte samtaler (avtales med Jessica)

### Gjenstående risiko

- Den største risikoen er at **buyers er lojale til Jessica, ikke selskapet**. Dersom hun slutter brått, mister vi kjøperkontakt som ikke kan erstattes med dokumentasjon.
- **Langsiktig mitigering:** Introduser Martin eller Daniel i buyer-relasjoner gradvis ved å CC dem på e-post og delta i videomøter. Bygg relasjonen til selskapet, ikke til én person.
- **Platform-side:** Buyers bør logge inn på jessicabrands.com slik at relasjonen er til plattformen, ikke til en e-postadresse.

---

## Scenario 3: 10× inquiries i uke én

**Forutsetning:** Markedsføring, viral spredning, eller sesongtopp sender 10× normalt volum.

### Kapasitet per person

| Person | Nåværende kapasitet | 10× kapasitet |
|--------|---------------------|---------------|
| Jessica | ~5 inquiries/uke | 50 inquiries/uke — **umulig alene** |
| Martin | Ordre-støtte, ikke primær inquiry | Uendret kapasitet |
| Daniel | Godkjenner, ikke operativ | Flaskehals ved mange > $5 000 |

### Hva som bryter først

1. **Jessicas tid** — 24-timers responstid kan ikke holdes
2. **Supabase Free tier bandwidth** — 10× trafikk mot image CDN kan nå 2GB-grensen
3. **Daniel-godkjenning** — hvis mange store ordre kommer inn, stopper flyten
4. **Quote-generator** — ingen rate-limiting, mange samtidige brukere kan gi DB-belastning

### Preventive tiltak implementert

1. **Vercel ignoreCommand** — bygger kun ved faktiske kodeendringer, sparer build-minutter
2. **Supabase bandwidth-tracking** — se `09_Tech/COSTS.md` for grenser og mitigering

### Tiltak ved faktisk 10× scenario

1. **Umiddelbar triaging** — Jessica prioriterer order-size og buyer-seriousness (se JESSICA_PLAYBOOK steg 2)
2. **Automatisk respons** — sett opp e-post autoresponder: "We've received your inquiry and will respond within 72 hours."
3. **Utvid svartid** — informer buyers om 72 timer i stedet for 24-timers SLA
4. **Daniel tar store saker** — alle inquiries > $10 000 USD håndteres direkte av Daniel

### Gjenstående risiko

- Ingen køsystem for inquiries — alt er manuelt. Ved høyt volum kan saker falle mellom stoler.
- **Langsiktig:** Supabase Pro ($25/mnd) ved 5 000 NOK/mnd inntekt, Cloudflare foran storage.

---

## Oppsummering: Mest kritiske enkeltpunkt-for-svikt

| Risiko | Sannsynlighet | Konsekvens | Mitigert? |
|--------|---------------|------------|-----------|
| Supabase DB pause | Høy (7 dager inaktivitet) | Platform ned | Delvis (SOP skrevet, cron ikke satt opp) |
| Jessica slutter | Lav–Middels | Tap av alle buyer-relasjoner | Delvis (SOP, logging) |
| Daniel utilgjengelig | Lav | Blokkert onboarding og teknisk | Delvis (SOP, Martin-opplæring) |
| config.env FYLL_INN | Eksisterende | All automatisering blokkert | Ikke (SOP skrevet, handling gjenstår) |
| 10× volum | Lav | Kapasitetsbrudd | Delvis (triaging-prosedyre) |
