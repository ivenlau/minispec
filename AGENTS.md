# AGENTS

Repository default workflow uses minispec.

## Default Rule

For any behavior change, execute minispec flow first:

1. `project` to generate or refresh `minispec/project.md`.
2. `new` to create or update a change card.
3. `apply` to implement only planned tasks.
4. `check` to validate acceptance and tests.
5. `close` to archive and update canonical specs.

## Paths

- Skill path: `.agents/skills/minispec/SKILL.md`
- Project contract: `minispec/project.md`
- Canonical specs: `minispec/specs/`
- Active changes: `minispec/changes/`
- Archive: `minispec/archive/`

## Exceptions

Skip minispec only for:

- non-code conversational requests
- tiny one-line typo fix with no behavior impact
