#!/bin/bash
# =============================================================
# keepalive-supabase.sh
# Pinger Supabase daglig for å forhindre automatisk DB-pause
# på Free tier (pause inntrer etter 7 dager inaktivitet).
#
# Cron: 0 8 * * * (kl 08:00 hver dag)
# Log:  $VAULT_DIR/08_Daily/keepalive.log
# =============================================================

set -euo pipefail
source "$(dirname "$0")/config.env"

LOG_FILE="$VAULT_DIR/08_Daily/keepalive.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Ping the settings table — lightweight read, always returns 200 if DB is up
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 10 \
  -H "apikey: $SUPABASE_SERVICE_ROLE" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE" \
  "$SUPABASE_URL/rest/v1/settings?select=key&limit=1")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "206" ]; then
  echo "$TIMESTAMP — OK (HTTP $HTTP_CODE)" >> "$LOG_FILE"
else
  echo "$TIMESTAMP — ADVARSEL: Supabase svarte HTTP $HTTP_CODE — DB kan være pauset" >> "$LOG_FILE"
  # If Resend key is configured, send an alert email
  if [ "$RESEND_API_KEY" != "FYLL_INN_RESEND_API_KEY" ]; then
    curl -s -X POST "https://api.resend.com/emails" \
      -H "Authorization: Bearer $RESEND_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{
        \"from\": \"$EMAIL_FROM\",
        \"to\": [\"$EMAIL_DANIEL\"],
        \"subject\": \"ADVARSEL: Supabase er nede ($HTTP_CODE)\",
        \"html\": \"<p>Keepalive-scriptet fikk HTTP $HTTP_CODE fra Supabase kl $TIMESTAMP. Sjekk <a href='https://app.supabase.com'>dashboard</a> og klikk Resume project.</p>\"
      }" > /dev/null
  fi
fi

# Keep log trimmed to last 90 lines (3 months of daily entries)
tail -n 90 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
