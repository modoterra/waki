# Waki

**Mise en place for [Omarchy](https://omarchy.com).**

Waki turns web apps into standalone desktop windows using Chromium's `--app` mode. A curated catalog of 120+ apps, Chromium profile isolation, and a simple TUI — that's it.

The name comes from the Japanese kitchen hierarchy: the *wakiita* (脇板) is the chef's trusted second, the one who makes sure everything is in its place before service begins.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/modoterra/waki/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/modoterra/waki.git
cd waki && bash install.sh
```

Launch with `waki` or press **SUPER SHIFT W**.

## What it does

- **Curated catalog** of 120+ web apps across 14 categories
- **Standalone windows** via Chromium `--app` mode — no browser chrome, no tabs
- **Multi-profile** — install the same app on different Chromium profiles (work vs personal)
- **Chef's recommendations** — first-run flow suggests essential apps to get started
- **Self-updating** — `waki update` pulls latest from git and seeds new catalog entries
- **Channels** — switch between `stable` and `canary`

## Commands

Run `waki` for the interactive TUI, or use commands directly:

```
waki webapp add       Add web apps from the catalog
waki webapp remove    Remove installed web apps
waki webapp refresh   Regenerate desktop entries
waki channel [name]   Switch between stable / canary
waki update           Update Waki from git
waki about            Show version and stats
waki uninstall        Completely remove Waki
waki help             Show this help
```

## Hooks

Waki fires hooks via `omarchy-hook` after installs and removals. Create executable scripts in `~/.config/omarchy/hooks/`:

| Hook | Arguments | Fired when |
|------|-----------|------------|
| `waki-webapp-install` | `$1` app name, `$2` app URL | After adding a web app |
| `waki-webapp-remove` | `$1` app label | After removing a web app |

Sample hooks are in `hooks/` and copied to `~/.config/omarchy/hooks/` during installation. Remove `.sample` to activate.

## Dependencies

- [gum](https://github.com/charmbracelet/gum) — terminal UI
- [sqlite3](https://sqlite.org/) — database
- [jq](https://jqlang.github.io/jq/) — JSON parsing
- [curl](https://curl.se/) — icon downloads
- [Chromium](https://www.chromium.org/) — browser runtime

## How it works

Waki keeps an SQLite database with the app catalog, Chromium profiles, and installs. When you add an app:

1. Picks a Chromium profile (if you have more than one)
2. Downloads the icon from [dashboard-icons](https://github.com/homarr-labs/dashboard-icons)
3. Creates a `.desktop` file in `~/.local/share/applications/`
4. The `.desktop` file calls `waki-webapp-launch <install-id>`, which queries the DB for the URL and profile, then launches Chromium in `--app` mode

Each app + profile combo gets its own desktop entry, so the same app on different profiles appears as separate launchers.

## Safety and data

Waki stores its state in a local SQLite database. The database lives at `database/waki.db` when you run from a local repo, or `~/.local/share/waki/database/waki.db` when installed via the script. The database and Chromium profiles are local-only and never leave your machine.

## Contributing

See `CONTRIBUTING.md` for setup, tests, and style guidelines.

## Security

See `SECURITY.md` for reporting instructions.

## License

[MIT](LICENSE)
