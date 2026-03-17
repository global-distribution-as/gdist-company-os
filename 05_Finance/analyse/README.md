# Vinn/tap-analyse — Global Distribution AS

> Etter **hver** avsluttet ordre eller tapt deal: fyll ut skjemaet. Tar 2 minutter.
> Første mandag hver måned: Claude analyserer alle oppføringer og gir dere en rapport.

---

## Slik fyller du ut (2 min)

1. Kopier `entries/_mal.md`
2. Gi filen navn etter konvensjonen: `ÅÅÅÅ-MM-DD_vinntak_[vunnet|tapt]_buyer-produkt.md`
3. Fyll ut frontmatter (toppen) og kryss av i riktig boks
4. Legg filen i `entries/` — eller dropp den i `00_INBOX/` (sorteres automatisk)

**Eksempel filnavn:**
```
2026-03-16_vinntak_vunnet_sportscohk-vinterjakker.md
2026-03-20_vinntak_tapt_beijing-retail-softshell.md
```

---

## Hva rapporten gir dere

Hver 1. i måneden kjøres analysen automatisk. Rapporten havner i `reports/` og inneholder:

- **Hitrate per produktkategori** — hvilke kategorier vi vinner flest deals på
- **Kjøpermønster** — hvem som kjøper igjen vs. engangs
- **Tapsgrunner** — hva vi taper på og konkrete tiltak
- **3 prioriterte anbefalinger** for neste måned

---

## Kjør analysen manuelt

```zsh
zsh ~/Documents/GlobalDistribution/scripts/monthly-analysis.sh
```

---

## Filer

| Fil | Hva |
|---|---|
| `entries/_mal.md` | Mal — kopier denne |
| `entries/DATO_vinntak_*.md` | Individuelle oppføringer |
| `reports/YYYY-MM_analyse.md` | Månedlige analyser fra Claude |
