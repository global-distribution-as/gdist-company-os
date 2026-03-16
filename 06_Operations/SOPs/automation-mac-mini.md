# Mac mini Automasjon

_Oppdatert: 2026-03-16_

## Status

Mac mini ankommer i løpet av uka. Denne guiden beskriver oppsettet.

## Katalogstruktur på Mac mini

```
~/
├── repos/
│   ├── aurora-trade-hub/       ← klon av g-dist/aurora-trade-hub
│   └── jessica-buyer-portal/   ← klon av g-dist/jessica-buyer-portal (når klar)
├── scripts/                    ← symlinks til infra/scripts/ i repo
├── logs/
│   ├── sync/                   ← logg fra sync-all.sh
│   └── daily-report/           ← logg fra daily-report.sh
└── Documents/
    └── GlobalDistribution/     ← Obsidian vault (klon av vault-repo)
```

## Første oppsett på Mac mini

```bash
# 1. Klon repoer
mkdir -p ~/repos
git clone https://github.com/g-dist/aurora-trade-hub ~/repos/aurora-trade-hub

# 2. Klon Obsidian vault (når vault har GitHub-repo)
git clone https://github.com/g-dist/gdist-obsidian-vault ~/Documents/GlobalDistribution

# 3. Installer Node.js via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install --lts

# 4. Installer vercel + supabase CLI
npm i -g vercel
brew install supabase/tap/supabase

# 5. Logg inn
gh auth login
vercel login
export SUPABASE_ACCESS_TOKEN=ditt_token_her

# 6. Gjør scripts kjørbare
chmod +x ~/repos/aurora-trade-hub/infra/scripts/*.sh
```

## Scripts

| Script | Formål | Anbefalt tid |
|--------|--------|-------------|
| `sync-all.sh` | Pull alle repoer + Obsidian vault | Hvert 30. min |
| `daily-report.sh` | Test + deploy-status → Obsidian | 06:00 hver dag |

Scripts ligger i `infra/scripts/` i repoet.

## Aktivere cron (gjøres manuelt når klar)

```bash
# Åpne crontab-editor
crontab -e

# Lim inn:
# Sync hvert 30. min
*/30 * * * * /Users/automation/repos/aurora-trade-hub/infra/scripts/sync-all.sh >> /Users/automation/logs/sync/cron.log 2>&1

# Daglig rapport kl. 06:00
0 6 * * * /Users/automation/repos/aurora-trade-hub/infra/scripts/daily-report.sh >> /Users/automation/logs/daily-report/cron.log 2>&1
```

> **Merk:** Erstatt `/Users/automation/` med faktisk brukernavn på Mac mini.

## Test script manuelt

```bash
# Test sync
~/repos/aurora-trade-hub/infra/scripts/sync-all.sh

# Test daglig rapport
~/repos/aurora-trade-hub/infra/scripts/daily-report.sh

# Sjekk logg
cat ~/logs/sync/$(date +%Y-%m-%d).log
```

## Relatert

- [[06_Operations/SOPs/dev-workflow]]
- [[09_Tech/Integrations/Tripletex]]
