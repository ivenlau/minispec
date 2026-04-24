# minispec

Language: **English** | [简体中文](README.zh-CN.md)

minispec is a lightweight spec-first workflow for AI coding tools.
It scaffolds a tiny, markdown-only contract (`project.md` + `specs/` + `changes/` + `archive/`) and teaches your AI agent — Claude Code, Codex, etc. — how to make changes through it.

## Install

### Linux / macOS / WSL / git-bash

```sh
curl -fsSL https://raw.githubusercontent.com/ivenlau/minispec/main/install.sh | sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/ivenlau/minispec/main/install.ps1 | iex
```

Both installers drop minispec into your user directory (no sudo, no elevation) and put a `minispec` command on your PATH. If `~/.local/bin` (Linux/macOS) is not on your PATH, the installer prints the exact line to add to your shell rc. On Windows, open a new terminal after install so the PATH refresh takes effect.

Verify:

```sh
minispec --version
```

## Quickstart

Three steps from a fresh directory to your first AI-driven change:

```sh
cd my-project
minispec init .                                    # scaffold the contract + AI skill files (also hides minispec from git — see below)
minispec project . auto "TypeScript Next.js app"   # generate minispec/project.md (auto-detect + context hint)
```

Pass `--no-gitignore` to `init` if you want to manage `.gitignore` yourself.

Then open your AI CLI (Claude Code or Codex) in `my-project/` and ask:

```
minispec new add checkout rate-limit
minispec apply 20260422-checkout-rate-limit
minispec check 20260422-checkout-rate-limit
minispec close 20260422-checkout-rate-limit checkout
```

The agent will read `AGENTS.md` / `CLAUDE.md` and the SKILL files that `init` dropped into `.agents/` and `.claude/`, create a change card in `minispec/changes/`, implement the plan, validate, and finally merge the change into `minispec/specs/checkout.md`.

## Tracking minispec in git

**Default: dev-local.** `minispec init` treats minispec as developer-local tooling. It appends a marker-wrapped block to the target project's `.gitignore` that hides `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`, and `minispec/` from git. Your product git history stays focused on product code; minispec scaffolding lives on disk but is invisible to `git add`.

The block looks like this (editable any time):

```gitignore
# >>> minispec — dev-local scaffolding (added by `minispec init`) >>>
# Remove this block to commit minispec files and track change history in
# git alongside your code. See README for details.
AGENTS.md
CLAUDE.md
.agents/
.claude/
minispec/
# <<< minispec <<<
```

**Opt out once** — pass `--no-gitignore` to skip the write on a specific `init` run:

```sh
minispec init --no-gitignore .
```

**Switch to team mode** (commit minispec alongside code so clones inherit the workflow, AI skills, and change history): delete the marker block from `.gitignore`, then `git add AGENTS.md CLAUDE.md .agents .claude minispec`.

Idempotence — running `minispec init` again on the same target never duplicates the marker block.

## Pausing minispec

minispec is opinionated by default — clarify, propose, card, apply, check, close — which is great for meaningful changes and heavy for a typo. When you need a break from the ceremony (hotfix loop, debugging, rapid exploration), pause it:

```sh
minispec pause --reason "debugging auth redirect"
```

While paused, agents treat your requests as normal coding tasks: no card, no propose, no merge. Guardrails still apply (no unauthorized dependency additions, no unrelated cleanup). When you're done:

```sh
minispec resume
```

Explicit `minispec <action>` calls always override the pause — if you say `minispec new add-refund-filter` while paused, the ceremony runs anyway.

Pause state lives in `minispec/.paused` and is always git-ignored via `minispec/.gitignore` (dropped by `minispec init`), so it stays per-developer. `minispec doctor` emits a `[WARN]` if you've been paused for more than 4 hours — a nudge, not a failure.

## Upgrading and removing

### Upgrade a project's agent files to match the latest CLI

After `install.sh` / `install.ps1` refreshes the CLI itself (re-run the same one-liner), projects that were already initialised still carry the old `AGENTS.md`, `CLAUDE.md`, and SKILL files. Pull the latest versions into the project:

```sh
minispec upgrade .                       # refresh 4 agent files (never touches business data)
minispec upgrade . --dry-run             # preview what would change
minispec upgrade . --include-template    # also pull the latest change.md template
```

`upgrade` never touches `minispec/project.md`, `minispec/specs/`, `minispec/changes/`, or `minispec/archive/` — those are yours.

### Remove minispec from a project

```sh
minispec remove .                        # prompts before deleting
minispec remove . --yes                  # no prompt (non-interactive use)
minispec remove . --keep-archive         # preserve minispec/archive/ (historical cards)
minispec remove . --dry-run              # preview what would be removed
```

`remove` deletes `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`, and the whole `minispec/` tree by default, and strips the `# >>> minispec` marker block from `.gitignore`.

### Uninstall the global CLI

```sh
minispec uninstall --yes                 # removes launcher + install dir + Windows PATH entry
```

Or, if the CLI itself is broken, bootstrap the uninstaller the same way as install:

