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
