#!/usr/bin/env bash
# Chromium profile detection

# List available Chromium profile directories from filesystem
waki_profiles_list() {
  local profiles=("Default")

  if [[ -d "$CHROMIUM_CONFIG_DIR" ]]; then
    for dir in "$CHROMIUM_CONFIG_DIR"/Profile\ *; do
      [[ -d "$dir" ]] && profiles+=("$(basename "$dir")")
    done
  fi

  printf '%s\n' "${profiles[@]}"
}

# Human-readable display name from Chromium files (no DB)
waki_profiles_display_name_live() {
  local profile_dir="$1"
  local resolved_dir
  resolved_dir=$(waki_profiles_resolve_dir "$profile_dir")
  local prefs_file="$CHROMIUM_CONFIG_DIR/$resolved_dir/Preferences"
  local local_state_file="$CHROMIUM_CONFIG_DIR/Local State"

  if [[ -f "$local_state_file" ]]; then
    local name
    name=$(jq -r --arg dir "$resolved_dir" '.profile.info_cache[$dir].name // empty' "$local_state_file" 2>/dev/null)
    if [[ -n "$name" ]]; then
      echo "$name"
      return
    fi
  fi

  if [[ -f "$prefs_file" ]]; then
    local name
    name=$(jq -r '.profile.name // empty' "$prefs_file" 2>/dev/null)
    if [[ -n "$name" ]]; then
      echo "$name"
      return
    fi
  fi
}

# Sync profile directories and display names into the database
waki_profiles_sync() {
  local profiles
  profiles=$(waki_profiles_list)

  while IFS= read -r profile_dir; do
    [[ -z "$profile_dir" ]] && continue
    waki_db_ensure_profile "$profile_dir" >/dev/null

    local display
    display=$(waki_profiles_display_name_live "$profile_dir")
    if [[ -n "$display" ]]; then
      waki_db_set_profile_display_name "$profile_dir" "$display"
    fi
  done <<< "$profiles"
}

# Human-readable display name for a profile directory
waki_profiles_display_name() {
  local profile_dir="$1"
  local live
  live=$(waki_profiles_display_name_live "$profile_dir")
  if [[ -n "$live" ]]; then
    echo "$live"
    return
  fi

  local stored
  stored=$(waki_db_get_profile_display_name "$profile_dir")
  if [[ -n "$stored" ]]; then
    echo "$stored"
    return
  fi

  local resolved_dir
  resolved_dir=$(waki_profiles_resolve_dir "$profile_dir")
  echo "$resolved_dir"
}

# Resolve profile directory from display name (if needed)
waki_profiles_resolve_dir() {
  local profile_dir="$1"
  local local_state_file="$CHROMIUM_CONFIG_DIR/Local State"

  if [[ -d "$CHROMIUM_CONFIG_DIR/$profile_dir" ]]; then
    echo "$profile_dir"
    return
  fi

  if [[ -f "$local_state_file" ]]; then
    local resolved
    resolved=$(jq -r --arg name "$profile_dir" '.profile.info_cache
      | to_entries[]
      | select(.value.name == $name)
      | .key' "$local_state_file" 2>/dev/null | head -n 1)
    if [[ -n "$resolved" ]]; then
      echo "$resolved"
      return
    fi
  fi

  echo "$profile_dir"
}

# Desktop file label: "AppName" for Default, "AppName (DisplayName)" for others
waki_desktop_label() {
  local app_name="$1"
  local profile_dir="$2"
  local profile_count
  profile_count=$(waki_profiles_list | wc -l)

  if [[ "$profile_dir" == "Default" && $profile_count -le 1 ]]; then
    echo "$app_name"
  else
    local display
    display=$(waki_profiles_display_name "$profile_dir")
    echo "$app_name ($display)"
  fi
}

# Interactive profile chooser (returns profile directory name)
waki_profiles_choose() {
  local header="${1:-Select Chromium profile:}"
  local profiles
  profiles=$(waki_profiles_list)

  local display_items=()
  while IFS= read -r profile; do
    local display_name
    display_name=$(waki_profiles_display_name "$profile")
    if [[ "$profile" == "$display_name" ]]; then
      display_items+=("$profile")
    else
      display_items+=("$profile ($display_name)")
    fi
  done <<< "$profiles"

  local choice
  choice=$(printf '%s\n' "${display_items[@]}" | gum choose --header "$header") || return 1

  # Extract directory name (strip parenthetical display name)
  echo "$choice" | sed 's/ (.*//'
}
