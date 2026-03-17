---
name: SOP — Fullfør config.env (Mac mini automatisering)
type: sop
created: 2026-03-17
priority: BLOKKERER AUTOMATISERING
---

# SOP: Fullfør config.env

## Status

`~/Documents/GlobalDistribution/scripts/config.env` inneholder plassholderverdier (`FYLL_INN`)
som blokkerer alle automatiseringsskript på Mac mini. Ingen skript virker før dette er gjort.

---

## Hva må fylles inn

Åpne filen: `~/Documents/GlobalDistribution/scripts/config.env`

### 1. Supabase

```
SUPABASE_URL=https://orsjlztclkiqntxznnyo.supabase.co
SUPABASE_ANON_KEY=[hent fra Supabase dashboard]
SUPABASE_SERVICE_ROLE_KEY=[hent fra Supabase dashboard — kun til server-scripts]
```

**Hent nøkler:** https://app.supabase.com → prosjekt `orsjlztclkiqntxznnyo` → Settings → API

> **Viktig:** `SERVICE_ROLE_KEY` omgår RLS. Bruk kun i server-side scripts, aldri i frontend.

### 2. Resend (e-post)

```
RESEND_API_KEY=[hent fra resend.com → API Keys]
RESEND_FROM_EMAIL=noreply@gdist.no
```

Dersom Resend-konto ikke er opprettet:
1. Gå til resend.com → opprett konto med din gdist.no-epost
2. Verifiser domenet gdist.no (legg til DNS TXT-record)
3. Opprett API-nøkkel med "Full access"

### 3. Anthropic (Claude API — for daglig rapport)

```
ANTHROPIC_API_KEY=[hent fra console.anthropic.com → API Keys]
```

Hent fra: https://console.anthropic.com → API Keys → Create new key

---

## Etter utfylling — test hvert skript

```bash
# Test Supabase-tilkobling
~/Documents/GlobalDistribution/scripts/keepalive-supabase.sh

# Test daglig rapport
~/Documents/GlobalDistribution/scripts/daily-report.sh

# Sjekk at ingen FYLL_INN gjenstår
grep -r "FYLL_INN" ~/Documents/GlobalDistribution/scripts/config.env
```

---

## Sikkerhet

- `config.env` skal aldri committes til Git
- Sjekk at `.gitignore` i scripts-mappen inkluderer `config.env`
- Ta backup av filen på en sikker, kryptert plass (f.eks. 1Password)

---

## Eier

**Daniel** fyller inn verdiene. **Martin** verifiserer at skriptene kjører etter utfylling.
