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
- follow coding standards defined in `AGENTS.md`.

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

Follow the coding standards defined in `AGENTS.md`. Key points:

- <standard 1 from AGENTS.md relevant to this task>
- <standard 2 from AGENTS.md relevant to this task>

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
