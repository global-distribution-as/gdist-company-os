# CLI + Obsidian Workflow

## Regler
- Jeg jobber primært i terminal (git, supabase, vercel).
- Obsidian brukes til:
  - Plan, oppsummeringer, beslutninger.
- Når du (Claude) foreslår noe:
  - Gi konkrete kommandoer
  - Si hvilke notater som bør oppdateres

## Vault-struktur

```
~/Documents/GlobalDistribution/
├── Home.md                  ← alltid åpne først
├── 00_Dashboard/            ← oversikt
├── 01_Buyers/            ← kjøpere (Asia)
├── 02_Suppliers/            ← leverandører (Europa)
├── 06_Operations/SOPs/            ← hvordan selskapet fungerer
├── 04_Decisions/            ← beslutningslogg
├── 03_Products/             ← produktkatalog
├── 08_Projects/             ← prosjekter
├── 09_Tech/                 ← teknisk dokumentasjon
├── 10_Log/                ← daglogg
├── 10_Log/               ← ukeslogg
├── _Templates/              ← maler
└── CLI-WORKFLOW.md          ← denne filen
```

## Kodebase

- Repo: `aurora-trade-hub` (global-distribution-as org)
- Stack: React 18 + TypeScript + Vite + Tailwind + shadcn/ui
- Se [[09_Tech/Platform/Architecture]] for detaljer

## Vanlige kommandoer

```bash
npm run dev        # Start dev-server (port 8080)
npm run build      # Bygg produksjon
npm run test       # Kjør tester
~/Documents/GlobalDistribution/sync.sh  # Sync vault til GitHub
```

## To domains

| Domain | Mappe | Portal-rute |
|--------|-------|-------------|
| Leverandører | `02_Suppliers/` | `/supplier/*` |
| Kjøpere | `01_Buyers/` | `/buyer/*` |
