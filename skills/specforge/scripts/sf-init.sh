#!/usr/bin/env bash
# Scaffold a SpecForge task directory and seed the problem statement.
# Usage: sf-init.sh <task-slug>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

slug="${1:-}"
if [ -z "$slug" ]; then
  echo "usage: sf-init.sh <task-slug>" >&2
  exit 2
fi

dir="$(sf_resolve_task_dir "$slug")"
target="$dir/01-problem-statement.md"

if [ -f "$target" ]; then
  echo "sf-init: refusing to overwrite existing $target" >&2
  exit 1
fi

mkdir -p "$dir"
cp "$SCRIPT_DIR/../templates/01-problem-statement.md" "$target"
printf '%s\n' "$dir"
