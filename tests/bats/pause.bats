#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TEST_ROOT="$(mktemp -d)"
  mkdir -p "$TEST_ROOT/minispec"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "pause creates .paused marker with paused_at" {
  run sh "$REPO_ROOT/scripts/ms-pause.sh" "$TEST_ROOT"
  [ "$status" -eq 0 ]
  [ -f "$TEST_ROOT/minispec/.paused" ]
  grep -q '^paused_at: ' "$TEST_ROOT/minispec/.paused"
}

@test "pause --reason writes reason into the marker" {
  run sh "$REPO_ROOT/scripts/ms-pause.sh" "$TEST_ROOT" --reason "debug loop"
  [ "$status" -eq 0 ]
  grep -q '^reason: debug loop$' "$TEST_ROOT/minispec/.paused"
}

@test "pause is idempotent — second call reports 'already paused'" {
  sh "$REPO_ROOT/scripts/ms-pause.sh" "$TEST_ROOT" > /dev/null
  original="$(cat "$TEST_ROOT/minispec/.paused")"
  sleep 1
  run sh "$REPO_ROOT/scripts/ms-pause.sh" "$TEST_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already paused"* ]]
  [ "$(cat "$TEST_ROOT/minispec/.paused")" = "$original" ]
}

@test "resume removes the marker and reports duration" {
  sh "$REPO_ROOT/scripts/ms-pause.sh" "$TEST_ROOT" > /dev/null
  [ -f "$TEST_ROOT/minispec/.paused" ]
  run sh "$REPO_ROOT/scripts/ms-resume.sh" "$TEST_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"resumed"* ]]
  [ ! -f "$TEST_ROOT/minispec/.paused" ]
}

@test "resume without an existing marker reports 'not paused'" {
  run sh "$REPO_ROOT/scripts/ms-resume.sh" "$TEST_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"not paused"* ]]
}

@test "doctor does NOT WARN about pause within 4 hours" {
  # Create a pause marker with a very recent timestamp.
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'paused_at: %s\n' "$ts" > "$TEST_ROOT/minispec/.paused"
  mkdir -p "$TEST_ROOT/minispec/specs" "$TEST_ROOT/minispec/changes" "$TEST_ROOT/minispec/archive" "$TEST_ROOT/minispec/templates"
  cp "$REPO_ROOT/minispec/templates/change.md" "$TEST_ROOT/minispec/templates/change.md"
  printf '# Project\n' > "$TEST_ROOT/minispec/project.md"

  run sh "$REPO_ROOT/scripts/ms-doctor.sh" "$TEST_ROOT"
  [[ "$output" != *"has been paused for"* ]]
}

@test "doctor WARNs about pause older than 4 hours" {
  # GNU date is available in bats-core CI (ubuntu + macOS via brew coreutils? —
  # fall back gracefully if not).
  if ! old_ts="$(date -u -d '5 hours ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"; then
    if ! old_ts="$(date -u -v -5H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"; then
      skip "no supported date flavour to synthesise '5 hours ago'"
    fi
  fi
  printf 'paused_at: %s\n' "$old_ts" > "$TEST_ROOT/minispec/.paused"
  mkdir -p "$TEST_ROOT/minispec/specs" "$TEST_ROOT/minispec/changes" "$TEST_ROOT/minispec/archive" "$TEST_ROOT/minispec/templates"
  cp "$REPO_ROOT/minispec/templates/change.md" "$TEST_ROOT/minispec/templates/change.md"
  printf '# Project\n' > "$TEST_ROOT/minispec/project.md"

  run sh "$REPO_ROOT/scripts/ms-doctor.sh" "$TEST_ROOT"
  [[ "$output" == *"has been paused for"* ]]
}

@test "ms-init drops minispec/.gitignore excluding .paused" {
  run sh "$REPO_ROOT/scripts/ms-init.sh" "$TEST_ROOT" --no-gitignore
  [ "$status" -eq 0 ]
  [ -f "$TEST_ROOT/minispec/.gitignore" ]
  grep -q '^\.paused$' "$TEST_ROOT/minispec/.gitignore"
}
