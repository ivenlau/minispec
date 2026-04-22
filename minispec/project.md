# Project Contract

This file defines project-wide constraints for minispec execution.

## Stack

- Language: POSIX shell + PowerShell 7 + Markdown
- Framework: none (plain scripts and documentation)
- Runtime: bash or sh (any POSIX-compliant shell); PowerShell 7+ for `.ps1` counterparts

## Commands

- Install: none (no runtime dependencies)
- Build: none (no compilation step)
- Test: `sh scripts/ms-doctor.sh .`
- Lint: `shellcheck scripts/*.sh` and `pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path scripts/*.ps1"` (requires shellcheck and PSScriptAnalyzer installed)

## Engineering Constraints

- Every script behavior change MUST update both `.sh` and `.ps1` to keep parity; single-side changes require an explicit justification in Notes.
- No new runtime dependencies — the repo must remain zero-install.
- Documentation and SKILL files are the contract; behavior described in them must be reflected in code and vice versa.
- Script edits follow `set -eu` (POSIX) and `$ErrorActionPreference = "Stop"` (PS) conventions already in place.

## Non-Goals

- Becoming a general task-orchestration CLI — stay scoped to spec-first change cards.
- Supporting project analysis beyond what the 6 defined actions cover.
- Runtime dependencies or compiled tooling (Node/Python/Rust etc.).

## Definition of Done

- Acceptance checklist in change card is fully checked.
- `sh scripts/ms-doctor.sh .` passes (exit 0) with no new semantic WARNs introduced by the change.
- Both `.sh` and `.ps1` sides of any touched script are updated in parallel.
- Related canonical spec in `minispec/specs/` is updated (e.g. `scripts.md`, `docs.md`, `skills.md`, `workflow.md`, `tooling.md`, `governance.md`).

## Generation Metadata

- Source: manual:dogfood
- Mode: existing
- Generated at: 2026-04-22

## Maintainer Notes

<!-- manual-managed; preserved across ms-project regenerations -->

- When adding detection for a new package ecosystem in `ms-project.*`, add a parallel `Detect-<Ecosystem>` on both sides in the same change card.
- Change IDs follow `YYYYMMDD-short-kebab-slug`; bump the date only, not the slug, if re-opening a closed change.
- `minispec/specs/workflow.md` is the self-spec and should be edited when `SKILL.md` action semantics change.
