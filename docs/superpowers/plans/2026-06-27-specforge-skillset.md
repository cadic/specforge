# SpecForge Skillset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert SpecForge's loose markdown prompts/templates into an agent skillset (one orchestrator + three stage skills) with deterministic bash helpers and a git-based, opencode-first distribution.

**Architecture:** A single `skills/` bundle authored once. The `specforge` orchestrator owns all deterministic logic (four bash scripts) and routes by a filesystem-derived phase. Three prose-only stage skills (`specforge-explore`, `specforge-spec`, `specforge-execute`) carry the reasoning content via thin `SKILL.md` entry points plus on-demand `references/` and `templates/`. State lives in the project's `docs/specforge/<task-slug>/` artifacts, not in any skill. Distribution is via the cross-agent `npx skills add` CLI (vercel-labs/skills), which auto-discovers the repo's `skills/` directory — with manual copy as a zero-dependency fallback. The repo ships no installer of its own.

**Tech Stack:** Bash (POSIX-leaning, macOS/BSD-compatible), `bats-core` for tests, Markdown with YAML frontmatter for skills, JSON for `.specforge.json` config.

## Global Constraints

These apply to every task. Copy values verbatim.

- `SKILL.md` files stay **thin**: frontmatter (`name:`, `description:`) + when-to-use + procedure-at-a-glance. Heavy content lives in `references/` and `templates/`, loaded only when that stage runs.
- **Scripts live only in the orchestrator** (`skills/specforge/scripts/`). The three stage skills are prose-only and never invoke scripts directly (the orchestrator and the spec self-check step are the only callers of `sf-validate.sh`).
- Bash must run on **macOS/BSD and GNU**: do not use `\b` word boundaries in `grep`; do not require `jq`.
- Default task root: `docs/specforge/<task-slug>/`. Overridable via a repo-root `.specforge.json` with key `task_root` (string).
- Phase keywords emitted by `sf-status.sh` are exactly: `setup`, `explore`, `spec`, `execute`.
- Artifact filenames are exactly: `01-problem-statement.md`, `02-solution-options.md`, `03-solution-hld.md`, `04-execution-spec.md`.
- **No project-specific conventions** in the bundle (no git branching, commit style, Jira/Bitbucket, `CD-NNN` naming).
- **No `chats/` transcript-saving** and **no `{{TASK_DIR}}` paste substitution** — the agent runs the skill directly, so the stage *is* the skill.
- **v1 scope: opencode only**, end-to-end (bundle + docs). Other agents are follow-on adapters and are out of scope here.
- The canonical bundle lives at repo root in `skills/`; tests in `tests/`. The repo ships no installer of its own — installation is the third-party `npx skills add` CLI (auto-discovers `skills/`) or manual copy. The `skills/` layout must stay at repo root so that CLI discovers it.

---

## File Structure

Created by this plan:

```
skills/
  specforge/
    SKILL.md
    scripts/
      _lib.sh                       # repo root, task-root, task-dir, placeholder helpers
      sf-init.sh                    # scaffold task dir + copy 01 template (refuses overwrite)
      sf-status.sh                  # phase detection -> routing truth
      sf-validate.sh                # placeholder/empty-cell/empty-item check
    templates/
      01-problem-statement.md
    references/
      workflow.md
  specforge-explore/
    SKILL.md
    references/
      process.md
  specforge-spec/
    SKILL.md
    references/
      process.md
    templates/
      04-execution-spec.md
  specforge-execute/
    SKILL.md
    references/
      checklist.md
tests/
  lib.bats
  sf-init.bats
  sf-validate.bats
  sf-status.bats
docs/
  writing-agents-md-for-specforge.md
README.md                           # rewritten
```

Deleted by this plan (Task 10), after their content is migrated:

```
01-problem-statement.md   prompt-solution-space.md   prompt-execution-spec.md
04-execution-spec.md      AGENTS.example.md
```

---

### Task 1: Test harness + `_lib.sh` core helpers

**Files:**
- Create: `skills/specforge/scripts/_lib.sh`
- Test: `tests/lib.bats`

**Interfaces:**
- Consumes: nothing (foundation task).
- Produces (sourced by every other script):
  - `sf_repo_root()` → prints the repo root (git toplevel, else `$PWD`).
  - `sf_task_root()` → prints `task_root` from `<repo-root>/.specforge.json`, else `docs/specforge`.
  - `sf_resolve_task_dir <slug>` → prints `<repo-root>/<task-root>/<slug>`.
  - `sf_has_placeholders <file>` → exit 0 if the file contains `<...>`-style placeholders, `TBD`, or the `❌` glyph; non-zero otherwise.

- [ ] **Step 1: Install bats-core**

Run: `brew install bats-core`
Then verify: `bats --version`
Expected: prints a version like `Bats 1.x.x`. (Fallback if Homebrew is unavailable: `git clone https://github.com/bats-core/bats-core.git /tmp/bats-core && /tmp/bats-core/install.sh "$HOME/.local" && export PATH="$HOME/.local/bin:$PATH"`.)

- [ ] **Step 2: Write the failing test**

Create `tests/lib.bats`:

