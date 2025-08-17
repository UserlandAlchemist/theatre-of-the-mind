#!/usr/bin/env bash
set -euo pipefail
uv run mkdocs serve -f mkdocs.private.yml -a 127.0.0.1:8001
