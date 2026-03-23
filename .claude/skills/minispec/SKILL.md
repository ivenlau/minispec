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

Support six actions:

- `project [context]`
- `new <idea>`
- `apply <change-id>`
- `check <change-id>`
- `analyze <quick|normal|deep>`
- `close <change-id>`

## Behavior

### new

1. Read `minispec/project.md`.
2. Read `minispec/specs/README.md` and related domain specs if they exist.
3. Create one new file in `minispec/changes/` using `minispec/templates/change.md`.
4. Fill `Why`, `Scope`, `Acceptance`, and an initial `Plan`.
5. Keep it short and testable. Ask for missing critical details only when necessary.

### project

1. Generate `minispec/project.md` as the first step for new adoption.
2. Existing project: auto-detect stack and likely commands.
3. New project: infer from user context or generate guided fields.
4. Tell user this is an editable draft and ask for corrections.
5. Always execute `project` directly (no script dependency):
   - Create or refresh `minispec/project.md` using this contract structure:
     - `## Stack` (`Language`, `Framework`, `Runtime`) [auto-managed]
     - `## Commands` (`Install`, `Build`, `Test`, `Lint`) [auto-managed]
     - `## Engineering Constraints` [manual-managed]
     - `## Non-Goals` [manual-managed]
     - `## Definition of Done` [manual-managed]
     - `## Generation Metadata` (source, mode, context) [auto-managed]
     - `## Guided Inputs` [auto-managed when unresolved]
   - If `minispec/project.md` already exists, apply merge strategy:
     - update only auto-managed sections
     - preserve manual-managed sections
     - if boundaries are ambiguous, create `.bak.<YYYYMMDDHHmmss>` first
   - Add optional `## Maintainer Notes` as manual-managed section when needed.
   - If stack detection is uncertain, use explicit guided placeholders (`TBD`) instead of guessing.

### apply

1. Open target file in `minispec/changes/<id>.md`.
2. Execute plan tasks in order and keep scope tight.
3. After each completed task, mark the checkbox as done.
4. If scope changes, update `Scope` and add one acceptance item before coding more.
5. Do not close the card in this action.

### check

1. Validate each acceptance item with evidence.
2. Run tests and lint commands defined in `minispec/project.md`.
3. Append short notes for pass or fail outcomes.

### analyze

1. Generate or refresh canonical analysis docs in `minispec/specs/`.
2. Execute analysis directly in Code CLI model context.
3. Modes:
   - `quick`: project-level summary.
   - `normal`: project + subproject/module analysis.
   - `deep`: project + subprojects + logic hotspot analysis.
4. Refresh `minispec/specs/README.md` with analysis snapshot and referenced docs.
5. Generate docs by mode:
   - always `project-map.md`
   - normal/deep add `subprojects.md`
   - deep add `logic-deep-dive.md`
6. Preserve `## Maintainer Notes` from existing specs README.
7. Mark deep findings as heuristic where appropriate.

### close

1. Confirm all acceptance items are complete.
2. Update canonical domain spec under `minispec/specs/`.
3. Mark card as `status: closed`.
4. Move card to `minispec/archive/`.

## Guardrails

- No dependency additions without explicit approval.
- No broad cleanup outside scope.
- No close action if acceptance is incomplete.
