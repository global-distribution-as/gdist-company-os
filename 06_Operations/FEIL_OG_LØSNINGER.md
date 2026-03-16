# Feil og løsninger — De 10 vanligste problemene

_Prøv løsningen selv først. Fungerer ingenting → ring Daniel._

---

### 1. Buyer svarer ikke etter at tilbud er sendt

**Vent:** 3 dager. Send én kort oppfølging: *"Bare en sjekk — har du fått tilbudet vårt?"*
**Etter 7 dager:** Marker inquiry som "Cold" i notatet. Ikke jag mer.
**Etter 30 dager:** Arkiver. Det er ikke din feil.

---

### 2. Leverandør overskrider leveringstiden

**Gjør straks:** Kontakt leverandør og få ny dato skriftlig.
**Informer buyer** umiddelbart — ikke vent. En ærlig beskjed redder relasjonen.
**Logg avviket** i ordre-notatet med dato og årsak.
**Hvis > 2 uker forsinkelse:** Flagg til Daniel — vi må vurdere kompensasjon.

---

### 3. Leverandør klarer ikke logge inn på portalen

**Sjekk 1:** Er de registrert med riktig e-postadresse? (Martin sjekker i Supabase)
**Sjekk 2:** Be dem bruke "Glemt passord" på innloggingssiden.
**Sjekk 3:** Hvis ingenting fungerer → Daniel fikser brukerkontoen (5 min).
Portal-URL: **web-platform-kappa-three.vercel.app**

---

### 4. Produkter vises ikke i katalogen etter opplasting

Produkter legges inn med status **"pending"** og må godkjennes av admin.
**Løsning:** Daniel logger inn på admin-dashboardet og godkjenner produktet.
Legg gjerne melding til Daniel: "Produkt fra [leverandør] venter på godkjenning."

---

### 5. Feil pris er sendt til buyer

**Ikke få panikk.** Send rettelse umiddelbart:
*"Beklager — vi sendte feil pris. Korrekt pris er [X]. Vi beklager forvirringen."*
**Dokumenter** hva som skjedde i ordre-notatet.
**Gi beskjed til Daniel** — han avgjør om vi holder den feilaktige prisen eller ikke.

---

### 6. Betaling er ikke mottatt ved forfall

**Dag 1 etter forfall:** Send høflig påminnelse per e-post/WeChat.
**Dag 5:** Send mer direkte påminnelse — nevn forfallsdatoen eksplisitt.
**Dag 10:** Flagg til Daniel. Han håndterer eskalering.
**Logg alt** i ordre-notatet og `05_Finance/payables-receivables.csv`.

---

### 7. Konflikt i Obsidian-vault (git-feil i terminalen)

Dette skjer hvis to maskiner har redigert samme fil.

```zsh
cd ~/Documents/GlobalDistribution
git status          # se hvilken fil som er i konflikt
```

Åpne den aktuelle filen. Finn linjene med `<<<<<<` og `>>>>>>`.
Behold den versjonen som er riktig, slett resten (inkl. markørene).

```zsh
git add .
git commit -m "vault: løs konflikt"
git push origin main
```

Usikker? Ring Daniel — han løser det på 5 minutter.

---

### 8. Daglig rapport kommer ikke på e-post

**Sjekk 1:** Er Mac mini-en slått på og koblet til nett?
**Sjekk 2:** `tail /tmp/gdist-daily-report.log` — ser du feilmeldinger?
**Sjekk 3:** Er `RESEND_API_KEY` korrekt i `scripts/config.env`?
**Midlertidig løsning:** Kjør manuelt: `zsh ~/Documents/GlobalDistribution/scripts/daily-report.sh`

---

### 9. Buyer kansellerer etter ordrebekreftelse

**Gjør straks:** Kontakt leverandør — kan bestillingen stoppes? (Kostnad?)
**Dokumenter** kanselleringen skriftlig fra buyer.
**Flagg umiddelbart til Daniel** — dette har potensielt økonomiske konsekvenser.
Avhengig av avtale kan buyer skylde oss avbestillingsgebyr.

---

### 10. Leverandør leverer feil varer eller feil mengde

**Ikke godta leveransen** uten å dokumentere avviket med bilder.
**Send avviksrapport til leverandør** skriftlig innen 24 timer etter mottak.
**Informer buyer** om statusen — ikke vent.
**Flagg til Daniel** — han avgjør om vi krever retting, erstatning eller prisreduksjon.

---

> **Generelt råd:** Hvis du ikke finner svaret her — prøv en gang til, deretter spør Daniel. Det er alltid bedre å spørre enn å gjette når penger er involvert.
