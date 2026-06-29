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
