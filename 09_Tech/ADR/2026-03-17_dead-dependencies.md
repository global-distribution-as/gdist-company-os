# ADR: Remove unused npm dependencies

**Date:** 2026-03-17
**Status:** Decided
**Priority:** 🟡 Medium — reduces bundle size and security surface

---

## Context

Both portal and jessica were scaffolded with a full shadcn/ui component set. Many packages were installed as part of that scaffold and are not used in any component.

As of 2026-03-17 audit, the following are installed but have no active usage:

| Package | Installed in | Used? | Size impact |
|---------|-------------|-------|------------|
| `@tanstack/react-query` | both | No (QueryClientProvider wraps but no hooks used) | ~45KB |
| `recharts` | portal | No | ~210KB |
| `react-hook-form` + `@hookform/resolvers` | portal | No (forms use raw onChange) | ~25KB |
| `zod` | portal | No | ~55KB |
| `embla-carousel-react` | portal | No | ~15KB |
| `react-day-picker` | portal | Barely (follow-up date in QuoteGenerator only) | ~30KB |
| `react-resizable-panels` | portal | No | ~20KB |
| `input-otp` | portal | No | ~8KB |
| `vaul` | portal | No | ~15KB |
| `next-themes` | portal | No (CSS vars used, no theme toggle) | ~5KB |
| `cmdk` | portal | No | ~20KB |

Estimated total dead weight: **~450KB uncompressed** (significantly less gzipped, but still parsed by browser).

---

## Decision

Remove all unused packages **except** `@tanstack/react-query` (planned for useUserRole caching — see separate ADR) and `react-day-picker` (used in QuoteGenerator).

Commands:
```bash
# portal
npm uninstall recharts react-hook-form @hookform/resolvers zod embla-carousel-react react-resizable-panels input-otp vaul next-themes cmdk --workspace=apps/portal

# jessica (mirror — check which are installed there too)
npm uninstall recharts react-hook-form @hookform/resolvers zod embla-carousel-react react-resizable-panels input-otp vaul next-themes cmdk --workspace=apps/jessica
```

Also remove any shadcn/ui component files that wrap these packages (Carousel.tsx, ResizablePanel.tsx, OtpInput.tsx, Drawer.tsx, ThemeProvider.tsx etc.) if they're not imported anywhere.

---

## Consequences

- Smaller bundle → faster initial load for buyers in China (high-latency connections)
- Smaller `node_modules` → faster CI/CD installs
- Fewer packages → smaller security surface (npm audit has fewer entries)
- Risk: one of these packages may be a transitive dependency for something we DO use — run `npm install` after removal and verify build passes before committing
