# Project Guidelines (GEMINI.md)

## Project Overview

**r2-tracker** is a Cloudflare Worker that sits in front of R2 buckets and tracks file downloads to a D1 database. It serves multiple R packages that host data on Cloudflare R2:

| Project | Subdomain | R2 Bucket |
|---------|-----------|-----------|
| nhanesdata | `nhanes.kylegrealis.com` | `nhanes-data` |
| nascaR.data | `nascar.kylegrealis.com` | `nascar-data` |

## Architecture

```
User calls read_nhanes("demo")
  -> arrow::read_parquet("https://nhanes.kylegrealis.com/demo.parquet")
    -> Cloudflare Worker (this project)
      -> Logs download to D1 (non-blocking)
      -> Fetches file from R2 bucket
      -> Streams file back to user
```

## Routes

| Route | Response |
|-------|----------|
| `GET /{name}.parquet` | Logs hit to D1, proxies file from R2 |
| `GET /stats` | JSON download counts (consumed by any app) |
| `GET /dashboard` | HTML page that visualizes /stats data |
| Everything else | 404 |

## Cloudflare Account

- **Account ID**: `1694d934fc8380e1d9e8ceca6c372c98`
- **Account name**: kyleGrealis

## Key Files

- `cloudflare.config.ts` -- Typed `cf` config binding R2 buckets, D1 database, and routes
- `src/index.js` -- The Worker code (request handler)
- `migrations/` -- D1 database schema migrations

## Commands

```bash
# Install dependencies
npm install

# Run locally for development
cf dev

# Deploy to Cloudflare
cf deploy

# Apply D1 migrations (remote by default; pass --local for local simulation)
cf d1 migrations apply 31a99c29-a83c-42e5-b8e9-eeefa02ca073

# Query D1 database directly
cf d1 query 31a99c29-a83c-42e5-b8e9-eeefa02ca073 --sql "SELECT * FROM file_stats LIMIT 10" -q
```

## Teaching Mode

Kyle is learning JavaScript/Cloudflare as he builds this project. Adjust assistance accordingly:

- **Simple JS things**: Give hints and let him figure it out. Point to the right concept or method, don't write the code.
- **Complex things** (Wrangler config, D1 migrations, Worker bindings, deployment): Give explicit instructions to run.
- **When he's stuck**: Act as a teacher. Answer questions with explanations, point him in the right direction.
- **Always**: Explain Cloudflare/JS/web concepts inline as they come up. Don't assume prior knowledge outside R/tidyverse.

## Style

- Vanilla JavaScript (no TypeScript, no build step)
- ES module syntax (`export default { ... }`)
- Keep it simple -- this is ~100 lines of code, not a framework

## Related Projects

- `/home/kyle/dev/nhanesdata` -- R package, `read_nhanes()` fetches from nhanes.kylegrealis.com
- `/home/kyle/dev/nascaR.data` -- R package, fetches from nascar.kylegrealis.com
