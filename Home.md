# Global Distribution AS

B2B distribution portal connecting **European sporting goods suppliers** with **Asian buyers**.

## Domains

- [[01-Suppliers/Suppliers Overview|Suppliers]] — European sporting goods suppliers
- [[02-Buyers/Buyers Overview|Buyers]] — Asian buyers

## Portals

| Portal | Route | Color |
|--------|-------|-------|
| Supplier | `/supplier/*` | Blue |
| Buyer | `/buyer/*` | Green |
| Admin | `/admin/*` | Purple |

## Quick Links

- [[04-Tech/Architecture|Architecture]]
- [[04-Tech/Stack|Stack]]
- [[05-Planning/Roadmap|Roadmap]]
- [[03-Admin/Admin Overview|Admin]]

## Status

- No auth/session management yet — login navigates directly to dashboard
- Data layer: static mock data in `src/lib/data/`
- No backend API or database yet
