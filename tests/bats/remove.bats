#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TEST_ROOT="$(mktemp -d)"
  sh "$REPO_ROOT/scripts/ms-init.sh" "$TEST_ROOT" > /dev/null
  mkdir -p "$TEST_ROOT/minispec/archive" "$TEST_ROOT/minispec/specs"
  printf 'archived' > "$TEST_ROOT/minispec/archive/20260423-done.md"
  printf 'spec content' > "$TEST_ROOT/minispec/specs/checkout.md"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "remove --yes deletes everything and strips gitignore marker" {
  run sh "$REPO_ROOT/scripts/ms-remove.sh" "$TEST_ROOT" --yes
  [ "$status" -eq 0 ]
  [ ! -e "$TEST_ROOT/AGENTS.md" ]
  [ ! -e "$TEST_ROOT/CLAUDE.md" ]
  [ ! -e "$TEST_ROOT/.agents" ]
  [ ! -e "$TEST_ROOT/.claude" ]
  [ ! -e "$TEST_ROOT/minispec" ]
  # gitignore marker gone
  if [ -f "$TEST_ROOT/.gitignore" ]; then
    ! grep -q '^# >>> minispec' "$TEST_ROOT/.gitignore"
  fi
}

@test "remove --keep-archive preserves archive but deletes the rest" {
  run sh "$REPO_ROOT/scripts/ms-remove.sh" "$TEST_ROOT" --yes --keep-archive
  [ "$status" -eq 0 ]
  [ -d "$TEST_ROOT/minispec/archive" ]
  [ -f "$TEST_ROOT/minispec/archive/20260423-done.md" ]
  # Other minispec subtrees deleted
  [ ! -e "$TEST_ROOT/minispec/specs" ]
  [ ! -e "$TEST_ROOT/minispec/changes" ]
  [ ! -e "$TEST_ROOT/minispec/templates" ]
  [ ! -e "$TEST_ROOT/minispec/project.md" ]
  # Other roots gone
  [ ! -e "$TEST_ROOT/AGENTS.md" ]
}

@test "remove --keep-specs preserves specs but deletes the rest" {
  run sh "$REPO_ROOT/scripts/ms-remove.sh" "$TEST_ROOT" --yes --keep-specs
  [ "$status" -eq 0 ]
  [ -d "$TEST_ROOT/minispec/specs" ]
  [ -f "$TEST_ROOT/minispec/specs/checkout.md" ]
  [ ! -e "$TEST_ROOT/minispec/archive" ]
}

@test "remove --dry-run does not delete anything" {
  run sh "$REPO_ROOT/scripts/ms-remove.sh" "$TEST_ROOT" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would delete"* ]]
  [ -e "$TEST_ROOT/minispec" ]
  [ -f "$TEST_ROOT/AGENTS.md" ]
}

@test "remove without --yes in non-TTY refuses" {
  run sh -c "sh '$REPO_ROOT/scripts/ms-remove.sh' '$TEST_ROOT' < /dev/null"
  [ "$status" -ne 0 ]
  [[ "$output" == *"non-interactively"* ]] || [[ "$output" == *"--yes to proceed"* ]]
}
