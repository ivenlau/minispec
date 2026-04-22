#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TEST_ROOT="$(mktemp -d)"
  mkdir -p "$TEST_ROOT/minispec/specs" "$TEST_ROOT/minispec/changes" "$TEST_ROOT/minispec/archive"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

write_card() {
  cat > "$TEST_ROOT/minispec/changes/$1.md"
}

@test "close succeeds when Acceptance is ticked (Plan unchecked)" {
  write_card 20260422-case-a <<EOF
---
id: 20260422-case-a
status: draft
---

# Why

test close succeeds with plan unchecked.

# Acceptance

- [x] Given X When Y Then Z

# Plan

- [ ] T1 still pending
EOF

  run sh "$REPO_ROOT/scripts/ms-close.sh" 20260422-case-a testdomain "$TEST_ROOT"
  [ "$status" -eq 0 ]
  [ -f "$TEST_ROOT/minispec/archive/20260422-case-a.md" ]
  [ ! -f "$TEST_ROOT/minispec/changes/20260422-case-a.md" ]
}

@test "close fails when Acceptance has any unchecked item" {
  write_card 20260422-case-b <<EOF
---
id: 20260422-case-b
status: draft
---

# Acceptance

- [ ] Given unchecked item

# Plan

- [x] T1 done
EOF

  run sh "$REPO_ROOT/scripts/ms-close.sh" 20260422-case-b testdomain "$TEST_ROOT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Acceptance section has unchecked items"* ]]
}

@test "merged spec contains archive cross-reference" {
  write_card 20260422-case-c <<EOF
---
id: 20260422-case-c
status: draft
---

# Why

cross-ref test.

# Acceptance

- [x] Given valid Then ok

# Plan

- [x] T1 done

# Notes

- user note
EOF

  run sh "$REPO_ROOT/scripts/ms-close.sh" 20260422-case-c testdomain "$TEST_ROOT"
  [ "$status" -eq 0 ]
  grep -Fq 'Auto-merged from `minispec/changes/20260422-case-c.md`' "$TEST_ROOT/minispec/specs/testdomain.md"
  grep -Fq 'See `minispec/archive/20260422-case-c.md` for plan and risk notes.' "$TEST_ROOT/minispec/specs/testdomain.md"
}

@test "close refuses when target archive already exists" {
  write_card 20260422-case-d <<EOF
---
id: 20260422-case-d
status: draft
---

# Acceptance

- [x] Given ok Then ok
EOF
  cp "$TEST_ROOT/minispec/changes/20260422-case-d.md" "$TEST_ROOT/minispec/archive/20260422-case-d.md"

  run sh "$REPO_ROOT/scripts/ms-close.sh" 20260422-case-d testdomain "$TEST_ROOT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Archive target already exists"* ]]
}
