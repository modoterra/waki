#!/usr/bin/env bash
# Waki shared helpers

export WAKI_ROOT="${WAKI_ROOT:-$HOME/.local/share/waki}"
export WAKI_BIN_DIR="${WAKI_BIN_DIR:-$HOME/.local/bin}"
export WAKI_DB_PATH="${WAKI_DB_PATH:-$WAKI_ROOT/database/waki.db}"
export WAKI_ICON_DIR="$HOME/.local/share/applications/icons"
export WAKI_DESKTOP_DIR="$HOME/.local/share/applications"
export WAKI_ICON_CDN="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png"
export CHROMIUM_CONFIG_DIR="${HOME}/.config/chromium"

waki_green()  { echo -e "\033[0;32m$1\033[0m"; }
waki_yellow() { echo -e "\033[0;33m$1\033[0m"; }
waki_red()    { echo -e "\033[0;31m$1\033[0m"; }

waki_require_tool() {
  local tool="$1"
  local hint="${2:-}"

  if ! command -v "$tool" &>/dev/null; then
    waki_red "Error: Required tool '$tool' is not installed."
    [[ -n "$hint" ]] && echo "  $hint"
    exit 1
  fi
}

waki_sql_escape() {
  echo "${1//\'/\'\'}"
}

waki_refresh_desktop() {
  update-desktop-database "$WAKI_DESKTOP_DIR" 2>/dev/null || true
}
