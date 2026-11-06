#!/usr/bin/env bash
#
# Build a deck without pdm.
#
#   ./build.sh                     # kcd_vietnam.deck.md -> dist/kcd_vietnam.html
#   ./build.sh --pdf               # ... and dist/kcd_vietnam.pdf
#   ./build.sh snow_corp_cncf.deck.md   # another deck
#   ./build.sh --pdf hami_intro.deck.md
#
# Requires: uv. On macOS also `brew install pango` (WeasyPrint needs it).
#
# Why not `make` or `pdm run slidr`? Two reasons:
#   1. slidr imports WeasyPrint at CLI import time, so even an HTML-only build
#      needs libpango present.
#   2. The `slidr` console script runs under a python whose DYLD_* environment
#      macOS strips, so it cannot find libpango even when it is installed.
#      `python -m slidr` through uv keeps the variable, so it works.

set -euo pipefail
cd "$(dirname "$0")"

deck=""
flags=()
for arg in "$@"; do
  case "$arg" in
    -*) flags+=("$arg") ;;
    *)  deck="$arg" ;;
  esac
done
deck="${deck:-kcd_vietnam.deck.md}"

exec env \
  DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:-/opt/homebrew/lib}" \
  UV_HTTP_TIMEOUT="${UV_HTTP_TIMEOUT:-300}" \
  uv run --no-project --with-editable ./slidr --with seaborn --with pillow \
  python -m slidr ${flags[@]+"${flags[@]}"} "$deck"
