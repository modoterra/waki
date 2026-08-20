import QtQuick
import Quickshell
import Quickshell.Io
import "WakiModel.js" as WakiModel

Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")

  readonly property string home: Quickshell.env("HOME")
  readonly property string sourceDir: manifest && manifest.__sourceDir ? String(manifest.__sourceDir) : ""
  readonly property string dataDir: home + "/.local/share/waki"
  readonly property string statePath: dataDir + "/state.json"
  readonly property string legacyDbPath: dataDir + "/database/waki.db"
  readonly property string catalogPath: sourceDir ? sourceDir + "/plugin/catalog.json" : ""
  readonly property string aliasFilePath: sourceDir ? sourceDir + "/aliases/git.sh" : ""
  readonly property string hooksSourceDir: sourceDir ? sourceDir + "/hooks" : ""
  readonly property string desktopDir: home + "/.local/share/applications"
  readonly property string iconDir: desktopDir + "/icons"
  readonly property string bindingsPath: home + "/.config/hypr/bindings.lua"
  readonly property string menuPath: home + "/.config/omarchy/extensions/omarchy-menu.jsonc"
  readonly property string bashrcPath: home + "/.bashrc"
  readonly property string hooksDir: home + "/.config/omarchy/hooks"
  readonly property string chromiumLocalStatePath: home + "/.config/chromium/Local State"
  readonly property string vscodeSettingsPath: home + "/.config/Code/User/settings.json"

  property var catalog: []
  property var state: WakiModel.emptyState()
  property var profiles: [{ directory: "Default", displayName: "Default" }]
  property bool ready: false
  property bool aliasEnabled: false
  property string setupNote: ""
  property string lastError: ""

  property bool catalogLoaded: false
  property bool stateLoaded: false
  property bool bindingsLoaded: false
  property bool menuLoaded: false
  property bool bashrcLoaded: false
  property bool profilesLoaded: false
  property bool dirsReady: false
  property bool setupStarted: false
  property bool migrateChecked: false

  property string bindingsText: ""
  property string menuText: ""
  property string bashrcText: ""
  property string pendingWritePath: ""
  property string pendingWriteText: ""
  property var writeQueue: []
  property bool writeBusy: false

  signal changed()

  function notify(title, body) {
    if (!root.omarchyPath) return
    Quickshell.execDetached([root.omarchyPath + "/bin/omarchy-notification-send", title, String(body || "")])
  }

  function persistState() {
    enqueueWrite(root.statePath, WakiModel.serializeState(root.state))
  }

  function replaceState(next) {
    root.state = next
    persistState()
    root.changed()
  }

  function tryFinishSetup() {
    if (root.setupStarted) return
    if (!root.dirsReady || !root.catalogLoaded || !root.stateLoaded) return
    if (!root.bindingsLoaded || !root.menuLoaded || !root.bashrcLoaded || !root.profilesLoaded) return
    if (!root.migrateChecked) return
    root.setupStarted = true
    applySetup()
    root.ready = true
    root.changed()
  }

  function applySetup() {
    Quickshell.execDetached(["mkdir", "-p", root.desktopDir, root.iconDir, root.hooksDir, root.home + "/.config/omarchy/extensions"])
    if (root.hooksSourceDir) {
      Quickshell.execDetached(["cp", "-n",
        root.hooksSourceDir + "/waki-webapp-install.sample",
        root.hooksSourceDir + "/waki-webapp-remove.sample",
        root.hooksDir + "/"])
    }

    if (root.state.setupApplied) return

    var notes = []
    var keybind = WakiModel.applyKeybindBlock(root.bindingsText, WakiModel.defaultKeybindChord())
    if (keybind.skipped === "taken") {
      notes.push(WakiModel.defaultKeybindChord() + " is already bound")
    } else if (keybind.changed) {
      enqueueWrite(root.bindingsPath, keybind.text)
      root.bindingsText = keybind.text
      notes.push("Bound " + WakiModel.defaultKeybindChord())
    }

    var menu = WakiModel.applyMenuEntry(root.menuText || "{\n}\n")
    if (menu.changed) {
      enqueueWrite(root.menuPath, menu.text)
      root.menuText = menu.text
    }

    var next = WakiModel.parseState(WakiModel.serializeState(root.state))
    next.setupApplied = true
    replaceState(next)
    root.setupNote = notes.join(". ")
  }

  function enqueueWrite(path, text) {
    var next = root.writeQueue.slice()
    next.push({ path: String(path), text: String(text) })
    root.writeQueue = next
    pumpWriteQueue()
  }

  function pumpWriteQueue() {
    if (root.writeBusy || root.writeQueue.length === 0) return
    var job = root.writeQueue[0]
    root.writeBusy = true
    root.pendingWriteText = job.text
    root.pendingWritePath = job.path
    writeDelay.restart()
  }

  function finishWrite() {
    var rest = root.writeQueue.slice(1)
    root.writeQueue = rest
    root.writeBusy = false
    pumpWriteQueue()
  }

  function installApp(app, profile) {
    if (!app || !app.name) return false
    var directory = profile && profile.directory ? profile.directory : "Default"
    var displayName = profile && profile.displayName ? profile.displayName : directory
    if (WakiModel.isInstalled(root.state, app.name, directory)) return false

    var label = WakiModel.desktopLabel(app.name, directory, displayName, root.profiles.length)
    var iconPath = root.iconDir + "/" + WakiModel.iconFileName(label)
    var desktopPath = root.desktopDir + "/" + label + ".desktop"

    Quickshell.execDetached(["mkdir", "-p", root.iconDir])
    Quickshell.execDetached(["curl", "-sfL", "-o", iconPath, WakiModel.iconUrl(app.iconSlug)])

    enqueueWrite(desktopPath, WakiModel.desktopFileContents({
      label: label,
      url: app.url,
      iconPath: iconPath,
      profileDirectory: directory
    }))

    var next = WakiModel.addInstall(root.state, {
      name: app.name,
      url: app.url,
      iconSlug: app.iconSlug,
      category: app.category,
      profileDirectory: directory,
      profileDisplayName: displayName,
      label: label
    })
    next = WakiModel.logEvent(next, "webapp_add", label)
    replaceState(next)
    Quickshell.execDetached(["omarchy-hook", "waki-webapp-install", app.name, app.url])
    Quickshell.execDetached(["update-desktop-database", root.desktopDir])
    return true
  }

  function installApps(apps, profile) {
    var added = 0
    for (var i = 0; i < apps.length; i++) {
      if (root.installApp(apps[i], profile)) added += 1
    }
    if (added > 0)
      root.notify("Waki", "Added " + added + " web app" + (added === 1 ? "" : "s"))
    return added
  }

  function removeLabel(label) {
    var match = null
    for (var i = 0; i < root.state.installs.length; i++) {
      if (root.state.installs[i].label === label) match = root.state.installs[i]
    }
    if (!match) return false
    Quickshell.execDetached(["rm", "-f",
      root.desktopDir + "/" + label + ".desktop",
      root.iconDir + "/" + WakiModel.iconFileName(label)])
    var next = WakiModel.removeInstallByLabel(root.state, label)
    next = WakiModel.logEvent(next, "webapp_remove", label)
    replaceState(next)
    Quickshell.execDetached(["omarchy-hook", "waki-webapp-remove", label])
    Quickshell.execDetached(["update-desktop-database", root.desktopDir])
    return true
  }

  function removeLabels(labels) {
    var removed = 0
    for (var i = 0; i < labels.length; i++) {
      if (root.removeLabel(labels[i])) removed += 1
    }
    if (removed > 0)
      root.notify("Waki", "Removed " + removed + " web app" + (removed === 1 ? "" : "s"))
    return removed
  }

  function refreshLaunchers(quiet) {
    for (var i = 0; i < root.state.installs.length; i++) {
      var install = root.state.installs[i]
      var iconPath = root.iconDir + "/" + WakiModel.iconFileName(install.label)
      enqueueWrite(root.desktopDir + "/" + install.label + ".desktop", WakiModel.desktopFileContents({
        label: install.label,
        url: install.url,
        iconPath: iconPath,
        profileDirectory: install.profileDirectory
      }))
      Quickshell.execDetached(["curl", "-sfL", "-o", iconPath, WakiModel.iconUrl(install.iconSlug)])
    }
    Quickshell.execDetached(["update-desktop-database", root.desktopDir])
    if (!quiet) root.notify("Waki", "Desktop entries refreshed")
  }

  function catalogByName(name) {
    for (var i = 0; i < root.catalog.length; i++) {
      if (root.catalog[i].name === name) return root.catalog[i]
    }
    return null
  }

  function chefPickApps() {
    var picks = WakiModel.chefPicks()
    var apps = []
    for (var i = 0; i < picks.length; i++) {
      var app = root.catalogByName(picks[i])
      if (app) apps.push(app)
    }
    return apps
  }

  function completeFirstRun(selectedNames) {
    var apps = []
    for (var i = 0; i < selectedNames.length; i++) {
      var app = root.catalogByName(selectedNames[i])
      if (app) apps.push(app)
    }
    if (apps.length > 0) root.installApps(apps, root.profiles[0])
    var next = WakiModel.parseState(WakiModel.serializeState(root.state))
    next.firstRunCompleted = true
    next = WakiModel.logEvent(next, "first_run", apps.length ? "completed" : "skipped")
    replaceState(next)
  }

  function setAliasEnabled(enabled) {
    if (enabled) {
      var applied = WakiModel.applyAliasBlock(root.bashrcText, root.aliasFilePath)
      if (applied.changed) {
        enqueueWrite(root.bashrcPath, applied.text)
        root.bashrcText = applied.text
      }
      root.aliasEnabled = true
      root.notify("Waki", "Git aliases enabled in ~/.bashrc")
    } else {
      var removed = WakiModel.removeAliasBlock(root.bashrcText)
      if (removed !== root.bashrcText) {
        enqueueWrite(root.bashrcPath, removed)
        root.bashrcText = removed
      }
      root.aliasEnabled = false
      root.notify("Waki", "Git aliases removed from ~/.bashrc")
    }
    root.changed()
  }

  function refreshAliases() {
    var stripped = WakiModel.removeAliasBlock(root.bashrcText)
    var applied = WakiModel.applyAliasBlock(stripped, root.aliasFilePath)
    enqueueWrite(root.bashrcPath, applied.text)
    root.bashrcText = applied.text
    root.aliasEnabled = true
    root.notify("Waki", "Git aliases refreshed")
    root.changed()
  }

  function installVscode() {
    vscodeProc.running = true
  }

  function updatePlugin() {
    Quickshell.execDetached(["omarchy-plugin-update", WakiModel.pluginId(), "--yes"])
    root.notify("Waki", "Updating plugin")
  }

  function uninstall() {
    var labels = []
    for (var i = 0; i < root.state.installs.length; i++)
      labels.push(root.state.installs[i].label)
    for (var j = 0; j < labels.length; j++)
      root.removeLabel(labels[j])

    var bindings = WakiModel.removeKeybindBlock(root.bindingsText)
    if (bindings !== root.bindingsText) enqueueWrite(root.bindingsPath, bindings)
    var menu = WakiModel.removeMenuEntry(root.menuText)
    if (menu !== root.menuText) enqueueWrite(root.menuPath, menu)
    if (root.aliasEnabled) root.setAliasEnabled(false)

    Quickshell.execDetached(["rm", "-f", root.statePath])
    root.state = WakiModel.emptyState()
    root.ready = true
    root.notify("Waki", "Launchers and desktop integration removed. Run omarchy plugin remove " + WakiModel.pluginId() + " to delete the plugin.")
    root.changed()
  }

  function importLegacyInstalls(raw) {
    try {
      var rows = JSON.parse(String(raw || "[]"))
      if (!Array.isArray(rows)) {
        root.migrateChecked = true
        tryFinishSetup()
        return
      }
      var next = WakiModel.parseState(WakiModel.serializeState(root.state))
      for (var i = 0; i < rows.length; i++) {
        var row = rows[i] || {}
        var directory = String(row.directory || "Default")
        var displayName = directory
        for (var p = 0; p < root.profiles.length; p++) {
          if (root.profiles[p].directory === directory)
            displayName = root.profiles[p].displayName
        }
        next = WakiModel.addInstall(next, {
          name: String(row.name || ""),
          url: String(row.url || ""),
          iconSlug: String(row.icon_slug || ""),
          category: String(row.category || ""),
          profileDirectory: directory,
          profileDisplayName: displayName,
          label: WakiModel.desktopLabel(row.name, directory, displayName, root.profiles.length)
        })
      }
      root.state = next
      persistState()
      root.refreshLaunchers(true)
    } catch (e) {
      root.lastError = "Legacy database import failed"
    }
    root.migrateChecked = true
    tryFinishSetup()
  }

  Timer {
    id: writeDelay
    interval: 20
    repeat: false
    onTriggered: {
      writer.setText(root.pendingWriteText)
      root.finishWrite()
    }
  }

  FileView {
    id: writer
    path: root.pendingWritePath
    printErrors: false
    atomicWrites: true
  }

  FileView {
    id: catalogFile
    path: root.catalogPath
    printErrors: false
    onLoaded: {
      try {
        var parsed = JSON.parse(text() || "[]")
        root.catalog = Array.isArray(parsed) ? parsed : []
      } catch (e) {
        root.catalog = []
        root.lastError = "Catalog JSON is invalid"
      }
      root.catalogLoaded = true
      root.tryFinishSetup()
    }
    onLoadFailed: {
      if (!root.catalogPath) return
      root.catalog = []
      root.lastError = "Catalog file missing"
      root.catalogLoaded = true
      root.tryFinishSetup()
    }
  }

  FileView {
    id: stateFile
    path: root.statePath
    printErrors: false
    atomicWrites: true
    onLoaded: {
      root.state = WakiModel.parseState(text())
      root.stateLoaded = true
      root.tryFinishSetup()
    }
    onLoadFailed: {
      root.state = WakiModel.emptyState()
      root.stateLoaded = true
      root.tryFinishSetup()
    }
  }

  FileView {
    id: bindingsFile
    path: root.bindingsPath
    printErrors: false
    onLoaded: {
      root.bindingsText = text()
      root.bindingsLoaded = true
      root.tryFinishSetup()
    }
    onLoadFailed: {
      root.bindingsText = ""
      root.bindingsLoaded = true
      root.tryFinishSetup()
    }
  }

  FileView {
    id: menuFile
    path: root.menuPath
    printErrors: false
    onLoaded: {
      root.menuText = text()
      root.menuLoaded = true
      root.tryFinishSetup()
    }
    onLoadFailed: {
      root.menuText = "{\n}\n"
      root.menuLoaded = true
      root.tryFinishSetup()
    }
  }

  FileView {
    id: bashrcFile
    path: root.bashrcPath
    printErrors: false
    onLoaded: {
      root.bashrcText = text()
      root.aliasEnabled = WakiModel.aliasEnabledIn(root.bashrcText)
      root.bashrcLoaded = true
      root.tryFinishSetup()
    }
    onLoadFailed: {
      root.bashrcText = ""
      root.aliasEnabled = false
      root.bashrcLoaded = true
      root.tryFinishSetup()
    }
  }

  FileView {
    id: chromiumLocalState
    path: root.chromiumLocalStatePath
    printErrors: false
    onLoaded: {
      root.profiles = WakiModel.parseChromiumProfiles(text())
      root.profilesLoaded = true
      root.tryFinishSetup()
    }
    onLoadFailed: {
      root.profiles = WakiModel.parseChromiumProfiles("")
      root.profilesLoaded = true
      root.tryFinishSetup()
    }
  }

  Process {
    id: ensureDirs
    command: ["mkdir", "-p", root.dataDir, root.desktopDir, root.iconDir]
    onExited: {
      root.dirsReady = true
      legacyDbCheck.running = true
      root.tryFinishSetup()
    }
  }

  Process {
    id: legacyDbCheck
    command: ["test", "-f", root.legacyDbPath]
    onExited: function(code) {
      if (code === 0) {
        migrateProc.running = true
        return
      }
      root.migrateChecked = true
      root.tryFinishSetup()
    }
  }

  Process {
    id: migrateProc
    command: ["sqlite3", "-json", root.legacyDbPath,
      "SELECT w.name, w.url, w.icon_slug, w.category, p.directory FROM waki_installs i JOIN waki_webapps w ON w.id = i.webapp_id JOIN waki_profiles p ON p.id = i.profile_id"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.importLegacyInstalls(text)
    }
    onExited: function(code) {
      if (code !== 0 && !root.migrateChecked) {
        root.migrateChecked = true
        root.tryFinishSetup()
      }
    }
  }

  Process {
    id: vscodeProc
    command: ["omarchy-install-vscode"]
    onExited: function(code) {
      if (code === 0)
        root.notify("Waki", "VS Code is ready. Settings: " + root.vscodeSettingsPath)
      else
        root.notify("Waki", "VS Code install failed. Is omarchy-install-vscode on PATH?")
    }
  }

  Component.onCompleted: {
    ensureDirs.running = true
  }

  onManifestChanged: {
    if (root.catalogPath) catalogFile.reload()
  }
}
