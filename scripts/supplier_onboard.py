#!/usr/bin/env python3
"""
supplier_onboard.py — Global Distribution AS
Kjøres av supplier-onboard.sh. Les alle env-variabler derfra.

Steg:
  1. Parse intake-fil (YAML frontmatter + produkttabell)
  2. Opprett leverandør i Supabase
  3. Opprett produkter i Supabase
  4. Generer velkomstemailer via Claude API
  5. Skriv Obsidian-leverandørfil
  6. Skriv e-postfiler
  7. Skriv 30-dagers påminnelse
  8. Arkiver intake-fil
"""

import json
import os
import re
import sys
import urllib.error
import urllib.request
from datetime import date, timedelta
from pathlib import Path

# ── Konfig fra env ───────────────────────────────────────────────────────────
SUPABASE_URL     = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_KEY     = os.environ["SUPABASE_SERVICE_ROLE"]
ANTHROPIC_KEY    = os.environ.get("ANTHROPIC_API_KEY", "")
VAULT_DIR        = Path(os.environ["VAULT_DIR"])
INTAKE_FILE      = Path(sys.argv[1])

TODAY      = date.today().isoformat()          # 2026-03-16
TODAY_DISP = date.today().strftime("%-d. %B %Y")  # 16. mars 2026
REMINDER   = (date.today() + timedelta(days=30)).isoformat()

# ── Logging ──────────────────────────────────────────────────────────────────
def log(msg: str):
    print(f"[{TODAY}] {msg}", flush=True)

def die(msg: str):
    log(f"FEIL: {msg}")
    sys.exit(1)

# ── Supabase REST ─────────────────────────────────────────────────────────────
def sb_post(table: str, data: dict) -> dict:
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    payload = json.dumps(data).encode()
    req = urllib.request.Request(url, data=payload, headers={
        "apikey":         SUPABASE_KEY,
        "Authorization":  f"Bearer {SUPABASE_KEY}",
        "Content-Type":   "application/json",
        "Prefer":         "return=representation",
    })
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            result = json.loads(r.read())
            return result[0] if isinstance(result, list) else result
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        die(f"Supabase {table} POST feilet: {e.code} — {body}")

# ── Claude API ────────────────────────────────────────────────────────────────
def claude(prompt: str, max_tokens: int = 1200) -> str:
    if not ANTHROPIC_KEY or ANTHROPIC_KEY.startswith("FYLL_INN"):
        log("Advarsel: ANTHROPIC_API_KEY ikke satt — bruker placeholder-epost")
        return None
    payload = json.dumps({
        "model": "claude-sonnet-4-6",
        "max_tokens": max_tokens,
        "messages": [{"role": "user", "content": prompt}]
    }).encode()
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=payload,
        headers={
            "x-api-key":          ANTHROPIC_KEY,
            "anthropic-version":  "2023-06-01",
            "content-type":       "application/json",
        }
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            data = json.loads(r.read())
            return data["content"][0]["text"]
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        log(f"Claude API feil: {e.code} — {body}")
        return None

# ── Parse intake-fil ──────────────────────────────────────────────────────────
def parse_intake(path: Path) -> tuple[dict, list[dict]]:
    text = path.read_text(encoding="utf-8")

    # --- YAML frontmatter ---
    fm_match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not fm_match:
        die("Intake-filen mangler YAML frontmatter (--- ... ---)")

    fm_text = fm_match.group(1)
    supplier = {}
    for line in fm_text.splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            supplier[k.strip()] = v.strip()

    required = ["firma", "kontakt", "epost", "land"]
    missing = [f for f in required if not supplier.get(f)]
    if missing:
        die(f"Mangler påkrevde felt: {', '.join(missing)}")

    # --- Produkttabell ---
    products = []
    in_table = False
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("| Navn") or line.startswith("|---"):
            in_table = True
            continue
        if not in_table:
            continue
        if not line.startswith("|"):
            in_table = False
            continue
        cols = [c.strip() for c in line.strip("|").split("|")]
        if len(cols) >= 2 and cols[0] and cols[0] not in ("Navn", "---", ""):
            products.append({
                "name":         cols[0],
                "category":     cols[1] if len(cols) > 1 else "Annet",
                "price_nok":    cols[2] if len(cols) > 2 else "",
                "brand":        cols[3] if len(cols) > 3 else supplier.get("firma", ""),
                "description":  cols[4] if len(cols) > 4 else "",
            })

    if not products:
        die("Ingen produkter funnet i tabellen — minst én rad kreves")

    return supplier, products

