# Writing your AGENTS.md for SpecForge execution

SpecForge does not ship an `AGENTS.md` template. Most projects already have an
`AGENTS.md` or `CLAUDE.md`, and SpecForge should not try to own that file.

During **Stage 3 (execute)**, the `specforge-execute` skill follows your
project's own `AGENTS.md`/`CLAUDE.md` for code style, naming, security, and
testing conventions. The methodology-level executor rules (single source of
truth; not-in-spec means it-does-not-exist; ask on ambiguity) live inside the
skill — you do not need to repeat them.

Put stack-specific standards in your project's `AGENTS.md`, for example:

- File and class naming conventions.
- Security patterns (input sanitization, output escaping, prepared statements).
- Formatting rules and the auto-fix command.
- Test framework, test locations, and the run command.
- Dependency-management rules (e.g. add deps via CLI, not by hand).
- Recurring mistakes to avoid — add a rule each time the AI repeats one.

The Execution-Spec references these standards in section 8.3; keep the spec
pointing at your `AGENTS.md` rather than duplicating its contents.
