#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-public}"
ROOT="$(git rev-parse --show-toplevel)"
DIST="$ROOT/dist"

mkdir -p "$DIST"

# Stamp: YYYYMMDD-HHMM + current git short hash
STAMP="$(date +%Y%m%d-%H%M)-$(git rev-parse --short HEAD)"

PUBZIP="$DIST/theatre-of-the-mind-public-$STAMP.zip"
INTDIR="$DIST/internal"
INTZIP="$DIST/theatre-of-the-mind-internal-$STAMP.zip"

if [[ "$MODE" == "public" ]]; then
  rm -f "$PUBZIP"
  (cd "$ROOT" && git archive --format=zip -o "$PUBZIP" HEAD)
  echo "Public archive: $PUBZIP"
  exit 0
fi

if [[ "$MODE" == "internal" ]]; then
  # sanity check: require the local private repo/folder
  if [[ ! -d "$ROOT/private" ]]; then
    echo "Missing $ROOT/private — add your private repo/folder there." >&2
    exit 2
  fi

  rm -rf "$INTDIR"
  mkdir -p "$INTDIR"

  # 1) extract the current committed public tree into a staging dir
  (cd "$ROOT" && git archive --format=tar HEAD) | tar -x -C "$INTDIR"

  # 2) layer private files into a clear path in the staging dir
  mkdir -p "$INTDIR/docs/private"
  rsync -a --delete "$ROOT/private/" "$INTDIR/docs/private/"

  # 3) zip the combined bundle
  (cd "$INTDIR" && zip -r9 "$INTZIP" . >/dev/null)
  echo "Internal archive: $INTZIP"
  exit 0
fi

# Clean dist/INTDIR on each run
rm -rf "$INTDIR"

echo "Usage: $0 [public|internal]" >&2
exit 1
