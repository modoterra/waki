# Contributing

Waki is an [Omarchy](https://omarchy.com) shell plugin. Contributions are welcome.

## Getting started

```bash
git clone https://github.com/modoterra/waki.git
cd waki
omarchy plugin validate .
```

For a live session, copy or clone this repo into `~/.config/omarchy/plugins/com.mdtrr.waki/` (not a symlink; `omarchy plugin add` rejects symlinks), then:

```bash
omarchy-shell shell rescanPlugins
omarchy plugin enable com.mdtrr.waki
omarchy-shell shell toggle com.mdtrr.waki
```

## Running tests

```bash
node --test test/waki-model.test.js
omarchy plugin validate .
```

`omarchy plugin validate` walks the tree for symlinks. Run it on a checkout that matches `omarchy plugin add` (no extra linked files).

## Code style

- Plugin UI and setup: QML + JavaScript under `plugin/`, following first-party Omarchy overlay patterns (`open` / `close` / `opened`, `qs.Commons`, `qs.Ui`).
- Catalog data: `plugin/catalog.json`.
- Domain helpers belong in `plugin/WakiModel.js` so `node --test` can cover them.
- Optional git aliases remain a bash source file at `aliases/git.sh` because that is what `~/.bashrc` sources.
- Functions in `WakiModel.js` stay small and named in full.

## Commit messages

Use Conventional Commits (e.g. `feat:`, `fix:`, `docs:`, `chore:`).

## Pull requests

- One concern per PR.
- Tests must pass.
- Keep the diff small.

## Reporting bugs

Open an [issue](https://github.com/modoterra/waki/issues).