# ── SKU-generator ─────────────────────────────────────────────────────────────
def make_sku(supplier_name: str, index: int) -> str:
    prefix = re.sub(r"[^A-Z]", "", supplier_name.upper())[:4]
    if len(prefix) < 2:
        prefix = (supplier_name.upper().replace(" ", "")[:4]).ljust(2, "X")
    return f"{prefix}-{index:03d}"

# ── Velkomstemail via Claude ───────────────────────────────────────────────────
def generate_emails(supplier: dict, products: list[dict]) -> dict:
    product_list = "\n".join(
        f"  - {p['name']} ({p['category']})" for p in products
    )
    prompt = f"""Skriv en velkomstemail fra Global Distribution AS til en ny leverandør.
Global Distribution AS er et norsk handelsselskap som kobler europeiske leverandører med asiatiske buyers.

Leverandørinfo:
- Firma: {supplier['firma']}
- Kontakt: {supplier['kontakt']}
- Land: {supplier['land']}
- Produkter:
{product_list}

Skriv TO versjoner — skill dem med "---ENGLISH---":
1. NORSK: Varm og profesjonell. Nevn at vi ser frem til samarbeidet, at produktene er lagt inn i systemet, og at vi tar kontakt innen 30 dager med oppdatering om buyer-interesse. Maks 150 ord.
2. ENGLISH: Same content in English. Max 150 words.

Ikke inkluder emnefelter eller signaturer — bare brødteksten."""

    result = claude(prompt)
    if not result:
        no = f"""Hei {supplier['kontakt']},

Velkommen som leverandør hos Global Distribution AS! Vi er glade for å ha {supplier['firma']} med i vårt nettverk.

Produktene dine er nå lagt inn i systemet vårt og gjort tilgjengelig for våre asiatiske buyers. Vi tar kontakt innen 30 dager med tilbakemelding om interesse.

Ikke nøl med å kontakte oss om du har spørsmål.

Beste hilsen,
Global Distribution AS"""
        en = f"""Dear {supplier['kontakt']},

Welcome to Global Distribution AS! We are pleased to have {supplier['firma']} as part of our supplier network.

Your products have been added to our system and are now available to our Asian buyer network. We will be in touch within 30 days with feedback on buyer interest.

Please don't hesitate to contact us if you have any questions.

Best regards,
Global Distribution AS"""
        return {"no": no, "en": en}

    parts = result.split("---ENGLISH---")
    return {
        "no": parts[0].strip(),
        "en": parts[1].strip() if len(parts) > 1 else parts[0].strip()
    }

