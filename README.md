# minispec

minispec is a lightweight spec-first workflow for AI coding tools.
It is designed to run with no extra CLI and no dependency install.

## Workflow

1. `project`: Generate or refresh `project.md`.
2. `new`: Create a change card from an idea.
3. `apply`: Implement tasks from the change card.
4. `check`: Validate acceptance criteria and test commands.
5. `close`: Merge final behavior into `specs/` and archive the change.

## Utility Scripts

- `scripts/ms-init.sh` / `scripts/ms-init.ps1`: create minispec folders and scaffold baseline files.
- `scripts/ms-doctor.sh` / `scripts/ms-doctor.ps1`: verify required structure.
- `scripts/ms-project.sh` / `scripts/ms-project.ps1`: optional helper to auto-generate `minispec/project.md` when scripts are available.
- `scripts/ms-close.sh` / `scripts/ms-close.ps1`: close a change card and auto-merge into one domain spec.

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

- `## Stack` (`Language`, `Framework`, `Runtime`)
- `## Commands` (`Install`, `Build`, `Test`, `Lint`)
- `## Engineering Constraints`
- `## Non-Goals`
- `## Definition of Done`
- `## Generation Metadata`

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

If `minispec/project.md` already exists, keep user customizations where obvious, or create a timestamped backup before refresh.

3. Review and correct commands.

Detected commands are best-effort. Confirm `Install`, `Build`, `Test`, and `Lint` before implementation.

### C. Use In AI CLI (Codex/Claude)

1. Run in Codex.

Ensure repo contains `AGENTS.md` and `.agents/skills/minispec/SKILL.md`.

Ask agent to run minispec actions:

- `minispec project . auto nextjs saas app`
- `minispec new add refund filter`
- `minispec apply 20260323-refund-filter`
- `minispec check 20260323-refund-filter`
- `minispec close 20260323-refund-filter`

2. Run in Claude Code.

Ensure repo contains `CLAUDE.md` and `.claude/skills/minispec/SKILL.md`.

Trigger the same actions through the minispec skill:

- `project nextjs saas app`
- `new add refund filter`
- `apply 20260323-refund-filter`
- `check 20260323-refund-filter`
- `close 20260323-refund-filter`

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
