#!/usr/bin/env bash
# Manage optional alias bundles.

WAKI_ALIAS_BLOCK_START="# >>> waki git aliases >>>"
WAKI_ALIAS_BLOCK_END="# <<< waki git aliases <<<"

waki_aliases_bashrc_path() {
  echo "${WAKI_BASHRC_PATH:-$HOME/.bashrc}"
}

waki_aliases_git_file() {
  echo "$WAKI_ROOT/lib/aliases/git.sh"
}

waki_aliases_render_block() {
  local git_alias_file
  git_alias_file=$(waki_aliases_git_file)

  cat <<EOF
$WAKI_ALIAS_BLOCK_START
if [[ -f "$git_alias_file" ]]; then
  source "$git_alias_file"
fi
$WAKI_ALIAS_BLOCK_END
EOF
}

waki_aliases_block_present() {
  local bashrc
  bashrc=$(waki_aliases_bashrc_path)
  [[ -f "$bashrc" ]] || return 1
  grep -qF "$WAKI_ALIAS_BLOCK_START" "$bashrc" && grep -qF "$WAKI_ALIAS_BLOCK_END" "$bashrc"
}

waki_aliases_remove_from_bashrc() {
  local bashrc
  bashrc=$(waki_aliases_bashrc_path)
  [[ -f "$bashrc" ]] || return 0

  local tmp
  tmp=$(mktemp)
  awk -v start="$WAKI_ALIAS_BLOCK_START" -v end="$WAKI_ALIAS_BLOCK_END" '
    $0 == start {skip=1; next}
    $0 == end {skip=0; next}
    skip != 1 {print}
  ' "$bashrc" > "$tmp"

  mv "$tmp" "$bashrc"
}

waki_aliases_add_to_bashrc() {
  local bashrc
  bashrc=$(waki_aliases_bashrc_path)
  mkdir -p "$(dirname "$bashrc")"
  touch "$bashrc"

  waki_aliases_remove_from_bashrc

  local block
  block=$(waki_aliases_render_block)
  printf '\n%s\n' "$block" >> "$bashrc"
}

waki_aliases_refresh_in_bashrc() {
  waki_aliases_add_to_bashrc
}