```bash
#!/usr/bin/env bats

setup() {
  TESTDIR="$(mktemp -d)"
  cd "$TESTDIR"
  git init -q
  LIB="$BATS_TEST_DIRNAME/../skills/specforge/scripts/_lib.sh"
}

teardown() {
  rm -rf "$TESTDIR"
}

@test "sf_repo_root returns git toplevel" {
  run bash -c "source '$LIB'; sf_repo_root"
  [ "$status" -eq 0 ]
  [ "$output" = "$(cd "$TESTDIR" && pwd -P)" ]
}

@test "sf_task_root defaults to docs/specforge" {
  run bash -c "source '$LIB'; sf_task_root"
  [ "$status" -eq 0 ]
  [ "$output" = "docs/specforge" ]
}

@test "sf_task_root honors .specforge.json override" {
  printf '{ "task_root": "coding-assistant/tasks" }\n' > .specforge.json
  run bash -c "source '$LIB'; sf_task_root"
  [ "$status" -eq 0 ]
  [ "$output" = "coding-assistant/tasks" ]
}

@test "sf_resolve_task_dir joins root, task-root, slug" {
  run bash -c "source '$LIB'; sf_resolve_task_dir my-task"
  [ "$status" -eq 0 ]
  [ "$output" = "$(cd "$TESTDIR" && pwd -P)/docs/specforge/my-task" ]
}

@test "sf_has_placeholders detects angle placeholders" {
  printf 'name: <...>\n' > f.md
  run bash -c "source '$LIB'; sf_has_placeholders f.md"
  [ "$status" -eq 0 ]
}

@test "sf_has_placeholders passes a clean file" {
  printf 'name: real value\n' > f.md
  run bash -c "source '$LIB'; sf_has_placeholders f.md"
  [ "$status" -ne 0 ]
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `bats tests/lib.bats`
Expected: FAIL — `_lib.sh` does not exist (`No such file or directory`).

- [ ] **Step 4: Write the implementation**

Create `skills/specforge/scripts/_lib.sh`:

```bash
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
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bats tests/lib.bats`
Expected: PASS — 6 tests.

- [ ] **Step 6: Commit**

```bash
git add skills/specforge/scripts/_lib.sh tests/lib.bats
git commit -m "feat: add SpecForge _lib.sh helpers + bats harness"
```

---

### Task 2: `sf-init.sh` + problem-statement template

**Files:**
- Create: `skills/specforge/scripts/sf-init.sh`
- Create: `skills/specforge/templates/01-problem-statement.md`
- Test: `tests/sf-init.bats`

**Interfaces:**
- Consumes: `_lib.sh` (`sf_resolve_task_dir`).
- Produces: `sf-init.sh <task-slug>` — creates the task dir, copies the `01-problem-statement.md` template into it, prints the task dir path on stdout; exits non-zero (without overwriting) if `01-problem-statement.md` already exists.

- [ ] **Step 1: Write the failing test**

Create `tests/sf-init.bats`:

```bash
#!/usr/bin/env bats

setup() {
  TESTDIR="$(mktemp -d)"
  cd "$TESTDIR"
  git init -q
  INIT="$BATS_TEST_DIRNAME/../skills/specforge/scripts/sf-init.sh"
}

teardown() {
  rm -rf "$TESTDIR"
}

@test "sf-init scaffolds task dir and 01 template" {
  run bash "$INIT" my-task
  [ "$status" -eq 0 ]
  [ -f "docs/specforge/my-task/01-problem-statement.md" ]
  grep -q "Problem Statement" "docs/specforge/my-task/01-problem-statement.md"
}

@test "sf-init prints the task dir" {
  run bash "$INIT" my-task
  [ "$output" = "$(cd "$TESTDIR" && pwd -P)/docs/specforge/my-task" ]
}

@test "sf-init refuses to overwrite an existing 01" {
  bash "$INIT" my-task
  run bash "$INIT" my-task
  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing to overwrite"* ]]
}

@test "sf-init honors .specforge.json task root" {
  printf '{ "task_root": "tasks" }\n' > .specforge.json
  run bash "$INIT" my-task
  [ "$status" -eq 0 ]
  [ -f "tasks/my-task/01-problem-statement.md" ]
}

