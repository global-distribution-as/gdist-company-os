#!/bin/zsh
# =============================================================
# monthly-analysis.sh — Global Distribution AS
# Leser vinn/tap-entries fra forrige måned, sender til Claude API,
# lagrer analyse som markdown-rapport i vault.
#
# Kjøres: 1. i hver måned kl. 08:00 via launchd
# Manuelt: zsh ~/Documents/GlobalDistribution/scripts/monthly-analysis.sh
#
# Krever: ANTHROPIC_API_KEY i scripts/config.env
# =============================================================

set -euo pipefail

# --- Konfig ---
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.env"

VAULT_DIR="${HOME}/Documents/GlobalDistribution"
ENTRIES_DIR="${VAULT_DIR}/05_Finance/analyse/entries"
REPORTS_DIR="${VAULT_DIR}/05_Finance/analyse/reports"
SYS_LOG="/tmp/gdist-monthly-analysis.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

log() { echo "[$TIMESTAMP] $1" | tee -a "$SYS_LOG"; }

log "=== Månedlig vinn/tap-analyse starter ==="

# --- Valider API-nøkkel ---
if [[ -z "${ANTHROPIC_API_KEY:-}" ]] || [[ "$ANTHROPIC_API_KEY" == "FYLL_INN"* ]]; then
  log "FEIL: ANTHROPIC_API_KEY ikke satt i config.env"
  log "      Legg til: ANTHROPIC_API_KEY=\"sk-ant-...\""
  exit 1
fi

# --- Beregn hvilken måned vi analyserer (forrige måned) ---
# Kjøres 1. i måneden → analyser forrige måned
ANALYSE_YEAR=$(date -v-1m '+%Y')
ANALYSE_MONTH=$(date -v-1m '+%m')
ANALYSE_LABEL=$(date -v-1m '+%B %Y')   # e.g. "februar 2026"
ANALYSE_PREFIX="${ANALYSE_YEAR}-${ANALYSE_MONTH}"
REPORT_FILE="${REPORTS_DIR}/${ANALYSE_PREFIX}_analyse.md"

log "Analyserer: $ANALYSE_LABEL"

# Tillat override for manuell kjøring: ANALYSE_MONTH_OVERRIDE=2026-03
if [[ -n "${ANALYSE_MONTH_OVERRIDE:-}" ]]; then
  ANALYSE_PREFIX="$ANALYSE_MONTH_OVERRIDE"
  ANALYSE_LABEL="$ANALYSE_MONTH_OVERRIDE (manuell)"
  REPORT_FILE="${REPORTS_DIR}/${ANALYSE_PREFIX}_analyse.md"
  log "Override: analyserer $ANALYSE_PREFIX"
fi

# --- Ikke overskriv eksisterende rapport ---
if [[ -f "$REPORT_FILE" ]]; then
  log "Rapport finnes allerede: $REPORT_FILE"
  log "Slett filen manuelt for å generere på nytt."
  exit 0
fi

mkdir -p "$REPORTS_DIR"

# --- Samle entries for perioden ---
# Henter alle vinntak-filer som starter med ANALYSE_PREFIX (ÅÅÅÅ-MM)
entries_content=""
entry_count=0

for f in "$ENTRIES_DIR"/${ANALYSE_PREFIX}_vinntak_*.md(N); do
  [[ -f "$f" ]] || continue
  fname="$(basename "$f")"
  entries_content+="
### Oppføring: $fname
$(cat "$f")
---
"
  (( entry_count += 1 ))
done

