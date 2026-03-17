#!/bin/zsh
# =============================================================
# sync-finance.sh — Global Distribution AS
# Synker ordrer og betalinger fra Supabase til transactions.csv
# og payables-receivables.csv automatisk.
#
# Eliminerer Martins manuelle CSV-registrering (~14 min/transaksjon).
#
# Kjøres: hver time via launchd (se launchd/com.gdist.sync-finance.plist)
# Manuelt: zsh ~/Documents/GlobalDistribution/scripts/sync-finance.sh
# =============================================================

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.env"

VAULT_DIR="${HOME}/Documents/GlobalDistribution"
FINANCE_DIR="${VAULT_DIR}/05_Finance"
TRANSACTIONS="${FINANCE_DIR}/transactions.csv"
PAYABLES="${FINANCE_DIR}/payables-receivables.csv"
LOG_FILE="/tmp/gdist-sync-finance.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

log() { echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"; }

# ── Roter logg ved >500KB ──────────────────────────────────────
[[ -f "$LOG_FILE" ]] && (( $(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0) > 512000 )) && \
  mv "$LOG_FILE" "${LOG_FILE}.bak"

log "=== Finance sync starter ==="

AUTH=(-H "apikey: $SUPABASE_SERVICE_ROLE" -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE")
BASE="$SUPABASE_URL/rest/v1"

# ── Initialiser CSV-filer hvis de mangler ──────────────────────
if [[ ! -f "$TRANSACTIONS" ]]; then
  echo "Dato,Ordre-ID,Type,Kategori,Motpart,Beloep_NOK,Valuta_Orig,Beloep_Orig,Betalt,Notat" \
    > "$TRANSACTIONS"
  log "Opprettet ny transactions.csv"
fi

if [[ ! -f "$PAYABLES" ]]; then
  echo "Dato,Type,Motpart,Ordre-ID,Beloep_NOK,Forfall,Status,Notat" \
    > "$PAYABLES"
  log "Opprettet ny payables-receivables.csv"
fi

# ── Hent eksisterende ordre-IDer fra CSV (deduplication) ──────
EXISTING_IDS=$(awk -F',' 'NR>1 && $2 != "" {print $2}' "$TRANSACTIONS" 2>/dev/null | sort -u)

# ── Hent ordrer fra Supabase ───────────────────────────────────
ORDERS=$(curl -sf \
  "$BASE/orders?select=order_number,buyer_id,supplier_cost_nok,sale_price_usd,payment_status,status,created_at,updated_at&status=neq.draft&order=created_at.asc" \
  "${AUTH[@]}" 2>/dev/null || echo "[]")

ORDER_COUNT=$(echo "$ORDERS" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
log "Hentet $ORDER_COUNT ordrer fra Supabase"

# ── Hent betalinger fra Supabase ───────────────────────────────
PAYMENTS=$(curl -sf \
  "$BASE/payments?select=order_id,payment_type,amount_nok,amount_nok,paid_date,payment_method,reference,created_at&order=created_at.asc" \
  "${AUTH[@]}" 2>/dev/null || echo "[]")

# ── Hent buyers for navn-oppslag ──────────────────────────────
BUYERS=$(curl -sf \
  "$BASE/buyers?select=id,name&active=eq.true" \
  "${AUTH[@]}" 2>/dev/null || echo "[]")

# ── Hent leverandører for navn-oppslag ────────────────────────
SUPPLIERS=$(curl -sf \
  "$BASE/suppliers?select=id,name&active=eq.true" \
  "${AUTH[@]}" 2>/dev/null || echo "[]")

# ── Skriv nye transaksjoner ───────────────────────────────────
NEW_ROWS=$(python3 - <<PYEOF
import json, sys, csv
from io import StringIO

orders   = json.loads('''${ORDERS}''')
payments = json.loads('''${PAYMENTS}''')
buyers   = {b['id']: b['name'] for b in json.loads('''${BUYERS}''')}
suppliers= {s['id']: s['name'] for s in json.loads('''${SUPPLIERS}''')}

existing_ids = set('''${EXISTING_IDS}'''.split('\n')) if '''${EXISTING_IDS}''' else set()

rows = []

# Ordre-rader (innkjøp + salg)
for o in orders:
    onum = o.get('order_number', '')
    if onum in existing_ids:
        continue  # allerede i CSV

    date = (o.get('created_at') or '')[:10]
    buyer_name  = buyers.get(o.get('buyer_id',''), 'Ukjent kjøper')
    pay_status  = o.get('payment_status', '')
    betalt      = 'J' if pay_status in ('paid', 'partial') else 'N'

    # Inntekt (salg til buyer) — hvis bekreftet
    if o.get('status') not in ('draft', 'pending') and o.get('sale_price_usd'):
        usd = float(o['sale_price_usd'])
        # Estimert NOK (placeholder kurs 11.0 — oppdater med faktisk kurs)
        nok = round(usd * 11.0, 0)
        rows.append([date, onum, 'Inntekt', 'Salg', buyer_name,
                     int(nok), 'USD', round(usd, 2), betalt,
                     f'Auto-synket fra Supabase'])

    # Utgift (varekjøp fra leverandør)
    if o.get('supplier_cost_nok'):
        cost = float(o['supplier_cost_nok'])
        rows.append([date, onum, 'Utgift', 'Varekjøp', 'Leverandør',
                     -int(cost), 'NOK', -int(cost), 'N',
                     'Auto-synket — bekreft leverandørnavn'])

# Betalings-rader
for p in payments:
    oid   = p.get('order_id', '')
    date  = (p.get('paid_date') or p.get('created_at') or '')[:10]
    ptype = p.get('payment_type', 'Ukjent')
    amt   = p.get('amount_nok') or 0
    ref   = p.get('reference') or ''
    method= p.get('payment_method') or ''
    rows.append([date, f'PAY-{oid[:8]}', 'Inntekt', 'Salg', 'Buyer',
                 float(amt), 'NOK', float(amt), 'J',
                 f'{ptype} via {method} {ref}'.strip()])

# Skriv til stdout som CSV-linjer
out = StringIO()
w = csv.writer(out)
for r in rows:
    w.writerow(r)
print(out.getvalue().strip())
PYEOF
)

if [[ -n "$NEW_ROWS" ]]; then
  ROW_COUNT=$(echo "$NEW_ROWS" | wc -l | tr -d ' ')
  echo "$NEW_ROWS" >> "$TRANSACTIONS"
  log "✓ Lagt til $ROW_COUNT nye rader i transactions.csv"
else
  log "Ingen nye transaksjoner å synke"
fi

# ── Oppdater payables-receivables ────────────────────────────
OVERDUE=$(curl -sf \
  "$BASE/orders?select=order_number,buyer_id,balance_due_usd,payment_status,created_at&payment_status=in.(unpaid,deposit_paid,partial,overdue)&order=created_at.asc" \
  "${AUTH[@]}" 2>/dev/null || echo "[]")

PAYABLES_ROWS=$(python3 - <<PYEOF
import json, csv
from io import StringIO

orders = json.loads('''${OVERDUE}''')
buyers = {b['id']: b['name'] for b in json.loads('''${BUYERS}''')}

out = StringIO()
w = csv.writer(out)

for o in orders:
    date     = (o.get('created_at') or '')[:10]
    onum     = o.get('order_number', '')
    buyer    = buyers.get(o.get('buyer_id',''), 'Ukjent')
    bal_usd  = float(o.get('balance_due_usd') or 0)
    bal_nok  = round(bal_usd * 11.0, 0)
    status   = 'Aapen'
    w.writerow([date, 'Skylder oss', buyer, onum,
                int(bal_nok), '', status, f'USD {bal_usd:.0f} utestående'])

print(out.getvalue().strip())
PYEOF
)

# Skriv ny payables-fil (overskriver — den er alltid current snapshot)
{
  echo "Dato,Type,Motpart,Ordre-ID,Beloep_NOK,Forfall,Status,Notat"
  [[ -n "$PAYABLES_ROWS" ]] && echo "$PAYABLES_ROWS"
} > "$PAYABLES"
log "✓ payables-receivables.csv oppdatert"

# ── Commit til git ────────────────────────────────────────────
cd "$VAULT_DIR"
if git status --porcelain 2>/dev/null | grep -q "05_Finance"; then
  git add "$TRANSACTIONS" "$PAYABLES"
  git commit -m "vault: auto-sync finans fra Supabase $(date '+%Y-%m-%d')" --quiet 2>/dev/null
  git push origin main --quiet 2>/dev/null && log "✓ Pushet til GitHub" || log "⚠️ Git push feilet — endringer lagret lokalt"
fi

log "=== Finance sync ferdig ==="
