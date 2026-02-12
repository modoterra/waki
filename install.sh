#!/usr/bin/env bash
# Waki installer — Mise en place for Omarchy
# Usage: curl -fsSL https://raw.githubusercontent.com/modoterra/waki/main/install.sh | bash
#        curl -fsSL ... | bash -s -- --canary

set -euo pipefail

REPO_URL="${WAKI_REPO_URL:-https://github.com/modoterra/waki.git}"
BIN_DIR="${WAKI_BIN_DIR:-$HOME/.local/bin}"
BINDINGS_CONF="$HOME/.config/hypr/bindings.conf"

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -n "${WAKI_ROOT:-}" ]]; then
  INSTALL_ROOT="$WAKI_ROOT"
elif [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/.git" ]]; then
  INSTALL_ROOT="$SCRIPT_DIR"
else
  INSTALL_ROOT="$HOME/.local/share/waki"
fi

BRANCH="main"

_green()  { printf "\033[0;32m%s\033[0m\n" "$1"; }
_yellow() { printf "\033[0;33m%s\033[0m\n" "$1"; }
_red()    { printf "\033[0;31m%s\033[0m\n" "$1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --canary) BRANCH="canary"; shift ;;
    *)        _red "Unknown option: $1"; exit 1 ;;
  esac
done

echo ""
_green "Waki Installer"
echo ""

check_dep() {
  local tool="$1" hint="$2"
  if ! command -v "$tool" &>/dev/null; then
    _red "Missing: $tool"
    echo "  $hint"
    return 1
  fi
  _green "Found $tool"
}

echo "Checking dependencies..."
deps_ok=true
check_dep git     "Install via your package manager (pacman -S git, etc.)" || deps_ok=false
check_dep gum     "Install from https://github.com/charmbracelet/gum"     || deps_ok=false
check_dep jq      "Install via your package manager (pacman -S jq, etc.)"  || deps_ok=false
check_dep sqlite3 "Install via your package manager (pacman -S sqlite, etc.)" || deps_ok=false

if [[ "$deps_ok" != "true" ]]; then
  echo ""
  _red "Please install missing dependencies and try again."
  exit 1
fi
echo ""

if [[ "$INSTALL_ROOT" == "$SCRIPT_DIR" ]]; then
  _green "Using local repo: $INSTALL_ROOT"
elif [[ -d "$INSTALL_ROOT/.git" ]]; then
  echo "Updating existing installation..."
  git -C "$INSTALL_ROOT" fetch --quiet
  git -C "$INSTALL_ROOT" checkout --quiet "$BRANCH"
  git -C "$INSTALL_ROOT" pull --quiet
  _green "Repository ready ($BRANCH branch)"
else
  echo "Installing Waki to $INSTALL_ROOT..."
  mkdir -p "$(dirname "$INSTALL_ROOT")"
  git clone --quiet --branch "$BRANCH" "$REPO_URL" "$INSTALL_ROOT"
  _green "Repository ready ($BRANCH branch)"
fi

mkdir -p "$BIN_DIR"

ln -sf "$INSTALL_ROOT/bin/waki" "$BIN_DIR/waki"
chmod +x "$INSTALL_ROOT/bin/waki"
_green "Linked $BIN_DIR/waki"

ln -sf "$INSTALL_ROOT/bin/waki-webapp-launch" "$BIN_DIR/waki-webapp-launch"
chmod +x "$INSTALL_ROOT/bin/waki-webapp-launch"
_green "Linked $BIN_DIR/waki-webapp-launch"

# Omarchy's bin dir so Walker can find it (systemd PATH doesn't include ~/.local/bin)
OMARCHY_BIN_DIR="$HOME/.local/share/omarchy/bin"
if [[ -d "$OMARCHY_BIN_DIR" ]]; then
  ln -sf "$INSTALL_ROOT/bin/waki-webapp-launch" "$OMARCHY_BIN_DIR/waki-webapp-launch"
  _green "Linked $OMARCHY_BIN_DIR/waki-webapp-launch"
fi

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo ""
  _yellow "Warning: $BIN_DIR is not on your PATH"
  echo "Add this to your shell config:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

KEYBIND="bindd = SUPER SHIFT, W, Waki, exec, omarchy-launch-floating-terminal-with-presentation $BIN_DIR/waki"

if [[ -f "$BINDINGS_CONF" ]]; then
  if ! grep -qF "SUPER SHIFT, W, Waki" "$BINDINGS_CONF"; then
    if grep -qE "SUPER SHIFT, W" "$BINDINGS_CONF"; then
      _yellow "SUPER SHIFT W keybinding already exists."
      if gum confirm "Overwrite existing SUPER SHIFT W binding?" --default=false; then
        sed -i '/SUPER SHIFT, W/d' "$BINDINGS_CONF"
        echo "" >> "$BINDINGS_CONF"
        echo "$KEYBIND" >> "$BINDINGS_CONF"
        _green "Replaced SUPER SHIFT W keybinding"
      else
        _yellow "Skipped keybinding update"
      fi
    else
      echo "" >> "$BINDINGS_CONF"
      echo "$KEYBIND" >> "$BINDINGS_CONF"
      _green "Added SUPER SHIFT W keybinding"
    fi
  else
    _green "Keybinding already present"
  fi
else
  _yellow "Skipped keybinding: $BINDINGS_CONF not found"
fi

HOOKS_DIR="$HOME/.config/omarchy/hooks"
if [[ -d "$HOOKS_DIR" ]]; then
  for sample in "$INSTALL_ROOT"/hooks/*.sample; do
    [[ ! -f "$sample" ]] && continue
    local_name=$(basename "$sample")
    [[ ! -f "$HOOKS_DIR/$local_name" ]] && cp "$sample" "$HOOKS_DIR/$local_name"
  done
  _green "Hook samples installed"
fi

echo ""
_green "Waki installed successfully!"
echo ""
echo "Run 'waki' to get started, or press SUPER SHIFT W."