```sh
curl -fsSL https://raw.githubusercontent.com/ivenlau/minispec/main/uninstall.sh | sh -s -- --yes
```

```powershell
irm https://raw.githubusercontent.com/ivenlau/minispec/main/uninstall.ps1 | iex
# (prompts for confirmation; set $env:MINISPEC_YES = "1" first to skip)
```

`uninstall` does not touch any project — projects keep their `minispec/` tree. Run `minispec remove <dir>` first if you also want to clean those.

## Workflow

1. `project`: Generate or refresh `project.md`. _(agent-preferred; script fallback: `scripts/ms-project.*`)_
2. `new`: Create a change card from an idea. _(agent-driven only)_
3. `apply`: Implement tasks from the change card. _(agent-driven only)_
4. `check`: Validate acceptance criteria and test commands. _(agent-driven only)_
5. `analyze`: In Code CLI, analyze repository context and sync `minispec/specs/README.md` plus referenced docs. _(agent-driven only)_
6. `close`: Merge final behavior into `specs/` and archive the change. _(agent-preferred; script fallback: `scripts/ms-close.*`)_

### CLI Syntax

All actions share the same shape regardless of AI CLI (Codex, Claude, …):

```text
minispec <action> [root] [mode] [context...]
```

- `<action>`: one of `project`, `new`, `apply`, `check`, `analyze`, `close`.
- `[root]`: optional repo root, defaults to `.`.
- `[mode]`: optional action-specific mode (for `project`: `auto` | `existing` | `new`; for `analyze`: `quick` | `normal` | `deep`).
- `[context...]`: remaining free-form tokens passed as context to the action.

You can omit `root` and `mode` — most examples in this README do.

## Utility Scripts

Scripts are a **fallback path for environments without an AI agent** (CI jobs, offline bootstrapping, manual use). When an AI agent is available, prefer executing the action in-context — the agent has richer judgment about stack detection and section merging. Both paths write to the same on-disk contract.

