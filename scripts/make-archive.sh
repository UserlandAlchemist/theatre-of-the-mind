#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------------
# NOTE ON ASSETS
#
# Image assets (e.g. scans, maps, illustrations) in `docs/private/b1/assets/`
# are intentionally excluded from the internal archive. They are large,
# non-essential for code review, and can be regenerated or stored outside git.
#
# If you need to package assets for distribution, remove or adjust the
# `--exclude="b1/assets/**"` rule in the rsync command below.
# --------------------------------------------------------------------

MODE="${1:-public}"
ROOT="$(git rev-parse --show-toplevel)"
DIST="$ROOT/dist"

mkdir -p "$DIST"

# Stamp: YYYYMMDD-HHMM + current git short hash
STAMP="$(date +%Y%m%d-%H%M)-$(git rev-parse --short HEAD)"


PUBZIP="$DIST/theatre-of-the-mind-public-$STAMP.zip"
INTDIR="$DIST/internal"
INTZIP="$DIST/theatre-of-the-mind-internal-$STAMP.zip"

# Common rsync excludes for private overlay
RSYNC_EXCLUDES=(
  "--exclude=.git"
  "--exclude=.gitignore"
  "--exclude=.gitattributes"
  "--exclude=.DS_Store"
  "--exclude=Thumbs.db"
)

if [[ "$MODE" == "public" ]]; then
  rm -f "$PUBZIP"
  (cd "$ROOT" && git archive --format=zip -o "$PUBZIP" HEAD)
  echo "Public archive: $PUBZIP"
  exit 0
fi


if [[ "$MODE" == "internal" ]]; then
  if [[ ! -d "$ROOT/private" ]]; then
    echo "Missing $ROOT/private — add your private repo/folder there." >&2
    exit 2
  fi

  mkdir -p "$INTDIR"

  # 1) export committed public tree to staging
  (cd "$ROOT" && git archive --format=tar HEAD) | tar -x -C "$INTDIR"

  # 2) overlay private files (without VCS/junk)
  mkdir -p "$INTDIR/docs/private"
  rsync -a --delete "${RSYNC_EXCLUDES[@]}" --exclude="b1/assets/**" "$ROOT/private/" "$INTDIR/docs/private/"

  # 3) zip everything
  (cd "$INTDIR" && zip -r9 "$INTZIP" . >/dev/null)
  echo "Internal archive: $INTZIP"

  # 4) remove staging unless KEEP_STAGING is set
  if [[ -z "${KEEP_STAGING:-}" ]]; then
    rm -rf "$INTDIR"
  else
    echo "KEEP_STAGING set — left staging at: $INTDIR"
  fi

  exit 0
fi

echo "Usage: $0 [public|internal]" >&2
exit 1
