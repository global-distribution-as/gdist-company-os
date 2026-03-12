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
├── 01_Customers/            ← kjøpere (Asia)
├── 02_Suppliers/            ← leverandører (Europa)
├── 03_Processes/            ← hvordan selskapet fungerer
├── 04_Decisions/            ← beslutningslogg
├── 05_Products/             ← produktkatalog
├── 06_Projects/             ← prosjekter
├── 07_Tech/                 ← teknisk dokumentasjon
├── 08_Daily/                ← daglogg
├── 09_Weekly/               ← ukeslogg
├── _Templates/              ← maler
└── CLI-WORKFLOW.md          ← denne filen
```

## Kodebase

- Repo: `aurora-trade-hub` (global-distribution-as org)
- Stack: React 18 + TypeScript + Vite + Tailwind + shadcn/ui
- Se [[07_Tech/Platform/Architecture]] for detaljer

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
| Kjøpere | `01_Customers/` | `/buyer/*` |
