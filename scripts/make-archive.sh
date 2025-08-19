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

# --- Config ---------------------------------------------------------------
# Where to place the finished archives (outside the repo).
DIST_DIR="${HOME}/dist/"

# Files/folders always excluded from the archive
COMMON_EXCLUDES=(
  ".git/"
  ".gitignore"
  ".DS_Store"
  ".gitattributes"
  "node_modules/"
  "__pycache__/"
  ".venv/"
  "venv/"
  ".mypy_cache/"
  ".pytest_cache/"
  ".ruff_cache/"
  ".idea/"
  ".vscode/"
  "dist/"                    # in case one exists in-repo
  "build/"
  # Never archive the db or logs (security/bloat risk)
  "evennia-server/server/evennia.db3"
  "evennia-server/server/evennia.db3-journal"
  "evennia-server/server/evennia.db3-wal"
  "evennia-server/server/evennia.db3-shm"
  "evennia-server/server/logs/"

  # Static files collected at runtime (optional to include with a flag)
  "evennia-server/web/static/"

  "docs/**/assets/"
  "docs/private/**/assets/"
  "private/**/assets/"
)

# Extra excludes that apply to *public* archives.
PUBLIC_ONLY_EXCLUDES=(
  "docs/private/"
  "*.secrets.*"
  "*secret*"
)

# -------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage: $(basename "$0") [--internal|--public] [--with-static]

Creates a timestamped zip archive of the repository contents:
  - Output location: ${DIST_DIR}
  - Default mode: --internal
  - Adds git-log.txt (last 10 commits) at the root of the zip.
  - By default excludes runtime DB, logs, and collected static files.

Options:
  --internal       Create an internal archive (default).
  --public         Create a public archive (also excludes docs/private and secrets).
  --with-static    Include collected static files (evennia-server/web/static).
  --with-assets   Include all 'assets/' directories under docs/ and docs/private/

Examples:
  $(basename "$0")                 # internal by default, no static
  $(basename "$0") --public        # public archive
  $(basename "$0") --with-static   # internal archive including static
  $(basename "$0") --public --with-static
EOF
}

MODE="internal"
INCLUDE_STATIC=false
INCLUDE_ASSETS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage; exit 0
      ;;
    --public)
      MODE="public"
      ;;
    --internal)
      MODE="internal"
      ;;
    --with-static)
      INCLUDE_STATIC=true
      ;;
      --with-assets)
      INCLUDE_ASSETS=true
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
  shift
done

# Resolve repo root and sanity checks
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

mkdir -p "${DIST_DIR}"

TS="$(date +"%Y%m%d-%H%M")"
SHA="$(git -C "${REPO_ROOT}" rev-parse --short=7 HEAD)"
ARCHIVE_NAME="theatre-of-the-mind-${MODE}-${TS}-${SHA}.zip"
ARCHIVE_PATH="${DIST_DIR}/${ARCHIVE_NAME}"

# Stage files in a temp dir so we can add git-log.txt at the root
STAGE_DIR="$(mktemp -d)"
cleanup() { rm -rf "${STAGE_DIR}"; }
trap cleanup EXIT

# Build rsync exclude list file
EXCLUDE_FILE="${STAGE_DIR}/.archive_excludes.txt"
: > "${EXCLUDE_FILE}"
for pat in "${COMMON_EXCLUDES[@]}"; do
  # Skip static files if --with-static flag was given
  if [[ "$INCLUDE_STATIC" == true && "$pat" == "evennia-server/web/static/" ]]; then
    continue
  fi
  if [[ "$INCLUDE_ASSETS" == true && "$pat" == "docs/**/assets/" ]] || \
   [[ "$INCLUDE_ASSETS" == true && "$pat" == "docs/private/**/assets/" ]] || \
   [[ "$INCLUDE_ASSETS" == true && "$pat" == "private/**/assets/" ]]; then
  continue
fi
  printf "%s\n" "${pat}" >> "${EXCLUDE_FILE}"
done

if [[ "${MODE}" == "public" ]]; then
  for pat in "${PUBLIC_ONLY_EXCLUDES[@]}"; do
    printf "%s\n" "${pat}" >> "${EXCLUDE_FILE}"
  done
fi

# Copy repo contents to staging (respecting excludes)
rsync -a \
  --delete \
  --exclude-from="${EXCLUDE_FILE}" \
  "${REPO_ROOT}/" "${STAGE_DIR}/"

# Add short git log (last 10 entries) at the root of the zip
git -C "${REPO_ROOT}" log --oneline -n 10 > "${STAGE_DIR}/git-log.txt"

# Create the zip from the staging directory
(
  cd "${STAGE_DIR}"
  # -r recursive, -q quiet-ish, -X strip extra file attrs, -y store symlinks as the link
  zip -r -X -y "${ARCHIVE_PATH}" .
)

echo "✅ Created archive: ${ARCHIVE_PATH}"
