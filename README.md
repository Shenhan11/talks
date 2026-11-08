# talks-slide-decks

Talk slide decks built with [decktile](https://github.com/decktile/decktile).

## Setup

```bash
uv tool install 'decktile[plot]'    # or: pipx install 'decktile[plot]'
```

`make` runs `make check` first, which installs or upgrades decktile when needed.

## Build

```bash
make                    # build all decks
make watch-<deck>       # watch and rebuild
```

## Decks

- `snow_corp_cncf.deck.md` - Shared GPU Scheduling (KubeCon Japan 2026)
- `hami_intro.deck.md` - HAMi Introduction and Features - Shared GPU Scheduling & Proactive Autoscaling (KubeCon Japan 2026)

## Assets

Images per deck live in `assets/<deck>/`. Symlinked into `dist/` on build.
