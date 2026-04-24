#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TEST_ROOT="$(mktemp -d)"
  sh "$REPO_ROOT/scripts/ms-init.sh" "$TEST_ROOT" --no-gitignore > /dev/null
  # Plant business content that must NOT be overwritten.
  mkdir -p "$TEST_ROOT/minispec/specs" "$TEST_ROOT/minispec/changes" "$TEST_ROOT/minispec/archive"
  printf 'MY REAL PROJECT CONTRACT' > "$TEST_ROOT/minispec/project.md"
  printf 'my canonical spec' > "$TEST_ROOT/minispec/specs/checkout.md"
  printf 'draft card' > "$TEST_ROOT/minispec/changes/20260424-active.md"
  printf 'archived card' > "$TEST_ROOT/minispec/archive/20260423-done.md"
  # Stomp on an agent file so upgrade has something to refresh.
  printf 'OUTDATED AGENT FILE' > "$TEST_ROOT/AGENTS.md"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "upgrade refreshes AGENTS.md from source" {
  run sh "$REPO_ROOT/scripts/ms-upgrade.sh" "$TEST_ROOT" --source "$REPO_ROOT"
  [ "$status" -eq 0 ]
  # AGENTS.md should now match the upstream version, not the "OUTDATED" text.
  ! grep -q 'OUTDATED AGENT FILE' "$TEST_ROOT/AGENTS.md"
  cmp -s "$REPO_ROOT/AGENTS.md" "$TEST_ROOT/AGENTS.md"
}

@test "upgrade leaves project.md untouched" {
  sh "$REPO_ROOT/scripts/ms-upgrade.sh" "$TEST_ROOT" --source "$REPO_ROOT" > /dev/null
  [ "$(cat "$TEST_ROOT/minispec/project.md")" = "MY REAL PROJECT CONTRACT" ]
}

@test "upgrade leaves specs/changes/archive untouched" {
  sh "$REPO_ROOT/scripts/ms-upgrade.sh" "$TEST_ROOT" --source "$REPO_ROOT" > /dev/null
  [ "$(cat "$TEST_ROOT/minispec/specs/checkout.md")" = "my canonical spec" ]
  [ "$(cat "$TEST_ROOT/minispec/changes/20260424-active.md")" = "draft card" ]
  [ "$(cat "$TEST_ROOT/minispec/archive/20260423-done.md")" = "archived card" ]
}

@test "upgrade --dry-run does not modify files" {
  printf 'OUTDATED AGENT FILE' > "$TEST_ROOT/AGENTS.md"
  run sh "$REPO_ROOT/scripts/ms-upgrade.sh" "$TEST_ROOT" --source "$REPO_ROOT" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would update"* ]]
  [ "$(cat "$TEST_ROOT/AGENTS.md")" = "OUTDATED AGENT FILE" ]
}

@test "upgrade --include-template refreshes change.md template" {
  printf 'outdated template' > "$TEST_ROOT/minispec/templates/change.md"
  sh "$REPO_ROOT/scripts/ms-upgrade.sh" "$TEST_ROOT" --source "$REPO_ROOT" --include-template > /dev/null
  cmp -s "$REPO_ROOT/minispec/templates/change.md" "$TEST_ROOT/minispec/templates/change.md"
}
