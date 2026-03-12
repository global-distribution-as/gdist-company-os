# Architecture

## Stack

- React 18 + TypeScript + Vite
- Tailwind CSS + shadcn/ui
- Vitest + Testing Library

## Repo Structure

```
aurora-trade-hub/
├── apps/gdist/src/
│   ├── pages/
│   │   ├── admin/
│   │   ├── buyer/
│   │   └── supplier/
│   ├── components/ui/   ← shadcn/ui (do not manually edit)
│   └── lib/data/        ← static mock data
└── packages/shared/     ← types, utils, i18n (EN/NO/CN)
```

## Portals

| Portal | Route | Color |
|--------|-------|-------|
| Supplier | `/supplier/*` | Blue |
| Buyer | `/buyer/*` | Green |
| Admin | `/admin/*` | Purple |

## Conventions

- Path alias `@/` → `src/`
- Dark-mode only design, HSL tokens in `index.css`
- `cn()` for conditional class merging
- Icons: lucide-react

## Commands

```bash
npm run dev        # port 8080
npm run build
npm run test
npm run lint
```

## Current Limitations

- No auth / session management yet
- Static mock data only — no backend or database
- No real API integration yet

## Related

- [[06_Projects/web-platform/Roadmap]]
- [[07_Tech/Infrastructure/]]
- [[07_Tech/Integrations/]]
