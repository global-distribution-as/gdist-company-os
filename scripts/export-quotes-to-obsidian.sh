#!/bin/zsh
# =============================================================
# export-quotes-to-obsidian.sh — Global Distribution AS
# Henter nye quotes fra Supabase og oppretter Obsidian-filer
# Kjøres: hvert 30. minutt via launchd
# =============================================================

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.env"

VAULT_DIR="$HOME/Documents/GlobalDistribution"
QUOTES_DIR="$VAULT_DIR/04_Orders/Quotes"
LOG_FILE="/tmp/gdist-quote-export.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

log() { echo "[$TIMESTAMP] $1" >> "$LOG_FILE"; }

mkdir -p "$QUOTES_DIR"

# Fetch quotes not yet exported
QUOTES=$(curl -sf \
  "$SUPABASE_URL/rest/v1/quotes?exported_to_obsidian=eq.false&status=eq.sent&select=id,quote_number,buyer_name_override,buyer_company,buyer_country,language,delivery_weeks,margin_pct,total_usd,notes,obsidian_followup_date,created_at" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE" \
  -H "apikey: $SUPABASE_SERVICE_ROLE" 2>/dev/null || echo "[]")

COUNT=$(echo "$QUOTES" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")

if [ "$COUNT" = "0" ]; then
  log "Ingen nye quotes å eksportere"
  exit 0
fi

log "Eksporterer $COUNT quote(s)..."

echo "$QUOTES" | python3 - <<'PYEOF'
import json, sys, os, subprocess

data = json.load(sys.stdin)
vault = os.path.expanduser("~/Documents/GlobalDistribution")
quotes_dir = os.path.join(vault, "04_Orders/Quotes")
supabase_url = os.environ.get("SUPABASE_URL", "")
service_role = os.environ.get("SUPABASE_SERVICE_ROLE", "")

import urllib.request

for q in data:
    qnum    = q.get("quote_number", "QUO-?")
    company = q.get("buyer_company") or q.get("buyer_name_override") or "Unknown"
    country = q.get("buyer_country", "")
    lang    = q.get("language", "en")
    weeks   = q.get("delivery_weeks", 6)
    margin  = q.get("margin_pct") or 0
    total   = q.get("total_usd") or 0
    notes   = q.get("notes") or ""
    followup= q.get("obsidian_followup_date") or ""
    date    = (q.get("created_at") or "")[:10]
    qid     = q.get("id")

    # Build filename per naming convention
    safe_company = company.lower().replace(" ", "-").replace("/", "-")[:30]
    filename = f"{date}_rapport_tilbud-{qnum.lower()}-{safe_company}.md"
    filepath = os.path.join(quotes_dir, filename)

    md = f"""---
title: {qnum}
type: rapport
date: {date}
followup: {followup}
status: sent
buyer: {company}
country: {country}
language: {lang}
---

# {qnum} — {company}

**Dato sendt:** {date}
**Buyer:** {company} · {country}
**Språk:** {lang.upper()}
**Levering:** {weeks}–{weeks+2} uker
**Total:** USD {total:,.2f}
**Margin:** {float(margin):.1f}%

## Notater

{notes or "—"}

## Oppfølging

**Neste kontakt:** {followup}
- [ ] Sjekk om buyer har mottatt tilbudet
- [ ] Følg opp status
- [ ] Oppdater buyer-profil i 01_Buyers/

## Logg

| Dato | Hendelse |
|------|----------|
| {date} | Tilbud generert og sendt |
"""

    with open(filepath, "w") as f:
        f.write(md)

    print(f"  Skrevet: {filename}")

    # Mark as exported in Supabase
    if qid and supabase_url and service_role:
        req = urllib.request.Request(
            f"{supabase_url}/rest/v1/quotes?id=eq.{qid}",
            data=json.dumps({"exported_to_obsidian": True}).encode(),
            headers={
                "Authorization": f"Bearer {service_role}",
                "apikey": service_role,
                "Content-Type": "application/json",
                "Prefer": "return=minimal",
            },
            method="PATCH"
        )
        try:
            urllib.request.urlopen(req)
        except Exception as e:
            print(f"  Advarsel: Klarte ikke markere som eksportert: {e}")

PYEOF

log "Eksport ferdig — $COUNT fil(er) skrevet til $QUOTES_DIR"

# Commit til git
cd "$VAULT_DIR"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  git add "$QUOTES_DIR"
  git commit -m "vault: eksporter $COUNT tilbud til Obsidian" --quiet
  git push origin main --quiet && log "✓ Pushet til GitHub"
fi
