# Dev Workflow — Global Distribution AS

_Oppdatert: 2026-03-16_

## Daglig arbeidsflyt

### Ny feature

1. **Opprett note i Obsidian** (`08_Projects/` eller `10_Log/`)
2. **Åpne terminal:**
   ```bash
   cd ~/projects/global-distribution/aurora-trade-hub
   claude
   ```
3. **Lim inn feature-prompt** fra `.claude/prompts/feature-impl.md`
4. Claude avklarer → lager plan → vent på **PLAN OK**
5. Claude implementerer, oppdaterer tester og docs
6. **Review diff:**
   ```bash
   git diff
   git status
   ```
7. **Commit og push:**
   ```bash
   git add [relevante filer]
   git commit -m "feat: kort beskrivelse"
   git push origin feat/branch-navn
   ```
8. **Opprett PR** via `gh pr create`
9. Den andre (Daniel/Martin) reviewer og merger

### Bugfix

1. Lim inn prompt fra `.claude/prompts/bugfix.md`
2. Claude finner root cause, fikser, tester
3. Direkte til `main` hvis kritisk, ellers PR

---

## Branch-konvensjon

| Prefix | Når |
|--------|-----|
| `feat/` | Ny funksjonalitet |
| `fix/` | Bugfix |
| `ops/` | Infra, deploy, scripts |
| `docs/` | Kun dokumentasjon |

Eksempel: `feat/ordre-status-filter`, `fix/supabase-auth-redirect`

## Commit-stil

```
feat: legg til ordrestatus-filter i admin
fix: riktig valuta i faktura-PDF
ops: koble Supabase til buyer-portal
docs: oppdater arkitekturoversikt
```

## Sync mellom Daniel og Martin

```bash
# Start dagen:
git pull origin main

# Jobbe på feature:
git checkout -b feat/navn
# ...jobb...
git push origin feat/navn
gh pr create

# Den andre merger PR → begge puller main
git checkout main && git pull
```

## Nyttige kommandoer

```bash
# Start utvikling
npm run dev:gdist      # port 8080
npm run dev:buyer      # port 8081

# Tester
npm run test

# Deploy preview (etter vercel login)
vercel

# Deploy produksjon
vercel --prod

# Se Vercel-logs
vercel logs [deployment-url]
```

## Relatert

- [[09_Tech/Platform/Architecture]]
- [[06_Operations/SOPs/how-we-use-claude]]
- [[09_Tech/Infrastructure/Vercel]]
