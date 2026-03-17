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
TECH_DIR="${VAULT_DIR}/09_Tech"
ERROR_LOG="${TECH_DIR}/error-log.md"
HEARTBEAT_FILE="/tmp/gdist-daily-report.heartbeat"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

log_error() {
  local CODE="$1" LINE="$2"
  local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p "$TECH_DIR"
  if [[ ! -f "$ERROR_LOG" ]] || ! grep -q "^| Tidspunkt" "$ERROR_LOG" 2>/dev/null; then
    printf "# Error Log — Global Distribution AS\n\n| Tidspunkt | Script | Linje | Detalj |\n|-----------|--------|-------|--------|\n" > "$ERROR_LOG"
  fi
  echo "| ${TIMESTAMP} | daily-report.sh | Linje ${LINE} | Exit code: ${CODE} |" >> "$ERROR_LOG"
}

trap 'log_error "$?" "$LINENO"' ERR

log "=== Daglig rapport starter: $TODAY ==="

# --- Kjør quote-expiration via Supabase RPC ---
# expire_stale_quotes() oppdaterer quotes med valid_until < today og status=sent → expired
EXPIRED_QUOTES=$(curl -sf \
  "${SUPABASE_URL}/rest/v1/rpc/expire_stale_quotes" \
  -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE" \
  -H "Content-Type: application/json" \
  -d '{}' 2>/dev/null || echo "0")
log "Quote-expiration: $EXPIRED_QUOTES tilbud utløpt"

# --- Sjekk heartbeat for andre scripts ---
check_heartbeat() {
  local NAME="$1"
  local FILE="/tmp/gdist-${NAME}.heartbeat"
  local MAX_HOURS="$2"
  if [[ ! -f "$FILE" ]]; then
    echo "⚠️  ${NAME}: aldri kjørt"
    return
  fi
  local LAST_RUN=$(cat "$FILE")
  local AGE_SECONDS=$(( $(date '+%s') - $(date -jf '%Y-%m-%d %H:%M:%S' "$LAST_RUN" '+%s' 2>/dev/null || echo 0) ))
  local MAX_SECONDS=$(( MAX_HOURS * 3600 ))
  if (( AGE_SECONDS > MAX_SECONDS )); then
    echo "⚠️  ${NAME}: sist kjørt $LAST_RUN ($(( AGE_SECONDS / 3600 ))t siden)"
  else
    echo "✅ ${NAME}: kjørte $LAST_RUN"
  fi
}

HEARTBEAT_STATUS=""
HEARTBEAT_STATUS+="  $(check_heartbeat 'vault-sync' 25)\n"
HEARTBEAT_STATUS+="  $(check_heartbeat 'weekly-analysis' 168)\n"
HEARTBEAT_STATUS+="  $(check_heartbeat 'monthly-analysis' 720)\n"

# --- Tell filer i vault ---
VAULT_ORDER_COUNT=$(find "${VAULT_DIR}/04_Orders" -maxdepth 3 -name "*.md" \
  ! -name "_*.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')

VAULT_INQUIRY_COUNT=$(find "${VAULT_DIR}/01_Buyers/Active" -maxdepth 2 -name "*.md" \
  ! -name "_*.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')

log "Vault-telling — Ordre: ${VAULT_ORDER_COUNT:-0}, Inquiries: ${VAULT_INQUIRY_COUNT:-0}"

# --- Sjekk forfalne påminnelser fra 10_Log/reminders/ ---
REMINDERS_DIR="${VAULT_DIR}/10_Log/reminders"
REMINDERS_TODAY=""
if [[ -d "$REMINDERS_DIR" ]]; then
  for f in "$REMINDERS_DIR"/${DATE_ISO}_reminder_*.md(N); do
    fname="$(basename "$f")"
    title=$(grep '^# ' "$f" 2>/dev/null | head -1 | sed 's/^# //')
    REMINDERS_TODAY+="  ⏰  ${title:-$fname}\n"
  done
fi

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

# Produkter venter på godkjenning (status = pending)
PENDING_PRODUCTS_JSON=$(curl -sf "$BASE/products?select=name,supplier_id&status=eq.pending&order=created_at.asc" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" -H "Content-Type: application/json" 2>/dev/null || echo "[]")

PENDING_PRODUCT_COUNT=$(echo "$PENDING_PRODUCTS_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d))" 2>/dev/null || echo "0")

log "Data hentet — Ordre: $ORDER_COUNT, Inquiries: $INQUIRY_COUNT, Forfalte: $OVERDUE_COUNT, Produkter til godkjenning: $PENDING_PRODUCT_COUNT"

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

build_pending_products_table() {
  echo "$PENDING_PRODUCTS_JSON" | python3 - <<'PYEOF'
import json, sys
items = json.load(sys.stdin)
if not items:
    print("  (ingen produkter venter)")
else:
    for p in items:
        print(f"  • {p.get('name','?')}")
PYEOF
}

ORDERS_TABLE=$(build_orders_table)
INQUIRY_TABLE=$(build_inquiry_table)
OVERDUE_TABLE=$(build_overdue_table)
PENDING_PRODUCTS_TABLE=$(build_pending_products_table)

# Overdue-header med varsel
if [ "$OVERDUE_COUNT" != "0" ] && [ "$OVERDUE_COUNT" != "?" ]; then
  OVERDUE_HEADER="⚠️  FORFALTE BETALINGER ($OVERDUE_COUNT)"
else
  OVERDUE_HEADER="Forfalte betalinger"
fi

REMINDER_SECTION=""
if [[ -n "$REMINDERS_TODAY" ]]; then
  REMINDER_SECTION="
⏰ PÅMINNELSER I DAG
$(echo -e "$REMINDERS_TODAY")"
fi

REPORT_TEXT="
======================================================
  GLOBAL DISTRIBUTION AS — Daglig rapport
  $TODAY
======================================================

  Dato:              $DATE_ISO
  Aktive ordre:      ${VAULT_ORDER_COUNT:-0}  (vault)
  Åpne inquiries:    ${VAULT_INQUIRY_COUNT:-0}  (vault)
  Supabase ordre:    $ORDER_COUNT
  Supabase inquiries: $INQUIRY_COUNT
  Forfalte:          $OVERDUE_COUNT
  Til godkjenning:   $PENDING_PRODUCT_COUNT produkter
  Utløpt i dag:      $EXPIRED_QUOTES tilbud
  Påminnelser:       $(echo -e "$REMINDERS_TODAY" | grep -c '⏰' 2>/dev/null || echo 0)
  Vault synket:      $(cd "${VAULT_DIR}" && git log -1 --format='%ar' 2>/dev/null || echo 'ukjent')
  Rapport generert:  $(date '+%H:%M:%S')

------------------------------------------------------

AUTOMATISERINGSSTATUS
$(echo -e "$HEARTBEAT_STATUS")
------------------------------------------------------

AKTIVE ORDRE ($ORDER_COUNT)
$ORDERS_TABLE

ÅPNE INQUIRIES ($INQUIRY_COUNT)
$INQUIRY_TABLE

$OVERDUE_HEADER
$OVERDUE_TABLE

PRODUKTER TIL GODKJENNING ($PENDING_PRODUCT_COUNT)
$PENDING_PRODUCTS_TABLE
$REMINDER_SECTION

------------------------------------------------------
Vault synket:   $(cd ~/Documents/GlobalDistribution && git log -1 --format='%ar' 2>/dev/null || echo 'ukjent')
Portal URL:     https://gdist.no/admin/dashboard
Inquiry URL:    https://gdist.no/inquiry
------------------------------------------------------
Automatisk rapport fra Mac mini • Global Distribution AS
"

log "Rapport bygget"

# =============================================================
# 3. Lagre rapport til vault
# =============================================================

DAILY_DIR="${VAULT_DIR}/08_Daily"
mkdir -p "$DAILY_DIR"
VAULT_REPORT_FILE="${DAILY_DIR}/${DATE_ISO}_rapport_daglig.md"

{
  echo "---"
  echo "tags: [rapport, daglig, auto]"
  echo "created: $DATE_ISO"
  echo "---"
  echo ""
  echo "$REPORT_TEXT"
} > "$VAULT_REPORT_FILE"

log "✓ Rapport lagret: $VAULT_REPORT_FILE"

# =============================================================
# 4. Send e-post via Resend
# =============================================================

if [ -z "$RESEND_API_KEY" ] || [ "$RESEND_API_KEY" = "FYLL_INN_RESEND_API_KEY" ]; then
  log "⚠️  RESEND_API_KEY ikke satt — skriver rapport til logg i stedet"
  echo "$REPORT_TEXT"
  log "Rapport lagret i vault: $VAULT_REPORT_FILE"
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

# Skriv heartbeat
echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$HEARTBEAT_FILE"

log "=== Rapport ferdig ==="
