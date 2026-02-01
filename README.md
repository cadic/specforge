# SpecForge

A structured methodology for AI-assisted software development using a two-stage pipeline: **reasoning model → specification → coding model**.

## The Problem

AI coding assistants often produce inconsistent results when given vague requirements. They may:
- Make architectural decisions "on the fly"
- Add unrequested improvements
- Interpret ambiguous requirements differently each time
- Skip edge cases not explicitly mentioned

## The Solution

SpecForge separates **thinking** from **coding** into two distinct stages:

1. **Solution Space Exploration** — A high-reasoning model asks questions, proposes multiple approaches, compares trade-offs, and helps you choose the best option
2. **Execution** — A coding model implements strictly according to a detailed specification, without interpretation or "improvements at discretion"

## Workflow

```
┌─────────────────┐
│ Problem         │
│ Statement       │
└────────┬────────┘
         ▼
┌──────────────────────────────────────┐
│  Stage 1: Solution Space Exploration │
│  (High-reasoning model)              │
├──────────────────────────────────────┤
│ • Clarifies requirements             │
│ • Proposes 2–4 approaches            │
│ • Compares trade-offs                │
│ • You choose one                     │
└────────┬─────────────────────────────┘
         ▼
┌─────────────────┐
│ Execution-Spec  │◄── Detailed, unambiguous specification
└────────┬────────┘
         ▼
┌──────────────────────────────────────┐
│  Stage 2: Implementation             │
│  (Coding model)                      │
├──────────────────────────────────────┤
│ • Follows spec exactly               │
│ • No architectural decisions         │
│ • No unrequested improvements        │
│ • Asks if unclear, doesn't guess     │
└────────┬─────────────────────────────┘
         ▼
┌─────────────────┐
│ Working Code    │
└─────────────────┘
```

## Key Principles

- **Separation of concerns**: Architecture decisions are made by humans with AI assistance, not delegated to a coding model
- **Explicit over implicit**: Everything required must be documented; if it's not in the spec, it doesn't exist
- **No "improvements at discretion"**: The executor follows the spec exactly
- **Checkpoints**: Multiple review points before code is written
- **Stack-agnostic**: Core templates work with any tech stack; coding standards live in your `AGENTS.md`

## Files

| File | Purpose |
|------|---------|
| `01-problem-statement.md` | Template for describing your task |
| `prompt-solution-space.md` | Prompt for Stage 1: Solution Space Exploration |
| `prompt-execution-spec.md` | Prompt for Stage 2: Generate Execution-Spec |
| `04-execution-spec.md` | Execution-Spec template (stack-agnostic) |
| `AGENTS.example.md` | Example coding standards (WordPress/PHP) |

## Task Directory Structure

For each task, create a directory with:

```
task-directory/
├── 01-problem-statement.md    # Your raw problem description
├── 02-solution-options.md     # Generated: reviewed approaches
├── 03-solution-hld.md         # Generated: chosen solution summary
├── 04-execution-spec.md       # Generated: detailed specification
├── AGENTS.md                  # Your coding standards (copy from example)
└── chats/
    ├── 01-solution-options-chat-1.md
    └── 02-execution-spec-chat-1.md
```

## Quick Start

1. Create a task directory
2. Copy `AGENTS.example.md` → `AGENTS.md` and adapt to your tech stack
3. Write your problem statement in `01-problem-statement.md` (stream of consciousness is fine)
4. Copy the templates to your task directory
5. Send `prompt-solution-space.md` to a high-reasoning model
6. Answer questions, review options, choose an approach
7. Send `prompt-execution-spec.md` to generate the detailed Execution-Spec
8. Review the spec carefully
9. Send the spec to a coding model with "implement this specification"
10. Review the implementation

## AGENTS.md

The `AGENTS.md` file contains coding standards and patterns for the AI to follow. The included example covers WordPress/PHP, but you should create your own for your stack:

- Naming conventions
- Security patterns
- Formatting rules
- Testing setup
- Common pitfalls to avoid

**When the AI makes recurring mistakes, add a rule to `AGENTS.md`.**

### Examples for Other Stacks

Your `AGENTS.md` might include:

**TypeScript/React:**
- Component file naming (`PascalCase.tsx`)
- Hook patterns (`use` prefix)
- State management conventions
- Testing with Jest/React Testing Library

**Python/Django:**
- PEP 8 compliance
- Model naming conventions
- View/serializer patterns
- pytest configuration

**Go:**
- Package naming
- Error handling patterns
- Interface conventions
- Testing with `go test`

## Effectiveness

Subjective observations from usage:

- **Design stage**: More effective than solo work — helps avoid analysis paralysis and documents decisions properly
- **Implementation stage**: Comparable to manual coding when in flow; faster when fatigued
- **vs. junior developers**: Significantly more effective — AI follows existing code patterns better and doesn't need extensive onboarding

## License

MIT
