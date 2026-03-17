#!/bin/zsh
# =============================================================
# follow-up-tracker.sh — Global Distribution AS
# Henter alle oppfølgingspunkter fra Supabase og skriver
# en daglig liste til Obsidian + sender e-post til Jessica og Martin.
#
# Erstatter manuell oppfølgingssporing (~10 min/poeng).
# Kjøres: kl 07:45 hver morgen, etter daily-report.sh
# Manuelt: zsh ~/Documents/GlobalDistribution/scripts/follow-up-tracker.sh
# =============================================================

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.env"

VAULT_DIR="${HOME}/Documents/GlobalDistribution"
LOG_FILE="/tmp/gdist-followup.log"
DATE_ISO=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

log() { echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"; }

log "=== Follow-up tracker starter ==="

AUTH=(-H "apikey: $SUPABASE_SERVICE_ROLE" -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE")
BASE="$SUPABASE_URL/rest/v1"

# ── 1. Tilbud uten svar > 48 timer ────────────────────────────
STALE_QUOTES=$(curl -sf \
  "$BASE/quotes?select=quote_number,buyer_id,total_usd,status,created_at&status=eq.sent&created_at=lt.$(date -v-2d '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || date -d '2 days ago' '+%Y-%m-%dT%H:%M:%S')Z&order=created_at.asc" \
  "${AUTH[@]}" 2>/dev/null || echo "[]")

# ── 2. Forfalte betalinger ────────────────────────────────────
OVERDUE_PAYMENTS=$(curl -sf \
  "$BASE/orders?select=order_number,buyer_id,balance_due_usd,payment_status,updated_at&payment_status=eq.overdue&order=updated_at.asc" \
  "${AUTH[@]}" 2>/dev/null || echo "[]")

# ── 3. Ordre uten oppdatering > 7 dager ──────────────────────
STALE_ORDERS=$(curl -sf \
  "$BASE/orders?select=order_number,buyer_id,status,updated_at&status=in.(confirmed,processing,shipped)&updated_at=lt.$(date -v-7d '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || date -d '7 days ago' '+%Y-%m-%dT%H:%M:%S')Z&order=updated_at.asc" \
  "${AUTH[@]}" 2>/dev/null || echo "[]")

# ── 4. Forsendelser forbi estimert ankomst ────────────────────
OVERDUE_SHIPMENTS=$(curl -sf \
  "$BASE/shipments?select=shipment_number,order_id,estimated_arrival,status,carrier&status=in.(in_transit,processing)&estimated_arrival=lt.${DATE_ISO}&order=estimated_arrival.asc" \
  "${AUTH[@]}" 2>/dev/null || echo "[]")

# ── 5. Buyers (kjøperoversikt) ────────────────────────────────
BUYERS=$(curl -sf \
  "$BASE/buyers?select=id,name&active=eq.true" \
  "${AUTH[@]}" 2>/dev/null || echo "[]")

# ── Bygg rapport ──────────────────────────────────────────────
REPORT=$(python3 - <<'PYEOF'
import json, sys, os
from datetime import datetime, timezone

stale_quotes    = json.loads(os.environ.get('STALE_QUOTES', '[]'))
overdue_pay     = json.loads(os.environ.get('OVERDUE_PAYMENTS', '[]'))
stale_orders    = json.loads(os.environ.get('STALE_ORDERS', '[]'))
overdue_ship    = json.loads(os.environ.get('OVERDUE_SHIPMENTS', '[]'))
buyers          = {b['id']: b['name'] for b in json.loads(os.environ.get('BUYERS', '[]'))}
today           = os.environ.get('DATE_ISO', '')

def buyer_name(bid):
    return buyers.get(bid, 'Ukjent buyer')

def days_ago(dt_str):
    if not dt_str:
        return '?'
    try:
        dt = datetime.fromisoformat(dt_str.replace('Z', '+00:00'))
        delta = datetime.now(timezone.utc) - dt
        return delta.days
    except:
        return '?'

lines = []
lines.append(f"# Oppfølgingsliste — {today}")
lines.append("")
lines.append("> Automatisk generert av follow-up-tracker.sh")
lines.append("")

total = len(stale_quotes) + len(overdue_pay) + len(stale_orders) + len(overdue_ship)

if total == 0:
    lines.append("✅ Ingen utestående oppfølgingspunkter i dag.")
    print('\n'.join(lines))
    sys.exit(0)

lines.append(f"**{total} punkt(er) krever handling i dag.**")
lines.append("")

# Section 1: Tilbud uten svar
lines.append(f"## 📨 Tilbud uten svar > 48 timer ({len(stale_quotes)})")
lines.append("")
if not stale_quotes:
    lines.append("- Ingen")
else:
    lines.append("*Ansvarlig: Jessica — følg opp med én kort melding*")
    lines.append("")
    for q in stale_quotes:
        d = days_ago(q.get('created_at'))
        buyer = buyer_name(q.get('buyer_id',''))
        total_usd = q.get('total_usd') or 0
        lines.append(f"- [ ] **{q.get('quote_number','?')}** — {buyer} — USD {total_usd:,.0f} — sendt {d} dager siden")
lines.append("")

# Section 2: Forfalte betalinger
lines.append(f"## 💰 Forfalte betalinger ({len(overdue_pay)})")
lines.append("")
if not overdue_pay:
    lines.append("- Ingen")
else:
    lines.append("*Ansvarlig: Martin — send påminnelse dag 1, eskalér til Daniel dag 10*")
    lines.append("")
    for o in overdue_pay:
        bal = float(o.get('balance_due_usd') or 0)
        buyer = buyer_name(o.get('buyer_id',''))
        lines.append(f"- [ ] **{o.get('order_number','?')}** — {buyer} — USD {bal:,.0f} utestående")
lines.append("")

# Section 3: Ordre uten oppdatering
lines.append(f"## 📦 Ordre uten oppdatering > 7 dager ({len(stale_orders)})")
lines.append("")
if not stale_orders:
    lines.append("- Ingen")
else:
    lines.append("*Ansvarlig: Martin — sjekk status med leverandør*")
    lines.append("")
    for o in stale_orders:
        d = days_ago(o.get('updated_at'))
        buyer = buyer_name(o.get('buyer_id',''))
        status = o.get('status','?')
        lines.append(f"- [ ] **{o.get('order_number','?')}** — {buyer} — Status: {status} — {d} dager siden sist oppdatert")
lines.append("")

# Section 4: Forsinkede forsendelser
lines.append(f"## 🚢 Forsendelser forbi estimert ankomst ({len(overdue_ship)})")
lines.append("")
if not overdue_ship:
    lines.append("- Ingen")
else:
    lines.append("*Ansvarlig: Martin — sjekk tracking og informer buyer*")
    lines.append("")
    for s in overdue_ship:
        eta = s.get('estimated_arrival','?')
        carrier = s.get('carrier') or 'Ukjent carrier'
        lines.append(f"- [ ] **{s.get('shipment_number','?')}** — {carrier} — Estimert ankomst: {eta}")
lines.append("")

lines.append("---")
lines.append(f"*Generert: {today} av follow-up-tracker.sh*")

print('\n'.join(lines))
PYEOF
)

# ── Eksporter env-vars for Python ────────────────────────────
export STALE_QUOTES="$STALE_QUOTES"
export OVERDUE_PAYMENTS="$OVERDUE_PAYMENTS"
export STALE_ORDERS="$STALE_ORDERS"
export OVERDUE_SHIPMENTS="$OVERDUE_SHIPMENTS"
export BUYERS="$BUYERS"
export DATE_ISO="$DATE_ISO"

REPORT=$(python3 - <<'PYEOF'
import json, sys, os
from datetime import datetime, timezone

stale_quotes    = json.loads(os.environ.get('STALE_QUOTES', '[]'))
overdue_pay     = json.loads(os.environ.get('OVERDUE_PAYMENTS', '[]'))
stale_orders    = json.loads(os.environ.get('STALE_ORDERS', '[]'))
overdue_ship    = json.loads(os.environ.get('OVERDUE_SHIPMENTS', '[]'))
buyers          = {b['id']: b['name'] for b in json.loads(os.environ.get('BUYERS', '[]'))}
today           = os.environ.get('DATE_ISO', '')

def buyer_name(bid):
    return buyers.get(bid, 'Ukjent buyer')

def days_ago(dt_str):
    if not dt_str: return '?'
    try:
        dt = datetime.fromisoformat(dt_str.replace('Z', '+00:00'))
        return (datetime.now(timezone.utc) - dt).days
    except: return '?'

lines = [f"# Oppfølgingsliste — {today}", ""]
lines.append("> Automatisk generert av follow-up-tracker.sh")
lines.append("")

total = len(stale_quotes) + len(overdue_pay) + len(stale_orders) + len(overdue_ship)

if total == 0:
    lines.append("✅ Ingen utestående oppfølgingspunkter i dag.")
    print('\n'.join(lines)); sys.exit(0)

lines.append(f"**{total} punkt(er) krever handling i dag.**")
lines.append("")

lines.append(f"## Tilbud uten svar > 48 timer ({len(stale_quotes)})")
lines.append("*Jessica — følg opp med én kort melding*" if stale_quotes else "")
lines.append("")
for q in stale_quotes:
    d = days_ago(q.get('created_at'))
    buyer = buyer_name(q.get('buyer_id',''))
    usd = q.get('total_usd') or 0
    lines.append(f"- [ ] **{q.get('quote_number','?')}** — {buyer} — USD {usd:,.0f} — sendt {d} dager siden")
if not stale_quotes: lines.append("- Ingen")
lines.append("")

lines.append(f"## Forfalte betalinger ({len(overdue_pay)})")
lines.append("*Martin — send påminnelse dag 1, eskalér til Daniel dag 10*" if overdue_pay else "")
lines.append("")
for o in overdue_pay:
    bal = float(o.get('balance_due_usd') or 0)
    buyer = buyer_name(o.get('buyer_id',''))
    lines.append(f"- [ ] **{o.get('order_number','?')}** — {buyer} — USD {bal:,.0f} utestående")
if not overdue_pay: lines.append("- Ingen")
lines.append("")

lines.append(f"## Ordre uten oppdatering > 7 dager ({len(stale_orders)})")
lines.append("*Martin — sjekk status med leverandør*" if stale_orders else "")
lines.append("")
for o in stale_orders:
    d = days_ago(o.get('updated_at'))
    buyer = buyer_name(o.get('buyer_id',''))
    lines.append(f"- [ ] **{o.get('order_number','?')}** — {buyer} — {d} dager siden sist oppdatert")
if not stale_orders: lines.append("- Ingen")
lines.append("")

lines.append(f"## Forsendelser forbi estimert ankomst ({len(overdue_ship)})")
lines.append("*Martin — sjekk tracking og informer buyer*" if overdue_ship else "")
lines.append("")
for s in overdue_ship:
    eta = s.get('estimated_arrival','?')
    carrier = s.get('carrier') or 'Ukjent'
    lines.append(f"- [ ] **{s.get('shipment_number','?')}** — {carrier} — Estimert ankomst: {eta}")
if not overdue_ship: lines.append("- Ingen")
lines.append("")

lines += ["---", f"*Generert: {today} av follow-up-tracker.sh*"]
print('\n'.join(lines))
PYEOF
)

TOTAL_ITEMS=$(echo "$REPORT" | grep -c '^\- \[ \]' 2>/dev/null || echo "0")

# ── Lagre til Obsidian ────────────────────────────────────────
FOLLOWUP_DIR="${VAULT_DIR}/00_Dashboard"
FOLLOWUP_FILE="${FOLLOWUP_DIR}/${DATE_ISO}_oppfølging.md"

echo "$REPORT" > "$FOLLOWUP_FILE"
log "✓ Oppfølgingsliste lagret: $FOLLOWUP_FILE ($TOTAL_ITEMS punkt(er))"

# ── Send e-post hvis det er punkter ──────────────────────────
if [[ "$TOTAL_ITEMS" -gt 0 ]] && [[ -n "${RESEND_API_KEY:-}" ]] && \
   [[ "$RESEND_API_KEY" != "FYLL_INN"* ]]; then

  SUBJECT="GDist oppfølging — $TOTAL_ITEMS punkt(er) krever handling (${DATE_ISO})"
  BODY="$REPORT"

  for TO in "$EMAIL_JESSICA" "$EMAIL_MARTIN"; do
    [[ -z "${TO:-}" ]] && continue
    python3 -c "
import json, urllib.request
payload = {
    'from': '$EMAIL_FROM',
    'to': ['$TO'],
    'subject': '$SUBJECT',
    'text': '''$BODY'''
}
req = urllib.request.Request(
    'https://api.resend.com/emails',
    data=json.dumps(payload).encode(),
    headers={'Authorization': 'Bearer $RESEND_API_KEY', 'Content-Type': 'application/json'}
)
urllib.request.urlopen(req)
" 2>/dev/null && log "✓ E-post sendt til $TO" || log "⚠️ E-post feilet for $TO"
  done
fi

# ── Git commit ────────────────────────────────────────────────
cd "$VAULT_DIR"
if git status --porcelain 2>/dev/null | grep -q "oppfølging"; then
  git add "$FOLLOWUP_FILE"
  git commit -m "vault: daglig oppfølgingsliste ${DATE_ISO}" --quiet 2>/dev/null
  git push origin main --quiet 2>/dev/null || true
fi

log "=== Follow-up tracker ferdig — $TOTAL_ITEMS punkt(er) ==="
