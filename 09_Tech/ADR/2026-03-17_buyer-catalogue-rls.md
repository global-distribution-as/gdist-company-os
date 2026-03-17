# ADR: BuyerCatalogue implementation and RLS design

**Date:** 2026-03-17
**Status:** Decided
**Priority:** 🔴 High — core buyer feature, needed before first buyer is onboarded

---

## Context

`BuyerCatalogue.tsx` in jessica is a placeholder with heading and no data fetch.
The buyer needs to browse active products to initiate quote requests.

The key RLS question: what can buyers see?

Current RLS (`20260315000002_rls_policies.sql`):
```sql
-- Buyers see active products
create policy "products: buyer can view active" on public.products
  for select using (status = 'active');
```

This is correct and sufficient. The catalogue should work with zero changes to RLS.

However, the products table currently exposes **supplier cost (`supplier_price_nok`)** in the same row as the product data. If a buyer's RLS policy allows SELECT, they can see supplier cost.

---

## Risk

A buyer calling:
```js
supabase.from('products').select('*')
```
would receive `supplier_price_nok` = what we paid the Norwegian supplier.

This breaks the core business model: **buyers must not see our cost structure**.

---

## Options considered

**A. SELECT only specific columns in BuyerCatalogue (chosen for now)**
```js
supabase.from('products').select('id, name, brand, category, description, image_url, status, price_range, stock_s, stock_m, stock_l, stock_xl, stock_xxl, min_order_qty')
```
Pro: Simple. Con: Developers must remember never to add `supplier_price_nok` to the select. Brittle.

**B. PostgreSQL view `public.buyer_product_view`**
Create a view that excludes all cost columns. Grant SELECT only on the view to buyers, not on the base table.
Pro: Structurally correct — impossible to expose cost columns. Con: requires migration, view maintenance.

**C. Row-level column masking (PostgreSQL 16+)**
Not yet widely supported in Supabase.

---

## Decision

**Phase 1 (implement now):** Explicit column select in BuyerCatalogue — never use `select('*')` from a buyer context.

**Phase 2 (before 10th buyer):** Create `buyer_product_view` that includes only buyer-safe columns. Update BuyerCatalogue to query the view. Add RLS to the view. Remove buyer SELECT policy from the base products table.

---

## BuyerCatalogue implementation spec

```tsx
// Fetch
const { data } = await supabase
  .from('products')
  .select('id, name, brand, category, description, image_url, price_range, stock_s, stock_m, stock_l, stock_xl, stock_xxl, min_order_qty')
  .eq('status', 'active')
  .order('name');

// UI: grid of product cards
// Each card: image, name, brand, category, sizes (S/M/L/XL/XXL indicators), MOQ
// CTA: "Request Quote" → /buyer/quotes/new?product=id
// Filter bar: category, brand, size availability
// Search: client-side filter on name/brand
```

---

## Consequences

- Buyers can browse the catalogue immediately after this is implemented
- Cost columns are never exposed in buyer context if explicit select is used
- Phase 2 view makes the cost protection structural rather than disciplinary
