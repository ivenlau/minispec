# Changelog

All notable changes to minispec are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/) once a first release is cut.

## [Unreleased]

### Added
- `minispec pause [--reason "<text>"]` / `minispec resume` — ceremony-control commands that temporarily disable the `new` / `apply` / `check` / `close` flow for quick edits, debugging, or exploration. Pause state lives in `minispec/.paused` (persistent across shells, explicitly visible to `ls`), auto-git-ignored via a new `minispec/.gitignore` that `ms-init` drops. Explicit `minispec <action>` invocations still run even while paused. `ms-doctor` emits a `[WARN]` if the pause has lasted more than 4 hours. Three SKILL files gain a `## Pause Awareness` rule so agents follow the semantics.
- One-line system installers at the repo root: `install.sh` (Linux/macOS/WSL/git-bash) and `install.ps1` (Windows PowerShell). Both drop minispec into the user directory and put a global `minispec` command on PATH.
- Global `minispec` CLI in `bin/minispec` (POSIX) + `bin/minispec.cmd` and `bin/minispec.ps1` (Windows). Dispatches `init` / `doctor` / `project` / `close` to the underlying scripts; prints agent-hand-off guidance for `new` / `apply` / `check` / `analyze`.
- README Quickstart rewritten around "one-line install → `minispec init .` → let the AI CLI take over".

- Canonical skill source at `minispec/SKILL.md`; platform mirrors in `.claude/skills/` and `.agents/skills/` now point to it.
- `## Maintainer Notes` section in `minispec/project.md`, preserved across `ms-project` regenerations.
- `minispec/specs/workflow.md` — the self-spec describing the 6-action contract in Given/When/Then form.
- `README.zh-CN.md` Chinese entry + language switcher on the English README.
- Semantic checks in `ms-doctor` (TBD placeholders, change filename pattern, frontmatter status validity, stale drafts, archive↔spec cross-reference, SKILL Guardrails drift).
- `tests/bats/` and `tests/pester/` test suites with shared `tests/fixtures/` and an onboarding `tests/README.md`.
- `.github/workflows/ci.yml` running shellcheck + PSScriptAnalyzer lint, bats on ubuntu, Pester on windows.
- `.gitignore` covering minispec backups (`*.bak.*`), common OS/editor cruft, and logs.
- `LICENSE` (MIT) and `CONTRIBUTING.md`.
- Repository structure diagram distinguishing the template repo from a downstream adopter.

### Removed
- `scripts/install.sh` (superseded by the root `install.sh` + `minispec init <dir>`).
- `scripts/minispec.sh` and `scripts/minispec.ps1` (superseded by `bin/minispec*`).

### Changed
- `ms-init` (both `.sh` and `.ps1`): by default, appends a marker-wrapped block to the target project's `.gitignore` hiding `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`, and `minispec/` from git — minispec becomes developer-local by default. The write is idempotent (re-running init never duplicates the block). Pass `--no-gitignore` (POSIX) or `-NoGitignore` (PowerShell) to opt out. `bin/minispec*` launcher forwards the flag across both platforms. README adds a "Tracking minispec in git" section documenting the default, the opt-out, and how to switch to team mode. `specs/workflow.md` gains a `## Bootstrap: init` section with the gitignore behavior as contract.
- `new` action (all three SKILL files + `specs/workflow.md`): the agent must now ask one clarifying question at a time to surface purpose/constraints/success criteria, and propose 2–3 named approaches with trade-offs before writing the change card. Single-reasonable-path problems skip the approach proposal and say so explicitly.
- `minispec/templates/change.md`: adds a `# Approach` section between `# Why` and `# Scope` with a `Considered` / `Chosen` skeleton so each card records the approach rationale; Approach stays in the card and archive (not merged into the domain spec, consistent with how Plan and Risks are handled).
- `ms-project.sh` / `.ps1` now agree on Next.js vs `next-sitemap` detection (exact dep-name match instead of substring grep on the sh side).
- `ms-close.sh` / `.ps1` only block on unchecked items inside the `# Acceptance` section; Plan items no longer block close.
- `ms-close.ps1` merge block rewritten with single-quoted here-string + `-f` placeholder formatting to remove the accidental-backtick dependency.
- `AGENTS.md` and `CLAUDE.md` rewritten to the full 6-action contract (was 5 and 4 respectively).
- Two platform SKILLs: both `description: Lightweight spec-first workflow for coding tasks.`; both include the same `## Guardrails` block.
- README workflow action list labels each action as `(agent-driven only)` vs `(agent-preferred; script fallback: …)`.
- Merged-spec Notes blocks now include a `See minispec/archive/<id>.md for plan and risk notes.` cross-reference.

### Fixed
- CI (`lint` job): `scripts/ms-init.sh` and `bin/minispec` no longer use the `CDPATH= cd …` prefix-assignment pattern that shellcheck flagged as SC1007 (ambiguous with a misspaced assignment). Both scripts now `unset CDPATH` once at the top, then use plain `cd -- …`.
- CI (`test-pester` job) — three distinct second-round fixes after `BeforeEach` location was resolved:
  - `scripts/ms-doctor.ps1`: four interpolated strings used `"$rel: …"` which PowerShell parses as a scoped-variable reference. Changed to `"${rel}: …"` to disambiguate. Blocked all five Doctor tests from running at all (ParserError at load time).
  - `tests/pester/Close.Tests.ps1`: `Write-TestCard` helper was defined at the top level of the `Describe` block — in Pester v5 that scope runs during discovery and is gone by run time. Moved the function into `BeforeAll` and changed it to take the target root as a parameter instead of relying on `$script:` scope.
  - `tests/pester/Init.Tests.ps1`: one assertion used `(?m)^minispec/$` against `.gitignore` content. On Windows the file ends lines with `\r\n`, and .NET regex `(?m)$` matches before `\n` but leaves `\r` in front of the anchor, so the match failed. Switched the assertion to `Get-Content` line-split + `Should -Contain`, which is line-ending-agnostic.
- CI (`test-pester` job, first round): `Doctor.Tests.ps1`, `Close.Tests.ps1`, `Init.Tests.ps1` and `Project.Tests.ps1` moved `BeforeEach` / `AfterEach` inside their `Describe` blocks (Pester v5 rejects them at the root of a test file). `Project.Tests.ps1` consolidated into a single `Describe "ms-project.ps1"` with `Context "detection"` and `Context "Maintainer Notes"` so setup/teardown are shared.
- `scripts/ms-close.ps1` no longer relies on PowerShell's backtick-following-non-special-char coincidence inside its merge here-string.
- "No script dependency" ambiguity in SKILLs replaced with explicit "prefer in-context generation; fall back to the script only without an AI agent."
