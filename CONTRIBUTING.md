# Contributing to minispec

Thanks for caring about minispec. The workflow you'll use to contribute **is** the workflow the project itself ships — we dogfood.

## TL;DR

1. Open a change card under `minispec/changes/` before touching code.
2. Keep Plan tight and Acceptance testable.
3. `sh scripts/ms-doctor.sh .` must pass; `bats tests/bats` and Pester must be green.
4. Close via `sh scripts/ms-close.sh <id> <domain> .` before opening a PR.

## Step by step

### 1. Pick or create an issue

Small fixes (typo, link) don't need an issue. Anything that changes behavior or shape needs one so there's a place to discuss scope.

### 2. Create a change card

Copy `minispec/templates/change.md` to `minispec/changes/<YYYYMMDD>-<slug>.md` and fill:

- `# Why` — what problem, who's affected.
- `# Scope` — In / Out. Out is load-bearing.
- `# Acceptance` — Given / When / Then lines, each testable.
- `# Plan` — T1, T2, T3 with Expected output.
- `# Risks and Rollback` — at minimum one risk + how to back out.

The ID must match `^[0-9]{8}-[a-z0-9-]+$`; `ms-doctor` will warn if not.

### 3. Apply the plan

Work through Plan tasks in order. Tick `- [x]` as you go. Keep commits small and referenced to the card ID. Do not expand scope silently — if you need to, add one Acceptance line first.

### 4. Check

- `sh scripts/ms-doctor.sh .` → must exit 0.
- `bats tests/bats` → all green (POSIX side).
- `Invoke-Pester tests/pester -Output Detailed` → all green (PowerShell side).
- Every script behavior change updates BOTH `.sh` and `.ps1` in the same card — this is an engineering constraint, not a suggestion.

Record the commands and their outcomes under the card's `# Notes`.

### 5. Close

```sh
sh scripts/ms-close.sh <id> <domain> .
```

`<domain>` is one of: `scripts` (script behavior), `docs` (README/AGENTS/CLAUDE), `skills` (SKILL files), `workflow` (the 6-action contract itself), `tooling` (.gitignore / tests / CI / install), `governance` (LICENSE / CONTRIBUTING / CHANGELOG).

Close will fail if Acceptance has any `- [ ]`. Plan items do not block close.

### 6. Open the PR

Title: `<domain>: <short summary>` (e.g. `scripts: detect-node parity fix`). Body should link the merged `## Change <id>` anchor in the spec file.

## Local setup

Nothing to install beyond what your OS ships with, plus the test tools:

```sh
# POSIX
sudo apt-get install -y shellcheck bats            # ubuntu/debian
brew install shellcheck bats-core                  # macOS

# PowerShell
Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser -Force
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
```

## Style

- Scripts: POSIX `sh` for `.sh` (no bashisms); PowerShell 7 for `.ps1`. Both always start with error-stop (`set -eu` / `$ErrorActionPreference = "Stop"`).
- Docs: English is the canonical source; `README.zh-CN.md` is a mirror. SKILL files stay English for agent stability.
- Change card language: either English or 中文 is fine — tests and scripts are the contract, not the card's prose.

## When in doubt

Open the card anyway, with your best guess. `# Notes` is a great place to say "unsure about X" — reviewers can react to a concrete draft faster than to an idea.