@test "sf-init errors without a slug" {
  run bash "$INIT"
  [ "$status" -ne 0 ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bats tests/sf-init.bats`
Expected: FAIL — `sf-init.sh` does not exist.

- [ ] **Step 3: Write the template**

Create `skills/specforge/templates/01-problem-statement.md`:

```markdown
# Problem Statement

> Write your problem description here. Stream of consciousness is fine — the AI will ask clarifying questions.

---

## What needs to be done?

<Describe the feature, bug fix, or change you need>

## Why?

<Context: what problem does this solve, what's the business value>

## Current state (if applicable)

<How does it work now? What's broken or missing?>

## Constraints (if known)

<Any technical limitations, deadlines, compatibility requirements>

## Additional context

<Links, screenshots, related tickets, prior discussions>
```

- [ ] **Step 4: Write the implementation**

Create `skills/specforge/scripts/sf-init.sh`:

```bash
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
```

- [ ] **Step 5: Make the script executable**

Run: `chmod +x skills/specforge/scripts/sf-init.sh`

- [ ] **Step 6: Run the test to verify it passes**

Run: `bats tests/sf-init.bats`
Expected: PASS — 5 tests.

- [ ] **Step 7: Commit**

```bash
git add skills/specforge/scripts/sf-init.sh skills/specforge/templates/01-problem-statement.md tests/sf-init.bats
git commit -m "feat: add sf-init.sh and 01 problem-statement template"
```

---

### Task 3: `sf-validate.sh`

**Files:**
- Create: `skills/specforge/scripts/sf-validate.sh`
- Test: `tests/sf-validate.bats`

**Interfaces:**
- Consumes: `_lib.sh`.
- Produces: `sf-validate.sh <file>` — exits `0` and prints `sf-validate: OK (<file>)` when clean; exits `1` and prints a categorized report when it finds any of: angle placeholders `<...>`, `TBD`, the `❌` glyph, empty table cells, empty list items. Exits `2` on usage/file errors.

- [ ] **Step 1: Write the failing test**

Create `tests/sf-validate.bats`:

```bash
#!/usr/bin/env bats

setup() {
  TESTDIR="$(mktemp -d)"
  cd "$TESTDIR"
  VALIDATE="$BATS_TEST_DIRNAME/../skills/specforge/scripts/sf-validate.sh"
}

teardown() {
  rm -rf "$TESTDIR"
}

@test "passes a fully filled document" {
  printf '# Spec\n\nProject: Widget API\n\n- invariant one\n\n| Term | Definition |\n| ---- | ---------- |\n| node | a unit |\n' > clean.md
  run bash "$VALIDATE" clean.md
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

@test "flags angle placeholders" {
  printf 'Project: <...>\n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"angle-placeholder"* ]]
}

@test "flags TBD" {
  printf 'Version: TBD\n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"TBD"* ]]
}

@test "flags the forbidden glyph" {
  printf 'Status: ❌\n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"forbidden-glyph"* ]]
}

@test "flags empty table cells" {
  printf '| a |  | c |\n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"empty-table-cell"* ]]
}

@test "flags empty list items" {
  printf 'List:\n- \n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"empty-list-item"* ]]
}

@test "does not flag a filled checkbox list" {
  printf -- '- [ ] do a thing\n- [x] done thing\n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 0 ]
}

@test "errors on a missing file" {
  run bash "$VALIDATE" nope.md
  [ "$status" -eq 2 ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bats tests/sf-validate.bats`
Expected: FAIL — `sf-validate.sh` does not exist.

- [ ] **Step 3: Write the implementation**

Create `skills/specforge/scripts/sf-validate.sh`:

```bash
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
```

- [ ] **Step 4: Make the script executable**

Run: `chmod +x skills/specforge/scripts/sf-validate.sh`

- [ ] **Step 5: Run the test to verify it passes**

Run: `bats tests/sf-validate.bats`
Expected: PASS — 8 tests.

- [ ] **Step 6: Commit**

```bash
git add skills/specforge/scripts/sf-validate.sh tests/sf-validate.bats
git commit -m "feat: add sf-validate.sh placeholder checker"
```

---

### Task 4: `sf-status.sh`

**Files:**
- Create: `skills/specforge/scripts/sf-status.sh`
- Test: `tests/sf-status.bats`

**Interfaces:**
- Consumes: `_lib.sh` (`sf_resolve_task_dir`, `sf_has_placeholders`).
- Produces: `sf-status.sh <task-slug>` — prints exactly one phase keyword on stdout: `setup` (no `01`), `explore` (`01` present, no `03`), `spec` (`03` present but no `04`, or `04` still contains placeholders), `execute` (`04` present and placeholder-free). Exits `2` without a slug.

- [ ] **Step 1: Write the failing test**

Create `tests/sf-status.bats`:

```bash
#!/usr/bin/env bats

setup() {
  TESTDIR="$(mktemp -d)"
  cd "$TESTDIR"
  git init -q
  STATUS="$BATS_TEST_DIRNAME/../skills/specforge/scripts/sf-status.sh"
  DIR="docs/specforge/t"
  mkdir -p "$DIR"
}

teardown() {
  rm -rf "$TESTDIR"
}

@test "setup when no 01 exists" {
  run bash "$STATUS" t
  [ "$output" = "setup" ]
}

@test "explore when 01 present and no 03" {
  printf 'x\n' > "$DIR/01-problem-statement.md"
  run bash "$STATUS" t
  [ "$output" = "explore" ]
}

@test "spec when 03 present and no 04" {
  printf 'x\n' > "$DIR/01-problem-statement.md"
  printf 'x\n' > "$DIR/02-solution-options.md"
  printf 'x\n' > "$DIR/03-solution-hld.md"
  run bash "$STATUS" t
  [ "$output" = "spec" ]
}

@test "spec when 04 still holds template placeholders" {
  printf 'x\n' > "$DIR/01-problem-statement.md"
  printf 'x\n' > "$DIR/03-solution-hld.md"
  printf 'Project: <...>\n' > "$DIR/04-execution-spec.md"
  run bash "$STATUS" t
  [ "$output" = "spec" ]
}

@test "execute when 04 is filled and placeholder-free" {
  printf 'x\n' > "$DIR/01-problem-statement.md"
  printf 'x\n' > "$DIR/03-solution-hld.md"
  printf 'Project: Widget API\n' > "$DIR/04-execution-spec.md"
  run bash "$STATUS" t
  [ "$output" = "execute" ]
}

@test "errors without a slug" {
  run bash "$STATUS"
  [ "$status" -eq 2 ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bats tests/sf-status.bats`
Expected: FAIL — `sf-status.sh` does not exist.

- [ ] **Step 3: Write the implementation**

Create `skills/specforge/scripts/sf-status.sh`:

```bash
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
```

- [ ] **Step 4: Make the script executable**

Run: `chmod +x skills/specforge/scripts/sf-status.sh`

- [ ] **Step 5: Run the test to verify it passes**

Run: `bats tests/sf-status.bats`
Expected: PASS — 6 tests.

- [ ] **Step 6: Run the whole suite as a regression gate**

Run: `bats tests/`
Expected: PASS — all tests across 4 files.

- [ ] **Step 7: Commit**

```bash
git add skills/specforge/scripts/sf-status.sh tests/sf-status.bats
git commit -m "feat: add sf-status.sh phase detection"
```

---

### Task 5: Orchestrator skill (`specforge`)

**Files:**
- Create: `skills/specforge/SKILL.md`
- Create: `skills/specforge/references/workflow.md`

**Interfaces:**
- Consumes: the four scripts from Tasks 1–4 (`sf-init.sh`, `sf-status.sh`, `sf-validate.sh`) and their phase keywords.
- Produces: the entry-point skill an agent loads first; routes to `specforge-explore`, `specforge-spec`, or `specforge-execute` based on the `sf-status.sh` keyword.

- [ ] **Step 1: Write `SKILL.md`**

Create `skills/specforge/SKILL.md`:

```markdown
---
name: specforge
description: Use when starting or resuming a SpecForge task — the orchestrator that scaffolds the task directory, detects the current phase, and routes to the explore, spec, or execute stage skill. Triggers on "specforge", "execution spec", "spec-driven implementation".
---

# SpecForge Orchestrator

SpecForge separates **reasoning** from **implementation** across three stages:
Explore → Spec → Execute. This skill is the entry point: it runs the
deterministic scripts and routes you to the right stage. It does not contain
stage content — it points to the stage skills.

## When to use

- The user asks to start a new SpecForge task, or to continue an existing one.
- You see a `docs/specforge/<task-slug>/` directory (or the configured task root)
  and need to know what to do next.

## Scripts (this skill owns them)

All paths are relative to this skill's `scripts/` directory. Run them from the
**project** repo root (they resolve the repo via git).

- `scripts/sf-init.sh <task-slug>` — scaffold the task dir and seed
  `01-problem-statement.md`. Refuses to overwrite an existing `01`.
- `scripts/sf-status.sh <task-slug>` — prints the current phase: `setup`,
  `explore`, `spec`, or `execute`.
- `scripts/sf-validate.sh <file>` — checks a document for unfilled placeholders.

## Procedure

1. Determine the task slug (ask the user if unknown).
2. If the task does not exist yet, run `sf-init.sh <slug>`, then help the user
   write `01-problem-statement.md`.
3. Run `sf-status.sh <slug>` and route by its output:
   - `setup` → help author `01-problem-statement.md`, then re-run status.
   - `explore` → use the **specforge-explore** skill.
   - `spec` → use the **specforge-spec** skill.
   - `execute` → use the **specforge-execute** skill.
4. After each stage completes, re-run `sf-status.sh` to confirm the next phase.

State lives in the filesystem, not in this skill. A developer can stop after any
stage and resume later — even in a different agent — and routing picks up exactly
where the `0X-*.md` files indicate.

For the full flow and the `.specforge.json` override, read
`references/workflow.md`.
```

- [ ] **Step 2: Write `references/workflow.md`**

Create `skills/specforge/references/workflow.md`:

```markdown
# SpecForge Workflow

## The three stages

1. **Explore** (`specforge-explore`) — solution-space exploration with a
   high-reasoning model. Clarify the problem, propose 2–4 approaches, compare
   trade-offs, let the user choose. Writes `02-solution-options.md` and
   `03-solution-hld.md`.
2. **Spec** (`specforge-spec`) — fill the Execution-Spec template from
   `03-solution-hld.md`. Factual, decision-only. Writes `04-execution-spec.md`
   and runs `sf-validate.sh` as a self-check.
3. **Execute** (`specforge-execute`) — implement strictly from
   `04-execution-spec.md`, following the project's own `AGENTS.md`/`CLAUDE.md`.

## Phase detection (the source of truth)

`sf-status.sh` derives the phase from which files exist:

| Files present | Phase | Keyword |
| ------------- | ----- | ------- |
| no `01` | help author the problem statement | `setup` |
| `01`, no `03` | Stage 1 | `explore` |
| `03`, no `04` (or `04` still a template copy) | Stage 2 | `spec` |
| `04` populated, placeholder-free | Stage 3 | `execute` |

## Task directory convention

- Default root: `docs/specforge/<task-slug>/`.
- Override per project with a `.specforge.json` at the repo root:

```json
{ "task_root": "coding-assistant/tasks" }
```

The scripts read `task_root` if present, else use `docs/specforge`. Only the
`task_root` key is recognized in v1.

## Artifacts per task

```
<task-root>/<task-slug>/
  01-problem-statement.md   # seeded by sf-init.sh, authored by you
  02-solution-options.md    # written by specforge-explore
  03-solution-hld.md        # written by specforge-explore (RESULT block)
  04-execution-spec.md      # written by specforge-spec
```

No `chats/` directory: the agent session is the transcript.
```

- [ ] **Step 3: Verify frontmatter and references resolve**

Run:
```bash
grep -qE '^name: specforge$' skills/specforge/SKILL.md \
  && grep -qE '^description: ' skills/specforge/SKILL.md \
  && test -f skills/specforge/references/workflow.md \
  && echo OK
```
Expected: prints `OK`.

- [ ] **Step 4: Commit**

```bash
git add skills/specforge/SKILL.md skills/specforge/references/workflow.md
git commit -m "feat: add specforge orchestrator skill"
```

---

### Task 6: Explore stage skill (`specforge-explore`)

**Files:**
- Create: `skills/specforge-explore/SKILL.md`
- Create: `skills/specforge-explore/references/process.md`

Source content: migrated from `prompt-solution-space.md`, with `{{TASK_DIR}}`
references and the `chats/` transcript step removed (per Global Constraints).

**Interfaces:**
- Consumes: `01-problem-statement.md` in the task dir; routed in by the orchestrator on phase `explore`.
- Produces: `02-solution-options.md` and `03-solution-hld.md` (containing the `=== RESULT FOR EXECUTION-SPEC ===` block) in the task dir.

- [ ] **Step 1: Write `SKILL.md`**

Create `skills/specforge-explore/SKILL.md`:

```markdown
---
name: specforge-explore
description: Use for SpecForge Stage 1 — solution-space exploration with a high-reasoning model. Clarify the problem, propose 2-4 approaches, compare trade-offs, let the user choose, then write 02-solution-options.md and 03-solution-hld.md. No code, no spec generation.
---

# SpecForge — Stage 1: Explore

You are a senior architect and technical facilitator. This is the
**solution-space exploration** stage, not implementation.

**Prohibited here:** writing code, generating the Execution-Spec, premature
optimization, pushing one solution without comparing alternatives.

**Model guidance (advisory):** run this stage on a high-reasoning model.

## Procedure at a glance

1. **Stage 1 — Clarify.** Restate the problem; state what is required vs. not
   required; ask only fact/constraint questions. End with the Stage 1
   checkpoint and wait.
2. **Stage 2 — Solution space.** Propose 2–4 fundamentally different approaches
   (no hybrids); for each: core idea, required changes, risks, pros/cons.
3. **Stage 3 — Compare.** Trade-offs against maintainability, blast radius,
   regression risk, long-term cost. Recommend, but let the user choose. End
   with the choice checkpoint and wait.
4. **Stage 4 — Prepare for spec.** After the user picks an option, write the
   two output files and emit the RESULT block.

Stop between stages and wait for the user — this is a dialogue, not a monologue.

For the full stage prompts, checkpoint strings, and exact output formats, read
`references/process.md`.
```

- [ ] **Step 2: Write `references/process.md`**

Create `skills/specforge-explore/references/process.md`:

```markdown
# Stage 1: Solution Space Exploration — Full Process

> For thinking / high-reasoning models. The stage *before* generating the
> Execution-Spec.

## Working files

Work inside the current task directory (the orchestrator resolved it). These
files are involved:

- `01-problem-statement.md` (input)
- `02-solution-options.md` (output)
- `03-solution-hld.md` (output)

If the problem statement is missing or empty — stop and ask.

## Model role

You are a senior architect and technical facilitator. We are at the
solution-space exploration stage, not implementation.

**Prohibited:** writing code; generating the Execution-Spec; premature
optimization; pushing a solution without comparing alternatives.

Reasoning, hypotheses, and comparisons are allowed and required.

## Non-functional priorities

maintainability · backward compatibility · minimal changes · performance ·
implementation speed · testability

## Dialogue instructions

Work strictly through the stages below. Do not skip stages. Stop between stages
and wait for the user's response.

### Hard checkpoints

- After Stage 1, end your message with:

```
=== WAITING FOR ANSWERS (STAGE 1) ===
```

- After Stages 2–3, end your message with:

```
=== YOUR CHOICE (STAGES 2–3) ===
Select an option: 1 / 2 / 3 / 4 (or suggest revisions to options/criteria)
```

If information is insufficient, return to Stage 1 and ask more questions instead
of proceeding.

## Stage 1. Problem clarification

- Restate the problem in your own words.
- Explicitly identify what is definitely required and what is not required.
- Ask clarifying questions (only about missing facts/constraints).
- Do not propose solutions yet. Output only: restatement, scope boundaries,
  questions. End with the Stage 1 checkpoint.

## Stage 2. Solution space

Propose 2–4 fundamentally different approaches. For each: core idea (brief);
required changes (modules/files/contracts); main risks; pros and cons.

Prohibited: proposing hybrids; leaving options without evaluation.

## Stage 3. Comparison and trade-offs

Compare options against maintainability, blast radius, regression risk, and
long-term cost of changes. State explicitly what we gain and what we pay. You
may give a recommendation, but do not make the final choice — frame it as a user
action ("select option N" or "clarify criteria"). End with the choice
checkpoint.

## Stage 4. Preparation for specification

After the user selects an option, produce the summary: selected approach (1–2
paragraphs); key invariants; hard constraints; boundaries of responsibility.

Do not generate the Execution-Spec. Do not write code.

### Final output (RESULT block)

```
=== RESULT FOR EXECUTION-SPEC ===

**Task:** (mandatory problem statement in 1–3 sentences)

**Selected Approach:** (brief, structured description of the chosen solution)

**Key Invariants:**
- ...

**Hard Constraints:**
- ...

**Boundaries of Responsibility:**
- ...
```

Formatting: markdown; one sentence per line; one statement per list item.

### File writing (Stage 4 only, after the user selects an option)

1. Write all reviewed options (final form from Stages 2–3) to
   `02-solution-options.md`.
2. Write the RESULT block (no extra comments) to `03-solution-hld.md`.
3. Output the RESULT block to chat unchanged.

This block is the input to Stage 2 (specforge-spec).
```

- [ ] **Step 3: Verify frontmatter and references resolve**

Run:
```bash
grep -qE '^name: specforge-explore$' skills/specforge-explore/SKILL.md \
  && grep -qE '^description: ' skills/specforge-explore/SKILL.md \
  && test -f skills/specforge-explore/references/process.md \
  && ! grep -q 'TASK_DIR' skills/specforge-explore/references/process.md \
  && ! grep -q 'chats/' skills/specforge-explore/references/process.md \
  && echo OK
```
Expected: prints `OK` (confirms no leftover `{{TASK_DIR}}` and no `chats/`).

- [ ] **Step 4: Commit**

```bash
git add skills/specforge-explore
git commit -m "feat: add specforge-explore stage skill"
```

---

### Task 7: Spec stage skill (`specforge-spec`)

**Files:**
- Create: `skills/specforge-spec/SKILL.md`
- Create: `skills/specforge-spec/references/process.md`
- Create: `skills/specforge-spec/templates/04-execution-spec.md`

Source content: `references/process.md` migrated from `prompt-execution-spec.md`
(transcript step removed, `{{TASK_DIR}}` removed, `sf-validate.sh` self-check
added); `templates/04-execution-spec.md` migrated from the root
`04-execution-spec.md` with the `AGENTS.md` references generalized to
"the project's `AGENTS.md`/`CLAUDE.md`".

**Interfaces:**
- Consumes: `03-solution-hld.md` (the RESULT block); routed in on phase `spec`.
- Produces: `04-execution-spec.md` in the task dir, validated clean by
  `skills/specforge/scripts/sf-validate.sh`.

- [ ] **Step 1: Write `SKILL.md`**

Create `skills/specforge-spec/SKILL.md`:

```markdown
---
name: specforge-spec
description: Use for SpecForge Stage 2 — generate the Execution-Spec. Consume 03-solution-hld.md, fill the 04 template with final decisions only (no alternatives), then self-check with sf-validate.sh before handoff to the executor.
---

# SpecForge — Stage 2: Spec

You are a senior architect filling out the Execution-Spec template for one task.
This document is consumed by a coding model **without interpretation** — any
ambiguity causes wrong implementation.

**Rules:** write strictly factually; no reasoning or alternatives; final
decisions only; leave no ambiguities; if in doubt, choose one solution and
document it.

## Procedure at a glance

1. Read `03-solution-hld.md` (must contain the `=== RESULT FOR EXECUTION-SPEC
   ===` block) and the template `templates/04-execution-spec.md`.
2. If facts are missing, ask clarifying questions and stop — end with
   `=== WAITING FOR ANSWERS (EXECUTION-SPEC) ===`.
3. Fill **all** sections of the template. Use imperative wording (must,
   prohibited, only, always/never). Add no new sections. Leave no placeholders.
4. Write the result to `04-execution-spec.md` in the task dir.
5. **Self-check** — run the validator:

   `bash <orchestrator>/scripts/sf-validate.sh <task-dir>/04-execution-spec.md`

   It must print `sf-validate: OK`. If it reports placeholders, empty cells, or
   empty list items, fix them and re-run until clean.
6. Output the same final document to chat with no additions.

For the full generate-spec prompt, read `references/process.md`.
```

- [ ] **Step 2: Write `references/process.md`**

Create `skills/specforge-spec/references/process.md`:

```markdown
# Stage 2: Generate Execution-Spec — Full Process

You are a senior architect. Your task is to fill out the Execution-Spec template
for a specific task.

Requirements: write strictly factually; avoid reasoning and alternatives;
document final decisions only; leave no ambiguities; if in doubt, choose one
solution and document it.

This document will be used by a coding model as a specification. Any ambiguity
will lead to incorrect implementation.

## Working files

Work inside the current task directory (the orchestrator resolved it).

- Input: `03-solution-hld.md` (must contain the `=== RESULT FOR EXECUTION-SPEC
  ===` block).
- Template: `templates/04-execution-spec.md` (in this skill) — fill it and write
  the result to `04-execution-spec.md` in the task dir.

If the input block is missing / contradictory / insufficient — ask questions and
stop.

## Instructions

0. Read `03-solution-hld.md` and the `04` template.
1. If facts are missing to fill any section, ask clarifying questions (without
   proposing solutions) and end your message with:

```
=== WAITING FOR ANSWERS (EXECUTION-SPEC) ===
```

2. After receiving answers (or if information is sufficient), produce the final
   document and apply these rules:

- Fill all sections of the Execution-Spec.
- Do not add new sections.
- Do not leave placeholders.
- Use imperative formulations: "must", "prohibited", "only", "always / never".
- Self-check: the text must not contain `❌`, `<...>`, `TBD`, empty list items,
  or empty table cells.
- Self-check: the task aligns with actual code and can be implemented.
- Self-check: the task is internally consistent (non-contradictory).
- Write the result to `04-execution-spec.md` in the task dir as a single
  document, ready for handoff to the executor.
- Run the validator and confirm it prints `sf-validate: OK`:

```
bash <orchestrator>/scripts/sf-validate.sh <task-dir>/04-execution-spec.md
```

- Output the exact same text to chat, with no additions.

**Output:** fully populated Execution-Spec document.
```

- [ ] **Step 3: Write `templates/04-execution-spec.md`**

Create `skills/specforge-spec/templates/04-execution-spec.md`:

```markdown
# Execution-Spec

> Template designed for the pipeline: **high-reasoning model → solution formulation → coding model → implementation**

This document is written by a thinking model and used by the executor *without interpretation*.

---

## 0. Document Purpose

**Document Origin:**
This Execution-Spec is generated **based on the output of the Solution Space Exploration stage**, specifically the block:

```
=== RESULT FOR EXECUTION-SPEC ===
<brief, structured description of the chosen solution>
```

This block is considered **input data** for populating all sections below.

**Goal:**
Implement the functionality *strictly in accordance* with this document.

**Prohibited:**

- any deviations from requirements;
- improvements and optimizations "at your discretion";
- rethinking the architecture;
- adding undocumented requirements.

**Executor's Role:**

- treat this document as the *single source of truth*;
- if a requirement is not described — assume it **does not exist**;
- in case of ambiguity — **ask a question**, do not guess;
- follow coding standards defined in the project's `AGENTS.md`/`CLAUDE.md`.

---

## 1. Context and Constraints

### 1.1 System Context

- Project/Application: <...>
- Tech stack: <...>
- Runtime/Platform version: <...>
- Framework version: <...>
- Module/Subsystem: <...>
- Integration points (if any): <...>

### 1.2 Hard Constraints

- <constraint 1>
- <constraint 2>
- <constraint 3>

> This section is mandatory. Constraints take priority over all other requirements.

---

## 2. Terms and Definitions

| Term | Definition |
| ---- | ---------- |
| <term> | <definition> |
| <term> | <definition> |

If a term is **not defined here**, it is **not used** in the implementation.

---

## 3. Required Behavior (Behavior Specification)

### 3.1 Main Scenario

Step by step, no explanations:

1. <step 1>
2. <step 2>
3. <step 3>

### 3.2 Alternative Scenarios and Errors

- If <condition> → <expected behavior>
- If <condition> → <error/status/code/message>

---

## 4. Rules and Invariants

<Format: statement, not explanation>

- <invariant 1>
- <invariant 2>
- <invariant 3>

---

## 5. Interfaces and Contracts

### 5.1 API Endpoints (if applicable)

**Endpoint:** `<METHOD> <route>`

Request:
```json
{
  "<field>": "<type and description>"
}
```

Response:
```json
{
  "<field>": "<type and description>"
}
```

Authentication/Authorization: <requirements>

### 5.2 Extension Points (if applicable)

Events, hooks, plugins, middleware, or other extension mechanisms:

| Extension Point | Type | Parameters | Description |
| --------------- | ---- | ---------- | ----------- |
| <name> | event / hook / middleware | <params> | <when it fires, what it does> |

### 5.3 External Dependencies (if applicable)

| Dependency | Purpose | Version Constraint |
| ---------- | ------- | ------------------ |
| <package/service> | <why needed> | <version> |

---

## 6. Data and Persistence

### 6.1 Storage Type

- [ ] In-memory
- [ ] File system
- [ ] Key-value store
- [ ] Relational database
- [ ] Document database
- [ ] Cache layer
- [ ] External service
- [ ] Other: <...>

### 6.2 Schema / Data Structures (if applicable)

```
<schema definition in appropriate format: SQL, JSON Schema, TypeScript interface, etc.>
```

- Migration strategy: <...>
- Cleanup/retention policy: <...>

### 6.3 Keys and Identifiers

| Key/Field | Storage | Type | Description |
| --------- | ------- | ---- | ----------- |
| <key_name> | <where stored> | <type> | <what it stores> |

---

## 7. Task Boundaries (Out of Scope)

Explicitly prohibited:

- <what not to do 1>
- <what not to do 2>
- <what not to do 3>

---

## 8. Implementation Requirements

### 8.1 What Must Be Done

#### Add

- <what to add 1>
- <what to add 2>

#### Modify

- <what to modify 1>
- <what to modify 2>

#### Delete (if applicable)

- <what to delete 1>

### 8.2 What **Not** To Do

- <prohibited action 1>
- <prohibited action 2>
- <prohibited action 3>

### 8.3 Coding Standards

Follow the coding standards defined in the project's `AGENTS.md`/`CLAUDE.md`. Key points:

- <standard 1 relevant to this task>
- <standard 2 relevant to this task>

---

## 9. Testing

### 9.1 Unit Tests

- Test location: <path>
- Run command: <command>
- Verify:
  - <what to verify 1>
  - <what to verify 2>

### 9.2 Integration Tests (if applicable)

- Test location: <path>
- Run command: <command>
- Verify:
  - <what to verify 1>
  - <what to verify 2>

### 9.3 E2E Tests (if applicable)

- Test location: <path>
- Run command: <command>
- Scenarios to cover:
  - <scenario 1>
  - <scenario 2>

---

## 10. Definition of Done

- [ ] Behavior from section 3 is implemented
- [ ] Constraints from section 1.2 are satisfied
- [ ] All tests from section 9 pass
- [ ] Linter/formatter passes with no errors
- [ ] No unfilled placeholders in the document (`<...>`, `TBD`)

---

## 11. Decision Rationale (Read-Only)

> Section for preserving the reasoning behind decisions.\
> **Executor is prohibited from using this section for changes.**

- <why this approach was chosen>
- <what alternatives were considered and why rejected>
- <what key trade-offs were made>
```

- [ ] **Step 4: Verify the template still validates as a template (placeholders expected) and references resolve**

Run:
```bash
grep -qE '^name: specforge-spec$' skills/specforge-spec/SKILL.md \
  && test -f skills/specforge-spec/references/process.md \
  && test -f skills/specforge-spec/templates/04-execution-spec.md \
  && ! grep -q 'TASK_DIR' skills/specforge-spec/references/process.md \
  && echo OK
bash skills/specforge/scripts/sf-validate.sh skills/specforge-spec/templates/04-execution-spec.md; echo "exit=$?"
```
Expected: first command prints `OK`; the validator prints a FAIL report and `exit=1` — correct, because the **template** is supposed to contain `<...>` placeholders (it is a blank template, not a finished spec).

- [ ] **Step 5: Commit**

```bash
git add skills/specforge-spec
git commit -m "feat: add specforge-spec stage skill + 04 template"
```

---

### Task 8: Execute stage skill (`specforge-execute`)

**Files:**
- Create: `skills/specforge-execute/SKILL.md`
- Create: `skills/specforge-execute/references/checklist.md`

Source content: the methodology-level executor rules (formerly section 0 of the
spec template / the deleted `AGENTS.example.md` preamble) move **inline** here.

**Interfaces:**
- Consumes: `04-execution-spec.md`; routed in on phase `execute`.
- Produces: the implementation (in the project), verified against
  `references/checklist.md`.

- [ ] **Step 1: Write `SKILL.md`**

Create `skills/specforge-execute/SKILL.md`:

```markdown
---
name: specforge-execute
description: Use for SpecForge Stage 3 — implement strictly from 04-execution-spec.md. Treat the spec as the single source of truth; if it is not in the spec it does not exist; ask on ambiguity instead of guessing; follow the project's own AGENTS.md/CLAUDE.md for code style.
---

# SpecForge — Stage 3: Execute

Implement the task strictly from `04-execution-spec.md`. This stage runs on a
coding model.

## Executor discipline (methodology-level — always applies)

- The Execution-Spec is the **single source of truth**.
- If a requirement is **not in the spec, it does not exist** — do not add
  undocumented behavior, improvements, or optimizations "at your discretion".
- Do not rethink the architecture or deviate from the spec.
- On any ambiguity or contradiction — **ask a question, do not guess**.
- Section 11 (Decision Rationale) is **read-only**: never use it to justify a
  change.
- For code style, naming, security, and testing conventions, follow the
  **project's own** `AGENTS.md`/`CLAUDE.md`. SpecForge does not own that file.

## Procedure

1. Read `04-execution-spec.md` end to end before writing any code.
2. Read the project's `AGENTS.md`/`CLAUDE.md` (if present) for code standards.
3. Implement sections 3, 4, 5, 6, and 8 exactly as written.
4. Respect section 7 (Out of Scope) and section 8.2 (What Not To Do).
5. Write the tests described in section 9.
6. Before claiming completion, run the Definition-of-Done self-verify in
   `references/checklist.md`.

If the spec is internally contradictory or missing facts you need, stop and ask
the user — return to Stage 2 if the spec itself must change.
```

- [ ] **Step 2: Write `references/checklist.md`**

Create `skills/specforge-execute/references/checklist.md`:

```markdown
# Stage 3: Definition of Done / Self-Verify

Confirm every item with evidence before reporting the task complete. Do not
assert success without running the relevant command.

- [ ] Behavior from spec section 3 (main + alternative scenarios) is implemented.
- [ ] Rules and invariants from section 4 hold.
- [ ] Interfaces and contracts from section 5 match the spec exactly.
- [ ] Data/persistence from section 6 is implemented as specified.
- [ ] Hard constraints from section 1.2 are satisfied.
- [ ] Nothing from section 7 (Out of Scope) or 8.2 (What Not To Do) was added.
- [ ] Tests from section 9 are written and pass — paste the run output.
- [ ] Linter/formatter passes with no errors — paste the run output.
- [ ] No undocumented behavior, files, or dependencies were introduced.

If any item fails, fix it and re-verify. Report failures honestly with the
command output; do not claim completion on unverified items.
```

- [ ] **Step 3: Verify frontmatter and references resolve**

Run:
```bash
grep -qE '^name: specforge-execute$' skills/specforge-execute/SKILL.md \
  && grep -qE '^description: ' skills/specforge-execute/SKILL.md \
  && test -f skills/specforge-execute/references/checklist.md \
  && echo OK
```
Expected: prints `OK`.

- [ ] **Step 4: Commit**

```bash
git add skills/specforge-execute
git commit -m "feat: add specforge-execute stage skill with inline executor rules"
```

---

### Task 9: README rewrite, migration cleanup, AGENTS note

**Files:**
- Modify: `README.md` (full rewrite)
- Create: `docs/writing-agents-md-for-specforge.md`
- Delete: `01-problem-statement.md`, `04-execution-spec.md`,
  `prompt-solution-space.md`, `prompt-execution-spec.md`, `AGENTS.example.md`

**Interfaces:**
- Consumes: the finished `skills/` bundle.
- Produces: user-facing docs and a clean repo root (old loose prompts/templates
  removed now that their content lives in the bundle).

- [ ] **Step 1: Confirm the old root files were migrated (sanity check before deleting)**

Run:
```bash
test -f skills/specforge/templates/01-problem-statement.md \
  && test -f skills/specforge-spec/templates/04-execution-spec.md \
  && test -f skills/specforge-explore/references/process.md \
  && test -f skills/specforge-spec/references/process.md \
  && echo "migrated-OK"
```
Expected: prints `migrated-OK`. Do not proceed to deletion unless it does.

- [ ] **Step 2: Delete the migrated root files**

Run:
```bash
git rm 01-problem-statement.md 04-execution-spec.md \
  prompt-solution-space.md prompt-execution-spec.md AGENTS.example.md
```
Expected: git stages 5 deletions.

- [ ] **Step 3: Write the AGENTS.md note**

Create `docs/writing-agents-md-for-specforge.md`:

```markdown
# Writing your AGENTS.md for SpecForge execution

SpecForge does not ship an `AGENTS.md` template. Most projects already have an
`AGENTS.md` or `CLAUDE.md`, and SpecForge should not try to own that file.

During **Stage 3 (execute)**, the `specforge-execute` skill follows your
project's own `AGENTS.md`/`CLAUDE.md` for code style, naming, security, and
testing conventions. The methodology-level executor rules (single source of
truth; not-in-spec means it-does-not-exist; ask on ambiguity) live inside the
skill — you do not need to repeat them.

Put stack-specific standards in your project's `AGENTS.md`, for example:

- File and class naming conventions.
- Security patterns (input sanitization, output escaping, prepared statements).
- Formatting rules and the auto-fix command.
- Test framework, test locations, and the run command.
- Dependency-management rules (e.g. add deps via CLI, not by hand).
- Recurring mistakes to avoid — add a rule each time the AI repeats one.

The Execution-Spec references these standards in section 8.3; keep the spec
pointing at your `AGENTS.md` rather than duplicating its contents.
```

- [ ] **Step 4: Rewrite `README.md`**

Replace the entire contents of `README.md` with:

```markdown
# SpecForge

A spec-driven methodology for AI-assisted development, packaged as an **agent
skillset**. SpecForge separates **reasoning** from **implementation** across
three stages:

1. **Explore** — solution-space exploration with a high-reasoning model.
2. **Spec** — generate an unambiguous Execution-Spec.
3. **Execute** — implement strictly from the spec with a coding model.

The methodology is authored once and runs in any `SKILL.md`-compatible coding
agent.

## How it is structured

```
skills/
  specforge/          # orchestrator: scaffolding, phase detection, routing (bash)
  specforge-explore/  # Stage 1 (prose, high-reasoning)
  specforge-spec/     # Stage 2 (prose, high-reasoning) + 04 template
  specforge-execute/  # Stage 3 (prose, coding model)
```

- **Skills live in the agent** (its global skills directory).
- **Artifacts live in your project**: `docs/specforge/<task-slug>/` (override the
  root with a `.specforge.json` at your repo root: `{ "task_root": "..." }`).

State lives in the filesystem. `skills/specforge/scripts/sf-status.sh` derives
the current phase from which `0X-*.md` files exist, so you can stop after any
stage and resume later — even in a different agent.

## Install

SpecForge installs with one command via the cross-agent
[`skills` CLI](https://github.com/vercel-labs/skills) — no clone, no config. It
auto-discovers the `skills/` directory in this repo, so there is nothing to set
up on our side.

**opencode (v1):**

```bash
npx skills add <owner>/specforge -a opencode -g --skill '*'
```

`-a opencode` targets opencode, `-g` installs globally (into
`~/.config/opencode/skills/`), and `--skill '*'` installs all four SpecForge
skills. Replace `<owner>/specforge` with this repo's GitHub path.

The same command works for any of the 70+ agents the CLI supports — swap the
agent name:

```bash
npx skills add <owner>/specforge -a claude-code -g --skill '*'
npx skills add <owner>/specforge -a codex -g --skill '*'
```

For Cursor (no global skills dir), install into the project instead (drop `-g`):

```bash
npx skills add <owner>/specforge -a cursor --skill '*'
```

**Manual fallback (zero dependencies):** copy the four `skills/specforge*`
directories into your agent's global skills directory by hand, e.g.
`cp -r skills/specforge* ~/.config/opencode/skills/`.

## Using it

1. In your agent, invoke the **specforge** skill and give it a task slug.
2. It scaffolds `docs/specforge/<slug>/01-problem-statement.md` — fill it in.
3. It detects the phase and routes you through Explore → Spec → Execute,
   stopping at checkpoints for your input.

## Coding standards

SpecForge does not ship an `AGENTS.md`. Stage 3 follows your project's own
`AGENTS.md`/`CLAUDE.md`. See
[docs/writing-agents-md-for-specforge.md](docs/writing-agents-md-for-specforge.md).

## Development

Bash helpers are tested with [bats-core](https://github.com/bats-core/bats-core):

```bash
brew install bats-core
bats tests/
```

## License

MIT
```

- [ ] **Step 5: Verify the build is consistent**

Run:
```bash
bats tests/ \
  && ! test -e prompt-solution-space.md \
  && ! test -e AGENTS.example.md \
  && grep -q 'agent skillset' README.md \
  && grep -q 'npx skills add' README.md \
  && ! grep -q 'install.sh' README.md \
  && echo "ALL-OK"
```
Expected: all tests pass and it prints `ALL-OK`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "docs: rewrite README for skillset, migrate AGENTS note, remove legacy prompts"
```

---

## Notes on resolved open items (spec §9)

- **opencode adapter shape** → no adapter to build: the third-party cross-agent `npx skills add <owner>/specforge -a opencode -g --skill '*'` CLI (vercel-labs/skills) auto-discovers the `skills/` dir; manual-copy fallback documented in README. Consistent with the spec's "no installer we maintain / no gatekeeper" intent.
- **`.specforge.json` schema** → single recognized key `task_root` (string); default `docs/specforge`.
- **`sf-validate.sh` invocation** → surfaced as a Stage-2 self-check the model runs (documented in `specforge-spec`); also available to the orchestrator.
- **README** → native install command per agent + manual-copy + Cursor `.cursor/skills/` fallback (Task 9).
