#!/bin/zsh
# =============================================================
# ai-router.sh — Global Distribution AS
# Bestemmer om en AI-oppgave skal til lokal Ollama eller Claude API.
# Logger hvert routing-valg til 09_Tech/ai-routing-log.csv
#
# BRUK:
#   source scripts/ai-router.sh
#   AI_BACKEND=$(route_ai_task "daily_summary")
#   # AI_BACKEND er "local" eller "cloud"
#
# Direkte test:
#   zsh scripts/ai-router.sh daily_summary
#   zsh scripts/ai-router.sh win_loss
# =============================================================

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.env"

ROUTING_LOG="${VAULT_DIR}/09_Tech/ai-routing-log.csv"
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"

# Sikre at loggfil har header
if [[ ! -f "$ROUTING_LOG" ]]; then
  mkdir -p "$(dirname "$ROUTING_LOG")"
  echo "timestamp,task_type,decision,reason,model" > "$ROUTING_LOG"
fi

# =============================================================
# Sjekk om Ollama kjører
# =============================================================

ollama_available() {
  curl -sf --max-time 2 "${OLLAMA_HOST}/api/tags" -o /dev/null 2>/dev/null
}

# =============================================================
# Routing-tabell
# =============================================================

route_ai_task() {
  local TASK_TYPE="${1:-unknown}"
  local DECISION=""
  local REASON=""
  local MODEL=""

  case "$TASK_TYPE" in
    # ─── TIER 1: Alltid Claude ───────────────────────────────
    "analysis"|"win_loss"|"customer_email"|"architecture"|"code_review"|"onboarding"|"contract"|"strategy"|"negotiation")
      DECISION="cloud"
      REASON="Tier 1: krever forretningsdømmekraft eller har reelle konsekvenser ved feil"
      MODEL="claude-sonnet-4-6"
      ;;

    # ─── TIER 2: Lokal hvis Ollama er oppe, ellers Claude ────
    "daily_summary"|"changelog"|"log_summary"|"translation_short"|"template_fill"|"classification"|"health_check"|"pattern_detect"|"doc_generate")
      if ollama_available; then
        DECISION="local"
        REASON="Tier 2: strukturert input/output, lokal modell tilstrekkelig"
        MODEL="qwen2.5:14b"
      else
        DECISION="cloud"
        REASON="Tier 2 men Ollama utilgjengelig — faller tilbake til Claude"
        MODEL="claude-sonnet-4-6"
      fi
      ;;

    # ─── Ukjent type: sikker fallback til sky ────────────────
    *)
      DECISION="cloud"
      REASON="Ukjent oppgavetype — bruker cloud som sikker fallback"
      MODEL="claude-sonnet-4-6"
      ;;
  esac

  # Logg valget
  local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${TIMESTAMP},${TASK_TYPE},${DECISION},\"${REASON}\",${MODEL}" >> "$ROUTING_LOG"

  echo "$DECISION"
}

# =============================================================
# Hjelpefunksjoner for scripts som bruker routeren
# =============================================================

# Kall lokal Ollama
call_local() {
  local PROMPT="$1"
  local MODEL="${2:-qwen2.5:14b}"
  local MAX_TOKENS="${3:-800}"

  if ! ollama_available; then
    echo "FEIL: Ollama ikke tilgjengelig på ${OLLAMA_HOST}" >&2
    return 1
  fi

  curl -sf "${OLLAMA_HOST}/api/generate" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json, sys
payload = {
  'model': sys.argv[1],
  'prompt': sys.argv[2],
  'stream': False,
  'options': {'num_predict': int(sys.argv[3])}
}
print(json.dumps(payload))
" "$MODEL" "$PROMPT" "$MAX_TOKENS")" | \
    python3 -c "import json,sys; print(json.load(sys.stdin).get('response',''))"
}

# Kall Claude API
call_cloud() {
  local PROMPT="$1"
  local MODEL="${2:-claude-sonnet-4-6}"
  local MAX_TOKENS="${3:-1000}"

  if [[ -z "${ANTHROPIC_API_KEY:-}" ]] || [[ "$ANTHROPIC_API_KEY" == "FYLL_INN"* ]]; then
    echo "FEIL: ANTHROPIC_API_KEY ikke satt" >&2
    return 1
  fi

  curl -sf "https://api.anthropic.com/v1/messages" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json, sys
payload = {
  'model': sys.argv[1],
  'max_tokens': int(sys.argv[2]),
  'messages': [{'role': 'user', 'content': sys.argv[3]}]
}
print(json.dumps(payload))
" "$MODEL" "$MAX_TOKENS" "$PROMPT")" | \
    python3 -c "import json,sys; print(json.load(sys.stdin)['content'][0]['text'])"
}

# Rut og kall riktig backend automatisk
call_ai() {
  local TASK_TYPE="$1"
  local PROMPT="$2"
  local MAX_TOKENS="${3:-800}"

  local BACKEND=$(route_ai_task "$TASK_TYPE")

  if [[ "$BACKEND" == "local" ]]; then
    call_local "$PROMPT" "qwen2.5:14b" "$MAX_TOKENS"
  else
    call_cloud "$PROMPT" "claude-sonnet-4-6" "$MAX_TOKENS"
  fi
}

# =============================================================
# Direkte kjøring: test routing-beslutning
# =============================================================

if [[ "${0:A}" == "${(%):-%x}" ]] || [[ "$0" == *"ai-router.sh" ]]; then
  TASK="${1:-unknown}"
  DECISION=$(route_ai_task "$TASK")
  echo "Oppgave: $TASK  →  Backend: $DECISION"

  if [[ "$DECISION" == "local" ]]; then
    echo "Modell: qwen2.5:14b (Ollama på ${OLLAMA_HOST})"
    ollama_available && echo "Status: ✅ Ollama kjører" || echo "Status: ⚠️  Ollama ikke tilgjengelig"
  else
    echo "Modell: claude-sonnet-4-6 (Anthropic API)"
  fi

  echo ""
  echo "Siste 5 routing-valg:"
  tail -5 "$ROUTING_LOG" 2>/dev/null | column -t -s','
fi
