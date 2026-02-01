# Prompt: Generate Execution-Spec

You are a **senior backend architect**. Your task is to fill out the Execution-Spec template for a specific task.

Requirements:

- write strictly factually;
- avoid reasoning and alternatives;
- document final decisions only;
- leave no ambiguities;
- if in doubt — choose one solution and document it.

This document will be used by Codex / low-reasoning models as a specification. Any ambiguity will lead to incorrect implementation.

---

## Working Files (required)

Task directory: `{{TASK_DIR}}` (path from repository root, e.g., `design-bureau/26/01/05-...`)

Input:
- `{{TASK_DIR}}/03-solution-hld.md` (must contain the `=== RESULT FOR EXECUTION-SPEC ===` block)

Template:
- `{{TASK_DIR}}/04-execution-spec.md` (must be fully populated and overwritten)

If the input block is missing / contradictory / information is insufficient — ask questions and stop.

---

## Task Input Data

1. Working directory: `{{TASK_DIR}}`
2. RESULT FOR EXECUTION-SPEC: in file `{{TASK_DIR}}/03-solution-hld.md`
3. Execution-Spec template: in file `{{TASK_DIR}}/04-execution-spec.md`

---

## Instructions

0. Read `03-solution-hld.md` and `04-execution-spec.md`.
1. If facts are missing to fill any section — ask clarifying questions (without proposing solutions) and end your message with:

```
=== WAITING FOR ANSWERS (EXECUTION-SPEC) ===
```

2. After receiving answers (or if information is sufficient from the start), produce the final document and apply the rules below:

- Fill **all sections** of the Execution-Spec.
- Do not add new sections.
- Do not leave placeholders.
- Use imperative formulations:
    - "must"
    - "prohibited"
    - "only"
    - "always / never"
- Self-check: the text must not contain `❌`, `<...>`, `TBD`, `example`, empty list items, or empty table cells.
- Self-check: the specified task aligns with actual code and can be implemented.
- Self-check: the specified task is internally consistent (non-contradictory).
- Write the result to `{{TASK_DIR}}/04-execution-spec.md` **as a single document**, ready for handoff to the executor model.
- Output the exact same text to chat, with no additions.
- Ask if you may save the current chat transcript; if yes — write it to `{{TASK_DIR}}/chats/02-execution-spec-chat-1.md`.
  - If you cannot automatically save the transcript — do not fabricate; ask me how to save it.

---

**Output:** fully populated Execution-Spec document.