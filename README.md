# Waki

**Mise en place for [Omarchy](https://omarchy.com).**

Waki is an Omarchy shell plugin. It turns a curated catalog of 120+ web apps into standalone desktop windows through Chromium `--app` mode, with optional profile isolation.

The name comes from the Japanese kitchen hierarchy: the *wakiita* (脇板) is the chef's trusted second, the one who makes sure everything is in its place before service begins.

## Install

```bash
omarchy plugin add https://github.com/modoterra/waki.git --enable
```

That clones the plugin into `~/.config/omarchy/plugins/modoterra.waki/`, validates `manifest.json`, and enables it. On first enable the service writes a Super+Shift+Alt+W keybind (if that chord is free) and a **Waki** row in the Omarchy menu.

Open Waki with Super+Shift+Alt+W, the Omarchy menu, or:

```bash
omarchy-shell shell toggle modoterra.waki
```

Update with `omarchy plugin update modoterra.waki`. Remove desktop integration from Waki's Uninstall action, then `omarchy plugin remove modoterra.waki`.

## What it does

- **Curated catalog** of 120+ web apps across 14 categories
- **Standalone windows** via `omarchy-launch-webapp`
- **Multi-profile** Chromium installs (work vs personal)
- **Chef's recommendations** on first open
- **Git aliases** (optional Oh My Zsh-style bundle in `~/.bashrc`)
- **VS Code** install through `omarchy-install-vscode`

Super+Shift+W stays Omawrite. Waki uses Super+Shift+Alt+W.

## Hooks

Waki fires hooks via `omarchy-hook` after installs and removals. Create executable scripts in `~/.config/omarchy/hooks/` (sample files are copied on enable; drop `.sample` to activate):

| Hook | Arguments | Fired when |
|------|-----------|------------|
| `waki-webapp-install` | `$1` app name, `$2` app URL | After adding a web app |
| `waki-webapp-remove` | `$1` app label | After removing a web app |

## How it works

State lives in `~/.local/share/waki/state.json`. The catalog ships as `plugin/catalog.json` inside the plugin. Adding an app downloads an icon, writes a `.desktop` file under `~/.local/share/applications/`, and launches later through `omarchy-launch-webapp`.

The overlay and setup service run inside `omarchy-shell`. Plugins are unsandboxed user code. Read the checkout before you enable it.

## Safety and data

The state file, desktop entries, and Chromium profiles stay on your machine. `omarchy plugin update` pulls git into the plugin directory and does not overwrite `state.json`.

## Contributing

See `CONTRIBUTING.md` for setup, tests, and style guidelines.

## Security

See `SECURITY.md` for reporting instructions.

## License

[MIT](LICENSE)
