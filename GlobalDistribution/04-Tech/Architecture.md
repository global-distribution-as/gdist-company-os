# Architecture

## Overview

Monorepo with a single web app (`apps/gdist`) and shared package (`packages/shared`).

## Stack

- React 18 + TypeScript
- Vite (bundler)
- Tailwind CSS + shadcn/ui
- Vitest + Testing Library

## Repo Structure

```
aurora-trade-hub/
├── apps/
│   └── gdist/           # Main web app
│       └── src/
│           ├── pages/
│           │   ├── admin/
│           │   ├── buyer/
│           │   └── supplier/
│           ├── components/
│           │   └── ui/  # shadcn/ui (do not manually edit)
│           └── lib/
│               └── data/ # Static mock data (admin.ts, buyer.ts, supplier.ts)
└── packages/
    └── shared/          # Shared types, utils, i18n
```

## Key Conventions

- Path alias: `@/` → `src/`
- Dark-mode-only design
- HSL color tokens in `src/index.css`
- `cn()` utility for conditional class merging
- Icons: lucide-react

## Commands

```bash
npm run dev        # Dev server (port 8080)
npm run build      # Production build
npm run test       # Run tests
npm run lint       # ESLint
```

## Current Limitations

- No auth/session management (login goes straight to dashboard)
- Static mock data only — no backend or database
- No real API integration yet

## Links

- [[Stack]]
- [[Data Layer]]
