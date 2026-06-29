# SpecForge

A spec-driven methodology for AI-assisted development, packaged as an
**agent skillset**. SpecForge separates **reasoning** from **implementation**
across three stages:

1. **Explore** — solution-space exploration with a high-reasoning model.
2. **Spec** — generate an unambiguous Execution-Spec.
3. **Execute** — implement strictly from the spec with a coding model.

The methodology is authored once and runs in any `SKILL.md`-compatible coding
agent.

## How it is structured

```
skills/
  specforge/          # orchestrator: scaffolding, phase detection, routing (bash)
  specforge-explore/  # Stage 1 (prose, high-reasoning)
  specforge-spec/     # Stage 2 (prose, high-reasoning) + 04 template
  specforge-execute/  # Stage 3 (prose, coding model)
```

- **Skills live in the agent** (its global skills directory).
- **Artifacts live in your project**: `docs/specforge/<task-slug>/` (override the
  root with a `.specforge.json` at your repo root: `{ "task_root": "..." }`).

State lives in the filesystem. `skills/specforge/scripts/sf-status.sh` derives
the current phase from which `0X-*.md` files exist, so you can stop after any
stage and resume later — even in a different agent.

## Install

SpecForge installs with one command via the cross-agent
[`skills` CLI](https://github.com/vercel-labs/skills) — no clone, no config. It
auto-discovers the `skills/` directory in this repo, so there is nothing to set
up on our side.

**opencode (v1):**

```bash
npx skills add cadic/specforge -a opencode -g --skill '*'
```

`-a opencode` targets opencode, `-g` installs globally (into
`~/.config/opencode/skills/`), and `--skill '*'` installs all four SpecForge
skills.

The same command works for any of the 70+ agents the CLI supports — swap the
agent name:

```bash
npx skills add cadic/specforge -a claude-code -g --skill '*'
npx skills add cadic/specforge -a codex -g --skill '*'
```

For Cursor (no global skills dir), install into the project instead (drop `-g`):

```bash
npx skills add cadic/specforge -a cursor --skill '*'
```

**Manual fallback (zero dependencies):** copy the four `skills/specforge*`
directories into your agent's global skills directory by hand, e.g.
`cp -r skills/specforge* ~/.config/opencode/skills/`.

## Using it

1. In your agent, invoke the **specforge** skill and give it a task slug.
2. It scaffolds `docs/specforge/<slug>/01-problem-statement.md` — fill it in.
3. It detects the phase and routes you through Explore → Spec → Execute,
   stopping at checkpoints for your input.

## Coding standards

SpecForge does not ship an `AGENTS.md`. Stage 3 follows your project's own
`AGENTS.md`/`CLAUDE.md`. See
[docs/writing-agents-md-for-specforge.md](docs/writing-agents-md-for-specforge.md).

## Development

Bash helpers are tested with [bats-core](https://github.com/bats-core/bats-core):

```bash
brew install bats-core
bats tests/
```

## License

MIT
