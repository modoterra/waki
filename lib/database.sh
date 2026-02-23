#!/usr/bin/env bash
# Waki database management

waki_db_init() {
  mkdir -p "$(dirname "$WAKI_DB_PATH")"
  waki_db_migrate

  local count
  count=$(sqlite3 "$WAKI_DB_PATH" "SELECT COUNT(*) FROM waki_webapps;" 2>/dev/null || echo "0")
  if [[ "$count" == "0" ]]; then
    waki_catalog_seed
    waki_db_log_event "catalog_seed" "initial"
  fi
}

waki_db_mark_migration_applied() {
  local name="$1"
  local esc_name
  esc_name=$(waki_sql_escape "$name")
  sqlite3 "$WAKI_DB_PATH" "INSERT INTO migrations (name) VALUES ('$esc_name');"
}

waki_db_has_profile_display_name_column() {
  local exists
  exists=$(sqlite3 "$WAKI_DB_PATH" "SELECT 1 FROM pragma_table_info('waki_profiles') WHERE name = 'display_name' LIMIT 1;" 2>/dev/null || true)
  [[ -n "$exists" ]]
}

waki_db_migrate() {
  local migrations_dir="$WAKI_ROOT/database/migrations"

  sqlite3 "$WAKI_DB_PATH" "CREATE TABLE IF NOT EXISTS migrations (
    id         INTEGER PRIMARY KEY,
    name       TEXT NOT NULL UNIQUE,
    applied_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
  );"

  for migration in "$migrations_dir"/*.sql; do
    [[ ! -f "$migration" ]] && continue
    local name
    name=$(basename "$migration")
    local applied
    applied=$(sqlite3 "$WAKI_DB_PATH" "SELECT 1 FROM migrations WHERE name='$name' LIMIT 1;" 2>/dev/null || true)
    [[ -n "$applied" ]] && continue

    if [[ "$name" == "0002-profile-display-name.sql" ]] && waki_db_has_profile_display_name_column; then
      waki_db_mark_migration_applied "$name"
      continue
    fi

    sqlite3 "$WAKI_DB_PATH" < "$migration"
    waki_db_mark_migration_applied "$name"
  done
}

waki_db_query() {
  sqlite3 -separator $'\t' "$WAKI_DB_PATH" "$@"
}

waki_db_get() {
  sqlite3 "$WAKI_DB_PATH" "$@"
}

waki_db_log_event() {
  waki_db_query "INSERT INTO waki_events (kind, detail) VALUES ('$1', '$(waki_sql_escape "$2")');"
}

waki_db_ensure_profile() {
  local directory="$1"
  local esc_dir
  esc_dir=$(waki_sql_escape "$directory")
  waki_db_query "INSERT OR IGNORE INTO waki_profiles (directory) VALUES ('$esc_dir');"
  waki_db_get "SELECT id FROM waki_profiles WHERE directory = '$esc_dir';"
}

waki_db_get_profile_display_name() {
  local directory="$1"
  local esc_dir
  esc_dir=$(waki_sql_escape "$directory")
  waki_db_get "SELECT display_name FROM waki_profiles WHERE directory = '$esc_dir' AND display_name IS NOT NULL AND display_name != '' LIMIT 1;"
}

waki_db_set_profile_display_name() {
  local directory="$1"
  local display_name="$2"
  local esc_dir
  local esc_name
  esc_dir=$(waki_sql_escape "$directory")
  esc_name=$(waki_sql_escape "$display_name")
  waki_db_query "UPDATE waki_profiles SET display_name = '$esc_name' WHERE directory = '$esc_dir';"
}

waki_db_add_install() {
  local webapp_id="$1"
  local profile_id="$2"
  local changed
  changed=$(sqlite3 "$WAKI_DB_PATH" "
    INSERT OR IGNORE INTO waki_installs (webapp_id, profile_id) VALUES ($webapp_id, $profile_id);
    SELECT changes();")
  [[ "$changed" -gt 0 ]]
}

waki_db_get_install_id() {
  local webapp_id="$1"
  local profile_id="$2"
  waki_db_get "SELECT id FROM waki_installs WHERE webapp_id = $webapp_id AND profile_id = $profile_id;"
}

waki_db_remove_install() {
  waki_db_query "DELETE FROM waki_installs WHERE id = $1;"
}

waki_db_is_installed() {
  local webapp_id="$1"
  local profile_id="$2"
  waki_db_get "SELECT 1 FROM waki_installs WHERE webapp_id = $webapp_id AND profile_id = $profile_id LIMIT 1;"
}

waki_db_list_installs() {
  waki_db_query "
    SELECT i.id, w.id, w.name, w.url, w.icon_slug, w.category, p.directory
    FROM waki_installs i
    JOIN waki_webapps w ON w.id = i.webapp_id
    JOIN waki_profiles p ON p.id = i.profile_id
    ORDER BY w.name, p.directory;"
}
