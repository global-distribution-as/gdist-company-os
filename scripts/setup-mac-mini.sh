#!/bin/zsh
# =============================================================
# setup-mac-mini.sh — Global Distribution AS
# Kjøres ÉN gang når Mac mini kobles til for første gang.
#
# BRUK:
#   1. Åpne Terminal på Mac mini
#   2. Kjør: zsh <(curl -s https://raw.githubusercontent.com/global-distribution-as/gdist-company-os/main/scripts/setup-mac-mini.sh)
#      ELLER kopiér denne filen og kjør: zsh setup-mac-mini.sh
# =============================================================

set -euo pipefail

# --- Farger ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo "${GREEN}✓${NC} $1"; }
warn() { echo "${YELLOW}⚠${NC}  $1"; }
info() { echo "${BLUE}→${NC}  $1"; }
err()  { echo "${RED}✗${NC} $1"; exit 1; }
step() { echo "\n${BOLD}[$1]${NC} $2"; }

echo ""
echo "${BOLD}=================================================${NC}"
echo "${BOLD}  Global Distribution AS — Mac mini oppsett${NC}"
echo "${BOLD}=================================================${NC}"
echo ""

MAC_USER=$(whoami)
HOME_DIR="$HOME"
VAULT_DIR="$HOME_DIR/Documents/GlobalDistribution"
VAULT_REPO="git@github.com:global-distribution-as/gdist-company-os.git"
SCRIPTS_DIR="$VAULT_DIR/scripts"
LAUNCHD_DIR="$HOME_DIR/Library/LaunchAgents"
CONFIG_FILE="$SCRIPTS_DIR/config.env"

# =============================================================
step "1/8" "Sjekk macOS og bruker"
# =============================================================
info "Bruker: $MAC_USER"
info "Hjemmemappe: $HOME_DIR"

if [[ "$(uname)" != "Darwin" ]]; then
  err "Dette scriptet krever macOS"
fi
ok "macOS bekreftet"

# =============================================================
step "2/8" "Homebrew"
# =============================================================
if command -v brew &>/dev/null; then
  ok "Homebrew allerede installert"
else
  info "Installerer Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Legg til i path for Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME_DIR/.zprofile"
  fi
  ok "Homebrew installert"
fi

# =============================================================
step "3/8" "Nødvendige verktøy"
# =============================================================
TOOLS=(git python3)
for tool in "${TOOLS[@]}"; do
  if command -v "$tool" &>/dev/null; then
    ok "$tool allerede installert"
  else
    info "Installerer $tool..."
    brew install "$tool"
    ok "$tool installert"
  fi
done

# =============================================================
step "4/8" "SSH-nøkkel for GitHub"
# =============================================================
SSH_KEY="$HOME_DIR/.ssh/id_ed25519"
if [ -f "$SSH_KEY" ]; then
  ok "SSH-nøkkel finnes allerede"
else
  info "Oppretter SSH-nøkkel..."
  mkdir -p "$HOME_DIR/.ssh"
  chmod 700 "$HOME_DIR/.ssh"
  ssh-keygen -t ed25519 -C "gdist-mac-mini@globaldistribution.no" -f "$SSH_KEY" -N ""
  ok "SSH-nøkkel opprettet"
fi

echo ""
echo "${BOLD}VIKTIG: Legg til denne SSH-nøkkelen i GitHub:${NC}"
echo "${YELLOW}→  github.com/organizations/global-distribution-as/settings/keys${NC}"
echo ""
cat "$SSH_KEY.pub"
echo ""
echo "Trykk ENTER når nøkkelen er lagt til i GitHub..."
read -r

# Test SSH-tilkobling
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  ok "GitHub SSH-tilkobling fungerer"
else
  warn "Klarte ikke verifisere GitHub SSH — fortsetter likevel"
fi

# =============================================================
step "5/8" "Klon Obsidian-vault"
# =============================================================
if [ -d "$VAULT_DIR/.git" ]; then
  ok "Vault allerede klonet"
  cd "$VAULT_DIR" && git pull --rebase origin main --quiet
  ok "Vault oppdatert"
