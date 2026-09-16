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

## Procedure

1. Read `03-solution-hld.md` (must contain the `=== RESULT FOR EXECUTION-SPEC
   ===` block) and the template `templates/04-execution-spec.md`.
2. If the input block is missing, contradictory, or facts are missing to fill
   any section, ask clarifying questions (without proposing solutions) and stop
   — end your message with `=== WAITING FOR ANSWERS (EXECUTION-SPEC) ===`.
3. Fill **all** sections of the template. Use imperative wording (must,
   prohibited, only, always/never). Add no new sections. Leave no placeholders.
   Self-check: the text must not contain `❌`, `<...>`, `TBD`, empty list items,
   or empty table cells; the task aligns with the actual code and is internally
   consistent.
4. Write the result to `04-execution-spec.md` in the task dir as a single
   document, ready for handoff to the executor.
5. **Self-check** — run the validator:

   `bash <orchestrator>/scripts/sf-validate.sh <task-dir>/04-execution-spec.md`

   It must print `sf-validate: OK`. If it reports placeholders, empty cells, or
   empty list items, fix them and re-run until clean.
6. In chat, report only the written file path and the validator result. Do not
   paste the document into chat.