# ── Obsidian leverandørfil ────────────────────────────────────────────────────
def write_obsidian_file(supplier: dict, products: list[dict],
                        supplier_id: str, product_rows: list[dict]) -> Path:
    dest_dir = VAULT_DIR / "02_Suppliers" / "Active"
    dest_dir.mkdir(parents=True, exist_ok=True)

    safe_name = re.sub(r"[^\w-]", "-", supplier["firma"].lower())
    filename  = f"{TODAY}_supplier_{safe_name}.md"
    filepath  = dest_dir / filename

    product_table = "\n".join(
        f"| {p['name']} | {p['category']} | {p.get('price_nok','')} | {p.get('sku','')} |"
        for p in product_rows
    )
    admin_url = f"https://gdist.no/admin/suppliers/{supplier_id}"

    content = f"""# Leverandør: {supplier['firma']}

**Status:** Aktiv
**Lagt til:** {TODAY}
**Supabase ID:** `{supplier_id}`
**Admin-link:** [{admin_url}]({admin_url})

---

## Kontaktinfo

**Kontaktperson:** {supplier.get('kontakt', '')}
**E-post:** {supplier.get('epost', '')}
**Telefon:** {supplier.get('telefon', '')}
**Nettside:** {supplier.get('nettside', '')}
**Lokasjon:** {supplier.get('lokasjon', '')}
**Land:** {supplier.get('land', '')}

---

## Produkter

| Produkt | Kategori | Pris NOK | SKU |
|---|---|---|---|
{product_table}

→ Produkter på plattformen: [{admin_url}]({admin_url})

---

## Betalingsbetingelser

**Betalingsbetingelser:** {supplier.get('betalingsbetingelser', 'Net 30')}
**Valuta:** {supplier.get('valuta', 'EUR')}

---

## Ordre

| Ordrenr | Dato | Status | Beløp |
|---|---|---|---|
|  |  |  |  |

---

## Notater

{supplier.get('notater', '')}

---

## Historikk

| Dato | Hendelse |
|---|---|
| {TODAY} | Leverandør opprettet via onboarding-pipeline |
| {REMINDER} | **Oppfølging — sjekk buyer-interesse** |
"""
    filepath.write_text(content, encoding="utf-8")
    return filepath

# ── Skriv e-postfiler ─────────────────────────────────────────────────────────
def write_email_files(supplier: dict, emails: dict) -> Path:
    email_dir = VAULT_DIR / "02_Suppliers" / "Active"
    safe_name = re.sub(r"[^\w-]", "-", supplier["firma"].lower())
    filepath  = email_dir / f"{TODAY}_supplier_{safe_name}-velkomstemail.md"

    content = f"""# Velkomstemail — {supplier['firma']}

_Generert: {TODAY}_
_Send til: {supplier.get('epost', '?')}_

---

## Norsk

{emails['no']}

---

## English

{emails['en']}

---

_Kopier teksten til e-postklienten din. Legg til emne, hilsen og signatur._
**Foreslått emne (NO):** Velkommen til Global Distribution AS — {supplier['firma']}
**Foreslått emne (EN):** Welcome to Global Distribution AS — {supplier['firma']}
"""
    filepath.write_text(content, encoding="utf-8")
    return filepath

# ── Skriv påminnelsesfil ──────────────────────────────────────────────────────
def write_reminder(supplier: dict, supplier_id: str) -> Path:
    reminder_dir = VAULT_DIR / "10_Log" / "reminders"
    reminder_dir.mkdir(parents=True, exist_ok=True)
    safe_name = re.sub(r"[^\w-]", "-", supplier["firma"].lower())
    filepath  = reminder_dir / f"{REMINDER}_reminder_followup-{safe_name}.md"

    content = f"""# Påminnelse: Oppfølging — {supplier['firma']}

**Dato:** {REMINDER} (30 dager etter onboarding)
**Leverandør:** {supplier['firma']}
**Kontakt:** {supplier.get('kontakt', '')} — {supplier.get('epost', '')}
**Supabase:** `{supplier_id}`

---

## Sjekkliste

- [ ] Er produktene synlig på gdist.no?
- [ ] Har noen buyers vist interesse?
- [ ] Er det buyers vi bør sende produktinfo til aktivt?
- [ ] Trenger leverandøren noe fra oss?
- [ ] Oppdater historikk i [[02_Suppliers/Active/{TODAY}_supplier_{safe_name}]]

## Kontakttekst (forslag)

> Hei {supplier.get('kontakt', '')}, vi ønsket å ta kontakt og gi deg en oppdatering etter de første 30 dagene. Produktene dine er aktive i systemet og vi har allerede vist dem til flere buyers. [Legg til spesifikk info om interesse].
"""
    filepath.write_text(content, encoding="utf-8")
    return filepath

# ── Arkiver intake-fil ────────────────────────────────────────────────────────
def archive_intake(intake_path: Path):
    archive_dir = VAULT_DIR / "_Archive" / "intakes"
    archive_dir.mkdir(parents=True, exist_ok=True)
    dest = archive_dir / intake_path.name
    intake_path.rename(dest)
    return dest

