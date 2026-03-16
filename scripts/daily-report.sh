#!/bin/zsh
# =============================================================
# daily-report.sh — Global Distribution AS
# Henter status fra Supabase og sender e-post til Daniel + Martin
# Kjøres: kl 07:30 hver morgen (se launchd/crontab.conf)
# =============================================================

set -euo pipefail

# --- Konfig ---
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.env"

LOG_FILE="/tmp/gdist-daily-report.log"
TODAY=$(date '+%A %d. %B %Y')
DATE_ISO=$(date '+%Y-%m-%d')

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

log "=== Daglig rapport starter: $TODAY ==="

# =============================================================
# 1. Hent data fra Supabase
# =============================================================

AUTH_HEADER="Authorization: Bearer $SUPABASE_SERVICE_ROLE"
APIKEY_HEADER="apikey: $SUPABASE_SERVICE_ROLE"
BASE="$SUPABASE_URL/rest/v1"

# Aktive ordre (ikke levert, ikke kansellert)
ORDERS_JSON=$(curl -sf "$BASE/orders?select=order_number,status,payment_status,sale_price_usd,balance_due_usd&status=neq.delivered&status=neq.cancelled&order=created_at.desc" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" -H "Content-Type: application/json" 2>/dev/null || echo "[]")

ORDER_COUNT=$(echo "$ORDERS_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d))" 2>/dev/null || echo "?")

# Åpne inquiries (status = new)
INQUIRIES_JSON=$(curl -sf "$BASE/inquiries?select=buyer_name,company,product_name,quantity,created_at&status=eq.new&order=created_at.desc" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" -H "Content-Type: application/json" 2>/dev/null || echo "[]")

INQUIRY_COUNT=$(echo "$INQUIRIES_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d))" 2>/dev/null || echo "?")

# Forfalte / ubetalt
OVERDUE_JSON=$(curl -sf "$BASE/orders?select=order_number,payment_status,balance_due_usd&payment_status=eq.overdue" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" -H "Content-Type: application/json" 2>/dev/null || echo "[]")

OVERDUE_COUNT=$(echo "$OVERDUE_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d))" 2>/dev/null || echo "0")

log "Data hentet — Ordre: $ORDER_COUNT, Inquiries: $INQUIRY_COUNT, Forfalte: $OVERDUE_COUNT"

# =============================================================
# 2. Bygg rapport
# =============================================================

build_orders_table() {
  echo "$ORDERS_JSON" | python3 - <<'PYEOF'
import json, sys
orders = json.load(sys.stdin)
if not orders:
    print("  (ingen aktive ordre)")
else:
    for o in orders:
        status = o.get('status','?').replace('_',' ').title()
        pay = o.get('payment_status','?').replace('_',' ').title()
        balance = o.get('balance_due_usd') or 0
        bal_str = f"  Utestående: ${balance:,.0f}" if balance > 0 else ""
        print(f"  • {o.get('order_number','?')}  [{status}]  Betaling: {pay}{bal_str}")
PYEOF
}

build_inquiry_table() {
  echo "$INQUIRIES_JSON" | python3 - <<'PYEOF'
import json, sys
from datetime import datetime, timezone
items = json.load(sys.stdin)
if not items:
    print("  (ingen åpne inquiries)")
else:
    for i in items:
        name = i.get('buyer_name','?')
        co = i.get('company','?')
        prod = i.get('product_name') or '?'
        qty = i.get('quantity')
        qty_str = f"  Mengde: {qty}" if qty else ""
        created = i.get('created_at','')[:10]
        print(f"  • {name} ({co})  →  {prod}{qty_str}  [mottatt {created}]")
PYEOF
}

build_overdue_table() {
  echo "$OVERDUE_JSON" | python3 - <<'PYEOF'
import json, sys
items = json.load(sys.stdin)
if not items:
    print("  (ingen forfalte)")
else:
    for o in items:
        balance = o.get('balance_due_usd') or 0
        print(f"  ⚠️  {o.get('order_number','?')}  —  ${balance:,.0f} USD utestående")
PYEOF
}

ORDERS_TABLE=$(build_orders_table)
INQUIRY_TABLE=$(build_inquiry_table)
OVERDUE_TABLE=$(build_overdue_table)

# Overdue-header med varsel
if [ "$OVERDUE_COUNT" != "0" ] && [ "$OVERDUE_COUNT" != "?" ]; then
  OVERDUE_HEADER="⚠️  FORFALTE BETALINGER ($OVERDUE_COUNT)"
else
  OVERDUE_HEADER="Forfalte betalinger"
fi

REPORT_TEXT="
======================================================
  GLOBAL DISTRIBUTION AS — Daglig rapport
  $TODAY
======================================================

AKTIVE ORDRE ($ORDER_COUNT)
$ORDERS_TABLE

ÅPNE INQUIRIES ($INQUIRY_COUNT)
$INQUIRY_TABLE

$OVERDUE_HEADER
$OVERDUE_TABLE

------------------------------------------------------
Vault synket:   $(cd ~/Documents/GlobalDistribution && git log -1 --format='%ar' 2>/dev/null || echo 'ukjent')
Portal URL:     https://web-platform-kappa-three.vercel.app
Inquiry URL:    https://web-platform-kappa-three.vercel.app/inquiry
------------------------------------------------------
Automatisk rapport fra Mac mini • Global Distribution AS
"

log "Rapport bygget"

# =============================================================
# 3. Send e-post via Resend
# =============================================================

if [ -z "$RESEND_API_KEY" ] || [ "$RESEND_API_KEY" = "FYLL_INN_RESEND_API_KEY" ]; then
  log "⚠️  RESEND_API_KEY ikke satt — skriver rapport til logg i stedet"
  echo "$REPORT_TEXT"
  echo "$REPORT_TEXT" >> "/tmp/gdist-rapport-$DATE_ISO.txt"
  log "Rapport skrevet til /tmp/gdist-rapport-$DATE_ISO.txt"
  exit 0
fi

SUBJECT="GDist daglig rapport — $DATE_ISO"

send_email() {
  local TO="$1"
  curl -sf "https://api.resend.com/emails" \
    -H "Authorization: Bearer $RESEND_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"from\": \"$EMAIL_FROM\",
      \"to\": [\"$TO\"],
      \"subject\": \"$SUBJECT\",
      \"text\": $(echo "$REPORT_TEXT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
    }" > /dev/null
}

send_email "$EMAIL_DANIEL" && log "✓ E-post sendt til Daniel"
send_email "$EMAIL_MARTIN" && log "✓ E-post sendt til Martin"

log "=== Rapport ferdig ==="
