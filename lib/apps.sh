#!/usr/bin/env bash
# Manage optional desktop app integrations.

waki_apps_vscode_package() {
  echo "${WAKI_VSCODE_PACKAGE:-visual-studio-code-bin}"
}

waki_apps_vscode_user_dir() {
  if [[ -n "${WAKI_VSCODE_USER_DIR:-}" ]]; then
    echo "$WAKI_VSCODE_USER_DIR"
    return
  fi

  echo "$HOME/.config/Code/User"
}

waki_apps_vscode_settings_path() {
  echo "$(waki_apps_vscode_user_dir)/settings.json"
}

waki_apps_vscode_installed() {
  command -v code &>/dev/null
}

waki_apps_install_vscode() {
  if ! command -v omarchy-install-vscode &>/dev/null; then
    waki_red "Error: omarchy-install-vscode is required."
    echo "  Install Omarchy helpers, then run 'waki app add' again."
    return 1
  fi

  omarchy-install-vscode
}
