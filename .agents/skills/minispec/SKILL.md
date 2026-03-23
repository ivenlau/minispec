---
name: minispec
description: Lightweight spec-first workflow for code changes.
---

# minispec

Lightweight spec-first workflow for code changes.

## Use This Skill When

- The user asks to implement or change behavior.
- The scope is unclear and needs a short acceptance-driven spec.
- You need traceability from intent to code changes.

## Inputs

- Action: `project`, `new`, `apply`, `check`, or `close`.
- Optional change id, for example: `20260323-refund-filter`.
- Optional user request text.

## Directory Contract

- `minispec/project.md`: project constraints and commands.
- `minispec/specs/`: canonical shipped behavior.
- `minispec/changes/`: active change cards.
- `minispec/archive/`: closed change cards.
- `minispec/templates/change.md`: change template.

## Action: new

1. Read `minispec/project.md`.
2. Read `minispec/specs/README.md` and related domain specs if they exist.
3. Create one new file in `minispec/changes/` using `minispec/templates/change.md`.
4. Fill `Why`, `Scope`, `Acceptance`, and an initial `Plan`.
5. Keep it short and testable. Ask for missing critical details only when necessary.

## Action: project

1. Generate or refresh `minispec/project.md` before first change card.
2. For existing repositories, detect stack and commands from project files.
3. For new repositories, infer from user context or use guided placeholders.
4. Ask user to review and refine generated commands before implementation.
5. Always execute `project` directly (no script dependency):
   - Create or refresh `minispec/project.md` using this contract structure:
     - `## Stack` (`Language`, `Framework`, `Runtime`)
     - `## Commands` (`Install`, `Build`, `Test`, `Lint`)
     - `## Engineering Constraints`
     - `## Non-Goals`
     - `## Definition of Done`
     - `## Generation Metadata` (include source and mode; add context when provided)
   - If `minispec/project.md` exists, keep behavior conservative:
     - keep user edits when obvious
     - otherwise create a timestamped `.bak.<YYYYMMDDHHmmss>` backup before refresh
   - If stack detection is uncertain, use explicit guided placeholders (`TBD`) instead of guessing.

## Action: apply

1. Open target file in `minispec/changes/<id>.md`.
2. Execute plan tasks in order and keep scope tight.
3. After each completed task, mark the checkbox as done.
4. If scope changes, update `Scope` and add one acceptance item before coding more.
5. Do not close the card in this action.

## Action: check

1. Open target change card and validate every acceptance line.
2. Run commands from `minispec/project.md` where available (`test` and `lint` first).
3. Record validation notes under `Notes` in the change file.
4. If any acceptance item fails, leave status as `draft` or `in_progress`.

## Action: close

1. Ensure all acceptance checkboxes are complete.
2. Update the relevant file in `minispec/specs/` with final shipped behavior.
3. Set frontmatter `status: closed` in the change file.
4. Move the change file from `minispec/changes/` to `minispec/archive/`.

## Output Style

- Keep updates concise and concrete.
- Always reference file paths changed.
- Separate assumptions from confirmed facts.
