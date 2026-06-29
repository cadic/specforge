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
