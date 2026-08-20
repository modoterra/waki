var PLUGIN_ID = "modoterra.waki"
var ICON_CDN = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png"

var CHEF_PICKS = [
  "ChatGPT",
  "Gmail",
  "YouTube",
  "GitHub",
  "Google Calendar",
  "Notion",
  "Discord",
  "WhatsApp"
]

var KEYBIND_BLOCK_START = "-- >>> waki keybind >>>"
var KEYBIND_BLOCK_END = "-- <<< waki keybind <<<"
var ALIAS_BLOCK_START = "# >>> waki git aliases >>>"
var ALIAS_BLOCK_END = "# <<< waki git aliases <<<"
var DEFAULT_KEYBIND_CHORD = "SUPER + SHIFT + ALT + W"
var TOGGLE_COMMAND = "omarchy-shell shell toggle " + PLUGIN_ID

function emptyState() {
  return {
    version: 1,
    firstRunCompleted: false,
    setupApplied: false,
    installs: [],
    events: []
  }
}

function asObject(value) {
  return value && typeof value === "object" && !Array.isArray(value) ? value : null
}

function parseState(raw) {
  try {
    var parsed = JSON.parse(String(raw || ""))
    var obj = asObject(parsed)
    if (!obj) return emptyState()
    var state = emptyState()
    if (Number(obj.version) === 1) state.version = 1
    state.firstRunCompleted = obj.firstRunCompleted === true
    state.setupApplied = obj.setupApplied === true
    if (Array.isArray(obj.installs)) {
      for (var i = 0; i < obj.installs.length; i++) {
        var install = normalizeInstall(obj.installs[i])
        if (install) state.installs.push(install)
      }
    }
    if (Array.isArray(obj.events)) {
      for (var j = 0; j < obj.events.length; j++) {
        var event = asObject(obj.events[j])
        if (event && event.kind) {
          state.events.push({
            kind: String(event.kind),
            detail: String(event.detail || ""),
            at: String(event.at || "")
          })
        }
      }
    }
    return state
  } catch (e) {
    return emptyState()
  }
}

function normalizeInstall(value) {
  var install = asObject(value)
  if (!install) return null
  var name = String(install.name || "")
  var url = String(install.url || "")
  var profileDirectory = String(install.profileDirectory || "Default")
  if (!name || !url) return null
  return {
    name: name,
    url: url,
    iconSlug: String(install.iconSlug || ""),
    category: String(install.category || ""),
    profileDirectory: profileDirectory,
    profileDisplayName: String(install.profileDisplayName || profileDirectory),
    label: String(install.label || name)
  }
}

function serializeState(state) {
  var current = asObject(state) || emptyState()
  return JSON.stringify({
    version: 1,
    firstRunCompleted: current.firstRunCompleted === true,
    setupApplied: current.setupApplied === true,
    installs: Array.isArray(current.installs) ? current.installs : [],
    events: Array.isArray(current.events) ? current.events : []
  }, null, 2) + "\n"
}

function cloneState(state) {
  return parseState(serializeState(state))
}

function logEvent(state, kind, detail) {
  var next = cloneState(state)
  next.events.push({
    kind: String(kind || ""),
    detail: String(detail || ""),
    at: new Date().toISOString()
  })
  return next
}

function isInstalled(state, name, profileDirectory) {
  var installs = asObject(state) && Array.isArray(state.installs) ? state.installs : []
  var needleName = String(name || "")
  var needleProfile = String(profileDirectory || "Default")
  for (var i = 0; i < installs.length; i++) {
    if (installs[i].name === needleName && installs[i].profileDirectory === needleProfile)
      return true
  }
  return false
}

function addInstall(state, install) {
  var normalized = normalizeInstall(install)
  if (!normalized) return cloneState(state)
  if (isInstalled(state, normalized.name, normalized.profileDirectory))
    return cloneState(state)
  var next = cloneState(state)
  next.installs.push(normalized)
  return next
}

function removeInstallByLabel(state, label) {
  var next = cloneState(state)
  var needle = String(label || "")
  var kept = []
  for (var i = 0; i < next.installs.length; i++) {
    if (next.installs[i].label !== needle) kept.push(next.installs[i])
  }
  next.installs = kept
  return next
}

function desktopLabel(name, profileDirectory, profileDisplayName, profileCount) {
  var appName = String(name || "")
  var directory = String(profileDirectory || "Default")
  var displayName = String(profileDisplayName || directory)
  if (directory === "Default" && Number(profileCount) <= 1) return appName
  return appName + " (" + displayName + ")"
}

function normalizedQuery(query) {
  return String(query || "").trim().toLowerCase()
}

function itemSearchText(item) {
  if (!item || typeof item !== "object") return ""
  return [item.title, item.subtitle, item.name, item.category, item.label]
    .map(function(part) { return String(part || "") })
    .join(" ")
    .toLowerCase()
}

