#!/usr/bin/env bash
set -euo pipefail

# serve-docs.sh — unified MkDocs dev server
# - Defaults to private docs
# - Can switch to public via --public
# - Lets you pick host/port and pass --strict

HOST="127.0.0.1"
PORT="8000"
MODE="private"
STRICT=0
BROWSE=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--private|--public] [--host HOST] [--port PORT] [--strict] [--browse] [--help]

Options:
  --private          Serve private docs (default)
  --public           Serve public docs
  --host HOST        Host to bind (default: ${HOST})
  --port PORT        Port to bind (default: ${PORT})
  --strict           Run mkdocs in strict mode
  --browse           Open the site in your browser
  -h, --help         Show this help

Examples:
  $(basename "$0")                       # private on 127.0.0.1:8000
  $(basename "$0") --public --port 8001  # public on port 8001
EOF
}

# --- Parse args ------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --private) MODE="private"; shift ;;
    --public)  MODE="public";  shift ;;
    --host)    HOST="${2:-}"; shift 2 ;;
    --port)    PORT="${2:-}"; shift 2 ;;
    --strict)  STRICT=1; shift ;;
    --browse)  BROWSE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

# --- Pick mkdocs runner (prefer uv if present) -----------------------------
run_mkdocs() {
  if command -v uv >/dev/null 2>&1; then
    uv run mkdocs "$@"
  else
    mkdocs "$@"
  fi
}

# --- Resolve config files --------------------------------------------------
# Public config candidates (first match wins)
PUBLIC_CFGS=(
  "mkdocs.yml"
  "mkdocs.yaml"
)

# Private config candidates (first match wins)
PRIVATE_CFGS=(
  "mkdocs.private.yml"
  "mkdocs.private.yaml"
  "mkdocs-internal.yml"
  "mkdocs-internal.yaml"
)

pick_cfg() {
  local -n list_ref=$1
  for cfg in "${list_ref[@]}"; do
    if [[ -f "$cfg" ]]; then
      echo "$cfg"; return 0
    fi
  done
  return 1
}

CFG_FILE=""
if [[ "$MODE" == "public" ]]; then
  if ! CFG_FILE="$(pick_cfg PUBLIC_CFGS)"; then
    echo "Error: No public mkdocs config found. Tried: ${PUBLIC_CFGS[*]}" >&2
    exit 1
  fi
else
  if ! CFG_FILE="$(pick_cfg PRIVATE_CFGS)"; then
    echo "Error: No private mkdocs config found. Tried: ${PRIVATE_CFGS[*]}" >&2
    exit 1
  fi
fi

# --- Build args ------------------------------------------------------------
ARGS=(serve -f "$CFG_FILE" -a "${HOST}:${PORT}")
if [[ $STRICT -eq 1 ]]; then
  ARGS+=(--strict)
fi

echo "→ Serving ${MODE} docs using ${CFG_FILE} at http://${HOST}:${PORT}"
if [[ $STRICT -eq 1 ]]; then
  echo "  (strict mode ON)"
fi

# Optionally open browser (best-effort, non-fatal)
open_browser() {
  url="http://${HOST}:${PORT}"
  if [[ $BROWSE -eq 1 ]]; then
    if command -v xdg-open >/dev/null 2>&1; then xdg-open "$url" >/dev/null 2>&1 || true
    elif command -v open >/dev/null 2>&1; then open "$url" >/dev/null 2>&1 || true
    fi
  fi
}

# Launch and open browser shortly after
( sleep 1; open_browser ) & disown
run_mkdocs "${ARGS[@]}"
