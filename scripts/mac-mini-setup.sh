#!/bin/zsh
# =============================================================
# mac-mini-setup.sh — Global Distribution AS
# Setter opp kode-miljøet på Mac mini: CLI-verktøy, repo, tokens.
# Kjøres ÉN gang etter setup-mac-mini.sh er fullført.
#
# BRUK:
#   zsh ~/Documents/GlobalDistribution/scripts/mac-mini-setup.sh
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

echo ""
echo "${BOLD}=================================================${NC}"
echo "${BOLD}  Global Distribution AS — Kode-miljø oppsett${NC}"
echo "${BOLD}=================================================${NC}"
echo ""

CODE_DIR="$HOME/projects/aurora-trade-hub"
CODE_REPO="git@github.com:g-dist/aurora-trade-hub.git"
ZSHRC="$HOME/.zshrc"
CLAUDE_ENV="$HOME/.claude-env"

# =============================================================
step "1/4" "Installer CLI-verktøy (git, supabase, vercel)"
# =============================================================

# git
if command -v git &>/dev/null; then
  ok "git $(git --version | awk '{print $3}')"
else
  info "Installerer git..."
  brew install git && ok "git installert" || fail "git installasjon feilet"
fi

# supabase CLI
if command -v supabase &>/dev/null; then
  ok "supabase $(supabase --version 2>/dev/null | head -1)"
else
  info "Installerer supabase CLI..."
  brew install supabase/tap/supabase && ok "supabase CLI installert" || fail "supabase CLI installasjon feilet"
fi

# vercel CLI
if command -v vercel &>/dev/null; then
  ok "vercel $(vercel --version 2>/dev/null | head -1)"
else
  info "Installerer vercel CLI..."
  npm install -g vercel && ok "vercel CLI installert" || fail "vercel CLI installasjon feilet"
fi

# =============================================================
step "2/4" "Klon aurora-trade-hub"
# =============================================================

if [[ -d "$CODE_DIR/.git" ]]; then
  ok "aurora-trade-hub allerede klonet"
  info "Oppdaterer..."
  git -C "$CODE_DIR" pull --rebase origin main --quiet && ok "Repo oppdatert" || warn "git pull feilet — fortsetter"
else
  info "Kloner $CODE_REPO..."
  mkdir -p "$(dirname "$CODE_DIR")"
  if git clone "$CODE_REPO" "$CODE_DIR"; then
    ok "Klonet til $CODE_DIR"
  else
    fail "git clone feilet — sjekk SSH-nøkkel og repo-tilgang"
  fi
fi

# npm install
if [[ -d "$CODE_DIR" ]]; then
  info "Installerer npm-pakker..."
  (cd "$CODE_DIR" && npm install --silent) && ok "npm install fullført" || warn "npm install hadde feil"
fi

# =============================================================
step "3/4" "Source tokens fra ~/.zshrc / ~/.claude-env"
# =============================================================

if [[ -f "$CLAUDE_ENV" ]]; then
  source "$CLAUDE_ENV"
  ok "Tokens lastet fra $CLAUDE_ENV"
elif [[ -f "$ZSHRC" ]]; then
  source "$ZSHRC" 2>/dev/null || true
  ok "Tokens lastet fra $ZSHRC"
else
  warn "Verken $CLAUDE_ENV eller $ZSHRC funnet — tokens ikke lastet"
fi

# Sjekk at nøkkelvariabler er satt
for VAR in SUPABASE_URL SUPABASE_PROJECT_REF; do
  if [[ -n "${(P)VAR:-}" ]]; then
    ok "$VAR er satt"
  else
    fail "$VAR mangler — legg til i $CLAUDE_ENV"
  fi
done

# =============================================================
step "4/4" "Helsesjekk"
# =============================================================

PORTAL_URL="https://gdist.no"
BUYER_URL="https://web-platform-kappa-three.vercel.app"
SUPABASE_HEALTH="${SUPABASE_URL:-https://orsjlztclkiqntxznnyo.supabase.co}/rest/v1/"

# Portal
info "Sjekker portal ($PORTAL_URL)..."
if curl -sf --max-time 8 "$PORTAL_URL" -o /dev/null; then
  ok "Portal svarer: $PORTAL_URL"
else
  fail "Portal svarer ikke: $PORTAL_URL"
fi

