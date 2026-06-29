#!/usr/bin/env bash
# Derive the current SpecForge phase from which 0X files exist.
# Usage: sf-status.sh <task-slug>
# Prints exactly one of: setup | explore | spec | execute
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

slug="${1:-}"
if [ -z "$slug" ]; then
  echo "usage: sf-status.sh <task-slug>" >&2
  exit 2
fi

dir="$(sf_resolve_task_dir "$slug")"
has() { [ -f "$dir/$1" ]; }

if ! has "01-problem-statement.md"; then
  echo "setup"
elif ! has "03-solution-hld.md"; then
  echo "explore"
elif ! has "04-execution-spec.md"; then
  echo "spec"
elif sf_has_placeholders "$dir/04-execution-spec.md"; then
  echo "spec"
else
  echo "execute"
fi
