# Hvordan vi bruker Claude Code

_Oppdatert: 2026-03-16_

## Hva Claude gjør for oss

Claude (via Claude Code CLI) er vår CTO-agent og gjør:
- Kodeimplementasjon (features, bugfix, refactor)
- Supabase-migrasjoner og datamodell
- Vercel-oppsett og deploy via CLI
- GitHub-repo-administrasjon
- Dokumentasjon (repo + Obsidian)
- Mac mini automation-scripts
- Ops-oppgaver (env-vars, CI/CD, linking)

## Slik starter en sesjon

```bash
cd ~/projects/global-distribution/aurora-trade-hub
claude
```

## Sikkerhetsprotokoller

**Alltid inkluder denne instruksjonen øverst i en ny sesjon:**

```
--dangerously-skip-permissions (skriv dette som egen melding for auto-godkjenning)
```

Deretter sikkerhets-prompten som sier:
- Destruktive kommandoer (rm, drop table, etc.) krever eksplisitt godkjenning
- Bruk `JEG GODKJENNER DENNE RISIKOEN` for å bekrefte

## Prompt-maler

Ligger i `.claude/prompts/` i repoet:
- `feature-impl.md` — ny feature
- `bugfix.md` — feilretting
- `ops-task.md` — infra/ops-oppgave

## Arbeidsflyt med Claude

1. **Plan first:** Claude lager alltid plan før den handler
2. **PLAN OK:** Du godkjenner planen eksplisitt
3. **Endringer:** Claude kjører ende-til-ende uten å spørre om småting
4. **Destruktive operasjoner:** Alltid stopp + eksplisitt godkjenning
5. **Docs:** Claude oppdaterer Obsidian-noter i samme sesjon

## Tips

- Gi konkrete akseptansekriterier i feature-prompts
- Nevn hvilke Supabase-tabeller som er involvert
- Si hvilken app (gdist / buyer) featuren gjelder
- Claude committer ikke automatisk — alltid review diff først

## Relatert

- [[06_Operations/SOPs/dev-workflow]]
- [[09_Tech/Platform/Architecture]]
- [[.claude/README.md]] i repoet
