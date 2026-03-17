# Vercel — Infrastruktur

_Oppdatert: 2026-03-16_

## Prosjekter

| Prosjekt | App | Repo | Status |
|----------|-----|------|--------|
| `web-platform` | apps/gdist | g-dist/aurora-trade-hub | ✅ Aktiv |
| _(kommer)_ | apps/buyer | g-dist/jessica-buyer-portal | 🔜 Planlagt |

## Plan (gratis Hobby-tier)

Vi bruker Vercel Hobby (gratis) til vi setter opp bankkonto og evt. trenger Pro.
- Gratis tier gir: 100GB bandwidth, preview deploys, custom domains, serverless functions
- Ingen kredittkortkrav for Hobby

## Koble lokalt repo til Vercel

```bash
# Installer CLI (allerede gjort)
npm i -g vercel

# Login én gang (åpner browser)
vercel login
# Velg "Continue with GitHub" → velg g-dist-kontoen

# Link repo til eksisterende Vercel-prosjekt
cd ~/projects/global-distribution/aurora-trade-hub
vercel link
# Svar på spørsmål:
#   Scope: g-dist
#   Link to existing project: Yes
#   Project name: web-platform
```

## Miljøvariabler (sett etter login)

```bash
# Legg til env-vars i Vercel for produksjon
vercel env add VITE_SUPABASE_URL production
vercel env add VITE_SUPABASE_ANON_KEY production

# Se eksisterende
vercel env ls
```

## Deploy

```bash
# Preview deploy (fra hvilken som helst branch)
vercel

# Produksjon
vercel --prod

# Sjekk deploy-status
vercel ls
vercel inspect [deployment-url]
```

## GitHub-integrasjon

- Push til `main` → automatisk produksjon-deploy
- Push til andre branches → automatisk preview deploy
- PR-er får preview-URL i kommentaren

## Custom domain (når klar)

```bash
vercel domains add gdist.no
vercel domains add www.gdist.no
```

## Relatert

- [[09_Tech/Platform/Architecture]]
- [[09_Tech/Infrastructure/Supabase]]
