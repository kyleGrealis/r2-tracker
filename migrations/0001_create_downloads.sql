CREATE TABLE IF NOT EXISTS downloads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file TEXT NOT NULL,
  project TEXT NOT NULL,
  downloads_at TEXT NOT NULL DEFAULT (datetime('now'))
);
