# Project Contract

This file defines project-wide constraints for minispec execution.

## Stack

- Language: TBD (pick language)
- Framework: TBD (pick framework)
- Runtime: TBD (pick runtime)

## Commands

- Install: TBD
- Build: TBD
- Test: TBD
- Lint: TBD

## Engineering Constraints

- Do not introduce new runtime dependencies without explicit approval.
- Keep changes minimal and focused on accepted scope.
- Add or update tests for behavior changes.

## Non-Goals

- Large refactors without a dedicated change card.
- Unrelated cleanup during feature delivery.

## Definition of Done

- Acceptance checklist in change card is fully checked.
- Tests pass locally with the defined project test command.
- Related canonical spec in `minispec/specs/` is updated.

## Generation Metadata

- Source: guided:new-project
- Mode: new
- Generated at: 2026-03-23 15:10:23 +08:00

## Guided Inputs

- Language and framework?
- Main runtime version requirement?
- Preferred package/dependency manager?
- Default build, test and lint commands?
- Any banned dependencies or architecture constraints?

