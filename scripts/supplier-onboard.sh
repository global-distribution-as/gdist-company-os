#!/bin/zsh
# =============================================================
# supplier-onboard.sh — Global Distribution AS
# Onboarder en ny leverandør fra intake-fil til:
#   • Obsidian leverandørfil
#   • Supabase (supplier + produkter)
#   • Velkomstemail (NO + EN)
#   • 30-dagers påminnelse
#
# Bruk:
#   zsh scripts/supplier-onboard.sh <intake-fil>
#   zsh scripts/supplier-onboard.sh 00_INBOX/2026-03-16_intake_hansen-textiles.md
#
# Kalles også automatisk av auto-route.sh for intake-filer.
# =============================================================

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.env"

LOG_FILE="/tmp/gdist-supplier-onboard.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

log() { echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"; }

# --- Valider argument ---
if [[ $# -lt 1 ]]; then
  echo "Bruk: zsh supplier-onboard.sh <intake-fil.md>"
  echo "Eksempel: zsh supplier-onboard.sh 00_INBOX/2026-03-16_intake_hansen-textiles.md"
  exit 1
fi

INTAKE_FILE="$1"

# Gjør til absolutt sti
if [[ "$INTAKE_FILE" != /* ]]; then
  INTAKE_FILE="${VAULT_DIR}/${INTAKE_FILE}"
fi

if [[ ! -f "$INTAKE_FILE" ]]; then
  log "FEIL: Finner ikke intake-fil: $INTAKE_FILE"
  exit 1
fi

# --- Valider API-nøkler ---
if [[ -z "${SUPABASE_SERVICE_ROLE:-}" ]] || [[ "$SUPABASE_SERVICE_ROLE" == "FYLL_INN"* ]]; then
  log "FEIL: SUPABASE_SERVICE_ROLE ikke satt i config.env"
  exit 1
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" ]] || [[ "$ANTHROPIC_API_KEY" == "FYLL_INN"* ]]; then
  log "Advarsel: ANTHROPIC_API_KEY ikke satt — velkomstemail blir placeholder"
fi

log "=== Supplier onboarding: $(basename "$INTAKE_FILE") ==="

# --- Kjør Python-pipeline ---
export SUPABASE_URL
export SUPABASE_SERVICE_ROLE
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
export VAULT_DIR

RESULT=$(python3 "$SCRIPT_DIR/supplier_onboard.py" "$INTAKE_FILE" 2> >(tee -a "$LOG_FILE" >&2))
PYTHON_EXIT=$?

if [[ $PYTHON_EXIT -ne 0 ]]; then
  log "FEIL: Python-pipeline feilet (exit $PYTHON_EXIT)"
  exit 1
fi

# --- Hent oppsummering fra Python (siste JSON-linje) ---
SUMMARY=$(echo "$RESULT" | grep '^{' | tail -1)

FIRMA=$(echo "$SUMMARY"        | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['firma'])"         2>/dev/null || echo "?")
PROD_COUNT=$(echo "$SUMMARY"   | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['product_count'])" 2>/dev/null || echo "?")
REMINDER=$(echo "$SUMMARY"     | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['reminder_date'])" 2>/dev/null || echo "?")
EMAIL_FILE=$(echo "$SUMMARY"   | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['email_file'])"    2>/dev/null || echo "?")

# --- Send bekreftelse via e-post ---
if [[ -n "${RESEND_API_KEY:-}" ]] && [[ "$RESEND_API_KEY" != "FYLL_INN"* ]]; then
  SUBJECT="✓ Ny leverandør live: $FIRMA"
  BODY="$FIRMA er nå onboardet.

Produkter i Supabase: $PROD_COUNT
Velkomstemail: $EMAIL_FILE
Påminnelse: $REMINDER

Husk å sende velkomstemail til leverandøren."

  python3 -c "
import json, urllib.request
payload = {
    'from': '$EMAIL_FROM',
    'to': ['$EMAIL_DANIEL', '$EMAIL_MARTIN'],
    'subject': '$SUBJECT',
    'text': '''$BODY'''
}
req = urllib.request.Request(
    'https://api.resend.com/emails',
    data=json.dumps(payload).encode(),
    headers={'Authorization': 'Bearer $RESEND_API_KEY', 'Content-Type': 'application/json'}
)
urllib.request.urlopen(req)
print('E-post sendt')
" 2>/dev/null && log "✓ Bekreftelse sendt til Daniel + Martin" || log "⚠️  E-post feilet (Resend)"
fi

log "=== Onboarding fullført: $FIRMA ($PROD_COUNT produkter) ==="
log "    Påminnelse satt: $REMINDER"
log "    Velkomstemail:   $EMAIL_FILE"
log ""
log "NESTE STEG:"
log "  1. Åpne e-postfilen og send til leverandøren"
log "  2. Sjekk at produktene ser riktige ut på gdist.no/admin"
log "  3. Slett reminder-notatet den $REMINDER etter oppfølging"
