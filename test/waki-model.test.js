const { describe, it } = require("node:test")
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const WakiModel = require("../plugin/WakiModel.js")

const catalogPath = path.join(__dirname, "../plugin/catalog.json")

describe("catalog.json", () => {
  const catalog = JSON.parse(fs.readFileSync(catalogPath, "utf8"))

  it("has 120 uniquely named apps with url, iconSlug, and category", () => {
    assert.equal(catalog.length, 120)
    const names = catalog.map((app) => app.name)
    assert.equal(new Set(names).size, 120)
    for (const app of catalog) {
      assert.equal(typeof app.name, "string")
      assert.ok(app.name.length > 0)
      assert.match(app.url, /^https?:\/\//)
      assert.ok(app.iconSlug.length > 0)
      assert.ok(app.category.length > 0)
    }
  })

  it("includes every chef pick", () => {
    const names = new Set(catalog.map((app) => app.name))
    for (const pick of WakiModel.CHEF_PICKS) {
      assert.ok(names.has(pick), `missing chef pick ${pick}`)
    }
  })
})

describe("state", () => {
  it("parseState returns empty state for blank or invalid JSON", () => {
    assert.deepEqual(WakiModel.parseState(""), WakiModel.emptyState())
    assert.deepEqual(WakiModel.parseState("{"), WakiModel.emptyState())
    assert.equal(WakiModel.emptyState().version, 1)
    assert.equal(WakiModel.emptyState().firstRunCompleted, false)
    assert.deepEqual(WakiModel.emptyState().installs, [])
  })

  it("round-trips a populated state", () => {
    const state = WakiModel.emptyState()
    const next = WakiModel.addInstall(state, {
      name: "Gmail",
      url: "https://mail.google.com",
      iconSlug: "gmail",
      category: "email",
      profileDirectory: "Default",
      profileDisplayName: "Person 1",
      label: "Gmail"
    })
    const parsed = WakiModel.parseState(WakiModel.serializeState(next))
    assert.equal(parsed.installs.length, 1)
    assert.equal(parsed.installs[0].name, "Gmail")
    assert.equal(WakiModel.isInstalled(parsed, "Gmail", "Default"), true)
    assert.equal(WakiModel.isInstalled(parsed, "Gmail", "Profile 1"), false)
  })

  it("addInstall is a no-op when the app and profile are already installed", () => {
    const app = {
      name: "Gmail",
      url: "https://mail.google.com",
      iconSlug: "gmail",
      category: "email",
      profileDirectory: "Default",
      profileDisplayName: "Person 1",
      label: "Gmail"
    }
    const once = WakiModel.addInstall(WakiModel.emptyState(), app)
    const twice = WakiModel.addInstall(once, app)
    assert.equal(twice.installs.length, 1)
  })

  it("removeInstallByLabel drops only that desktop label", () => {
    let state = WakiModel.emptyState()
    state = WakiModel.addInstall(state, {
      name: "Gmail",
      url: "https://mail.google.com",
      iconSlug: "gmail",
      category: "email",
      profileDirectory: "Default",
      profileDisplayName: "Personal",
      label: "Gmail (Personal)"
    })
    state = WakiModel.addInstall(state, {
      name: "Gmail",
      url: "https://mail.google.com",
      iconSlug: "gmail",
      category: "email",
      profileDirectory: "Profile 1",
      profileDisplayName: "Work",
      label: "Gmail (Work)"
    })
    const next = WakiModel.removeInstallByLabel(state, "Gmail (Work)")
    assert.equal(next.installs.length, 1)
    assert.equal(next.installs[0].label, "Gmail (Personal)")
  })
})

describe("desktopLabel", () => {
  it("uses the bare app name for Default when it is the only profile", () => {
    assert.equal(WakiModel.desktopLabel("Gmail", "Default", "Person 1", 1), "Gmail")
  })

  it("appends the profile display name when more than one profile exists", () => {
    assert.equal(WakiModel.desktopLabel("Gmail", "Default", "Personal", 2), "Gmail (Personal)")
    assert.equal(WakiModel.desktopLabel("Gmail", "Profile 1", "Work", 2), "Gmail (Work)")
  })
})

describe("filterItems", () => {
  const items = [
    { title: "Add web apps", subtitle: "Install from the catalog" },
    { title: "Gmail", subtitle: "email" },
    { title: "GitHub", subtitle: "development" }
  ]

  it("returns all items for an empty query", () => {
    assert.equal(WakiModel.filterItems(items, "").length, 3)
  })

  it("matches title or subtitle case-insensitively", () => {
    const found = WakiModel.filterItems(items, "MAIL")
    assert.equal(found.length, 1)
    assert.equal(found[0].title, "Gmail")
    assert.equal(WakiModel.filterItems(items, "catalog").length, 1)
  })
})

describe("chromium profiles", () => {
  it("always includes Default and reads names from Local State", () => {
    const raw = JSON.stringify({
      profile: {
        info_cache: {
          Default: { name: "Personal" },
          "Profile 1": { name: "Work" }
        }
      }
    })
    const profiles = WakiModel.parseChromiumProfiles(raw)
    assert.deepEqual(profiles, [
      { directory: "Default", displayName: "Personal" },
      { directory: "Profile 1", displayName: "Work" }
    ])
  })

  it("falls back to Default when Local State is missing", () => {
    assert.deepEqual(WakiModel.parseChromiumProfiles(""), [
      { directory: "Default", displayName: "Default" }
    ])
  })
})

describe("desktop file", () => {
  it("quotes profile directories that contain spaces", () => {
    const body = WakiModel.desktopFileContents({
      label: "Gmail (Work)",
      url: "https://mail.google.com",
      iconPath: "/tmp/gmail.png",
      profileDirectory: "Profile 1"
    })
    assert.match(body, /^Name=Gmail \(Work\)$/m)
    assert.match(body, /Exec=omarchy-launch-webapp https:\/\/mail\.google\.com --profile-directory="Profile 1"/)
    assert.match(body, /^Icon=\/tmp\/gmail\.png$/m)
  })

  it("builds the dashboard-icons CDN URL from a slug", () => {
    assert.equal(
      WakiModel.iconUrl("gmail"),
      "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/gmail.png"
    )
  })
})

describe("marked blocks", () => {
  const start = WakiModel.KEYBIND_BLOCK_START
  const end = WakiModel.KEYBIND_BLOCK_END
  const chord = "SUPER + SHIFT + ALT + W"

  it("rewrites a marked keybind block when the plugin id changes", () => {
    const oldBlock = [
      "keep me",
      "-- >>> waki keybind >>>",
      'o.bind("SUPER + SHIFT + ALT + W", "Waki", "omarchy-shell shell toggle modoterra.waki")',
      "-- <<< waki keybind <<<",
      ""
    ].join("\n")
    const result = WakiModel.applyKeybindBlock(oldBlock, chord)
    assert.equal(result.changed, true)
    assert.match(result.text, /toggle com\.mdtrr\.waki/)
    assert.doesNotMatch(result.text, /toggle modoterra\.waki/)
    assert.match(result.text, /keep me/)
  })

  it("inserts a keybind block and is idempotent", () => {
    const once = WakiModel.applyKeybindBlock("hl = {}\n", chord)
    const twice = WakiModel.applyKeybindBlock(once.text, chord)
    assert.equal(once.changed, true)
    assert.equal(twice.changed, false)
    assert.equal((twice.text.match(/o\.bind/g) || []).length, 1)
    assert.match(twice.text, new RegExp(start.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")))
    assert.match(twice.text, /omarchy-shell shell toggle com\.mdtrr\.waki/)
  })

  it("skips the keybind when the chord is already used outside the block", () => {
    const existing = `o.bind("${chord}", "Other", "true")\n`
    const result = WakiModel.applyKeybindBlock(existing, chord)
    assert.equal(result.changed, false)
    assert.equal(result.skipped, "taken")
    assert.equal(result.text, existing)
  })

  it("removes only the marked keybind block", () => {
    const applied = WakiModel.applyKeybindBlock("keep me\n", chord)
    const removed = WakiModel.removeKeybindBlock(applied.text)
    assert.match(removed, /keep me/)
    assert.doesNotMatch(removed, /com\.mdtrr\.waki/)
  })

  it("inserts a waki menu row after the opening brace", () => {
    const source = "{\n  // comment\n}\n"
    const once = WakiModel.applyMenuEntry(source)
    const twice = WakiModel.applyMenuEntry(once.text)
    assert.equal(once.changed, true)
    assert.equal(twice.changed, false)
    assert.match(once.text, /"waki"\s*:/)
    assert.match(once.text, /omarchy-shell shell toggle com\.mdtrr\.waki/)
  })

  it("rewrites the menu action when the plugin id changes", () => {
    const stale = '{\n  "waki": {"icon":"x","label":"Waki","action":"omarchy-shell shell toggle modoterra.waki"}\n}\n'
    const result = WakiModel.applyMenuEntry(stale)
    assert.equal(result.changed, true)
    assert.match(result.text, /toggle com\.mdtrr\.waki/)
    assert.doesNotMatch(result.text, /toggle modoterra\.waki/)
  })

  it("writes a bashrc alias block that sources the given file", () => {
    const aliasFile = "/plugins/com.mdtrr.waki/aliases/git.sh"
    const once = WakiModel.applyAliasBlock("export PATH=1\n", aliasFile)
    const twice = WakiModel.applyAliasBlock(once.text, aliasFile)
    assert.equal(once.changed, true)
    assert.equal(twice.changed, false)
    assert.match(once.text, /export PATH=1/)
    assert.match(once.text, /source "\/plugins\/com\.mdtrr\.waki\/aliases\/git\.sh"/)
    const removed = WakiModel.removeAliasBlock(once.text)
    assert.match(removed, /export PATH=1/)
    assert.doesNotMatch(removed, /waki git aliases/)
  })
})
