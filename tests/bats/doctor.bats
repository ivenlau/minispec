#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TEST_ROOT="$(mktemp -d)"
  mkdir -p "$TEST_ROOT/minispec/specs" "$TEST_ROOT/minispec/changes" \
           "$TEST_ROOT/minispec/archive" "$TEST_ROOT/minispec/templates"
  printf '# Project Contract\n\n## Stack\n- Language: TBD\n' > "$TEST_ROOT/minispec/project.md"
  cp "$REPO_ROOT/minispec/templates/change.md" "$TEST_ROOT/minispec/templates/change.md"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "doctor fails fast when minispec root is missing" {
  rm -rf "$TEST_ROOT/minispec"
  run sh "$REPO_ROOT/scripts/ms-doctor.sh" "$TEST_ROOT"
  [ "$status" -eq 2 ]
  [[ "$output" == *"MISSING"* ]]
}

@test "doctor PASS (exit 0) but WARNs on TBD placeholders" {
  run sh "$REPO_ROOT/scripts/ms-doctor.sh" "$TEST_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"still contains TBD"* ]]
  [[ "$output" == *"Result: PASS"* ]]
}

@test "doctor WARNs on bad-name.md in changes/" {
  printf -- "---\nid: bad\nstatus: draft\n---\n" > "$TEST_ROOT/minispec/changes/bad-name.md"
  run sh "$REPO_ROOT/scripts/ms-doctor.sh" "$TEST_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"filename does not match YYYYMMDD-slug"* ]]
}

@test "doctor WARNs on unknown status in frontmatter" {
  cat > "$TEST_ROOT/minispec/changes/20260421-weird.md" <<EOF
---
id: 20260421-weird
status: stalled
---
EOF
  run sh "$REPO_ROOT/scripts/ms-doctor.sh" "$TEST_ROOT"
  [[ "$output" == *"unknown status 'stalled'"* ]]
}

@test "doctor WARNs on orphan archive without matching spec" {
  cat > "$TEST_ROOT/minispec/archive/20260422-orphan.md" <<EOF
---
id: 20260422-orphan
status: closed
---
EOF
  run sh "$REPO_ROOT/scripts/ms-doctor.sh" "$TEST_ROOT"
  [[ "$output" == *"no matching '## Change 20260422-orphan'"* ]]
}

@test "doctor does NOT WARN when all three SKILL Guardrails match" {
  mkdir -p "$TEST_ROOT/.claude/skills/minispec" "$TEST_ROOT/.agents/skills/minispec"
  for f in \
    "$TEST_ROOT/minispec/SKILL.md" \
    "$TEST_ROOT/.claude/skills/minispec/SKILL.md" \
    "$TEST_ROOT/.agents/skills/minispec/SKILL.md"; do
    cat > "$f" <<EOF
# test skill

## Guardrails

- rule A
- rule B
EOF
  done

  run sh "$REPO_ROOT/scripts/ms-doctor.sh" "$TEST_ROOT"
  [[ "$output" != *"out-of-sync '## Guardrails'"* ]]
}

@test "doctor WARNs when one SKILL Guardrails section drifts" {
  mkdir -p "$TEST_ROOT/.claude/skills/minispec" "$TEST_ROOT/.agents/skills/minispec"

  cat > "$TEST_ROOT/minispec/SKILL.md" <<EOF
# canonical

## Guardrails

- rule A
- rule B
EOF

  cat > "$TEST_ROOT/.claude/skills/minispec/SKILL.md" <<EOF
# claude mirror

## Guardrails

- rule A
- rule B
EOF

  cat > "$TEST_ROOT/.agents/skills/minispec/SKILL.md" <<EOF
# agents mirror

## Guardrails

- rule A
- rule B
- rule C (drift)
EOF

  run sh "$REPO_ROOT/scripts/ms-doctor.sh" "$TEST_ROOT"
  [[ "$output" == *"out-of-sync '## Guardrails'"* ]]
}
