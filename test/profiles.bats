#!/usr/bin/env bats
# Tests for lib/profiles.sh

setup() {
  load test_helper/common
  setup_test_env

  mkdir -p "$CHROMIUM_CONFIG_DIR/Default"
  mkdir -p "$CHROMIUM_CONFIG_DIR/Profile 2"

  cat > "$CHROMIUM_CONFIG_DIR/Local State" <<'JSON'
{
  "profile": {
    "info_cache": {
      "Default": {"name": "Work"},
      "Profile 2": {"name": "Personal"}
    }
  }
}
JSON
}

teardown() {
  teardown_test_env
}

@test "profiles list finds Default profile" {
  run waki_profiles_list
  assert_success
  assert_output --partial "Default"
}

@test "profiles list finds Profile 2" {
  run waki_profiles_list
  assert_success
  assert_output --partial "Profile 2"
}

@test "profiles list always includes Default even without chromium dir" {
  rm -rf "$CHROMIUM_CONFIG_DIR"
  mkdir -p "$CHROMIUM_CONFIG_DIR"
  run waki_profiles_list
  assert_success
  assert_output "Default"
}

@test "profiles display_name reads from Local State" {
  run waki_profiles_display_name "Default"
  assert_success
  assert_output "Work"
}

@test "profiles display_name for Profile 2" {
  run waki_profiles_display_name "Profile 2"
  assert_success
  assert_output "Personal"
}

@test "profiles display_name falls back to dir name when no Local State" {
  rm -f "$CHROMIUM_CONFIG_DIR/Local State"
  mkdir -p "$CHROMIUM_CONFIG_DIR/Profile 3"
  run waki_profiles_display_name "Profile 3"
  assert_success
  assert_output "Profile 3"
}

@test "desktop_label for Default profile includes display name when multiple profiles" {
  run waki_desktop_label "ChatGPT" "Default"
  assert_success
  assert_output "ChatGPT (Work)"
}

@test "desktop_label for non-Default includes display name" {
  run waki_desktop_label "ChatGPT" "Profile 2"
  assert_success
  assert_output "ChatGPT (Personal)"
}
