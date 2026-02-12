#!/usr/bin/env bats
# Tests for lib/catalog.sh

setup() {
  load test_helper/common
  setup_test_env
  waki_db_init
}

teardown() {
  teardown_test_env
}

@test "catalog has 120 apps after seeding" {
  run waki_db_get "SELECT COUNT(*) FROM waki_webapps;"
  assert_success
  assert_output "120"
}

@test "catalog seed is idempotent" {
  waki_catalog_seed
  run waki_db_get "SELECT COUNT(*) FROM waki_webapps;"
  assert_success
  assert_output "120"
}

@test "all expected categories exist" {
  run waki_db_query "SELECT DISTINCT category FROM waki_webapps ORDER BY category;"
  assert_success
  assert_output --partial "ai"
  assert_output --partial "cloud"
  assert_output --partial "communication"
  assert_output --partial "design"
  assert_output --partial "development"
  assert_output --partial "email"
  assert_output --partial "finance"
  assert_output --partial "google"
  assert_output --partial "media"
  assert_output --partial "productivity"
  assert_output --partial "proton"
  assert_output --partial "social"
  assert_output --partial "utilities"
}

@test "catalog list returns all apps" {
  result=$(waki_catalog_list | wc -l)
  [ "$result" -eq 120 ]
}

@test "catalog get returns a single app by name" {
  run waki_catalog_get "ChatGPT"
  assert_success
  assert_output --partial "ChatGPT"
  assert_output --partial "chatgpt.com"
}

@test "catalog get with nonexistent name returns empty" {
  run waki_catalog_get "Nonexistent App"
  assert_success
  assert_output ""
}

@test "no installs initially" {
  run waki_db_list_installs
  assert_success
  assert_output ""
}

@test "adding an install is tracked" {
  local app_id profile_id
  app_id=$(waki_db_get "SELECT id FROM waki_webapps WHERE name = 'ChatGPT';")
  profile_id=$(waki_db_ensure_profile "Default")

  waki_db_add_install "$app_id" "$profile_id"

  run waki_db_list_installs
  assert_success
  assert_output --partial "ChatGPT"
}

@test "get_install_id returns the install id" {
  local app_id profile_id
  app_id=$(waki_db_get "SELECT id FROM waki_webapps WHERE name = 'ChatGPT';")
  profile_id=$(waki_db_ensure_profile "Default")

  waki_db_add_install "$app_id" "$profile_id"

  run waki_db_get_install_id "$app_id" "$profile_id"
  assert_success
  [ "$output" -gt 0 ]
}

@test "removing an install works" {
  local app_id profile_id
  app_id=$(waki_db_get "SELECT id FROM waki_webapps WHERE name = 'ChatGPT';")
  profile_id=$(waki_db_ensure_profile "Default")

  waki_db_add_install "$app_id" "$profile_id"
  local install_id
  install_id=$(waki_db_get_install_id "$app_id" "$profile_id")
  waki_db_remove_install "$install_id"

  run waki_db_list_installs
  assert_success
  assert_output ""
}

@test "duplicate install is rejected" {
  local app_id profile_id
  app_id=$(waki_db_get "SELECT id FROM waki_webapps WHERE name = 'ChatGPT';")
  profile_id=$(waki_db_ensure_profile "Default")

  waki_db_add_install "$app_id" "$profile_id"
  run waki_db_add_install "$app_id" "$profile_id"
  assert_failure
}
