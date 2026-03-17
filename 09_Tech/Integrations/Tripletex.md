# Tripletex — Integrasjon

_Oppdatert: 2026-03-16_

## Status

**Planlagt** — ikke implementert ennå.

## Formål

Tripletex er regnskapssystem. Integrasjonen skal synke:
- Fakturaer (invoices → Tripletex)
- Innbetalinger (payments → Tripletex)
- Kunder/kjøpere (buyers → Tripletex kunder)
- Leverandører (suppliers → Tripletex leverandører)

## Koblingspunkter i databasen

Alle relevante tabeller har `tripletex_id text`-felt:
- `suppliers.tripletex_id`
- `buyers.tripletex_id`
- `products.tripletex_id`
- `orders.tripletex_id`
- `payments.tripletex_id`
- `invoices.tripletex_id`

## Plan for implementasjon

1. Sett opp Tripletex API-token (ligger i Tripletex under Innstillinger → API)
2. Lag `infra/scripts/tripletex-sync.js` (node-script)
3. Kjør på Mac mini som nattlig cron (00:30 hver natt)
4. Logg resultat til `~/logs/tripletex-sync/YYYY-MM-DD.log`

## Ressurser

- Tripletex API docs: https://tripletex.no/v2 (swagger)
- Auth: Employee token + consumer token → session token

## Relatert

- [[09_Tech/Infrastructure/Supabase]]
- [[02_Operations/SOP/automation-mac-mini]]
