#!/usr/bin/env bats
# Tests for lib/apps.sh

setup() {
  load test_helper/common
  setup_test_env
}

teardown() {
  teardown_test_env
}

@test "waki_apps_vscode_user_dir defaults to Code" {
  run waki_apps_vscode_user_dir
  assert_success
  assert_output "$HOME/.config/Code/User"
}

@test "waki_apps_vscode_user_dir respects explicit override" {
  export WAKI_VSCODE_USER_DIR="$HOME/custom-vscode/User"

  run waki_apps_vscode_user_dir
  assert_success
  assert_output "$HOME/custom-vscode/User"
}

@test "waki_apps_install_vscode calls omarchy installer" {
  cat > "$WAKI_BIN_DIR/omarchy-install-vscode" <<'STUB'
#!/usr/bin/env bash
touch "$HOME/omarchy_install_called"
STUB
  chmod +x "$WAKI_BIN_DIR/omarchy-install-vscode"

  export PATH="$WAKI_BIN_DIR:$PATH"

  run waki_apps_install_vscode
  assert_success
  assert [ -f "$HOME/omarchy_install_called" ]
}

@test "waki_apps_install_vscode fails when omarchy installer missing" {
  export PATH="$WAKI_BIN_DIR:/usr/bin:/bin"

  run waki_apps_install_vscode
  assert_failure
  assert_output --partial "omarchy-install-vscode is required"
}
