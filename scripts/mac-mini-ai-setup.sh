#!/bin/zsh
# =============================================================
# mac-mini-ai-setup.sh — Global Distribution AS
# Setter opp lokal AI-infrastruktur på Mac mini M4 (16GB).
# Installerer Ollama, laster ned anbefalt modell, verifiserer drift.
#
# BRUK:
#   zsh ~/Documents/GlobalDistribution/scripts/mac-mini-ai-setup.sh
#
# Kjøres etter mac-mini-setup.sh er fullført.
# =============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo "${GREEN}✓${NC} $1"; }
warn() { echo "${YELLOW}⚠${NC}  $1"; }
info() { echo "${BLUE}→${NC}  $1"; }
fail() { echo "${RED}✗${NC} $1"; FAILED+=("$1"); }
step() { echo "\n${BOLD}[$1]${NC} $2"; }

FAILED=()

OLLAMA_HOST="http://localhost:11434"
PRIMARY_MODEL="qwen2.5:14b"     # ~8.7GB RAM — sterk på norsk og strukturert output
FAST_MODEL="llama3.2:3b"        # ~2.0GB RAM — for rask klassifisering
CLAUDE_ENV="$HOME/.claude-env"
SCRIPT_DIR="${0:A:h}"

echo ""
echo "${BOLD}=================================================${NC}"
echo "${BOLD}  Global Distribution AS — Lokal AI-oppsett${NC}"
echo "${BOLD}  Mac mini M4 16GB — Ollama + qwen2.5:14b${NC}"
echo "${BOLD}=================================================${NC}"
echo ""

# RAM-sjekk
TOTAL_RAM_GB=$(sysctl -n hw.memsize 2>/dev/null | python3 -c "import sys; print(int(sys.stdin.read())/1024**3)" 2>/dev/null || echo "0")
info "Detektert RAM: ${TOTAL_RAM_GB:.0f} GB"
if python3 -c "import sys; sys.exit(0 if float('${TOTAL_RAM_GB}') >= 14 else 1)" 2>/dev/null; then
  ok "RAM tilstrekkelig for qwen2.5:14b"
else
  warn "Under 16GB RAM detektert — qwen2.5:14b kan bli tregt. Vurderer llama3.1:8b i stedet."
  PRIMARY_MODEL="llama3.1:8b"
fi

# =============================================================
step "1/6" "Installer Ollama via Homebrew"
# =============================================================

if command -v ollama &>/dev/null; then
  OLLAMA_VER=$(ollama --version 2>/dev/null | head -1 || echo "ukjent versjon")
  ok "Ollama allerede installert: $OLLAMA_VER"
else
  info "Installerer Ollama..."
  brew install ollama && ok "Ollama installert" || fail "Ollama installasjon feilet"
fi

# =============================================================
step "2/6" "Start Ollama som bakgrunnsservice"
# =============================================================

# Start via brew services (persistent across reboots)
if brew services list 2>/dev/null | grep -q "ollama.*started"; then
  ok "Ollama service kjører allerede"
else
  info "Starter Ollama service..."
  if brew services start ollama 2>/dev/null; then
    ok "Ollama service startet (persistent — starter ved login)"
  else
    warn "brew services feilet — prøver direkte start..."
    ollama serve &>/tmp/ollama.log &
    sleep 3
    if curl -sf --max-time 5 "${OLLAMA_HOST}/api/tags" -o /dev/null; then
      ok "Ollama kjører (manuell start)"
      warn "NB: ikke persistent — legg til i launchd manuelt"
    else
      fail "Ollama starter ikke"
    fi
  fi
fi

# Vent på at Ollama er klar
info "Venter på Ollama API..."
ATTEMPTS=0
until curl -sf --max-time 2 "${OLLAMA_HOST}/api/tags" -o /dev/null 2>/dev/null; do
  (( ATTEMPTS += 1 ))
  if (( ATTEMPTS > 10 )); then
    fail "Ollama API svarer ikke etter 10 forsøk"
    break
  fi
  sleep 2
done
[[ $ATTEMPTS -le 10 ]] && ok "Ollama API tilgjengelig på ${OLLAMA_HOST}"

# =============================================================
step "3/6" "Last ned modeller"
# =============================================================

pull_model() {
  local MODEL="$1"
  local DESC="$2"
  info "Henter $MODEL ($DESC)..."
  if ollama list 2>/dev/null | grep -q "^${MODEL}"; then
    ok "$MODEL allerede lastet ned"
  else
    if ollama pull "$MODEL"; then
      ok "$MODEL lastet ned"
    else
      fail "$MODEL — nedlasting feilet"
    fi
  fi
}

pull_model "$PRIMARY_MODEL" "primær — norsk og strukturert output, ~8.7GB"
pull_model "$FAST_MODEL"    "rask klassifisering, ~2GB"