# ── MAIN ──────────────────────────────────────────────────────────────────────
def main():
    if not INTAKE_FILE.exists():
        die(f"Intake-fil finnes ikke: {INTAKE_FILE}")

    log(f"=== Leverandør-onboarding starter: {INTAKE_FILE.name} ===")

    # 1. Parse
    log("1/7 Parser intake-fil...")
    supplier, products = parse_intake(INTAKE_FILE)
    log(f"    Leverandør: {supplier['firma']} | {len(products)} produkt(er)")

    # 2. Opprett leverandør i Supabase
    log("2/7 Oppretter leverandør i Supabase...")
    sb_supplier = sb_post("suppliers", {
        "name":             supplier["firma"],
        "contact_name":     supplier.get("kontakt", ""),
        "email":            supplier.get("epost", ""),
        "phone":            supplier.get("telefon", ""),
        "location":         supplier.get("lokasjon", ""),
        "country":          supplier.get("land", ""),
        "payment_terms":    supplier.get("betalingsbetingelser", "Net 30"),
        "notes":            supplier.get("notater", ""),
        "active":           True,
    })
    supplier_id = sb_supplier["id"]
    log(f"    OK — ID: {supplier_id}")

    # 3. Opprett produkter i Supabase
    log(f"3/7 Oppretter {len(products)} produkt(er) i Supabase...")
    product_rows = []
    for i, p in enumerate(products, 1):
        sku = make_sku(supplier["firma"], i)
        try:
            price = float(p["price_nok"]) if p.get("price_nok") else None
        except ValueError:
            price = None

        sb_product = sb_post("products", {
            "sku":                sku,
            "name":               p["name"],
            "brand":              p.get("brand", supplier["firma"]),
            "category":           p.get("category", "Annet"),
            "description":        p.get("description", ""),
            "supplier_id":        supplier_id,
            "supplier_price_nok": price,
            "stock_quantity":     0,
            "stock_status":       "out_of_stock",
            "status":             "active",
        })
        p["sku"] = sku
        p["id"]  = sb_product["id"]
        product_rows.append(p)
        log(f"    ✓ {p['name']} [{sku}]")

    # 4. Generer velkomstemailer
    log("4/7 Genererer velkomstemailer via Claude...")
    emails = generate_emails(supplier, product_rows)
    log("    OK")

    # 5. Skriv Obsidian-fil
    log("5/7 Skriver Obsidian leverandørfil...")
    obsidian_path = write_obsidian_file(supplier, products, supplier_id, product_rows)
    log(f"    → {obsidian_path.relative_to(VAULT_DIR)}")

    # 6. Skriv e-postfiler
    log("6/7 Skriver e-postfiler...")
    email_path = write_email_files(supplier, emails)
    log(f"    → {email_path.relative_to(VAULT_DIR)}")

    # 7. Skriv påminnelse
    log("7/7 Setter 30-dagers påminnelse...")
    reminder_path = write_reminder(supplier, supplier_id)
    log(f"    → {reminder_path.relative_to(VAULT_DIR)}")

    # 8. Arkiver intake
    archive_path = archive_intake(INTAKE_FILE)
    log(f"    Intake arkivert → {archive_path.relative_to(VAULT_DIR)}")

    log("")
    log(f"=== FERDIG: {supplier['firma']} er live på plattformen ===")
    log(f"    Supabase ID:   {supplier_id}")
    log(f"    Produkter:     {len(product_rows)}")
    log(f"    Obsidian-fil:  {obsidian_path.name}")
    log(f"    Velkomstemail: {email_path.name}")
    log(f"    Påminnelse:    {REMINDER}")

    # Skriv oppsummering til stdout for shell-wrapperen
    print(json.dumps({
        "supplier_id":   supplier_id,
        "firma":         supplier["firma"],
        "product_count": len(product_rows),
        "obsidian":      str(obsidian_path),
        "email_file":    str(email_path),
        "reminder_date": REMINDER,
    }))

if __name__ == "__main__":
    main()
