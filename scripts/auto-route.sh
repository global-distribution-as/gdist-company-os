#!/bin/zsh
# =============================================================
# auto-route.sh — Global Distribution AS
# Sorterer filer fra 00_INBOX/ til riktig mappe basert på
# navnekonvensjonen: ÅÅÅÅ-MM-DD_type_beskrivelse.md
#
# Kjøres: hvert 5. minutt via launchd
# Logg:   vault/09_Tech/routing-log.md  (markdown, synces til GitHub)
#         /tmp/gdist-auto-route.log      (system-logg, feilsøking)
#
# Bruk manuelt:
#   zsh ~/Documents/GlobalDistribution/scripts/auto-route.sh
# =============================================================

set -euo pipefail

# --- Konfigurasjon ---
SCRIPT_DIR="${0:A:h}"
VAULT_DIR="${HOME}/Documents/GlobalDistribution"
INBOX_DIR="${VAULT_DIR}/00_INBOX"
MD_LOG="${VAULT_DIR}/09_Tech/routing-log.md"
SYS_LOG="/tmp/gdist-auto-route.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
DATE_ONLY=$(date '+%Y-%m-%d')

# --- Rutingtabell: type → destinasjonsmappe (relativ til VAULT_DIR) ---
typeset -A ROUTES
ROUTES=(
  ordre       "04_Orders"
  order       "04_Orders"
  inquiry     "01_Buyers/Active"
  buyer       "01_Buyers/Active"
  supplier    "02_Suppliers/Active"
  leverandor  "02_Suppliers/Active"
  kontrakt    "07_Legal/Contracts"
  contract    "07_Legal/Contracts"
  faktura     "05_Finance/Invoices"
  invoice     "05_Finance/Invoices"
  sop         "06_Operations/SOPs"
  beslutning  "08_Projects/portal/decisions"
  decision    "08_Projects/portal/decisions"
  rapport     "05_Finance/Reports"
  meeting     "06_Operations/Meetings"
  referat     "06_Operations/Meetings"
  produkt     "03_Products/Catalogue"
  product     "03_Products/Catalogue"
  log         "10_Log"
  vinntak     "05_Finance/analyse/entries"
)

# --- Hjelpefunksjoner ---

sys_log() {
  echo "[$TIMESTAMP] $1" >> "$SYS_LOG"
}

# Roter system-logg ved >1 MB
if [[ -f "$SYS_LOG" ]] && (( $(stat -f%z "$SYS_LOG" 2>/dev/null || echo 0) > 1048576 )); then
  mv "$SYS_LOG" "${SYS_LOG}.bak"
fi

# Initialiser markdown-logg hvis den ikke finnes
if [[ ! -f "$MD_LOG" ]]; then
  mkdir -p "$(dirname "$MD_LOG")"
  {
    echo "# Routing Log — auto-route.sh"
    echo ""
    echo "> Automatisk generert. Filer droppes i \`00_INBOX/\` og sorteres hit."
    echo "> Format: \`ÅÅÅÅ-MM-DD_type_beskrivelse.md\` — se [[NAVNEKONVENSJON]]."
    echo ""
    echo "---"
    echo ""
  } > "$MD_LOG"
  sys_log "Opprettet ny routing-log: $MD_LOG"
fi

# md_log: skriv én linje til markdown-loggen
# Legger til dato-header første gang for i dag
md_log() {
  local route_status="$1"   # OK | FEIL | UKJENT
  local fn="$2"
  local dest="$3"
  local note="${4:-}"

  # Legg til datooverskrift hvis ikke allerede der
  if ! grep -qF "## ${DATE_ONLY}" "$MD_LOG" 2>/dev/null; then
    echo "" >> "$MD_LOG"
    echo "## ${DATE_ONLY}" >> "$MD_LOG"
    echo "" >> "$MD_LOG"
  fi

  case "$route_status" in
    OK)      echo "- ${TIMESTAMP} | \`${fn}\` → \`${dest}\` ✓" >> "$MD_LOG" ;;
    FEIL)    echo "- ${TIMESTAMP} | \`${fn}\` → FEIL: ${note}" >> "$MD_LOG" ;;
    UKJENT)  echo "- ${TIMESTAMP} | \`${fn}\` → ⚠️ Ukjent type — beholdt i \`00_INBOX/\`" >> "$MD_LOG" ;;
  esac
}

