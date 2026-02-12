#!/usr/bin/env bats
# Integration tests for the waki CLI (bin/waki)

setup() {
  load test_helper/common
  setup_test_env

  WAKI_BIN="$WAKI_ROOT/bin/waki"

  cat > "$WAKI_BIN_DIR/gum" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
  style)
    shift
    while [[ "${1:-}" == --* ]]; do shift; done
    echo "$@"
    ;;
  choose|filter|input|confirm)
    exit 1
    ;;
  *)
    exit 1
    ;;
esac
STUB
  chmod +x "$WAKI_BIN_DIR/gum"

  export PATH="$WAKI_BIN_DIR:$PATH"
}

teardown() {
  teardown_test_env
}

@test "waki help exits 0 and shows usage" {
  run "$WAKI_BIN" help
  assert_success
  assert_output --partial "Usage: waki"
  assert_output --partial "webapp add"
  assert_output --partial "webapp refresh"
  assert_output --partial "uninstall"
}

@test "waki --help exits 0" {
  run "$WAKI_BIN" --help
  assert_success
  assert_output --partial "Usage: waki"
}

@test "waki about shows version and stats" {
  run "$WAKI_BIN" about
  assert_success
  assert_output --partial "Waki v"
  assert_output --partial "Catalog:"
}

@test "waki unknown command exits 1" {
  run "$WAKI_BIN" notacommand
  assert_failure
  assert_output --partial "Unknown command"
}

@test "waki webapp unknown subcommand exits 1" {
  run "$WAKI_BIN" webapp notasub
  assert_failure
  assert_output --partial "Usage: waki webapp"
}
