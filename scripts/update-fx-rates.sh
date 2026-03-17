#!/bin/bash
# =============================================================
# update-fx-rates.sh
# Henter NOK/USD og NOK/CNY fra frankfurter.app (ECB-data)
# og oppdaterer Supabase settings-tabellen.
#
# Cron: 0 9 * * 1-5 (hverdager kl 09:00 — etter ECB-oppdatering)
# Log:  $VAULT_DIR/08_Daily/fx-rates.log
# ADR:  vault/09_Tech/ADR/2026-03-17_fx-rate-api.md
# =============================================================

set -euo pipefail
source "$(dirname "$0")/config.env"

LOG_FILE="$VAULT_DIR/08_Daily/fx-rates.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
mkdir -p "$(dirname "$LOG_FILE")"

# Fetch rates from frankfurter.app (ECB data, free, no API key)
RESPONSE=$(curl -s --max-time 15 "https://api.frankfurter.app/latest?from=NOK&to=USD,CNY")

if [ -z "$RESPONSE" ] || echo "$RESPONSE" | grep -q "error"; then
  echo "$TIMESTAMP — FEIL: Kunne ikke hente FX-kurs. Beholder eksisterende verdier." >> "$LOG_FILE"
  exit 0
fi

USD=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['rates']['USD'])" 2>/dev/null)
CNY=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['rates']['CNY'])" 2>/dev/null)

if [ -z "$USD" ] || [ -z "$CNY" ]; then
  echo "$TIMESTAMP — FEIL: Parsing av FX-respons feilet. Beholder eksisterende verdier." >> "$LOG_FILE"
  exit 0
fi

SUPABASE_HEADERS=(
  -H "apikey: $SUPABASE_SERVICE_ROLE"
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE"
  -H "Content-Type: application/json"
  -H "Prefer: return=minimal"
)

# Update NOK/USD
USD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH \
  "${SUPABASE_HEADERS[@]}" \
  "$SUPABASE_URL/rest/v1/settings?key=eq.nok_usd_rate" \
  -d "{\"value\": \"$USD\", \"updated_at\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\"}")

# Update NOK/CNY
CNY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH \
  "${SUPABASE_HEADERS[@]}" \
  "$SUPABASE_URL/rest/v1/settings?key=eq.nok_cny_rate" \
  -d "{\"value\": \"$CNY\", \"updated_at\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\"}")

if [ "$USD_STATUS" = "204" ] && [ "$CNY_STATUS" = "204" ]; then
  echo "$TIMESTAMP — OK: NOK/USD=$USD, NOK/CNY=$CNY (HTTP $USD_STATUS/$CNY_STATUS)" >> "$LOG_FILE"
else
  echo "$TIMESTAMP — ADVARSEL: Supabase-oppdatering feilet. USD=$USD_STATUS CNY=$CNY_STATUS. Kurs IKKE oppdatert." >> "$LOG_FILE"
fi

# Keep log trimmed to last 60 lines
tail -n 60 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
