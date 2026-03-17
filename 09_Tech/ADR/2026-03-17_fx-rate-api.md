---
name: ADR — FX-kurs API (frankfurter.app)
type: adr
created: 2026-03-17
status: accepted
---

# ADR: Automatisk valutakurs-oppdatering via frankfurter.app

## Kontekst

Valutakursene NOK/USD og NOK/CNY er hardkodet i `quoteEngine.ts` og `SupplierUpload.tsx`.
Disse brukes til å beregne priser til buyers. Kurser som ikke oppdateres fører til at
quotes er feil — enten for høye (tapte salg) eller for lave (tapte marginer).

Migrasjon `20260317000002` opprettet en `settings`-tabell i Supabase med seed-verdier:
- `nok_usd_rate` = 0.088
- `nok_cny_rate` = 0.65

Men disse oppdateres ikke automatisk.

## Beslutning

**Bruk [frankfurter.app](https://www.frankfurter.app/) som FX-kilde.**

Frankfurter er et gratis, åpent API drevet av den europeiske sentralbanken (ECB).
Ingen API-nøkkel kreves. Oppdateres daglig på virkedager.

### Endepunkt

```
GET https://api.frankfurter.app/latest?from=NOK&to=USD,CNY
```

Eksempel-respons:
```json
{
  "base": "NOK",
  "rates": { "USD": 0.0882, "CNY": 0.6423 }
}
```

### Implementering

Et daglig cron-skript på Mac mini kaller API-et og oppdaterer `settings`-tabellen i Supabase:

```bash
#!/bin/bash
# update-fx-rates.sh
source ~/Documents/GlobalDistribution/scripts/config.env

RATES=$(curl -s "https://api.frankfurter.app/latest?from=NOK&to=USD,CNY")
USD=$(echo $RATES | python3 -c "import sys,json; print(json.load(sys.stdin)['rates']['USD'])")
CNY=$(echo $RATES | python3 -c "import sys,json; print(json.load(sys.stdin)['rates']['CNY'])")

# Oppdater Supabase settings
curl -s -X PATCH \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  "$SUPABASE_URL/rest/v1/settings?key=eq.nok_usd_rate" \
  -d "{\"value\": \"$USD\"}"

curl -s -X PATCH \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  "$SUPABASE_URL/rest/v1/settings?key=eq.nok_cny_rate" \
  -d "{\"value\": \"$CNY\"}"

echo "$(date): FX oppdatert — USD=$USD, CNY=$CNY" >> ~/Documents/GlobalDistribution/08_Daily/fx-update.log
```

Cron: `0 9 * * 1-5` (hverdager kl 09:00 — etter ECB-oppdatering)

### Frontend

`QuoteGenerator` og `SupplierUpload` henter kurs fra `settings`-tabellen:

```typescript
const { data } = await supabase
  .from('settings')
  .select('key, value')
  .in('key', ['nok_usd_rate', 'nok_cny_rate']);
```

Hardkodede verdier i koden er nå fallback-kommentarer, ikke aktive verdier.

## Konsekvenser

**Positivt:**
- Kurs oppdateres automatisk uten manuell inngripen
- Gratis — ingen API-kostnad
- Enkel feilsøking: se `08_Daily/fx-update.log`

**Negativt / risiko:**
- frankfurter.app kan gå ned (ECB-data er uoffisiell tredjepart)
- Fallback: bruk siste verdi i `settings`-tabellen (ikke null ut kursen)
- Løsning: ved HTTP-feil, skriv til loggen og behold eksisterende verdi

## Alternativer vurdert

| API | Kostnad | Kilde | Beslutning |
|-----|---------|-------|-----------|
| frankfurter.app | Gratis | ECB | **Valgt** |
| exchangerate-api.com | Gratis (1500 req/mnd) / $10/mnd | Kommersiell | Unødvendig |
| Norges Bank API | Gratis | Autoritativ | Kompleks XML-format |
| Open Exchange Rates | $12/mnd | Kommersiell | For dyrt i oppstartsfase |
