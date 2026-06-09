const db = require('./db');

db.exec(`
CREATE TABLE IF NOT EXISTS camps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  osm_type TEXT NOT NULL,
  osm_id INTEGER NOT NULL,
  name TEXT,
  lat REAL NOT NULL,
  lng REAL NOT NULL,
  tags_json TEXT NOT NULL,
  city TEXT,
  district TEXT,
  address TEXT,
  updated_at TEXT DEFAULT (datetime('now')),
  UNIQUE(osm_type, osm_id)
);

CREATE TABLE IF NOT EXISTS geocode_cache (
  key TEXT PRIMARY KEY,          -- "lat,lng" (rounded)
  city TEXT,
  district TEXT,
  address TEXT,
  updated_at TEXT DEFAULT (datetime('now'))
);
`);

module.exports = db;
