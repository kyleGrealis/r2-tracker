# Project Decision Log

This document records technical, statistical, and architectural decisions made throughout the lifecycle of this project.

Entries are ordered chronologically with newest entries at the top.

---

## 2026-11-25: Migrate Worker Configuration from wrangler.toml to cf CLI

- **Context / Problem**: Managing Cloudflare account resources with global `cf` while deploying Workers and D1 migrations through per-repo `wrangler.toml` required duplicate OAuth logins and left bindings untyped until runtime.
- **Decision Taken**: Migrated `r2-tracker` to `cloudflare.config.ts` via `cf migrate`, switched `package.json` scripts to `cf dev` / `cf deploy`, removed `wrangler.toml`, and added `.cloudflare/` to `.gitignore`.
- **Rationale & Trade-offs**: Unifies Worker deploys, D1 migrations (`cf d1 migrations apply`), and account ops under one CLI while generating `.cloudflare/types/index.d.ts` for compile-time binding checks. Retains `wrangler` in `devDependencies` because `cf` currently delegates bundling to it when `@cloudflare/vite-plugin` is not declared.
- **Related Files**: `cloudflare.config.ts`, `package.json`, `.gitignore`, `GEMINI.md`

---

## 2026-11-25: Maintain D1 Rollup Tables and 30-Minute Edge Cache for /stats

- **Context / Problem**: Unindexed `COUNT(*)` and `COUNT(DISTINCT client_hash)` queries over ~155k `downloads` rows scanned ~310k rows per `/stats` pair. A 60-second desktop bar poll burned Cloudflare D1's 5M daily free row-read quota in under 30 minutes.
- **Decision Taken**: Added `file_stats`, `file_clients`, `project_stats`, and `project_clients` rollup tables (backfilled in `0003_add_file_stats_rollup.sql` and updated inside `ctx.waitUntil()` on each `.parquet` download), plus a 30-minute `caches.default` edge cache on `/stats` and `/dashboard`.
- **Rationale & Trade-offs**: A covering index alone still scales linearly with total downloads (~155k index entries per `/stats` pair), whereas rollup reads stay flat at ~175 rows (~900x cheaper) while keeping the raw `downloads` table intact for `/raw` and `/cleaned`. Adds 2 to 3 lightweight D1 writes per `.parquet` download inside the non-blocking background task.
- **Related Files**: `migrations/0003_add_file_stats_rollup.sql`, `src/index.js`, `src/utils.js`