# --- Samle historiske entries for kjøpermønster-analyse ---
all_entries_content=""
all_count=0
for f in "$ENTRIES_DIR"/*.md(N); do
  [[ "$(basename "$f")" == "_mal.md" ]] && continue
  [[ -f "$f" ]] || continue
  all_entries_content+="$(basename "$f"): $(grep -E '^(buyer:|type:|produkt-kategori:|verdi-nok:)' "$f" | tr '\n' ' ')
"
  (( all_count += 1 ))
done

log "Fant $entry_count entries for $ANALYSE_LABEL, $all_count totalt historisk"

if (( entry_count == 0 )); then
  log "Ingen entries for $ANALYSE_LABEL — oppretter tom rapport"
  cat > "$REPORT_FILE" <<EOF
# Vinn/tap-analyse — $ANALYSE_LABEL

_Generert: $TIMESTAMP_

Ingen vinn/tap-oppføringer registrert for $ANALYSE_LABEL.

**Husk å fylle ut skjema** etter hver avsluttet deal eller tapt inquiry.
Se: \`05_Finance/analyse/entries/_mal.md\`
EOF
  exit 0
fi

# --- Bygg prompt ---
PROMPT=$(python3 -c "
import sys

entries = '''$entries_content'''
historical = '''$all_entries_content'''
periode = '$ANALYSE_LABEL'
totalt = '$all_count'

prompt = f'''Du er forretningsanalytiker for Global Distribution AS, et norsk handelsselskap som kobler europeiske leverandører med asiatiske buyers (primært Kina, Hong Kong, Korea).

Analyser vinn/tap-dataene for {periode}. Bruk også historiske data for kjøpermønster-analyse.

## Vinn/tap-oppføringer for {periode}:

{entries}

## Historiske oppføringer (alle {totalt} totalt — kun nøkkelfelter):

{historical}

## Din oppgave:

Skriv en strukturert analyse på norsk med disse seksjonene:

### 1. Oppsummering for {periode}
Antall vunnet vs. tapt, total verdi, hitrate.

### 2. Produktkategorier — hitrate
Hvilke kategorier vinner vi flest deals på? Hvilke taper vi? Vær konkret.

### 3. Kjøpermønster
Hvem kjøper igjen? Hvem var engangskjøpere? Hvilke buyers bør vi prioritere videre?

### 4. Tapsgrunner og tiltak
De vanligste grunnene til at vi taper. For hver grunn: ett konkret tiltak vi kan gjøre neste måned.

### 5. Tre prioriterte anbefalinger
De tre viktigste tingene Martin og Jessica bør gjøre annerledes neste måned. Vær spesifikk og handlingsrettet — ikke generell.

Skriv direkte og konsist. Unngå generelle råd. Bruk tallene der de finnes.'''

print(prompt)
")

log "Prompt bygget (${#PROMPT} tegn) — kaller Claude API..."

# --- Kall Claude API ---
API_RESPONSE=$(python3 - <<PYEOF
import json, sys, urllib.request, urllib.error

api_key = "$ANTHROPIC_API_KEY"
prompt  = """$PROMPT"""

payload = {
    "model": "claude-sonnet-4-6",
    "max_tokens": 2000,
    "messages": [{"role": "user", "content": prompt}]
}

req = urllib.request.Request(
    "https://api.anthropic.com/v1/messages",
    data=json.dumps(payload).encode(),
    headers={
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
    }
)

try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read())
        print(data["content"][0]["text"])
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(f"API_ERROR: {e.code} {body}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"API_ERROR: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
)

if [[ -z "$API_RESPONSE" ]]; then
  log "FEIL: Tom respons fra Claude API"
  exit 1
fi

log "Svar mottatt — lagrer rapport"

# --- Lagre rapport ---
cat > "$REPORT_FILE" <<EOF
# Vinn/tap-analyse — $ANALYSE_LABEL

_Generert: $TIMESTAMP av monthly-analysis.sh_
_Entries analysert: $entry_count (denne måneden) / $all_count (totalt)_

---

$API_RESPONSE

---

_Neste analyse: 1. $(date -v+1m '+%B %Y')_
_Entries-mappe: \`05_Finance/analyse/entries/\`_
EOF

log "✓ Rapport lagret: $REPORT_FILE"

# --- Send e-post hvis Resend er konfigurert ---
if [[ -n "${RESEND_API_KEY:-}" ]] && [[ "$RESEND_API_KEY" != "FYLL_INN"* ]]; then
  SUBJECT="GDist månedlig analyse — $ANALYSE_LABEL"
  BODY="Vinn/tap-analysen for $ANALYSE_LABEL er klar.\n\nÅpne i Obsidian: 05_Finance/analyse/reports/$(basename "$REPORT_FILE")\n\n---\n$API_RESPONSE"

  send_email() {
    local TO="$1"
    python3 -c "
import json, urllib.request
body = '''$BODY'''
payload = {
    'from': '$EMAIL_FROM',
    'to': ['$TO'],
    'subject': '$SUBJECT',
    'text': body
}
req = urllib.request.Request(
    'https://api.resend.com/emails',
    data=json.dumps(payload).encode(),
    headers={'Authorization': 'Bearer $RESEND_API_KEY', 'Content-Type': 'application/json'}
)
urllib.request.urlopen(req)
" 2>/dev/null && echo "✓ E-post sendt til $TO" || echo "⚠️  E-post feilet for $TO"
  }

  send_email "$EMAIL_DANIEL" | while read line; do log "$line"; done
  send_email "$EMAIL_MARTIN" | while read line; do log "$line"; done
fi

log "=== Analyse ferdig ==="
