# Navnekonvensjon — Global Distribution AS

Gjelder for alle operative filer i Obsidian, GitHub og Vercel.
Ikke for systemfiler (se «Unntak» nederst).

---

## Format

```
ÅÅÅÅ-MM-DD_type_beskrivelse.md
```

| Del | Regler |
|-----|--------|
| **ÅÅÅÅ-MM-DD** | Dato dokumentet ble opprettet. ISO 8601. Aldri endre dato etterpå. |
| **type** | Én av de ni godkjente typene (se under). Alltid lowercase. |
| **beskrivelse** | Kort, presist, lowercase, ord skilt med bindestrek. Ingen æøå. |

**Eksempel:** `2026-03-16_ordre_vinterjakke-sportscohk-500stk.md`

---

## Godkjente typer

| Type | Brukes for | Eksempel |
|------|-----------|---------|
| `ordre` | Salgsordre fra buyer | `2026-03-16_ordre_vinterjakke-sportscohk-500stk.md` |
| `inquiry` | Innkommende forespørsel fra buyer | `2026-03-14_inquiry_softshell-beijing-retail-group.md` |
| `supplier` | Leverandørnotat | `2026-01-10_supplier_bergans-of-norway.md` |
| `buyer` | Kjøpernotat | `2026-02-05_buyer_sportscohk-hongkong.md` |
| `kontrakt` | Signert avtale | `2026-03-01_kontrakt_bergans-leverandoravtale-2026.md` |
| `faktura` | Faktura ut eller inn | `2026-03-20_faktura_ORD-2026-001-sportscohk.md` |
| `sop` | Standard arbeidsprosedyre | `2026-03-16_sop_behandle-ny-inquiry.md` |
| `beslutning` | Viktig beslutning logget | `2026-03-10_beslutning_eksklusivitet-korea-marked.md` |
| `rapport` | Rapport eller analyse | `2026-03-01_rapport_pl-februar-2026.md` |
| `vinntak` | Vinn/tap-analyse etter deal | `2026-03-20_vinntak_tapt_beijing-retail-softshell.md` |
| `tilbud` | Generert tilbudsdokument | `2026-03-16_tilbud_QUO-2026-001-sportscohk.md` |
| `intake` | Ny leverandør-onboarding (trigger automatisk pipeline) | `2026-03-16_intake_hansen-textiles.md` |

---

## Regler

1. **Dato = opprettelsesdato.** Endre den aldri, selv om innholdet oppdateres.
2. **Kun lowercase** i type og beskrivelse. `Ordre` er feil. `ordre` er riktig.
3. **Ingen æ, ø, å** — bruk `ae`, `o`, `aa` eller et engelskspråklig alternativ.
4. **Ingen mellomrom** — bruk bindestrek.
5. **Beskrivelse maks 5 ord** — vær konkret, ikke generell.
6. **Ordrenummer i beskrivelse** der det finnes: `..._faktura_ORD-2026-001-buyer.md`

---

## Gjelder ikke for (unntak)

Disse filene følger egne navneregler og skal **ikke** endres:

| Mønster | Eksempel |
|---------|---------|
| Systemfiler med store bokstaver | `README.md`, `Home.md`, `SYNC-SETUP.md` |
| Playbooks og onboarding | `MARTIN_PLAYBOOK.md`, `JESSICA_PLAYBOOK.md`, `VELKOMMEN.md` |
| Maler | `_Templates/*.md` |
| Indeksfiler | `_Index.md` |
| Dashboard | `Dashboard.md` |
| Loggfiler | `Daily-log-*.md` |
| Denne filen | `NAVNEKONVENSJON.md` |

---

## Sjekk hvilke filer som bryter konvensjonen

```zsh
zsh ~/Documents/GlobalDistribution/scripts/check-names.sh
```

---

## GitHub og Vercel

Samme regler gjelder for filer i kodebasen som er dokumenter (ikke kode).
Kodefilene følger sine egne konvensjoner (camelCase for komponenter, kebab-case for routes).
