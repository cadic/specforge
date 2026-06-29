#!/usr/bin/env bash
# Shared helpers for SpecForge orchestrator scripts.
# Sourced by sf-init.sh, sf-status.sh, sf-validate.sh.

# Print the repository root. Uses git when available, else the current dir.
sf_repo_root() {
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
  else
    pwd -P
  fi
}

# Print the task root, relative to repo root. Reads .specforge.json if present.
sf_task_root() {
  local config
  config="$(sf_repo_root)/.specforge.json"
  if [ -f "$config" ]; then
    local value
    value="$(grep -oE '"task_root"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" \
      | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/')"
    if [ -n "$value" ]; then
      printf '%s\n' "$value"
      return 0
    fi
  fi
  printf '%s\n' "docs/specforge"
}

# Print the absolute task directory for a slug.
sf_resolve_task_dir() {
  local slug="$1"
  printf '%s/%s/%s\n' "$(sf_repo_root)" "$(sf_task_root)" "$slug"
}

# Exit 0 if the file still contains unfilled placeholders / forbidden markers.
sf_has_placeholders() {
  local file="$1"
  grep -qE '<[^>]+>|TBD|❌' "$file"
}