# =============================================================
step "4/6" "Test modell med GDist-eksempel"
# =============================================================

info "Tester $PRIMARY_MODEL med daglig rapport-oppgave..."

TEST_PROMPT="Du er assistent for Global Distribution AS, et norsk B2B-handelsselskap.
Basert på denne dataen, skriv en tre-setnings oppsummering på norsk:
- Aktive ordre: 3
- Åpne inquiries: 2 (én fra Hong Kong, én fra Seoul)
- Forfalte betalinger: 0
- Siste vault-sync: i dag kl 08:00

Svar direkte, ingen intro."

TEST_RESPONSE=$(curl -sf --max-time 60 "${OLLAMA_HOST}/api/generate" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${PRIMARY_MODEL}\",
    \"prompt\": $(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$TEST_PROMPT"),
    \"stream\": false,
    \"options\": {\"num_predict\": 150}
  }" 2>/dev/null | python3 -c "
import json, sys
try:
    r = json.load(sys.stdin)
    print(r.get('response', '').strip()[:300])
except:
    print('(kunne ikke parse svar)')
" 2>/dev/null || echo "(timeout eller feil)")

if [[ -n "$TEST_RESPONSE" ]] && [[ "$TEST_RESPONSE" != "(timeout eller feil)" ]]; then
  ok "Modelltest vellykket"
  echo ""
  echo "  ${BLUE}Testsvar fra $PRIMARY_MODEL:${NC}"
  echo "$TEST_RESPONSE" | sed 's/^/  /'
  echo ""
else
  fail "Modelltest feilet — $PRIMARY_MODEL svarer ikke korrekt"
fi

# =============================================================
step "5/6" "Legg til OLLAMA_HOST i ~/.claude-env"
# =============================================================

if [[ -f "$CLAUDE_ENV" ]]; then
  if grep -q "OLLAMA_HOST" "$CLAUDE_ENV"; then
    ok "OLLAMA_HOST allerede satt i $CLAUDE_ENV"
  else
    echo "" >> "$CLAUDE_ENV"
    echo "# --- Lokal AI (Ollama) ---" >> "$CLAUDE_ENV"
    echo "OLLAMA_HOST=\"${OLLAMA_HOST}\"" >> "$CLAUDE_ENV"
    echo "OLLAMA_PRIMARY_MODEL=\"${PRIMARY_MODEL}\"" >> "$CLAUDE_ENV"
    echo "OLLAMA_FAST_MODEL=\"${FAST_MODEL}\"" >> "$CLAUDE_ENV"
    ok "OLLAMA_HOST lagt til i $CLAUDE_ENV"
  fi
else
  warn "$CLAUDE_ENV finnes ikke — opprett den og legg til: OLLAMA_HOST=\"${OLLAMA_HOST}\""
fi

# =============================================================
step "6/6" "Verifiser HTTP-endepunkt og service-status"
# =============================================================

info "Sjekker Ollama API..."
OLLAMA_STATUS=$(curl -sf --max-time 5 "${OLLAMA_HOST}/api/tags" 2>/dev/null | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{len(d.get(\"models\",[]))} modeller lastet')" 2>/dev/null || echo "feil")

if [[ "$OLLAMA_STATUS" != "feil" ]]; then
  ok "Ollama API: ${OLLAMA_STATUS}"
else
  fail "Ollama API ikke tilgjengelig"
fi

info "Service-status:"
brew services list 2>/dev/null | grep ollama | sed 's/^/  /' || echo "  (brew services ikke tilgjengelig)"

# =============================================================
# Sluttrapport
# =============================================================

echo ""
echo "${BOLD}=================================================${NC}"

if (( ${#FAILED[@]} == 0 )); then
  echo "${GREEN}${BOLD}  ✅ LOKAL AI KLAR${NC}"
  echo "${BOLD}=================================================${NC}"
  echo ""
  echo "  Primær modell:  $PRIMARY_MODEL"
  echo "  Rask modell:    $FAST_MODEL"
  echo "  API-endepunkt:  ${OLLAMA_HOST}"
  echo ""
  echo "  Test manuelt:"
  echo "    ollama run $PRIMARY_MODEL"
  echo ""
  echo "  Bruk i scripts:"
  echo "    source scripts/ai-router.sh"
  echo "    call_ai \"daily_summary\" \"din prompt her\""
  echo ""
  echo "  Månedlig kostnad: kr 0 (+ ~kr 15 elektrisitet)"
else
  echo "${RED}${BOLD}  ✗ IKKE KLAR — ${#FAILED[@]} feil${NC}"
  echo "${BOLD}=================================================${NC}"
  for msg in "${FAILED[@]}"; do
    echo "  ${RED}✗${NC} $msg"
  done
  echo ""
  echo "Fiks disse og kjør scriptet på nytt."
fi

echo ""
