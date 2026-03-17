# Supabase — Database & Auth

_Oppdatert: 2026-03-16_

## Prosjekt

| | |
|--|--|
| **Project ID** | `orsjlztclkiqntxznnyo` |
| **URL** | `https://orsjlztclkiqntxznnyo.supabase.co` |
| **Plan** | Free (500 MB DB, 1 GB storage, 50K MAU) |

> ⚠️ Nøkler ligge i `.env.local`-filer lokalt og som Vercel env-vars. Aldri i kode.

## Tabeller

| Tabell | Beskrivelse |
|--------|-------------|
| `profiles` | Utvidet brukerprofil (kobler til auth.users) |
| `user_roles` | Roller: admin / supplier / buyer |
| `suppliers` | Europeiske leverandører |
| `buyers` | Asiatiske kjøpere |
| `products` | Produktkatalog (knyttet til supplier) |
| `quotes` | Pristilbud til buyers |
| `quote_items` | Linjer i et quote |
| `orders` | Ordrer (fra godkjent quote eller direkte) |
| `order_items` | Linjer i en ordre |
| `inventory` | Lagerstatus per produkt/batch |
| `shipments` | Forsendelser (carrier, tracking, status) |
| `contracts` | Kontrakter (PDF i Supabase Storage) |
| `payments` | Innbetalinger (deposit + balance) |
| `invoices` | Fakturaer (PDF i Supabase Storage) |

## Nøkkelrelasjoner

```
auth.users → profiles → user_roles
suppliers → products → order_items → orders → buyers
orders → shipments
orders → payments
orders → invoices
orders → contracts
quotes → quote_items → products
inventory → products
inventory → suppliers
```

## RLS-oversikt

| Rolle | Kan lese | Kan skrive |
|-------|---------|-----------|
| admin | Alt | Alt |
| supplier | Egne produkter, ordrer, inventory | Produkter (egne) |
| buyer | Aktive produkter, egne quotes/ordrer/fakturaer | Quotes (opprette) |

## Tripletex-integrasjon

Alle relevante tabeller har `tripletex_id text`-felt for ekstern referanse.
Fremtidig synk: webhook eller nattlig script på Mac mini.

## Koble CLI

```bash
# Hent access token fra: https://supabase.com/dashboard/account/tokens
export SUPABASE_ACCESS_TOKEN=ditt_token_her

# Link lokalt
supabase link --project-ref orsjlztclkiqntxznnyo

# Push migrasjoner
supabase db push

# Se diff mot remote
supabase db diff
```

## Vanlige queries

```sql
-- Hent alle aktive ordrer med buyer-navn
select o.order_number, b.name as buyer, o.status, o.sale_price_usd
from orders o
join buyers b on b.id = o.buyer_id
where o.status not in ('delivered', 'cancelled')
order by o.created_at desc;

-- Hent inventory per supplier
select s.name as supplier, p.name as product, i.quantity, i.stage
from inventory i
join products p on p.id = i.product_id
join suppliers s on s.id = i.supplier_id
order by s.name, p.name;

-- Utestående betalinger
select o.order_number, b.name as buyer, o.balance_due_usd, o.payment_status
from orders o
join buyers b on b.id = o.buyer_id
where o.payment_status in ('unpaid', 'deposit_paid', 'partial', 'overdue')
order by o.balance_due_usd desc;
```

## Relatert

- [[09_Tech/Platform/Architecture]]
- [[09_Tech/Integrations/Tripletex]]
