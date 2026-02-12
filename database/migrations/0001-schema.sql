CREATE TABLE IF NOT EXISTS waki_webapps (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    name      TEXT    NOT NULL UNIQUE,
    url       TEXT    NOT NULL,
    icon_slug TEXT    NOT NULL,
    category  TEXT    NOT NULL DEFAULT 'uncategorized'
);

CREATE TABLE IF NOT EXISTS waki_profiles (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    directory  TEXT    NOT NULL UNIQUE,
    display_name TEXT,
    created_at TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

INSERT OR IGNORE INTO waki_profiles (directory) VALUES ('Default');

CREATE TABLE IF NOT EXISTS waki_installs (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    webapp_id  INTEGER NOT NULL REFERENCES waki_webapps(id),
    profile_id INTEGER NOT NULL REFERENCES waki_profiles(id),
    created_at TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    UNIQUE(webapp_id, profile_id)
);

CREATE INDEX IF NOT EXISTS idx_waki_installs_webapp  ON waki_installs(webapp_id);
CREATE INDEX IF NOT EXISTS idx_waki_installs_profile ON waki_installs(profile_id);

CREATE TABLE IF NOT EXISTS waki_events (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    kind       TEXT    NOT NULL,
    detail     TEXT    NOT NULL DEFAULT '',
    created_at TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);
