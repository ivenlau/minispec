# CLAUDE

Use minispec as default delivery workflow for behavior changes.

## Workflow Contract

1. Create or refresh a change card in `minispec/changes/`.
2. Implement only accepted scope.
3. Validate acceptance items and tests.
4. Update `minispec/specs/` and archive on completion.

Before first change in a repository, run `project` to generate or refresh `minispec/project.md`.

## Skill

- `.claude/skills/minispec/SKILL.md`

## Context Files

- `minispec/project.md`
- `minispec/specs/`
- `minispec/templates/change.md`

## Exception Rule

Skip minispec only for trivial typo-only edits with no behavior change.
