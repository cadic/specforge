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
