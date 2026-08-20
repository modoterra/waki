import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "WakiModel.js" as WakiModel

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  property var service: null

  property bool opened: false
  property string screen: "loading"
  property string filterText: ""
  property int selectedIndex: 0
  property bool cursorActive: false
  property var selectedSet: ({})
  property var pendingApps: []

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property int contentMargin: Style.spacing.panelPadding
  property int headerHeight: Math.max(Style.space(34), Style.font.title + Style.spacing.controlPaddingY * 2)
  property int footerHeight: Math.max(Style.space(22), Style.font.caption + Style.spacing.sm)
  property int contentSpacing: Style.spacing.md
  property int cardWidth: Math.min(Style.space(720), panel.width - Style.gapsOut * 2)
  property int cardHeight: Math.min(Style.space(560), panel.height - Style.gapsOut * 2)
  property int rowHeight: Math.max(Style.space(50), Style.font.body + Style.font.caption + Style.spacing.rowPaddingX * 2)

  readonly property bool isToggleScreen: screen === "catalog" || screen === "installed" || screen === "firstRun"
  readonly property bool isListScreen: screen === "home" || screen === "catalog" || screen === "installed" || screen === "profiles" || screen === "aliases" || screen === "firstRun"

  function open(payloadJson) {
    root.opened = true
    root.filterText = ""
    root.selectedIndex = 0
    root.cursorActive = true
    root.selectedSet = ({})
    root.pendingApps = []
    if (root.service && root.service.ready) root.enterInitialScreen()
    else root.screen = "loading"
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || WakiModel.pluginId())
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function enterInitialScreen() {
    if (root.service && root.service.state && !root.service.state.firstRunCompleted) {
      var picks = {}
      var apps = root.service.chefPickApps()
      for (var i = 0; i < apps.length; i++) picks[apps[i].name] = true
      root.selectedSet = picks
      root.goTo("firstRun")
    } else {
      root.goTo("home")
    }
  }

  function goTo(nextScreen) {
    root.screen = nextScreen
    root.filterText = ""
    root.selectedIndex = 0
    root.cursorActive = true
    if (nextScreen === "catalog" || nextScreen === "installed")
      root.selectedSet = ({})
    root.rebuildDisplay()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function goHome() {
    root.pendingApps = []
    root.goTo("home")
  }

  function headerPrompt() {
    if (root.screen === "loading") return "Loading Waki…"
    if (root.screen === "about") return "About Waki"
    if (root.screen === "uninstall") return "Uninstall Waki"
    if (root.filterText) return root.filterText
    if (root.screen === "home") return "Search Waki…"
    if (root.screen === "catalog") return "Add web apps…"
    if (root.screen === "installed") return "Remove web apps…"
    if (root.screen === "profiles") return "Choose a Chromium profile…"
    if (root.screen === "aliases") return "Git aliases"
    if (root.screen === "firstRun") return "Chef's recommendations"
    return "Waki"
  }

  function footerHint() {
    if (root.screen === "catalog" || root.screen === "firstRun")
      return "Space toggles · Enter installs · Esc backs out"
    if (root.screen === "installed")
      return "Space toggles · Enter removes · Esc backs out"
    if (root.screen === "profiles")
      return "Enter installs on this profile"
    if (root.screen === "about")
      return "Esc returns home"
    return "Type to filter · Enter selects · Esc closes"
  }

  function currentRows() {
    if (!root.service) return []
    if (root.screen === "home") return WakiModel.filterItems(WakiModel.homeActions(), root.filterText)
    if (root.screen === "aliases") return WakiModel.aliasActions(root.service.aliasEnabled)
    if (root.screen === "profiles") {
      var profiles = root.service.profiles || []
      var rows = []
      for (var p = 0; p < profiles.length; p++) {
        rows.push({
          id: profiles[p].directory,
          title: profiles[p].displayName,
          subtitle: profiles[p].directory,
          profile: profiles[p]
        })
      }
      return rows
    }
    if (root.screen === "catalog" || root.screen === "firstRun") {
      var apps = root.screen === "firstRun" ? root.service.chefPickApps() : (root.service.catalog || [])
      var catalogRows = []
      for (var i = 0; i < apps.length; i++) {
        var app = apps[i]
        catalogRows.push({
          id: app.name,
          title: app.name,
          subtitle: app.category,
          app: app,
          checked: root.selectedSet[app.name] === true
        })
      }
      return WakiModel.filterItems(catalogRows, root.filterText)
    }
    if (root.screen === "installed") {
      var installs = (root.service.state && root.service.state.installs) ? root.service.state.installs : []
      var installedRows = []
      for (var n = 0; n < installs.length; n++) {
        installedRows.push({
          id: installs[n].label,
          title: installs[n].label,
          subtitle: installs[n].profileDisplayName || installs[n].profileDirectory,
          checked: root.selectedSet[installs[n].label] === true
        })
      }
      return WakiModel.filterItems(installedRows, root.filterText)
    }
    return []
  }

  function rebuildDisplay() {
    var rows = root.currentRows()
    displayModel.clear()
    for (var i = 0; i < rows.length; i++) {
      var row = rows[i]
      displayModel.append({
        itemId: String(row.id || row.title || ""),
        title: String(row.title || ""),
        subtitle: String(row.subtitle || ""),
        checked: row.checked === true
      })
    }
    if (displayModel.count === 0) root.selectedIndex = 0
    else if (root.selectedIndex >= displayModel.count) root.selectedIndex = displayModel.count - 1
    else if (root.selectedIndex < 0) root.selectedIndex = 0
    root.cursorActive = displayModel.count > 0
    Qt.callLater(function() {
      if (resultList.visible && displayModel.count > 0)
        resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    })
  }

  function setFilter(nextFilter) {
    if (!root.isListScreen || root.screen === "profiles" || root.screen === "aliases")
      return
    root.filterText = nextFilter
    root.selectedIndex = 0
    root.cursorActive = true
    root.rebuildDisplay()
  }

  function select(delta) {
    if (displayModel.count === 0) return
    if (!root.cursorActive) {
      root.cursorActive = true
      root.selectedIndex = delta < 0 ? displayModel.count - 1 : 0
    } else {
      root.selectedIndex = (root.selectedIndex + delta + displayModel.count) % displayModel.count
    }
    resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
  }

  function selectAbsolute(index) {
    if (displayModel.count === 0) return
    var next = Math.max(0, Math.min(index, displayModel.count - 1))
    root.selectedIndex = next
    root.cursorActive = true
    resultList.positionViewAtIndex(next, ListView.Contain)
  }

  function selectedIds() {
    var ids = []
    for (var key in root.selectedSet) {
      if (root.selectedSet[key]) ids.push(key)
    }
    return ids
  }

  function toggleCurrent() {
    if (!root.isToggleScreen || !root.cursorActive || displayModel.count === 0) return
    var row = displayModel.get(root.selectedIndex)
    var next = {}
    for (var key in root.selectedSet) next[key] = root.selectedSet[key]
    if (next[row.itemId]) delete next[row.itemId]
    else next[row.itemId] = true
    root.selectedSet = next
    root.rebuildDisplay()
  }

  function appsFromNames(names) {
    var apps = []
    for (var i = 0; i < names.length; i++) {
      var app = root.service.catalogByName(names[i])
      if (app) apps.push(app)
    }
    return apps
  }

  function confirmToggles() {
    var ids = root.selectedIds()
    if (ids.length === 0 && root.screen !== "firstRun" && root.cursorActive && displayModel.count > 0)
      ids = [displayModel.get(root.selectedIndex).itemId]
    if (root.screen === "installed") {
      if (ids.length === 0) return
      root.service.removeLabels(ids)
      root.goHome()
      return
    }
    if (root.screen === "firstRun") {
      root.service.completeFirstRun(ids)
      root.goHome()
      return
    }
    if (root.screen === "catalog") {
      if (ids.length === 0) return
      var apps = root.appsFromNames(ids)
      if ((root.service.profiles || []).length > 1) {
        root.pendingApps = apps
        root.goTo("profiles")
        return
      }
      root.service.installApps(apps, (root.service.profiles || [])[0])
      root.goHome()
    }
  }

  function activateIndex(index) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    if (root.isToggleScreen) {
      root.confirmToggles()
      return
    }
    if (root.screen === "profiles") {
      var profiles = root.service.profiles || []
      var profile = profiles[index]
      root.service.installApps(root.pendingApps, profile)
      root.pendingApps = []
      root.goHome()
      return
    }
    if (root.screen === "aliases") {
      if (row.itemId === "alias-add") root.service.setAliasEnabled(true)
      else if (row.itemId === "alias-remove") root.service.setAliasEnabled(false)
      else if (row.itemId === "alias-refresh") root.service.refreshAliases()
      root.rebuildDisplay()
      return
    }
    if (root.screen === "home") {
      if (row.itemId === "add") root.goTo("catalog")
      else if (row.itemId === "remove") root.goTo("installed")
      else if (row.itemId === "refresh") root.service.refreshLaunchers()
      else if (row.itemId === "vscode") root.service.installVscode()
      else if (row.itemId === "aliases") root.goTo("aliases")
      else if (row.itemId === "update") root.service.updatePlugin()
      else if (row.itemId === "about") root.goTo("about")
      else if (row.itemId === "uninstall") root.screen = "uninstall"
    }
  }

  function handleEscape() {
    if (root.filterText) {
      root.setFilter("")
      return
    }
    if (root.screen === "firstRun") {
      root.service.completeFirstRun([])
      root.goHome()
      return
    }
    if (root.screen !== "home" && root.screen !== "loading") {
      root.goHome()
      return
    }
    root.dismiss()
  }

  function aboutLines() {
    var catalogCount = root.service && root.service.catalog ? root.service.catalog.length : 0
    var installedCount = root.service && root.service.state && root.service.state.installs
      ? root.service.state.installs.length : 0
    var version = root.manifest && root.manifest.version ? root.manifest.version : ""
    return [
      "Waki " + version,
      "Mise en place for Omarchy",
      "Catalog: " + catalogCount + " apps (" + installedCount + " installed)",
      "Toggle: " + WakiModel.defaultKeybindChord(),
      root.service && root.service.setupNote ? root.service.setupNote : "Menu row: Waki"
    ]
  }

  Connections {
    target: root.service
    function onChanged() {
      if (root.opened) root.rebuildDisplay()
    }
    function onReadyChanged() {
      if (root.opened && root.service && root.service.ready && root.screen === "loading")
        root.enterInitialScreen()
    }
  }

  ListModel { id: displayModel }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "modoterra-waki"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        z: root.screen === "uninstall" ? 20 : 0

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (root.screen === "uninstall") {
            if (uninstallConfirm.handleKey(event)) event.accepted = true
            return
          }

          if (event.key === Qt.Key_Escape) {
            root.handleEscape()
            event.accepted = true
          } else if (root.isListScreen && Util.editsFilter(event, root.filterText)
                     && root.screen !== "profiles" && root.screen !== "aliases") {
            root.setFilter(Util.editedFilter(event, root.filterText))
            event.accepted = true
          } else if (event.key === Qt.Key_Space && root.isToggleScreen) {
            root.toggleCurrent()
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.select(1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageUp) {
            root.select(-8)
            event.accepted = true
          } else if (event.key === Qt.Key_PageDown) {
            root.select(8)
            event.accepted = true
          } else if (event.key === Qt.Key_Home) {
            root.selectAbsolute(0)
            event.accepted = true
          } else if (event.key === Qt.Key_End) {
            root.selectAbsolute(displayModel.count - 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.cursorActive) root.activateIndex(root.selectedIndex)
            else if (displayModel.count > 0) root.cursorActive = true
            event.accepted = true
          } else if (root.isListScreen && root.screen !== "profiles" && root.screen !== "aliases"
                     && event.text && event.text.length === 1
                     && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.setFilter(root.filterText + event.text)
            event.accepted = true
          }
        }

        ConfirmDialog {
          id: uninstallConfirm
          anchors.fill: parent
          opened: root.screen === "uninstall"
          z: 10
          message: "Remove Waki launchers, keybind, and menu row?"
          confirmText: "Uninstall"
          background: root.background
          foreground: root.foreground
          scrim: root.scrim
          selectedBackground: root.selectedBackground
          selectedText: root.selectedText
          fontFamily: root.fontFamily
          cornerRadius: root.cornerRadius
          onCanceled: root.goHome()
          onConfirmed: {
            root.service.uninstall()
            root.dismiss()
          }
        }
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: root.contentSpacing

        Rectangle {
          width: parent.width
          height: root.headerHeight
          radius: root.cornerRadius
          color: "transparent"

          Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.headerPrompt()
            color: root.foreground
            opacity: root.filterText ? 1 : 0.58
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
            elide: Text.ElideRight
          }
        }

        Item {
          width: parent.width
          height: parent.height - root.headerHeight - root.footerHeight - root.contentSpacing * 2

          ListView {
            id: resultList
            anchors.fill: parent
            model: displayModel
            visible: root.isListScreen
            clip: true
            spacing: Style.space(4)
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
              id: row
              required property int index
              required property string itemId
              required property string title
              required property string subtitle
              required property bool checked

              readonly property bool hasCursor: root.cursorActive && index === root.selectedIndex

              width: ListView.view.width
              height: root.rowHeight
              radius: root.cornerRadius
              color: hasCursor ? root.selectedBackground : "transparent"

              Row {
                anchors.fill: parent
                anchors.leftMargin: Style.space(12)
                anchors.rightMargin: Style.space(12)
                anchors.topMargin: Style.space(8)
                anchors.bottomMargin: Style.space(8)
                spacing: Style.space(10)

                Text {
                  visible: root.isToggleScreen
                  width: visible ? Style.space(22) : 0
                  height: parent.height
                  text: row.checked ? "󰄲" : "󰄱"
                  color: row.hasCursor ? root.selectedText : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.title
                  verticalAlignment: Text.AlignVCenter
                }

                Column {
                  width: parent.width - (root.isToggleScreen ? Style.space(32) : 0)
                  height: parent.height
                  spacing: Style.space(2)

                  Text {
                    width: parent.width
                    text: row.title
                    color: row.hasCursor ? root.selectedText : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.title
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    visible: row.subtitle.length > 0
                    text: row.subtitle
                    color: row.hasCursor ? root.selectedText : root.foreground
                    opacity: 0.7
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: if (containsMouse) {
                  root.cursorActive = true
                  root.selectedIndex = index
                }
                onClicked: {
                  root.cursorActive = true
                  root.selectedIndex = index
                  if (root.isToggleScreen) root.toggleCurrent()
                  else root.activateIndex(index)
                }
              }
            }
          }

          Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(10)
            visible: root.screen === "about" || root.screen === "loading"

            Repeater {
              model: root.screen === "about" ? root.aboutLines() : ["Loading Waki…"]
              Text {
                required property string modelData
                width: parent.width
                text: modelData
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                wrapMode: Text.Wrap
              }
            }
          }

          Column {
            anchors.centerIn: parent
            spacing: Style.space(8)
            visible: root.isListScreen && displayModel.count === 0 && root.screen !== "loading"

            Text {
              text: root.filterText ? "No matches" : "Nothing here yet"
              color: root.foreground
              opacity: 0.8
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              horizontalAlignment: Text.AlignHCenter
              width: parent.width
            }
          }
        }

        Text {
          width: parent.width
          height: root.footerHeight
          text: root.footerHint()
          color: root.foreground
          opacity: 0.55
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          verticalAlignment: Text.AlignVCenter
        }
      }
    }
  }
}
