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
sh scripts/ms-init.sh .
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-init.ps1' -Root ."
```

2. Generate `project.md` (guided or context-driven) directly.

Create or refresh `minispec/project.md` with these sections:

- `## Stack` (`Language`, `Framework`, `Runtime`) [auto-filled by CLI]
- `## Commands` (`Install`, `Build`, `Test`, `Lint`) [auto-filled by CLI]
- `## Engineering Constraints` [manual-maintained]
- `## Non-Goals` [manual-maintained]
- `## Definition of Done` [manual-maintained]
- `## Generation Metadata` [auto-filled by CLI]
- `## Guided Inputs` [auto-filled when unresolved]
- Optional `## Maintainer Notes` [manual-maintained]

If stack detection is uncertain, keep explicit `TBD` placeholders instead of guessing.

3. Review and edit `minispec/project.md`.

The generated file is a draft. Update stack and command lines to your real setup.

4. Create first change.

Copy template and rename with change id:

```text
minispec/changes/20260323-your-change.md
```

Populate:

- Why
- Scope (In/Out)
- Acceptance (Given/When/Then)
- Plan (task checklist)

### B. Existing Project

1. Run doctor.

```sh
sh scripts/ms-doctor.sh .
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-doctor.ps1' -Root ."
```

2. Generate or refresh `project.md` from repository context directly.

Detect likely stack and commands from project files when possible; otherwise use guided placeholders.

If `minispec/project.md` already exists, update auto-filled sections and preserve manual-maintained sections. If section boundaries are unclear, create a timestamped backup before refresh.

3. Review and correct commands.

Detected commands are best-effort. Confirm `Install`, `Build`, `Test`, and `Lint` before implementation.

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
