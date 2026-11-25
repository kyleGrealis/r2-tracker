-- Rollup table for constant-cost /stats and /dashboard reads (~175 rows total)
CREATE TABLE IF NOT EXISTS file_stats (
  project TEXT NOT NULL,
  file TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  unique_users INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (project, file)
);

-- Per-file client_hash deduplication for exact unique_users increments
CREATE TABLE IF NOT EXISTS file_clients (
  project TEXT NOT NULL,
  file TEXT NOT NULL,
  client_hash TEXT NOT NULL,
  PRIMARY KEY (project, file, client_hash)
);

-- Project-level unique_users rollup and deduplication for /dashboard totals
CREATE TABLE IF NOT EXISTS project_stats (
  project TEXT PRIMARY KEY,
  unique_users INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS project_clients (
  project TEXT NOT NULL,
  client_hash TEXT NOT NULL,
  PRIMARY KEY (project, client_hash)
);

-- Index on downloads for /raw, /cleaned, and ad-hoc queries
CREATE INDEX IF NOT EXISTS idx_downloads_project_file
  ON downloads (project, file);

-- Backfill rollups from existing downloads log
INSERT OR REPLACE INTO file_stats (project, file, count, unique_users)
SELECT
  project,
  file,
  COUNT(*) AS count,
  COUNT(DISTINCT client_hash) AS unique_users
FROM downloads
GROUP BY project, file;

INSERT OR IGNORE INTO file_clients (project, file, client_hash)
SELECT DISTINCT project, file, client_hash
FROM downloads
WHERE client_hash IS NOT NULL;

INSERT OR IGNORE INTO project_clients (project, client_hash)
SELECT DISTINCT project, client_hash
FROM downloads
WHERE client_hash IS NOT NULL;

INSERT OR REPLACE INTO project_stats (project, unique_users)
SELECT
  project,
  COUNT(*) AS unique_users
FROM project_clients
GROUP BY project;
