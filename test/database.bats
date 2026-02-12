#!/usr/bin/env bats
# Tests for lib/database.sh and database migrations

setup() {
  load test_helper/common
  setup_test_env
}

teardown() {
  teardown_test_env
}

@test "waki_db_init creates the database file" {
  refute [ -f "$WAKI_DB_PATH" ]
  waki_db_init
  assert [ -f "$WAKI_DB_PATH" ]
}

@test "waki_db_init creates the waki_webapps table" {
  waki_db_init
  run sqlite3 "$WAKI_DB_PATH" ".tables"
  assert_success
  assert_output --partial "waki_webapps"
}

@test "waki_db_init is idempotent" {
  waki_db_init
  run waki_db_init
  assert_success
}

@test "waki_db_query returns tab-separated results" {
  waki_db_init
  run waki_db_query "SELECT name FROM waki_webapps WHERE category = 'proton' ORDER BY name LIMIT 1;"
  assert_success
  assert_output "Proton Calendar"
}

@test "waki_db_get returns a scalar value" {
  waki_db_init
  run waki_db_get "SELECT COUNT(*) FROM waki_webapps;"
  assert_success
  [ "$output" -gt 100 ]
}

@test "waki_webapps table has expected columns" {
  waki_db_init
  run sqlite3 "$WAKI_DB_PATH" "PRAGMA table_info(waki_webapps);"
  assert_success
  assert_output --partial "name"
  assert_output --partial "url"
  assert_output --partial "icon_slug"
  assert_output --partial "category"
}

@test "waki_profiles table has expected columns" {
  waki_db_init
  run sqlite3 "$WAKI_DB_PATH" "PRAGMA table_info(waki_profiles);"
  assert_success
  assert_output --partial "directory"
  assert_output --partial "created_at"
}

@test "waki_installs table has expected columns" {
  waki_db_init
  run sqlite3 "$WAKI_DB_PATH" "PRAGMA table_info(waki_installs);"
  assert_success
  assert_output --partial "webapp_id"
  assert_output --partial "profile_id"
  assert_output --partial "created_at"
}

@test "Default profile is seeded automatically" {
  waki_db_init
  run waki_db_get "SELECT directory FROM waki_profiles WHERE directory = 'Default';"
  assert_success
  assert_output "Default"
}

@test "waki_db_log_event records an event" {
  waki_db_init
  waki_db_log_event "test_kind" "test_detail"
  run waki_db_get "SELECT detail FROM waki_events WHERE kind = 'test_kind';"
  assert_success
  assert_output "test_detail"
}
