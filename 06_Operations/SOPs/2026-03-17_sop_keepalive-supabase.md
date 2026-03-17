---
name: SOP — Supabase Keepalive (Forhindre DB-pause)
type: sop
created: 2026-03-17
priority: KRITISK
---

# SOP: Supabase Keepalive — Forhindre automatisk databasepause

## Bakgrunn

Supabase Free tier pauser databasen automatisk etter **7 dager uten aktivitet**.
Når DB er pauset: alle API-kall feiler, portalen er nede, buyers og leverandører ser feil.
Gjenoppstart tar 1–2 minutter og krever manuell handling i Supabase-dashboardet.

**Dette er ikke akseptabelt i produksjon.** En ukentlig keepalive-ping forhindrer pausen helt.

---

## Løsning: Daglig keepalive via Mac mini cron

### Steg 1 — Verifiser at `config.env` er fylt ut

```bash
cat ~/Documents/GlobalDistribution/scripts/config.env | grep SUPABASE
```

Du skal se:
```
SUPABASE_URL=https://orsjlztclkiqntxznnyo.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

Hvis verdiene er `FYLL_INN`, se `SOPs/2026-03-17_sop_config-env.md` først.

### Steg 2 — Opprett keepalive-script

Opprett filen `~/Documents/GlobalDistribution/scripts/keepalive-supabase.sh`:

```bash
#!/bin/bash
# keepalive-supabase.sh
# Pinger Supabase en gang om dagen for å forhindre at Free tier-databasen pauses.
# Cron: kjøres daglig kl 08:00.

set -e
source ~/Documents/GlobalDistribution/scripts/config.env

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  "$SUPABASE_URL/rest/v1/settings?select=key&limit=1")

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ "$RESPONSE" = "200" ]; then
  echo "$TIMESTAMP — Supabase keepalive OK (HTTP $RESPONSE)" >> ~/Documents/GlobalDistribution/08_Daily/keepalive.log
else
  echo "$TIMESTAMP — ADVARSEL: Supabase keepalive feilet (HTTP $RESPONSE)" >> ~/Documents/GlobalDistribution/08_Daily/keepalive.log
fi
```

```bash
chmod +x ~/Documents/GlobalDistribution/scripts/keepalive-supabase.sh
```

### Steg 3 — Legg til i crontab

```bash
crontab -e
```

Legg til:
```
0 8 * * * /bin/bash ~/Documents/GlobalDistribution/scripts/keepalive-supabase.sh
```

### Steg 4 — Test manuelt

```bash
~/Documents/GlobalDistribution/scripts/keepalive-supabase.sh
cat ~/Documents/GlobalDistribution/08_Daily/keepalive.log
```

Du skal se: `YYYY-MM-DD HH:MM:SS — Supabase keepalive OK (HTTP 200)`

---

## Alternativ: Supabase Pro ($25/mnd)

Pro-tier deaktiverer automatisk pause permanent. Vurder dette når månedlig omsetning
overstiger 5 000 NOK — da er $25/mnd en neglisjerbar kostnad mot nedetidsrisiko.

---

## Feilsøking

| Symptom | Tiltak |
|---------|--------|
| HTTP 503 i loggen | DB er pauset — åpne dashboard.supabase.com, klikk "Resume project" |
| HTTP 401 | `SUPABASE_ANON_KEY` er feil eller utløpt |
| Script kjører ikke | Sjekk `crontab -l` — bekreft at linjen finnes |
| Ingen loggfil | `08_Daily/`-mappen mangler — kjør `mkdir -p ~/Documents/GlobalDistribution/08_Daily/` |

---

## Eier

**Daniel** setter opp. **Martin** sjekker loggen ukentlig (se MARTIN_PLAYBOOK → morgenrutine).
