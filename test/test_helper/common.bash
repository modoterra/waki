#!/usr/bin/env bash
# Common test setup for all waki bats tests

WAKI_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAKI_PROJECT_ROOT="$(cd "$WAKI_TEST_DIR/.." && pwd)"

load "$WAKI_TEST_DIR/test_helper/bats-support/load"
load "$WAKI_TEST_DIR/test_helper/bats-assert/load"

# Set up an isolated test environment so tests never touch real user data
setup_test_env() {
  TEST_TMPDIR="$(mktemp -d)"
  export WAKI_ROOT="$WAKI_PROJECT_ROOT"
  export WAKI_DB_PATH="$TEST_TMPDIR/waki.db"
  export WAKI_BIN_DIR="$TEST_TMPDIR/bin"
  export WAKI_DESKTOP_DIR="$TEST_TMPDIR/applications"
  export WAKI_ICON_DIR="$TEST_TMPDIR/icons"
  export CHROMIUM_CONFIG_DIR="$TEST_TMPDIR/chromium"
  export HOME="$TEST_TMPDIR/home"

  mkdir -p "$WAKI_BIN_DIR" "$WAKI_DESKTOP_DIR" "$WAKI_ICON_DIR" "$HOME"

  # Source libraries fresh in the test environment
  source "$WAKI_ROOT/lib/helpers.sh"
  source "$WAKI_ROOT/lib/database.sh"
  source "$WAKI_ROOT/lib/catalog.sh"
  source "$WAKI_ROOT/lib/profiles.sh"

  waki_db_init
  waki_profiles_sync
}

teardown_test_env() {
  [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR:-}" ]] && rm -rf "$TEST_TMPDIR"
}