function filterItems(items, query) {
  var values = Array.isArray(items) ? items : []
  var needle = normalizedQuery(query)
  if (!needle) return values.slice()
  var out = []
  for (var i = 0; i < values.length; i++) {
    if (itemSearchText(values[i]).indexOf(needle) >= 0) out.push(values[i])
  }
  return out
}

function parseChromiumProfiles(raw) {
  var profiles = [{ directory: "Default", displayName: "Default" }]
  try {
    var parsed = JSON.parse(String(raw || ""))
    var cache = asObject(parsed) && asObject(parsed.profile) && asObject(parsed.profile.info_cache)
    if (!cache) return profiles
    var seen = { Default: true }
    if (cache.Default && cache.Default.name)
      profiles[0].displayName = String(cache.Default.name)
    var keys = Object.keys(cache)
    keys.sort()
    for (var i = 0; i < keys.length; i++) {
      var directory = keys[i]
      if (seen[directory]) continue
      seen[directory] = true
      var info = asObject(cache[directory]) || {}
      profiles.push({
        directory: directory,
        displayName: String(info.name || directory)
      })
    }
    return profiles
  } catch (e) {
    return profiles
  }
}

function quoteDesktopArg(value) {
  var text = String(value || "")
  if (!/[\s"]/.test(text)) return text
  return "\"" + text.replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\""
}

function desktopFileContents(fields) {
  var label = String(fields && fields.label || "")
  var url = String(fields && fields.url || "")
  var iconPath = String(fields && fields.iconPath || "")
  var profileDirectory = String(fields && fields.profileDirectory || "Default")
  var execLine = [
    "omarchy-launch-webapp",
    quoteDesktopArg(url),
    "--profile-directory=" + quoteDesktopArg(profileDirectory)
  ].join(" ")
  return [
    "[Desktop Entry]",
    "Version=1.0",
    "Name=" + label,
    "Comment=" + label,
    "Exec=" + execLine,
    "Terminal=false",
    "Type=Application",
    "Icon=" + iconPath,
    "StartupNotify=true",
    ""
  ].join("\n")
}

function iconUrl(slug) {
  return ICON_CDN + "/" + String(slug || "") + ".png"
}

function iconFileName(label) {
  return String(label || "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "") + ".png"
}

function removeMarkedBlock(text, startMarker, endMarker) {
  var source = String(text || "")
  var start = source.indexOf(startMarker)
  if (start === -1) return source
  var end = source.indexOf(endMarker, start)
  if (end === -1) return source
  var after = end + endMarker.length
  if (source.charAt(after) === "\n") after += 1
  var before = source.slice(0, start)
  var rest = source.slice(after)
  if (before.slice(-2) === "\n\n" && rest.charAt(0) === "\n")
    before = before.slice(0, -1)
  return before + rest
}

function hasMarkedBlock(text, startMarker, endMarker) {
  var source = String(text || "")
  var start = source.indexOf(startMarker)
  if (start === -1) return false
  return source.indexOf(endMarker, start) !== -1
}

function insertMarkedBlock(text, startMarker, endMarker, body) {
  var stripped = removeMarkedBlock(text, startMarker, endMarker).replace(/\s*$/, "")
  var block = startMarker + "\n" + body + "\n" + endMarker + "\n"
  if (!stripped) return block
  return stripped + "\n\n" + block
}

function keybindBody(chord) {
  return "o.bind(\"" + chord + "\", \"Waki\", \"" + TOGGLE_COMMAND + "\")"
}

function applyKeybindBlock(text, chord) {
  var usedChord = String(chord || DEFAULT_KEYBIND_CHORD)
  var source = String(text || "")
  if (hasMarkedBlock(source, KEYBIND_BLOCK_START, KEYBIND_BLOCK_END))
    return { text: source, changed: false, skipped: "" }
  var without = removeMarkedBlock(source, KEYBIND_BLOCK_START, KEYBIND_BLOCK_END)
  if (without.indexOf(usedChord) !== -1)
    return { text: source, changed: false, skipped: "taken" }
  return {
    text: insertMarkedBlock(source, KEYBIND_BLOCK_START, KEYBIND_BLOCK_END, keybindBody(usedChord)),
    changed: true,
    skipped: ""
  }
}

function removeKeybindBlock(text) {
  return removeMarkedBlock(text, KEYBIND_BLOCK_START, KEYBIND_BLOCK_END)
}

function menuEntryJson() {
  return {
    icon: "󰦨",
    label: "Waki",
    action: TOGGLE_COMMAND,
    keywords: "webapp catalog chromium"
  }
}

function hasJsoncKey(text, key) {
  return new RegExp("\"" + key + "\"\\s*:").test(String(text || ""))
}

function applyMenuEntry(text) {
  var source = String(text || "")
  if (hasJsoncKey(source, "waki"))
    return { text: source, changed: false }
  var value = JSON.stringify(menuEntryJson())
  var open = source.indexOf("{")
  if (open === -1) {
    return { text: "{\n  \"waki\": " + value + "\n}\n", changed: true }
  }
  var entry = "\n  \"waki\": " + value + ","
  return { text: source.slice(0, open + 1) + entry + source.slice(open + 1), changed: true }
}

function removeMenuEntry(text) {
  var source = String(text || "")
  var next = source.replace(/\n?\s*"waki"\s*:\s*\{[^}]*\},?/, "")
  return next
}

function aliasBlock(aliasFile) {
  return [
    ALIAS_BLOCK_START,
    "if [[ -f \"" + aliasFile + "\" ]]; then",
    "  source \"" + aliasFile + "\"",
    "fi",
    ALIAS_BLOCK_END
  ].join("\n")
}

function applyAliasBlock(text, aliasFile) {
  var source = String(text || "")
  if (hasMarkedBlock(source, ALIAS_BLOCK_START, ALIAS_BLOCK_END))
    return { text: source, changed: false }
  return {
    text: insertMarkedBlock(source, ALIAS_BLOCK_START, ALIAS_BLOCK_END, aliasBlock(aliasFile).split("\n").slice(1, -1).join("\n")),
    changed: true
  }
}

function removeAliasBlock(text) {
  return removeMarkedBlock(text, ALIAS_BLOCK_START, ALIAS_BLOCK_END)
}

function aliasEnabledIn(text) {
  return hasMarkedBlock(text, ALIAS_BLOCK_START, ALIAS_BLOCK_END)
}

function chefPicks() {
  return CHEF_PICKS.slice()
}

function pluginId() {
  return PLUGIN_ID
}

function defaultKeybindChord() {
  return DEFAULT_KEYBIND_CHORD
}

function toggleCommand() {
  return TOGGLE_COMMAND
}

function homeActions() {
  return [
    { id: "add", title: "Add web apps", subtitle: "Install from the catalog" },
    { id: "remove", title: "Remove web apps", subtitle: "Delete Waki launchers" },
    { id: "refresh", title: "Refresh launchers", subtitle: "Rewrite desktop entries" },
    { id: "vscode", title: "Install VS Code", subtitle: "Uses omarchy-install-vscode" },
    { id: "aliases", title: "Git aliases", subtitle: "Oh My Zsh-style aliases in ~/.bashrc" },
    { id: "update", title: "Update Waki", subtitle: "omarchy plugin update" },
    { id: "about", title: "About", subtitle: "Version and catalog stats" },
    { id: "uninstall", title: "Uninstall", subtitle: "Remove launchers, keybind, and menu row" }
  ]
}

function aliasActions(enabled) {
  if (enabled) {
    return [
      { id: "alias-refresh", title: "Refresh aliases", subtitle: "Rewrite the managed bashrc block" },
      { id: "alias-remove", title: "Remove aliases", subtitle: "Delete the managed bashrc block" }
    ]
  }
  return [
    { id: "alias-add", title: "Enable git aliases", subtitle: "Source aliases/git.sh from ~/.bashrc" }
  ]
}

if (typeof module !== "undefined") {
  module.exports = {
    PLUGIN_ID: PLUGIN_ID,
    CHEF_PICKS: CHEF_PICKS,
    KEYBIND_BLOCK_START: KEYBIND_BLOCK_START,
    KEYBIND_BLOCK_END: KEYBIND_BLOCK_END,
    ALIAS_BLOCK_START: ALIAS_BLOCK_START,
    ALIAS_BLOCK_END: ALIAS_BLOCK_END,
    DEFAULT_KEYBIND_CHORD: DEFAULT_KEYBIND_CHORD,
    TOGGLE_COMMAND: TOGGLE_COMMAND,
    emptyState: emptyState,
    parseState: parseState,
    serializeState: serializeState,
    logEvent: logEvent,
    isInstalled: isInstalled,
    addInstall: addInstall,
    removeInstallByLabel: removeInstallByLabel,
    desktopLabel: desktopLabel,
    filterItems: filterItems,
    parseChromiumProfiles: parseChromiumProfiles,
    desktopFileContents: desktopFileContents,
    iconUrl: iconUrl,
    iconFileName: iconFileName,
    applyKeybindBlock: applyKeybindBlock,
    removeKeybindBlock: removeKeybindBlock,
    applyMenuEntry: applyMenuEntry,
    removeMenuEntry: removeMenuEntry,
    applyAliasBlock: applyAliasBlock,
    removeAliasBlock: removeAliasBlock,
    aliasEnabledIn: aliasEnabledIn,
    hasMarkedBlock: hasMarkedBlock,
    chefPicks: chefPicks,
    pluginId: pluginId,
    defaultKeybindChord: defaultKeybindChord,
    toggleCommand: toggleCommand,
    homeActions: homeActions,
    aliasActions: aliasActions,
    menuEntryJson: menuEntryJson
  }
}