else
  info "Kloner vault..."
  mkdir -p "$HOME_DIR/Documents"
  git clone "$VAULT_REPO" "$VAULT_DIR"
  ok "Vault klonet til $VAULT_DIR"
fi

# =============================================================
step "6/8" "Konfigurer scripts"
# =============================================================

# Erstatt 'gdist' med faktisk brukernavn i alle scripts og plister
info "Tilpasser scripts til bruker: $MAC_USER"
for f in "$SCRIPTS_DIR"/*.sh "$SCRIPTS_DIR"/launchd/*.plist "$SCRIPTS_DIR"/crontab.conf; do
  [ -f "$f" ] && sed -i '' "s|/Users/gdist|$HOME_DIR|g" "$f"
done

# Gjør scripts kjørbare
chmod +x "$SCRIPTS_DIR"/*.sh
ok "Scripts er kjørbare"

# Sjekk om config.env er fylt ut
if grep -q "FYLL_INN" "$CONFIG_FILE" 2>/dev/null; then
  echo ""
  warn "config.env har tomme verdier som må fylles ut:"
  echo "  $CONFIG_FILE"
  echo ""
  echo "Åpne filen og fyll inn:"
  echo "  - SUPABASE_SERVICE_ROLE  (fra Supabase Dashboard → Settings → API)"
  echo "  - RESEND_API_KEY         (fra resend.com)"
  echo "  - EMAIL_DANIEL og EMAIL_MARTIN"
  echo ""
  echo "Trykk ENTER når config.env er fylt ut..."
  read -r
fi

ok "config.env lest"

# =============================================================
step "7/8" "Installer LaunchAgents (NOT startet ennå)"
# =============================================================
mkdir -p "$LAUNCHD_DIR"

for plist in "$SCRIPTS_DIR/launchd/"*.plist; do
  PLIST_NAME=$(basename "$plist")
  cp "$plist" "$LAUNCHD_DIR/$PLIST_NAME"
  info "Kopiert: $PLIST_NAME"
done

ok "LaunchAgents kopiert — IKKE aktivert ennå"

echo ""
echo "${BOLD}For å aktivere automatisering, kjør disse kommandoene:${NC}"
echo ""
echo "  # Vault-sync hvert 10. minutt:"
echo "  launchctl load $LAUNCHD_DIR/com.gdist.vault-sync.plist"
echo ""
echo "  # Daglig rapport kl 07:30:"
echo "  launchctl load $LAUNCHD_DIR/com.gdist.daily-report.plist"
echo ""
echo "  # Sjekk at de kjører:"
echo "  launchctl list | grep gdist"
echo ""

# =============================================================
step "8/8" "Test daglig rapport (dry run)"
# =============================================================
echo "Vil du teste daglig rapport nå? (sender til logg, ikke e-post) [j/N]"
read -r ANSWER
if [[ "$ANSWER" =~ ^[jJyY]$ ]]; then
  info "Kjører test..."
  # Sett dummy API-key for test-run (sender til logg)
  RESEND_API_KEY="" zsh "$SCRIPTS_DIR/daily-report.sh" || warn "Test feilet — sjekk /tmp/gdist-daily-report.log"
  ok "Test fullført — sjekk: cat /tmp/gdist-daily-report.log"
else
  info "Hopper over test"
fi

# =============================================================
# Ferdig
# =============================================================
echo ""
echo "${BOLD}=================================================${NC}"
echo "${GREEN}${BOLD}  Oppsett fullført!${NC}"
echo "${BOLD}=================================================${NC}"
echo ""
echo "Neste steg:"
echo "  1. Åpne Obsidian → 'Open folder as vault' → $VAULT_DIR"
echo "  2. Aktiver LaunchAgents (kommandoer ovenfor)"
echo "  3. Verifiser daglig rapport i Resend-dashboardet"
echo ""
echo "Loggfiler:"
echo "  tail -f /tmp/gdist-vault-sync.log"
echo "  tail -f /tmp/gdist-daily-report.log"
echo ""
