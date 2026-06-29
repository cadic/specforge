#!/usr/bin/env bash
# Check a SpecForge document for unfilled placeholders and empty fields.
# Usage: sf-validate.sh <file>
# Exit 0 = clean, 1 = problems found, 2 = usage/file error.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

target="${1:-}"
if [ -z "$target" ]; then
  echo "usage: sf-validate.sh <file>" >&2
  exit 2
fi
if [ ! -f "$target" ]; then
  echo "sf-validate: file not found: $target" >&2
  exit 2
fi

found=0
report() {
  local label="$1" pattern="$2" hits
  hits="$(grep -nE "$pattern" "$target" || true)"
  if [ -n "$hits" ]; then
    found=1
    echo "[$label]"
    echo "$hits"
  fi
}

report "angle-placeholder" '<[^>]+>'
report "TBD" 'TBD'
report "forbidden-glyph" '❌'
report "empty-table-cell" '\|[[:space:]]*\|'
report "empty-list-item" '^[[:space:]]*[-*][[:space:]]*$'

if [ "$found" -ne 0 ]; then
  echo "sf-validate: FAIL ($target)" >&2
  exit 1
fi
echo "sf-validate: OK ($target)"
