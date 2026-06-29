# SpecForge Skillset — Design

**Date:** 2026-06-26
**Status:** Approved design, pre-implementation

## 1. Purpose

Convert SpecForge from a set of loose markdown prompts/templates (with a manual,
copy-paste workflow) into an **agent skillset**: a set of progressive-disclosure
skills that any SKILL.md-compatible coding agent can discover and run, plus a
lightweight, git-based distribution model.

SpecForge's methodology is unchanged — a three-stage pipeline that separates
**reasoning** from **implementation**:

1. **Explore** — solution-space exploration with a high-reasoning model.
2. **Spec** — generate an unambiguous Execution-Spec.
3. **Execute** — implement strictly from the spec with a coding model.

## 2. Goals and non-goals

### Goals
- Author the methodology **once** and run it across multiple agents (opencode
  first; Claude Code, Codex, Cursor, and others later).
- Use **progressive disclosure**: thin `SKILL.md` entry points; heavy content in
  reference/template files loaded only when a stage runs.
- Offload **deterministic work** (scaffolding, phase detection, spec validation)
  to bash scripts; reserve the model for reasoning.
- Keep artifacts in the project repo; keep the methodology engine in the agent.
- Zero-friction, no-gatekeeper distribution.

### Non-goals
- No heavyweight `npx`/installer framework (obsolete given native SKILL.md
  discovery).
- No project-specific conventions baked in (git branching, commit style,
  Bitbucket/Jira PR creation, ticket naming). Those belong to each project.
