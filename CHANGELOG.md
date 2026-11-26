# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- D1 rollup tables (`file_stats`, `file_clients`, `project_stats`, `project_clients`) and `idx_downloads_project_file` index in `migrations/0003_add_file_stats_rollup.sql`.
- 30-minute Cloudflare Edge Cache (`caches.default`) on `/stats` and `/dashboard` responses.
- Typed `cloudflare.config.ts` configuration via `cf migrate` and root `GEMINI.md` project guide.
- Project decision log (`DECISIONS.md`) and changelog (`CHANGELOG.md`).

### Changed
- Switched `/stats` and `/dashboard` from full-table scans on `downloads` to constant-cost rollup table reads (~175 rows).
- Updated `.parquet` download logging to update rollup tables non-blocking via `ctx.waitUntil()` while preserving the raw `downloads` log.
- Migrated `package.json` `dev` and `deploy` scripts from `wrangler` to `cf` and ignored `.cloudflare/` build artifacts.

### Removed
- Legacy `wrangler.toml` configuration file.

## [0.1.0] - 2026-02-15

### Added
- Cloudflare Worker (`src/index.js`) proxying `nhanes.kylegrealis.com` and `nascar.kylegrealis.com` R2 `.parquet` downloads with non-blocking D1 logging.
- `/stats`, `/dashboard`, `/raw`, and `/cleaned` endpoints for dataset download reporting.
- Anonymized unique-user tracking (`client_hash` via SHA-256 IP prefix and `country` column) in `migrations/0002_add_client_hash.sql`.
- Rhino Shiny dashboard (`r2-dashboard/`) with interactive bar/line charts, date-range selector, CRAN + R2 footer totals, and mobile responsive layout.
