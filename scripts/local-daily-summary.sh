#!/bin/zsh
# =============================================================
# local-daily-summary.sh — Global Distribution AS
# Leser strukturerte tall fra vault og Supabase,
# sender til lokal Ollama for AI-narrativ, lagrer i vault.
#
# Dette er Tier 2-oppgaven som er flyttet fra Claude API til
# lokal modell. Sparer ~0 kr/mnd nå, men skalerer gratis.
#
# BRUK:
#   zsh ~/Documents/GlobalDistribution/scripts/local-daily-summary.sh
# Kjøres av daily-report.sh automatisk hvis Ollama er oppe.
# =============================================================

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.env"
source "$SCRIPT_DIR/ai-router.sh"

LOG_FILE="/tmp/gdist-local-summary.log"
DATE_ISO=$(date '+%Y-%m-%d')
TODAY=$(date '+%A %d. %B %Y')
DAILY_DIR="${VAULT_DIR}/08_Daily"
ORDER_DIR="${VAULT_DIR}/04_Orders"
BUYER_DIR="${VAULT_DIR}/01_Buyers/Active"
TECH_DIR="${VAULT_DIR}/09_Tech"
ERROR_LOG="${TECH_DIR}/error-log.md"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

log_error() {
  local CODE="$1" LINE="$2"
  local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p "$TECH_DIR"
  if [[ ! -f "$ERROR_LOG" ]] || ! grep -q "^| Tidspunkt" "$ERROR_LOG" 2>/dev/null; then
    printf "# Error Log — Global Distribution AS\n\n| Tidspunkt | Script | Linje | Detalj |\n|-----------|--------|-------|--------|\n" > "$ERROR_LOG"
  fi
  echo "| ${TIMESTAMP} | local-daily-summary.sh | Linje ${LINE} | Exit code: ${CODE} |" >> "$ERROR_LOG"
}

trap 'log_error "$?" "$LINENO"' ERR

log "=== Lokal daglig oppsummering starter: $DATE_ISO ==="

# Sjekk at Ollama er oppe
if ! ollama_available; then
  log "⚠️  Ollama ikke tilgjengelig — avbryter (normal daglig rapport kjøres uansett)"
  exit 0
fi

# =============================================================
# 1. Les strukturert data fra vault
# =============================================================

ORDER_COUNT=$(find "$ORDER_DIR" -maxdepth 3 -name "*.md" ! -name "_*.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
BUYER_COUNT=$(find "$BUYER_DIR" -maxdepth 2 -name "*.md" ! -name "_*.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')

# Siste 3 ordre-titler (for kontekst)
RECENT_ORDERS=$(find "$ORDER_DIR" -maxdepth 3 -name "*.md" ! -name "_*.md" 2>/dev/null | \
  sort -r | head -3 | while read f; do basename "$f" .md | sed 's/^[0-9-]*_//' | tr '_' ' '; done | \
  tr '\n' ', ' | sed 's/,$//')
[[ -z "$RECENT_ORDERS" ]] && RECENT_ORDERS="ingen nylige ordre"

# Siste vault-sync
LAST_SYNC=$(cd "${VAULT_DIR}" && git log -1 --format='%ar' 2>/dev/null || echo "ukjent")

# Hent Supabase-tall (samme som daily-report.sh — disse er allerede hentet der)
# Her leser vi fra den siste daglige rapporten hvis den finnes
EXISTING_REPORT="${DAILY_DIR}/${DATE_ISO}_rapport_daglig.md"
SUPABASE_ORDERS="?"
SUPABASE_INQUIRIES="?"
OVERDUE_COUNT="0"

if [[ -f "$EXISTING_REPORT" ]]; then
  SUPABASE_ORDERS=$(grep "Supabase ordre:" "$EXISTING_REPORT" | head -1 | awk '{print $NF}' 2>/dev/null || echo "?")
  SUPABASE_INQUIRIES=$(grep "Supabase inquiries:" "$EXISTING_REPORT" | head -1 | awk '{print $NF}' 2>/dev/null || echo "?")
  OVERDUE_COUNT=$(grep "Forfalte:" "$EXISTING_REPORT" | head -1 | awk '{print $NF}' 2>/dev/null || echo "0")
fi

log "Data: Vault ordre=$ORDER_COUNT, Vault buyers=$BUYER_COUNT, Supabase ordre=$SUPABASE_ORDERS"

# =============================================================
# 2. Bygg prompt og kall lokal Ollama
# =============================================================

PROMPT="Du er en kompakt forretningsassistent for Global Distribution AS, et norsk B2B-importselskap (pre-launch).

Status for ${TODAY}:
- Aktive ordre i vault: ${ORDER_COUNT}
- Aktive buyers i vault: ${BUYER_COUNT}
- Ordre i Supabase (live): ${SUPABASE_ORDERS}
- Åpne inquiries i Supabase: ${SUPABASE_INQUIRIES}
- Forfalte betalinger: ${OVERDUE_COUNT}
- Siste vault-sync: ${LAST_SYNC}
- Nylige ordre: ${RECENT_ORDERS}

Skriv en 3–5 setningers situasjonsvurdering på norsk. Vær konkret — ikke generell. Pek på én ting som trenger oppmerksomhet i dag hvis tallene tilsier det. Ingen innledning, ingen avslutning, bare selve vurderingen."

log "Sender til lokal Ollama (qwen2.5:14b)..."

SUMMARY=$(call_local "$PROMPT" "qwen2.5:14b" "300" 2>/dev/null || echo "")

if [[ -z "$SUMMARY" ]]; then
  log "⚠️  Tom respons fra Ollama — hopper over AI-oppsummering"
  exit 0
fi

log "AI-oppsummering mottatt ($(echo "$SUMMARY" | wc -c | tr -d ' ') tegn)"

# =============================================================
# 3. Lagre til vault
# =============================================================

SUMMARY_FILE="${DAILY_DIR}/${DATE_ISO}_ai_daglig_oppsummering.md"

{
  echo "---"
  echo "tags: [ai, daglig, lokal, auto]"
  echo "created: $DATE_ISO"
  echo "model: qwen2.5:14b"
  echo "backend: local"
  echo "---"
  echo ""
  echo "# AI Daglig Oppsummering — ${DATE_ISO}"
  echo ""
  echo "> Generert lokalt av qwen2.5:14b på Mac mini. Ingen data forlot systemet."
  echo ""
  echo "---"
  echo ""
  echo "$SUMMARY"
  echo ""
  echo "---"
  echo ""
  echo "**Datakilde:** Vault ${DATE_ISO} + Supabase live-data"
  echo "_Generert: $(date '+%H:%M:%S') av local-daily-summary.sh_"
} > "$SUMMARY_FILE"

log "✓ AI-oppsummering lagret: $SUMMARY_FILE"

# Også legg til i routing-log (merk at call_local ikke logger — gjør det eksplisitt)
echo "$(date '+%Y-%m-%d %H:%M:%S'),daily_summary,local,\"Vault+Supabase data → norsk narrativ\",qwen2.5:14b" >> \
  "${VAULT_DIR}/09_Tech/ai-routing-log.csv" 2>/dev/null || true

log "=== Lokal daglig oppsummering ferdig ==="