- No model auto-switching (most agents can't; we advise instead).

## 3. Architecture overview

### 3.1 Hybrid placement
- **Skills live in the agent** (global skills dir, e.g.
  `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/`).
- **Artifacts live in the project** (the per-task `0X-*.md` files).

Cursor is the exception: it has no global skills dir, so for Cursor the skills
are committed into the repo at `.cursor/skills/`. That fits the hybrid model —
for Cursor, "agent skills" and "project repo" are the same place.

### 3.2 Canonical bundle + thin per-agent adapters
`SKILL.md` is a cross-tool open standard (Claude Code, Codex, Cursor, Gemini,
opencode, …). The skill **content** is authored once; only the **entry point /
manifest** differs per agent. This mirrors the proven structure of
`obra/superpowers`:

- `skills/` — the methodology, authored once, shared verbatim.
- `.<agent>-plugin/` (or equivalent) — a small manifest per agent; a couple of
  agents (opencode, Pi) also want a tiny JS/TS shim because they load plugins as
  code.

Adding an agent later = drop in one more manifest. No change to the methodology.

### 3.3 Distribution
- A single public GitHub repo **is** the distribution.
- Each agent installs via its **own native command** pointing at the repo
  (e.g. `opencode-marketplace install <repo>`, `/plugin install …`,
  `pi install git:…`).
- Optional `marketplace.json` (Claude Code) / community-list entries (opencode,
  Codex) for discovery — all self-hosted in the repo, **no third-party approval
  gate** anywhere.
- Manual copy of the skill folders into the agent's skills dir is the
  zero-dependency fallback, documented in the README.

**v1 scope:** opencode only, end-to-end (bundle + one adapter + docs). Other
agents are cheap follow-on adapters.

## 4. Skill structure

Orchestrator + 3 stage skills. The orchestrator owns all deterministic logic and
routing; the three stage skills are prose-only reasoning skills.

```
skills/
  specforge/                    # orchestrator: deterministic + routing
    SKILL.md                    # thin: when-to-use, runs scripts, routes by phase
    scripts/
      _lib.sh                   # repo root, task-dir + .specforge.json resolution
      sf-init.sh                # scaffold task dir + copy 01 template (refuses overwrite)
      sf-status.sh              # phase detection from which 0X files exist -> routing truth
      sf-validate.sh            # regex check: <...>, TBD, the forbidden-marker glyph, empty cells/items
    templates/
      01-problem-statement.md
    references/
      workflow.md               # full flow + .specforge.json override spec

  specforge-explore/            # Stage 1 (prose only, high-reasoning)
    SKILL.md                    # staged procedure overview + checkpoints
    references/
      process.md                # full dialogue prompt; 02/03 output formats

  specforge-spec/               # Stage 2 (prose only, high-reasoning)
    SKILL.md                    # procedure + self-check summary
    references/
      process.md                # full generate-spec prompt
    templates/
      04-execution-spec.md

  specforge-execute/            # Stage 3 (prose only, coding model)
    SKILL.md                    # executor-discipline rules (inline) + DoD
    references/
      checklist.md              # Definition-of-Done / self-verify
```

### 4.1 Responsibilities

**`specforge` (orchestrator)** — entry point. Resolves the task dir, runs the
deterministic scripts, detects the current phase, and routes to the right stage
skill. Owns cross-stage flow and checkpoints. Does **not** duplicate stage
content — it points to the stage skills. Stage skills never touch scripts.

**`specforge-explore` (Stage 1)** — solution-space exploration: clarify →
propose 2–4 approaches → compare trade-offs → user chooses. Writes
`02-solution-options.md` and `03-solution-hld.md` (the
`=== RESULT FOR EXECUTION-SPEC ===` block). High-reasoning work; no code, no
spec generation.

**`specforge-spec` (Stage 2)** — consumes `03`, fills the spec template, writes
`04-execution-spec.md`. Factual, decision-only, no open alternatives. Runs a
self-check (via `sf-validate.sh`) for placeholders before handoff.

**`specforge-execute` (Stage 3)** — implements strictly from `04`. Carries the
**methodology-level executor-discipline rules** inline (single source of truth;
if it is not in the spec it does not exist; ask on ambiguity, do not guess).
Follows the **project's own** `AGENTS.md`/`CLAUDE.md` for code style.

### 4.2 State model
State lives in the **filesystem**, not in any skill. `sf-status.sh` derives the
phase deterministically from which `0X-*.md` files exist:

- no `01` → setup (help author the problem statement)
- `01`, no `03` → Stage 1 (explore)
- `02` + `03`, no `04` → Stage 2 (spec)
- `04` (populated, not the template copy) → Stage 3 (execute)

A dev can stop after any stage and resume later — even in a different agent — and
the orchestrator picks up exactly where the files indicate.

### 4.3 Task directory convention
- Default root: `docs/specforge/<task-slug>/`.
- Override per project via a `.specforge.json` at the repo root (e.g. a project
  that already uses `coding-assistant/CD-NNN-slug/`).
- The orchestrator reads `.specforge.json` if present, else uses the default.

## 5. Progressive disclosure + determinism

Two complementary mechanisms:

- **Progressive disclosure (reasoning):** `SKILL.md` files stay thin (name,
  description, when-to-use, the procedure at a glance). Heavy content — full
  staged prompts, the big spec template — lives in `references/` and
  `templates/`, loaded only when that stage runs. Mirrors superpowers'
  `brainstorming/` (thin `SKILL.md` + on-demand reference files).
- **Deterministic scripts (mechanics):** scaffolding, phase detection, and spec
  validation are bash, not LLM guesswork. The `SKILL.md` says *when* and *why*;
  the scripts do the reliable *what*. Adapted from the chamfr fork's
  `specforge-*.sh` helpers, generalized (chamfr-specifics removed).

## 6. Migration from the current repo

| Current file | New home |
|---|---|
| `prompt-solution-space.md` | `specforge-explore/references/process.md` |
| `prompt-execution-spec.md` | `specforge-spec/references/process.md` |
| `04-execution-spec.md` | `specforge-spec/templates/04-execution-spec.md` |
| `01-problem-statement.md` | `specforge/templates/01-problem-statement.md` |
| `AGENTS.example.md` | **Removed as a shipped template** (see below) |

### AGENTS.example.md
- Deleted as a copy-template. Most projects already have an `AGENTS.md`/
  `CLAUDE.md`; SpecForge should not try to own that file.
- The few **methodology-level** executor rules (single source of truth;
  not-in-spec = does-not-exist; ask on ambiguity) move **inline into
  `specforge-execute/SKILL.md`**.
- Stack-specific coding standards remain the project's responsibility.
- An optional short note, "writing your AGENTS.md for SpecForge execution," can
  live in repo `docs/` (not installed as a skill).

## 7. Deliberately excluded (YAGNI / project-specific)

Kept out of the generic skillset; a project may add its own overlay:

- Git branching and commit conventions.
- Bitbucket/Jira PR creation, `CD-NNN` ticket naming.
- `{{TASK_DIR}}` paste-into-new-chat substitution (obsolete: the agent runs the
  skill directly rather than pasting a prompt into a fresh chat, so the stage
  *is* the skill).
- `chats/` transcript-saving (a manual-flow artifact; the agent session *is* the
  transcript now).

## 8. Decisions and rationale

- **Hybrid placement** (skills in agent, artifacts in repo) — confirmed with the
  user; `AGENTS.md` as a shipped example is obsolete.
- **opencode-first, deep** — prove the canonical-bundle + one-adapter loop
  end-to-end before adding cheap follow-on adapters.
- **`SKILL.md` open standard** collapses the per-agent "adapter" to install
  location + a small manifest; verified across opencode, Claude Code, Codex,
  Cursor.
- **No installer, no approval gate** — verified: all four ecosystems use
  git-based, self-hosted distribution; "marketplaces" are self-hosted manifests
  or community lists, not reviewed app stores.
- **Orchestrator + 3 sub-skills**, scripts in the orchestrator only — preserves
  independent stage skills while giving the deterministic scripts a single home
  and avoiding fragile cross-skill references.
- **Model guidance kept advisory** — most agents can't self-switch models.

## 9. Open items for the implementation plan

- Exact opencode adapter shape (JS shim vs documented copy into
  `~/.config/opencode/skills/`).
- Final `.specforge.json` schema (at minimum: task-root override).
- Whether `sf-validate.sh` is invoked by the orchestrator or surfaced as a
  stage-2 step the model calls.
- README content: install paths per agent + manual-copy fallback.
