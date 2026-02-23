#!/usr/bin/env bats
# Tests for lib/aliases.sh

setup() {
  load test_helper/common
  setup_test_env
}

teardown() {
  teardown_test_env
}

@test "waki_aliases_add_to_bashrc creates managed block" {
  run waki_aliases_add_to_bashrc
  assert_success

  assert [ -f "$HOME/.bashrc" ]
  run grep -F "# >>> waki git aliases >>>" "$HOME/.bashrc"
  assert_success
  run grep -F "$WAKI_ROOT/lib/aliases/git.sh" "$HOME/.bashrc"
  assert_success
}

@test "waki_aliases_add_to_bashrc is idempotent" {
  run waki_aliases_add_to_bashrc
  assert_success

  run waki_aliases_add_to_bashrc
  assert_success

  run grep -cF "# >>> waki git aliases >>>" "$HOME/.bashrc"
  assert_success
  assert_output "1"

  run grep -cF "# <<< waki git aliases <<<" "$HOME/.bashrc"
  assert_success
  assert_output "1"
}

@test "waki_aliases_remove_from_bashrc removes only managed block" {
  printf 'export PATH="$HOME/.local/bin:$PATH"\n' > "$HOME/.bashrc"
  waki_aliases_add_to_bashrc

  run waki_aliases_remove_from_bashrc
  assert_success

  run grep -F 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"
  assert_success
  run grep -F "# >>> waki git aliases >>>" "$HOME/.bashrc"
  assert_failure
}
