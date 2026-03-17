# ADR: Quote Number Generation

**Date:** 2026-03-16
**Status:** Open — not yet implemented

## Context

The current `next_quote_number()` SQL function uses `SELECT COUNT(*) + 1 FROM quotes` to generate a sequential quote number. This is not safe under concurrent inserts: two simultaneous quote submissions can read the same count and produce duplicate quote numbers.

At current volume (one admin generating quotes), this race is unlikely but not impossible. Quote numbers are referenced in PDF documents, bank transfers, and Obsidian vault files — a duplicate number causes real confusion.

## Options Considered

1. **Keep `count(*)+1`** — acceptable at very low volume if quote generation is strictly one-admin-at-a-time. High future risk.

2. **PostgreSQL `SEQUENCE`** — `CREATE SEQUENCE quote_number_seq START 1001`. `next_quote_number()` calls `nextval('quote_number_seq')`. Atomic, no race condition, never duplicates.

3. **UUID with display alias** — generate a UUID internally but display a short code (e.g. GD-2026-001). More complex, no clear benefit.

## Decision

Replace `count(*)+1` with a **PostgreSQL SEQUENCE** (option 2). Simple one-line migration, no application code changes needed beyond replacing the function body.

Migration:
```sql
CREATE SEQUENCE IF NOT EXISTS quote_number_seq START 1001;

CREATE OR REPLACE FUNCTION next_quote_number()
RETURNS integer LANGUAGE sql AS $$
  SELECT nextval('quote_number_seq')::integer;
$$;
```

## Consequences

- Quote numbers will no longer be contiguous if a quote is deleted (sequence gaps are expected and acceptable)
- The sequence starts at 1001 — adjust if existing quotes already exceed this
- Zero risk of duplicate numbers under any concurrency
- Migration is safe to apply without downtime
