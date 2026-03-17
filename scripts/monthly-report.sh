#!/bin/zsh
# =============================================================
# monthly-report.sh — Global Distribution AS
# Spør monthly_patterns view, genererer plattformrapport.
# Skriver til 08_Daily/YYYY-MM_platform_report.md
#
# BRUK:
#   zsh ~/Documents/GlobalDistribution/scripts/monthly-report.sh
#   REPORT_MONTH_OVERRIDE=2026-02 zsh .../monthly-report.sh
# =============================================================

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.env"

LOG_FILE="/tmp/gdist-monthly-report.log"
DATE_ISO=$(date '+%Y-%m-%d')
TECH_DIR="${VAULT_DIR}/09_Tech"
ERROR_LOG="${TECH_DIR}/error-log.md"
HEARTBEAT_FILE="/tmp/gdist-monthly-report.heartbeat"

# Hvilken måned skal rapporteres? Standard: forrige måned
if [[ -n "${REPORT_MONTH_OVERRIDE:-}" ]]; then
  REPORT_MONTH="$REPORT_MONTH_OVERRIDE"
else
  REPORT_MONTH=$(date -v-1m '+%Y-%m')
fi

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

log_error() {
  local CODE="$1" LINE="$2"
  local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p "$TECH_DIR"
  if [[ ! -f "$ERROR_LOG" ]] || ! grep -q "^| Tidspunkt" "$ERROR_LOG" 2>/dev/null; then
    printf "# Error Log — Global Distribution AS\n\n| Tidspunkt | Script | Linje | Detalj |\n|-----------|--------|-------|--------|\n" > "$ERROR_LOG"
  fi
  echo "| ${TIMESTAMP} | monthly-report.sh | Linje ${LINE} | Exit code: ${CODE} |" >> "$ERROR_LOG"
}

trap 'log_error "$?" "$LINENO"' ERR

log "=== Månedlig plattformrapport starter: $REPORT_MONTH ==="

AUTH_HEADER="Authorization: Bearer $SUPABASE_SERVICE_ROLE"
APIKEY_HEADER="apikey: $SUPABASE_SERVICE_ROLE"
BASE="$SUPABASE_URL/rest/v1"

# =============================================================
# 1. Hent data fra monthly_patterns view
# =============================================================

PATTERNS_JSON=$(curl -sf \
  "${BASE}/monthly_patterns?month=eq.${REPORT_MONTH}-01T00%3A00%3A00%2B00%3A00&order=type,outcome" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" \
  -H "Content-Type: application/json" 2>/dev/null || echo "[]")

# =============================================================
# 2. Hent råtall for måneden
# =============================================================

MONTH_START="${REPORT_MONTH}-01"
MONTH_END=$(date -v+1m -v"$(date '+%d')d" -jf "%Y-%m-%d" "${MONTH_START}" '+%Y-%m-01' 2>/dev/null || \
  python3 -c "from datetime import date; import calendar; y,m = map(int,'${REPORT_MONTH}'.split('-')); print(date(y + (m//12), (m%12)+1, 1))")

ORDER_COUNT=$(curl -sf \
  "${BASE}/orders?select=id&created_at=gte.${MONTH_START}&created_at=lt.${MONTH_END}" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" \
  -H "Prefer: count=exact" \
  -o /dev/null -w "%{size_download}" 2>/dev/null || echo "?")

INQUIRY_COUNT=$(curl -sf \
  "${BASE}/inquiries?select=id&created_at=gte.${MONTH_START}&created_at=lt.${MONTH_END}" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" \
  -H "Prefer: count=exact" \
  -o /dev/null -w "%{size_download}" 2>/dev/null || echo "?")

# Bruk Python for Prefer: count header (returnerer content-range)
get_count() {
  local ENDPOINT="$1"
  curl -sf "${BASE}/${ENDPOINT}&created_at=gte.${MONTH_START}&created_at=lt.${MONTH_END}" \
    -H "$AUTH_HEADER" -H "$APIKEY_HEADER" \
    -H "Prefer: count=exact" \
    -D - -o /dev/null 2>/dev/null | \
    grep -i "content-range" | sed 's/.*\///' | tr -d '\r' || echo "?"
}

ORDER_COUNT=$(get_count "orders?select=id")
INQUIRY_COUNT=$(get_count "inquiries?select=id")
EVENT_ERRORS=$(curl -sf \
  "${BASE}/events?type=eq.error&created_at=gte.${MONTH_START}&created_at=lt.${MONTH_END}" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" \
  -H "Prefer: count=exact" \
  -D - -o /dev/null 2>/dev/null | \
  grep -i "content-range" | sed 's/.*\///' | tr -d '\r' || echo "0")

log "Data hentet — Ordre: $ORDER_COUNT, Inquiries: $INQUIRY_COUNT, Feil: $EVENT_ERRORS"

# =============================================================
# 3. Bygg rapport via Python
# =============================================================

REPORT_BODY=$(echo "$PATTERNS_JSON" | python3 - <<PYEOF
import json, sys

patterns = json.load(sys.stdin)

if not patterns:
    print("  (ingen events logget denne måneden)")
    sys.exit(0)

# Grupper per type
by_type = {}
for p in patterns:
    t = p.get('type', '?')
    if t not in by_type:
        by_type[t] = []
    by_type[t].append(p)

for t, rows in sorted(by_type.items()):
    total = sum(r.get('event_count', 0) for r in rows)
    success = sum(r.get('event_count', 0) for r in rows if r.get('outcome') == 'success')
    failure = sum(r.get('event_count', 0) for r in rows if r.get('outcome') == 'failure')
    success_rate = int(100 * success / total) if total > 0 else 0

    avg_durations = [r.get('avg_duration_seconds') for r in rows if r.get('avg_duration_seconds')]
    avg_str = f"  Gj.sn tid: {sum(avg_durations)/len(avg_durations):.0f}s" if avg_durations else ""

    status = "✅" if success_rate >= 90 else ("⚠️" if success_rate >= 70 else "❌")
    print(f"{status}  {t.upper()}: {total} totalt  ({success} ok / {failure} feil — {success_rate}% suksess){avg_str}")

PYEOF
)

# =============================================================
# 4. Lagre rapport
# =============================================================

REPORT_DIR="${VAULT_DIR}/08_Daily"
mkdir -p "$REPORT_DIR"
REPORT_FILE="${REPORT_DIR}/${REPORT_MONTH}_platform_report.md"

{
  echo "---"
  echo "tags: [rapport, månedlig, plattform, auto]"
  echo "created: $DATE_ISO"
  echo "periode: $REPORT_MONTH"
  echo "---"
  echo ""
  echo "# Plattformrapport — ${REPORT_MONTH}"
  echo ""
  echo "| | |"
  echo "|---|---|"
  echo "| Ordre inngått | ${ORDER_COUNT} |"
  echo "| Inquiries mottatt | ${INQUIRY_COUNT} |"
  echo "| Systemfeil logget | ${EVENT_ERRORS} |"
  echo ""
  echo "---"
  echo ""
  echo "## Events per type"
  echo ""
  echo "$REPORT_BODY"
  echo ""
  echo "---"
  echo ""
  echo "_Automatisk rapport fra Mac mini • $(date '+%Y-%m-%d %H:%M')_"
} > "$REPORT_FILE"

log "✓ Rapport lagret: $REPORT_FILE"

# Skriv heartbeat
echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$HEARTBEAT_FILE"

log "=== Månedlig plattformrapport ferdig ==="
