#!/bin/zsh
# =============================================================
# check-names.sh — Global Distribution AS
# Sjekker at operative filer i vaulten følger navnekonvensjonen:
#   ÅÅÅÅ-MM-DD_type_beskrivelse.md
#
# Bruk: zsh ~/Documents/GlobalDistribution/scripts/check-names.sh
# =============================================================

VAULT_DIR="${0:A:h}/.."
VAULT_DIR="$(cd "$VAULT_DIR" && pwd)"

# --- Farger ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
GRAY='\033[0;90m'; BOLD='\033[1m'; NC='\033[0m'

# --- Gyldige typer ---
VALID_TYPES="ordre|inquiry|supplier|buyer|kontrakt|faktura|sop|beslutning|rapport"

# --- Korrekt mønster ---
# 2026-03-16_type_beskrivelse-med-bindestreker.md
PATTERN="^[0-9]{4}-[0-9]{2}-[0-9]{2}_(${VALID_TYPES})_[a-z0-9][a-z0-9-]*\.md$"

# --- Unntak: filer og mapper som IKKE skal sjekkes ---
# Mønstrene matches mot hele relative stien fra vault-roten
EXEMPT_PATTERNS=(
  "^\.git/"                        # git-internals
  "/_Templates/"                   # maler
  "/_Archive/"                     # arkiv
  "/node_modules/"                 # hvis noe havner her
  "/_Index\.md$"                   # indeksfiler
  "/README\.md$"                   # readme-filer
  "/Dashboard\.md$"                # dashboard
  "/Home\.md$"                     # hjem
  "/SYNC-SETUP\.md$"               # systemfil
  "/CLI-WORKFLOW\.md$"             # systemfil
  "/NAVNEKONVENSJON\.md$"          # denne konvensjonen
  "/MARTIN_PLAYBOOK\.md$"          # playbooks
  "/JESSICA_PLAYBOOK\.md$"
  "/VELKOMMEN\.md$"
  "/FEIL_OG_L"                     # FEIL_OG_LØSNINGER (æøå-safe match)
  "/KONTAKTER\.md$"
  "/00_START_HER\.md$"
  "/Daily-log-"                    # daglige logger
  "/Daglig-sjekkliste\.md$"
  "/Catalogue\.md$"                # produkt-katalog (strukturfil)
  "/changelog\.md$"                # tekniske endringslogg
  "/Roadmap\.md$"                  # teknisk roadmap
  "/Architecture\.md$"             # teknisk doc
  "/Supabase\.md$"
  "/Vercel\.md$"
  "/Tripletex\.md$"
  "/Tasks\.md$"
  "/Prosjekt-mal\.md$"
  "/Global-Distribution-Ops\.md$"
  "/\.obsidian/"                   # obsidian-konfig
  "/PHILOSOPHY\.md$"               # selskapets verdidokument
  "/00_START_HER\.md$"             # onboarding-startpunkt (duplikat av VELKOMMEN)
)

is_exempt() {
  # Prepend / so root-level files match patterns like /README\.md$
  local rel="/$1"
  for pat in "${EXEMPT_PATTERNS[@]}"; do
    if echo "$rel" | grep -qE "$pat"; then
      return 0
    fi
  done
  return 1
}

# --- Samle filer ---
violations=()
skipped=0
checked=0

while IFS= read -r -d '' filepath; do
  rel="${filepath#$VAULT_DIR/}"
  filename="$(basename "$filepath")"

  if is_exempt "$rel"; then
    (( skipped++ ))
    continue
  fi

  (( checked++ ))

  if ! echo "$filename" | grep -qE "$PATTERN"; then
    violations+=("$rel")
  fi

done < <(find "$VAULT_DIR" -name "*.md" -print0 | sort -z)

# --- Rapport ---
echo ""
echo "${BOLD}Global Distribution — Navnesjekk${NC}"
echo "Vault: $VAULT_DIR"
echo "$(date '+%Y-%m-%d %H:%M')"
echo ""

if [ ${#violations[@]} -eq 0 ]; then
  echo "${GREEN}${BOLD}✓ Alle $checked operative filer følger konvensjonen.${NC}"
else
  echo "${RED}${BOLD}✗ ${#violations[@]} fil(er) bryter navnekonvensjonen:${NC}"
  echo ""
  for v in "${violations[@]}"; do
    filename="$(basename "$v")"
    dir="$(dirname "$v")"
    echo "  ${RED}✗${NC} ${YELLOW}${filename}${NC}"
    echo "    ${GRAY}→ $dir${NC}"
  done
  echo ""
  echo "${BOLD}Forventet format:${NC}"
  echo "  ${GREEN}ÅÅÅÅ-MM-DD_type_beskrivelse.md${NC}"
  echo ""
  echo "${BOLD}Gyldige typer:${NC}"
  echo "  ${GREEN}ordre  inquiry  supplier  buyer  kontrakt  faktura  sop  beslutning  rapport${NC}"
  echo ""
  echo "Eksempel: ${GREEN}2026-03-16_ordre_vinterjakke-sportscohk-500stk.md${NC}"
fi

echo ""
echo "${GRAY}Sjekket: $checked fil(er)  |  Hoppet over (unntak): $skipped fil(er)${NC}"
echo ""
