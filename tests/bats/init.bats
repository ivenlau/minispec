#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TEST_ROOT="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "init scaffolds the contract tree" {
  run sh "$REPO_ROOT/scripts/ms-init.sh" "$TEST_ROOT"
  [ "$status" -eq 0 ]
  [ -d "$TEST_ROOT/minispec/specs" ]
  [ -d "$TEST_ROOT/minispec/changes" ]
  [ -d "$TEST_ROOT/minispec/archive" ]
  [ -f "$TEST_ROOT/minispec/templates/change.md" ]
  [ -f "$TEST_ROOT/.agents/skills/minispec/SKILL.md" ]
  [ -f "$TEST_ROOT/.claude/skills/minispec/SKILL.md" ]
  [ -f "$TEST_ROOT/AGENTS.md" ]
  [ -f "$TEST_ROOT/CLAUDE.md" ]
}

@test "init appends the minispec marker block to .gitignore by default" {
  run sh "$REPO_ROOT/scripts/ms-init.sh" "$TEST_ROOT"
  [ "$status" -eq 0 ]
  [ -f "$TEST_ROOT/.gitignore" ]
  grep -q '^# >>> minispec' "$TEST_ROOT/.gitignore"
  grep -qE '^minispec/$' "$TEST_ROOT/.gitignore"
  grep -qE '^AGENTS\.md$' "$TEST_ROOT/.gitignore"
  grep -qE '^\.claude/$' "$TEST_ROOT/.gitignore"
}

@test "init preserves existing .gitignore content and appends the block below" {
  printf 'node_modules/\n*.log\n' > "$TEST_ROOT/.gitignore"
  run sh "$REPO_ROOT/scripts/ms-init.sh" "$TEST_ROOT"
  [ "$status" -eq 0 ]
  grep -q '^node_modules/$' "$TEST_ROOT/.gitignore"
  grep -q '^\*\.log$' "$TEST_ROOT/.gitignore"
  grep -q '^# >>> minispec' "$TEST_ROOT/.gitignore"
}

@test "init is idempotent — second run does not duplicate the marker block" {
  sh "$REPO_ROOT/scripts/ms-init.sh" "$TEST_ROOT"
  sh "$REPO_ROOT/scripts/ms-init.sh" "$TEST_ROOT"
  count="$(grep -c '^# >>> minispec' "$TEST_ROOT/.gitignore")"
  [ "$count" -eq 1 ]
}

@test "init with --no-gitignore does not create .gitignore" {
  run sh "$REPO_ROOT/scripts/ms-init.sh" "$TEST_ROOT" --no-gitignore
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_ROOT/.gitignore" ]
}

@test "init accepts --no-gitignore before the target directory" {
  run sh "$REPO_ROOT/scripts/ms-init.sh" --no-gitignore "$TEST_ROOT"
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_ROOT/.gitignore" ]
}

@test "init --no-gitignore leaves an existing .gitignore untouched" {
  printf 'node_modules/\n' > "$TEST_ROOT/.gitignore"
  run sh "$REPO_ROOT/scripts/ms-init.sh" "$TEST_ROOT" --no-gitignore
  [ "$status" -eq 0 ]
  ! grep -q '^# >>> minispec' "$TEST_ROOT/.gitignore"
  grep -q '^node_modules/$' "$TEST_ROOT/.gitignore"
}
