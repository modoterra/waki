# Contributing

Waki is part of the [Omarchy](https://omarchy.com) ecosystem. Contributions are welcome.

## Getting started

```bash
git clone https://github.com/modoterra/waki.git
cd waki
```

Run locally without installing:

```bash
./bin/waki
```

## Running tests

Tests use [Bats](https://github.com/bats-core/bats-core) (included as a git submodule):

```bash
git submodule update --init --recursive
./test/bats/bin/bats test/
```

## Code style

- Bash. No Python, no Node, no Ruby.
- Minimalism is key. Less code is better code.
- Functions prefixed with `waki_`.
- SQL tables prefixed with `waki_`.
- No large ASCII art or decorative comment blocks.

## Commit messages

Use Conventional Commits (e.g. `feat:`, `fix:`, `docs:`, `chore:`).

## Pull requests

- One concern per PR.
- Tests must pass.
- Keep the diff small.

## Reporting bugs

Open an [issue](https://github.com/modoterra/waki/issues).
