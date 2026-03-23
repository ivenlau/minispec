---
name: minispec
description: Lightweight spec-first workflow for coding tasks.
---

# minispec

Lightweight spec-first workflow for coding tasks.

## Trigger

Use this skill when user asks to plan or implement a code change and wants small, clear, acceptance-based execution.

## Required Context

- `minispec/project.md`
- `minispec/specs/`
- `minispec/changes/`
- `minispec/archive/`
- `minispec/templates/change.md`

## Commands

Support five actions:

- `project [context]`
- `new <idea>`
- `apply <change-id>`
- `check <change-id>`
- `close <change-id>`

## Behavior

### new

1. Draft one change card from template.
2. Define minimal scope and out-of-scope.
3. Write at least two testable acceptance scenarios.
4. Add an execution plan with explicit file-level tasks.

### project

1. Generate `minispec/project.md` as the first step for new adoption.
2. Existing project: auto-detect stack and likely commands.
3. New project: infer from user context or generate guided fields.
4. Tell user this is an editable draft and ask for corrections.
5. Always execute `project` directly (no script dependency):
   - Create or refresh `minispec/project.md` using the same contract structure:
     - `## Stack` (`Language`, `Framework`, `Runtime`)
     - `## Commands` (`Install`, `Build`, `Test`, `Lint`)
     - `## Engineering Constraints`
     - `## Non-Goals`
     - `## Definition of Done`
     - `## Generation Metadata` (include source and mode; add context when provided)
   - If `minispec/project.md` already exists, preserve obvious user customizations; otherwise create a timestamped `.bak.<YYYYMMDDHHmmss>` backup before refresh.
   - If stack detection is uncertain, use explicit guided placeholders (`TBD`) instead of guessing.

### apply

1. Implement only tasks in the current card.
2. Mark task checkboxes as tasks complete.
3. Keep edits focused; avoid unrelated refactor.
4. If a new requirement appears, update acceptance before implementing it.

### check

1. Validate each acceptance item with evidence.
2. Run tests and lint commands defined in `minispec/project.md`.
3. Append short notes for pass or fail outcomes.

### close

1. Confirm all acceptance items are complete.
2. Update canonical domain spec under `minispec/specs/`.
3. Mark card as `status: closed`.
4. Move card to `minispec/archive/`.

## Guardrails

- No dependency additions without explicit approval.
- No broad cleanup outside scope.
- No close action if acceptance is incomplete.