# safe_destination: returner trygg filsti — legger til HHmmss-suffiks ved kollisjon
safe_destination() {
  local dest_dir="$1"
  local fn="$2"
  local dest="${dest_dir}/${fn}"

  if [[ ! -e "$dest" ]]; then
    echo "$dest"
    return
  fi

  local base="${fn%.md}"
  local ts=$(date '+%H%M%S')
  echo "${dest_dir}/${base}-${ts}.md"
}

# --- Sjekk at INBOX finnes ---
if [[ ! -d "$INBOX_DIR" ]]; then
  sys_log "FEIL: INBOX-mappen finnes ikke: $INBOX_DIR"
  exit 1
fi

# --- Prosesser filer i INBOX ---
moved=0
skipped=0
unknown=0

for filepath in "$INBOX_DIR"/*(.N); do
  fn="$(basename "$filepath")"

  # Hopp over README og skjulte filer
  [[ "$fn" == "README.md" ]] && continue
  [[ "$fn" == .* ]] && continue

  # Kun .md-filer
  if [[ "$fn" != *.md ]]; then
    sys_log "Hopper over ikke-md fil: $fn"
    (( skipped += 1 ))
    continue
  fi

  # --- Trekk ut type ---
  # Standard: ÅÅÅÅ-MM-DD_type_beskrivelse.md → andre _-felt
  # Fallback:  type-beskrivelse.md            → del før første -
  file_type=""
  if echo "$fn" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}_'; then
    file_type=$(echo "$fn" | cut -d'_' -f2 | tr '[:upper:]' '[:lower:]')
  else
    file_type=$(echo "$fn" | cut -d'-' -f1 | tr '[:upper:]' '[:lower:]')
  fi

  # --- Spesialbehandling: intake → kjør onboarding-pipeline ---
  if [[ "$file_type" == "intake" ]]; then
    sys_log "Intake-fil oppdaget: $fn — starter supplier-onboard.sh"
    md_log "OK" "$fn" "onboarding-pipeline"
    if zsh "$SCRIPT_DIR/supplier-onboard.sh" "$filepath" >> "$SYS_LOG" 2>&1; then
      sys_log "✓ Onboarding fullført: $fn"
    else
      sys_log "FEIL: Onboarding feilet for $fn — se $SYS_LOG"
      md_log "FEIL" "$fn" "" "supplier-onboard.sh feilet"
    fi
    (( moved += 1 ))
    continue
  fi

  # --- Finn destinasjon ---
  if [[ -z "${ROUTES[$file_type]:-}" ]]; then
    sys_log "Ukjent type '${file_type}' for fil: $fn — flytter til 00_INBOX/UNSORTED/"
    UNSORTED_DIR="${INBOX_DIR}/UNSORTED"
    mkdir -p "$UNSORTED_DIR"
    unsorted_dest="$(safe_destination "$UNSORTED_DIR" "$fn")"
    if mv "$filepath" "$unsorted_dest"; then
      md_log "UKJENT" "$fn" "00_INBOX/UNSORTED/" ""
      sys_log "Plassert i UNSORTED: $fn"
    else
      sys_log "FEIL: Klarte ikke flytte $fn til UNSORTED"
    fi
    (( unknown += 1 ))
    continue
  fi

  dest_dir="${VAULT_DIR}/${ROUTES[$file_type]}"

  # Opprett destinasjonsmappe hvis den mangler
  if [[ ! -d "$dest_dir" ]]; then
    mkdir -p "$dest_dir"
    sys_log "Opprettet mappe: ${ROUTES[$file_type]}"
  fi

  # Håndter navnekollisjon
  dest_file="$(safe_destination "$dest_dir" "$fn")"
  dest_basename="$(basename "$dest_file")"

  # Flytt
  if mv "$filepath" "$dest_file"; then
    sys_log "Flyttet: $fn → ${ROUTES[$file_type]}/${dest_basename}"
    md_log "OK" "$fn" "${ROUTES[$file_type]}/${dest_basename}"
    osascript -e "display notification \"${fn}\" with title \"GDist\" subtitle \"→ ${ROUTES[$file_type]}\"" 2>/dev/null || true
    (( moved += 1 ))
  else
    sys_log "FEIL: Kunne ikke flytte $fn"
    md_log "FEIL" "$fn" "" "mv feilet"
  fi
done

# Oppsummering i system-logg (kun hvis noe skjedde)
if (( moved > 0 || unknown > 0 )); then
  sys_log "Ferdig — flyttet: $moved | ukjent: $unknown | hoppet over: $skipped"
fi

exit 0