- `scripts/ms-init.sh` / `scripts/ms-init.ps1`: create minispec folders and scaffold baseline files. _(primary path — always script-driven)_
- `scripts/ms-doctor.sh` / `scripts/ms-doctor.ps1`: verify required structure. _(primary path — always script-driven)_
- `scripts/ms-project.sh` / `scripts/ms-project.ps1`: auto-generate `minispec/project.md`. _(fallback; agents should prefer in-context generation)_
- `scripts/ms-close.sh` / `scripts/ms-close.ps1`: close a change card and auto-merge into one domain spec. _(fallback; agents should prefer in-context close)_
Once `minispec` is on your PATH (see [Install](#install)), prefer the global command over calling these scripts directly:

| CLI command              | Underlying script                          |
|--------------------------|--------------------------------------------|
| `minispec init <dir>`    | `scripts/ms-init.sh` / `scripts/ms-init.ps1` |
| `minispec doctor [<dir>]`| `scripts/ms-doctor.sh` / `scripts/ms-doctor.ps1` |
| `minispec project ...`   | `scripts/ms-project.sh` / `scripts/ms-project.ps1` |
| `minispec close <id> <domain> [<dir>]` | `scripts/ms-close.sh` / `scripts/ms-close.ps1` |
| `minispec --version`     | reads `VERSION` at the install share dir   |

The scripts are still useful for CI or offline environments where the global CLI is not installed.

POSIX shell examples:

```sh
sh scripts/ms-init.sh .
sh scripts/ms-doctor.sh .
sh scripts/ms-close.sh 20260323-refund-filter refunds .
```

PowerShell examples:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-init.ps1' -Root ."
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-doctor.ps1' -Root ."
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-close.ps1' -ChangeId 20260323-refund-filter -Domain refunds -Root ."
```

## Quickstart

### A. New Project

1. Initialize folder structure and baseline files.

```sh
minispec init .
```

Script fallback (no global CLI):

```sh
sh scripts/ms-init.sh .
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ms-init.ps1 -Root .
```

2. Generate `project.md` (guided or context-driven).

Ask your AI CLI (Claude Code / Codex) to run:

```sh
minispec project . auto "TypeScript Next.js app"
```

The agent reads the skill, auto-detects what it can from your project files (package.json / pyproject.toml / go.mod / etc.), fills unknown fields as `TBD`, and writes `minispec/project.md` with these sections:

- `## Stack` (`Language`, `Framework`, `Runtime`) [auto-managed]
- `## Commands` (`Install`, `Build`, `Test`, `Lint`) [auto-managed]
- `## Engineering Constraints` [manual-managed]
- `## Non-Goals` [manual-managed]
- `## Definition of Done` [manual-managed]
- `## Generation Metadata` [auto-managed]
- `## Guided Inputs` [auto-managed when unresolved]
- `## Maintainer Notes` [manual-managed, preserved across regenerations]

Script fallback (no AI agent):

```sh
sh scripts/ms-project.sh . auto "TypeScript Next.js app"
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ms-project.ps1 -Root . -Mode auto -Context "TypeScript Next.js app"
```

If stack detection is uncertain, the result keeps explicit `TBD` placeholders instead of guessing.

3. Review and edit `minispec/project.md`.

```sh
$EDITOR minispec/project.md           # or code / notepad / vim
```

The generated file is a draft. Update `Stack` and `Commands` to your real setup. Don't touch `Generation Metadata` — it is rewritten on every `minispec project` run.

4. Create the first change card.

In your AI CLI:

```sh
minispec new add checkout rate-limit
```

The agent will ask one clarifying question at a time (purpose / constraints / success criteria), propose 2–3 approaches, then write the card at `minispec/changes/<YYYYMMDD-slug>.md` with `Why` / `Approach` / `Scope` / `Acceptance` / `Plan` filled in.

To write one manually without an agent:

```sh
cp minispec/templates/change.md minispec/changes/20260422-your-change.md
$EDITOR minispec/changes/20260422-your-change.md
```

Populate `Why`, `Approach`, `Scope` (In/Out), `Acceptance` (Given/When/Then), `Plan` (task checklist).

### B. Existing Project

1. Run doctor to surface structural and semantic issues.

```sh
minispec doctor .
```

Script fallback:

```sh
sh scripts/ms-doctor.sh .
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ms-doctor.ps1 -Root .
```

2. Generate or refresh `project.md` from repository context.

In your AI CLI:

```sh
minispec project . auto "Spring Boot service + PostgreSQL"
```

Drop the quoted string if you want pure auto-detection with no context hint:

```sh
minispec project . auto
```

The agent detects stack from project files when possible. If `minispec/project.md` already exists, auto-managed sections refresh, manual-managed sections are preserved, and a `.bak.<YYYYMMDDHHmmss>` backup is written when section boundaries are unclear.

Script fallback:

```sh
sh scripts/ms-project.sh . auto "Spring Boot service + PostgreSQL"
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ms-project.ps1 -Root . -Mode auto -Context "Spring Boot service + PostgreSQL"
```

3. Review and correct commands.

```sh
$EDITOR minispec/project.md
```

Detected commands are best-effort. Confirm `Install`, `Build`, `Test`, and `Lint` before the first implementation change.

### C. Use In AI CLI (Codex/Claude)

The action commands are identical across environments — only the entry files and skill path differ.

1. Run in Codex.

Ensure repo contains `AGENTS.md` and `.agents/skills/minispec/SKILL.md`.

2. Run in Claude Code.

Ensure repo contains `CLAUDE.md` and `.claude/skills/minispec/SKILL.md`.

In either environment, ask the agent to run the same commands:

- `minispec project nextjs saas app`
- `minispec new add refund filter`
- `minispec apply 20260323-refund-filter`
- `minispec check 20260323-refund-filter`
- `minispec analyze deep`
- `minispec close 20260323-refund-filter`

If you want to pin `root` and `mode` explicitly, use the longer form, e.g. `minispec project . auto nextjs saas app` or `minispec analyze deep .`.

### D. Close Criteria

Only close when:

- acceptance checklist is complete
- tests pass
- canonical domain spec in `minispec/specs/` is updated

### E. Doctor and Auto Close

Run directory checks:

```sh
sh scripts/ms-doctor.sh .
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-doctor.ps1' -Root ."
```

Close and auto-merge one completed change:

```sh
sh scripts/ms-close.sh 20260323-refund-filter refunds .
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-close.ps1' -ChangeId 20260323-refund-filter -Domain refunds -Root ."
```

### F. Analyze Canonical Specs

In Code CLI, run `analyze` as a model-driven action. Do not rely on local analyze scripts.

Examples:

- `minispec analyze quick`
- `minispec analyze normal`
- `minispec analyze deep`

Mode definitions:

- `quick`: project-level overview.
- `normal`: project + subproject/module boundaries.
- `deep`: project + subprojects + logic hotspot analysis.

## Repo layout vs adopted-project layout

This repo's outer directory is `minispec/`. Inside, there is a nested `minispec/` that holds the contract (project.md, specs, changes, archive, templates). When a downstream project adopts minispec via `scripts/ms-init.sh`, it gets the same contract directory inside its own repo — under whatever its repo name is — not a doubled `minispec/minispec/`.

This repo (template source):

```text
minispec/                     # repo root (happens to be called minispec)
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── minispec/                 # the contract directory (this is what ms-init copies)
│   ├── project.md
│   ├── specs/
│   ├── changes/
│   ├── archive/
│   └── templates/
├── .agents/ .claude/         # platform skill entries
└── scripts/                  # fallback scripts
```

A project that adopted minispec via `ms-init`:

```text
my-app/                       # any downstream repo
├── AGENTS.md and/or CLAUDE.md
├── minispec/                 # only one level — the contract lives here
│   ├── project.md
│   ├── specs/
│   ├── changes/
│   └── archive/
└── src/ ...                  # the rest of the project
```

## Directory Layout

```text
minispec/
  project.md
  specs/
  changes/
  archive/
  templates/
```

## File Rules

- Use one file per active change in `changes/`.
- Keep `specs/` as source of truth for behavior already shipped.
- Move completed changes to `archive/`.

## Suggested Change ID

`YYYYMMDD-short-slug`, for example: `20260323-refund-filter`.
