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