# Buyer portal
info "Sjekker buyer portal ($BUYER_URL)..."
if curl -sf --max-time 8 "$BUYER_URL" -o /dev/null; then
  ok "Buyer portal svarer: $BUYER_URL"
else
  fail "Buyer portal svarer ikke: $BUYER_URL"
fi

# Supabase
info "Sjekker Supabase..."
SUPA_STATUS=$(curl -sf --max-time 8 "$SUPABASE_HEALTH" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE:-}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE:-}" \
  -o /dev/null -w "%{http_code}" 2>/dev/null || echo "000")

if [[ "$SUPA_STATUS" == "200" ]]; then
  ok "Supabase tilkoblet (HTTP 200)"
elif [[ "$SUPA_STATUS" == "401" ]]; then
  warn "Supabase nås, men SUPABASE_SERVICE_ROLE mangler eller er feil (HTTP 401)"
else
  fail "Supabase svarer ikke (HTTP $SUPA_STATUS)"
fi

# =============================================================
step "5/5" "Registrer launchd-plister"
# =============================================================

LAUNCHD_DIR="$HOME/Documents/GlobalDistribution/scripts/launchd"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENTS"

PLISTS=(
  "com.gdist.daily-report.plist"
  "com.gdist.monthly-analysis.plist"
  "com.gdist.weekly-analysis.plist"
  "com.gdist.vault-sync.plist"
  "com.gdist.auto-route.plist"
)

for PLIST in "${PLISTS[@]}"; do
  SRC="${LAUNCHD_DIR}/${PLIST}"
  DST="${LAUNCH_AGENTS}/${PLIST}"

  if [[ ! -f "$SRC" ]]; then
    warn "$PLIST ikke funnet i $LAUNCHD_DIR — hopper over"
    continue
  fi

  # Erstatt /Users/gdist med riktig hjemmemappe
  sed "s|/Users/gdist|${HOME}|g" "$SRC" > "$DST"

  # Unload først (ignorerer feil hvis ikke lastet)
  launchctl unload "$DST" 2>/dev/null || true

  if launchctl load "$DST" 2>/dev/null; then
    ok "$PLIST registrert"
  else
    fail "$PLIST — launchctl load feilet"
  fi
done

# =============================================================
# Sluttrapport
# =============================================================

echo ""
echo "${BOLD}=================================================${NC}"

if (( ${#FAILED[@]} == 0 )); then
  echo "${GREEN}${BOLD}  ✅ READY — alle sjekker OK${NC}"
  echo "${BOLD}=================================================${NC}"
  echo ""
  echo "Kodebase: $CODE_DIR"
  echo "Portal:   $PORTAL_URL"
  echo "Supabase: ${SUPABASE_URL:-ikke satt}"
  echo ""
  echo "Neste steg:"
  echo "  cd $CODE_DIR && vercel --prod"

  # Send e-post bekreftelse til Daniel hvis Resend er konfigurert
  if [[ -n "${RESEND_API_KEY:-}" ]] && [[ "$RESEND_API_KEY" != "FYLL_INN_RESEND_API_KEY" ]]; then
    info "Sender bekreftelse til Daniel..."
    SETUP_REPORT="Mac mini er klar.

Oppsummering:
- Kodebase: $CODE_DIR
- Portal: $PORTAL_URL
- Supabase: $SUPABASE_URL
- Launchd-plister registrert: ${#PLISTS[@]}
- Tidspunkt: $(date '+%Y-%m-%d %H:%M:%S')

Alle sjekker OK. Systemet er operativt."

    curl -sf "https://api.resend.com/emails" \
      -H "Authorization: Bearer $RESEND_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{
        \"from\": \"${EMAIL_FROM:-rapport@globaldistribution.no}\",
        \"to\": [\"${EMAIL_DANIEL:-daniel@globaldistribution.no}\"],
        \"subject\": \"✅ SYSTEM READY — Mac mini er klar\",
        \"text\": $(echo "$SETUP_REPORT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
      }" > /dev/null && ok "Bekreftelse sendt til Daniel" || warn "E-post feilet — fortsetter"
  fi
else
  echo "${RED}${BOLD}  ✗ IKKE KLAR — ${#FAILED[@]} feil${NC}"
  echo "${BOLD}=================================================${NC}"
  echo ""
  echo "Følgende feilet:"
  for msg in "${FAILED[@]}"; do
    echo "  ${RED}✗${NC} $msg"
  done
  echo ""
  echo "Fiks disse og kjør scriptet på nytt."
fi

echo ""
