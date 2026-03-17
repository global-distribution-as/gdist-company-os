#!/bin/zsh
# =============================================================
# weekly-analysis.sh — Global Distribution AS
# Les de 4 siste ukentlige reviews, la Claude finne mønstre.
# Skriver rapport til 08_Daily/YYYY-MM_weekly_patterns.md
#
# BRUK:
#   zsh ~/Documents/GlobalDistribution/scripts/weekly-analysis.sh
# =============================================================

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.env"

LOG_FILE="/tmp/gdist-weekly-analysis.log"
DATE_ISO=$(date '+%Y-%m-%d')
MONTH=$(date '+%Y-%m')
TECH_DIR="${VAULT_DIR}/09_Tech"
ERROR_LOG="${TECH_DIR}/error-log.md"
HEARTBEAT_FILE="/tmp/gdist-weekly-analysis.heartbeat"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

log_error() {
  local CODE="$1" LINE="$2"
  local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p "$TECH_DIR"
  if [[ ! -f "$ERROR_LOG" ]] || ! grep -q "^| Tidspunkt" "$ERROR_LOG" 2>/dev/null; then
    echo "# Error Log — Global Distribution AS\n\n| Tidspunkt | Script | Linje | Detalj |\n|-----------|--------|-------|--------|\n" > "$ERROR_LOG"
  fi
  echo "| ${TIMESTAMP} | weekly-analysis.sh | Linje ${LINE} | Exit code: ${CODE} |" >> "$ERROR_LOG"
}

trap 'log_error "$?" "$LINENO"' ERR

log "=== Ukentlig analyse starter: $DATE_ISO ==="

# Sjekk API-nøkkel
if [ -z "${ANTHROPIC_API_KEY:-}" ] || [ "$ANTHROPIC_API_KEY" = "FYLL_INN_ANTHROPIC_API_KEY" ]; then
  log "⚠️  ANTHROPIC_API_KEY ikke satt — avbryter"
  exit 1
fi

# =============================================================
# 1. Finn de 4 siste ukentlige reviews
# =============================================================

REVIEW_DIR="${VAULT_DIR}/08_Daily"
REVIEWS=()

# Søk etter filer med _review_ukentlig i navn, sortert nyest først
if [[ -d "$REVIEW_DIR" ]]; then
  while IFS= read -r f; do
    REVIEWS+=("$f")
  done < <(find "$REVIEW_DIR" -name "*_review_ukentlig.md" -type f 2>/dev/null | sort -r | head -4)
fi

if (( ${#REVIEWS[@]} == 0 )); then
  log "⚠️  Ingen ukentlige reviews funnet i $REVIEW_DIR — ingenting å analysere"
  exit 0
fi

log "Fant ${#REVIEWS[@]} review(s): ${REVIEWS[*]}"

# =============================================================
# 2. Bygg innhold for Claude
# =============================================================

COMBINED_TEXT=""
for f in "${REVIEWS[@]}"; do
  FNAME=$(basename "$f")
  CONTENT=$(cat "$f" 2>/dev/null || echo "(lesefeil)")
  COMBINED_TEXT+="--- REVIEW: ${FNAME} ---\n${CONTENT}\n\n"
done

PROMPT="Du er en forretningsanalytiker for Global Distribution AS, et norsk B2B-importselskap i oppstartsfasen.

Her er de ${#REVIEWS[@]} siste ukentlige reviews fra operasjonsansvarlig Martin:

$(echo -e "$COMBINED_TEXT")

Analyser disse og gi meg:

1. **3 MØNSTRE** — gjentakende trender, positive eller negative (konkrete, ikke vage)
2. **1 ANBEFALING** — den ene tingen vi bør endre eller starte med neste uke

Format:
**Mønster 1:** [tittel]
[1-2 setninger]

**Mønster 2:** [tittel]
[1-2 setninger]

**Mønster 3:** [tittel]
[1-2 setninger]

**Anbefaling for neste uke:**
[1-3 setninger — konkret og handlingsrettet]

Vær direkte. Ingen fyllord."

# =============================================================
# 3. Kall Claude API
# =============================================================

log "Sender til Claude API..."

API_RESPONSE=$(curl -sf "https://api.anthropic.com/v1/messages" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d "$(python3 -c "
import json, sys
prompt = sys.argv[1]
payload = {
  'model': 'claude-sonnet-4-6',
  'max_tokens': 800,
  'messages': [{'role': 'user', 'content': prompt}]
}
print(json.dumps(payload))
" "$PROMPT")" 2>/dev/null)

if [ -z "$API_RESPONSE" ]; then
  log "✗ API-kall feilet — tom respons"
  exit 1
fi

ANALYSIS=$(echo "$API_RESPONSE" | python3 -c "
import json, sys
resp = json.load(sys.stdin)
print(resp.get('content', [{}])[0].get('text', '(tomt svar)'))
" 2>/dev/null || echo "(kunne ikke parse API-svar)")

log "Svar mottatt fra Claude"

# =============================================================
# 4. Lagre rapport til vault
# =============================================================

REPORT_DIR="${VAULT_DIR}/08_Daily"
mkdir -p "$REPORT_DIR"
REPORT_FILE="${REPORT_DIR}/${MONTH}_weekly_patterns.md"

{
  echo "---"
  echo "tags: [analyse, ukentlig, auto, mønstre]"
  echo "created: $DATE_ISO"
  echo "reviews_analysert: ${#REVIEWS[@]}"
  echo "---"
  echo ""
  echo "# Ukentlige mønstre — ${MONTH}"
  echo ""
  echo "> Automatisk analyse av ${#REVIEWS[@]} ukentlige reviews."
  echo "> Generert: ${DATE_ISO}"
  echo ""
  echo "---"
  echo ""
  echo "$ANALYSIS"
  echo ""
  echo "---"
  echo ""
  echo "## Reviews analysert"
  for f in "${REVIEWS[@]}"; do
    echo "- $(basename "$f")"
  done
} > "$REPORT_FILE"

log "✓ Rapport lagret: $REPORT_FILE"

# Skriv heartbeat
echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$HEARTBEAT_FILE"

log "=== Ukentlig analyse ferdig ==="
