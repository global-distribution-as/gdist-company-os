# Changelog

## 2026-03-17 — Mac mini M4 Setup Fixes

### Vercel Scope
- Confirmed only scope available is `lushdans-projects` (no `g-dist` team exists)
- Re-linked aurora-trade-hub to `lushdans-projects/aurora-trade-hub`
- Project ID: `prj_qR0il7y4WhccVsp7KHx8Wykmh1aW`

### Supabase Project Ref
- Corrected project ref to `vffhvngwcjtqurtoyzun` (portal, North EU Stockholm)
- Updated `~/.claude-env` with `SUPABASE_PROJECT_REF=vffhvngwcjtqurtoyzun`
- Updated `aurora-trade-hub/CLAUDE.md` with correct Supabase ref
- Confirmed Supabase CLI linked (`supabase projects list` shows linked indicator)
- Note: original ref `orsjlztclkiqntxznnyo` was never used in codebase (no hardcoded refs found)

### Verification
- Vercel: linked to lushdans-projects scope ✓
- Supabase: connected to portal project (vffhvngwcjtqurtoyzun) ✓
- `supabase projects list`: access confirmed ✓
- `~/.claude-env`: SUPABASE_PROJECT_REF set ✓
- `CLAUDE.md`: Supabase ref documented ✓

---

## 2026-03-17 — Mac mini M4 Setup Complete

### Full setup completed
- Git: GDist Operations / gdist@icloud.com
- SSH: ed25519 key (gdist-mini) added to GitHub
- Repos: aurora-trade-hub cloned to ~/projects/
- Vault: gdist-company-os cloned to ~/Documents/GlobalDistribution
- Obsidian: v1.12.4 installed
- Ollama: running with qwen2.5:32b, qwen2.5-coder:14b, nomic-embed-text
- n8n: v2.12.2 running on :5678 via launchd (Node 22)
- Vercel: aurora-trade-hub linked (lushdans-projects)
- Supabase: linked to vffhvngwcjtqurtoyzun (portal)
- zshrc: 27 aliases, custom PS1, env vars configured
- Sleep: disabled (pmset sleep=0, disksleep=0)
- GitHub CLI: v2.88.1 installed

### n8n fix
- n8n crashed on Node 25 (isolated-vm native build incompatible)
- Fixed launchd plist to use /opt/homebrew/opt/node@22/bin/node explicitly
- Confirmed healthy: `curl localhost:5678/healthz` returns `{"status":"ok"}`

### Ollama test
- qwen2.5:32b tested with Norwegian prompt — responded correctly

---

## 2026-03-17 — Remote Access Setup

### Tailscale
- Installed and authenticated as g-dist@
- Mac mini Tailscale IP: 100.75.168.54
- MacBook Pro Tailscale IP: 100.111.160.10

### SSH
- Remote Login enabled
- SSH key (id_ed25519_gdist) added to authorized_keys
- SSH config: `ssh gdist-mini` connects via Tailscale
- Tested locally (localhost) and remotely (100.75.168.54)

### SSH Config
- `github.com` → g-dist (org key)
- `gdist-mini` → 100.75.168.54 via Tailscale

### Hostname
- Pending sudo: `sudo scutil --set HostName/LocalHostName/ComputerName gdist-mini`

### Documentation
- Created 06_Tech/REMOTE_ACCESS.md with connection guide, service checks, and troubleshooting
