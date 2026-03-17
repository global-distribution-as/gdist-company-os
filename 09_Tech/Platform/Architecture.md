# Platform Architecture — Global Distribution AS

_Oppdatert: 2026-03-16_

## Oversikt

To-persons selskap (Daniel + Martin) som driver B2B-eksport av europeisk sportsutstyr til asiatiske kjøpere. Plattformen håndterer leverandørkommunikasjon, produktkatalog, ordreflyt, logistikk og fakturering.

## Repoer

| Repo | GitHub | Formål | Deploy |
|------|--------|--------|--------|
| `aurora-trade-hub` | [g-dist/aurora-trade-hub](https://github.com/g-dist/aurora-trade-hub) | Admin + Supplier portal (monorepo) | Vercel (`web-platform`) |
| `jessica-buyer-portal` | g-dist/jessica-buyer-portal _(kommer)_ | Kjøper-portal (JessicaGD) | Vercel (gratis) |

## Apps

### apps/gdist — Intern portal (gdist.no / globaldistribution.no)
- **Brukere:** Daniel, Martin (admin), europeiske leverandører (supplier)
- **Stack:** React 18 + Vite + TypeScript + Tailwind + Radix UI
- **Portaler:**
  - `/admin/*` — full oversikt: buyers, orders, products, inventory, suppliers, settings
  - `/supplier/*` — leverandør ser egne produkter, ordrer, laster opp lister

### apps/buyer — Kjøper-portal (JessicaGD.cn)
- **Brukere:** Asiatiske kjøpere
- **Branding:** JessicaGD / Jessica (separat fra gdist.no)
- **Portaler:**
  - `/buyer/*` — katalog, quotes, ordrer, profil

## Teknisk stack

```
Frontend:  React 18, Vite, TypeScript
Styling:   Tailwind CSS, Radix UI (shadcn/ui-stil)
State:     TanStack Query v5
Routing:   React Router v6
Auth/DB:   Supabase (PostgreSQL + Auth + Storage)
Deploy:    Vercel (Hobby — gratis)
i18n:      i18next (EN/NO/CN)
Forms:     React Hook Form + Zod
```

## Monorepo-struktur

```
aurora-trade-hub/
├── apps/
│   ├── gdist/          ← Admin + Supplier portal
│   └── buyer/          ← Kjøper-portal (JessicaGD)
├── packages/
│   └── shared/         ← Supabase-klient, typer, i18n, utils
├── supabase/
│   └── migrations/     ← SQL-migrasjoner
├── infra/
│   └── scripts/        ← Ops-scripts (sync, rapport)
├── docs/               ← Dev-dokumentasjon
└── .claude/            ← Claude-instruksjoner og prompt-maler
```

## Dataflyt

```
Bruker (browser)
  → Vite SPA (Vercel CDN)
  → Supabase JS Client (anon key + JWT)
  → PostgreSQL med Row Level Security (RLS)
  → Retur til komponent via TanStack Query
```

## Auth & Roller

Supabase Auth + custom `user_roles`-tabell.

| Rolle | Tilgang |
|-------|---------|
| `admin` | Alt |
| `supplier` | Egne produkter, ordrer, inventory |
| `buyer` | Katalog (aktive produkter), egne quotes/ordrer/fakturaer |

## Konvensjoner

- Path alias `@/` → `src/`
- Dark-mode only design, HSL tokens i `index.css`
- `cn()` for conditional class merging
- Icons: lucide-react

## Kommandoer

```bash
npm run dev:gdist      # gdist på port 8080
npm run dev:buyer      # buyer på port 8081
npm run build:gdist    # produksjonsbygg
npm run test           # Vitest
npm run lint           # ESLint
```

## Relatert

- [[09_Tech/Infrastructure/Vercel]]
- [[09_Tech/Infrastructure/Supabase]]
- [[09_Tech/Integrations/Tripletex]]
- [[06_Operations/SOPs/dev-workflow]]
- [[06_Operations/SOPs/how-we-use-claude]]
