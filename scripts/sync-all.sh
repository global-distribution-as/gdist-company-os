#!/bin/zsh
# =============================================================
# sync-all.sh — Global Distribution AS
# Synker Obsidian-vault til GitHub
# Kjøres: hvert 10. minutt via launchd (se crontab.conf)
# =============================================================

set -euo pipefail

VAULT_DIR="$HOME/Documents/GlobalDistribution"
LOG_FILE="/tmp/gdist-vault-sync.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

log() { echo "[$TIMESTAMP] $1" >> "$LOG_FILE"; }

# Roter log-fil hvis den er over 1 MB
if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0) -gt 1048576 ]; then
  mv "$LOG_FILE" "${LOG_FILE}.bak"
fi

cd "$VAULT_DIR" || { log "FEIL: Finner ikke vault $VAULT_DIR"; exit 1; }

# Sjekk om det er noe å synke
if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
  # Ingen lokale endringer — gjør likevel en pull
  git pull --rebase origin main --quiet 2>> "$LOG_FILE" || log "Pull feilet (ingen nett?)"
  exit 0
fi

# Legg til alt og commit
git add . 2>> "$LOG_FILE"
git commit -m "vault: auto-sync $TIMESTAMP" --quiet 2>> "$LOG_FILE"

# Pull + push (håndterer konflikter)
if git pull --rebase origin main --quiet 2>> "$LOG_FILE"; then
  if git push origin main --quiet 2>> "$LOG_FILE"; then
    log "✓ Synket OK"
  else
    log "FEIL: Push feilet"
  fi
else
  log "FEIL: Pull/rebase feilet — sjekk konflikter manuelt"
  # Abort rebase slik at ikke alt henger
  git rebase --abort 2>> "$LOG_FILE" || true
fi
