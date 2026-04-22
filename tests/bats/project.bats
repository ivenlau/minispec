#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TEST_ROOT="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "detect_node distinguishes next from next-sitemap" {
  cp "$REPO_ROOT/tests/fixtures/next-real/package.json" "$TEST_ROOT/package.json"
  run sh "$REPO_ROOT/scripts/ms-project.sh" "$TEST_ROOT" existing
  [ "$status" -eq 0 ]
  grep -q '^- Framework: Next.js$' "$TEST_ROOT/minispec/project.md"
}

@test "detect_node does NOT match next-sitemap as Next.js" {
  cp "$REPO_ROOT/tests/fixtures/nextish/package.json" "$TEST_ROOT/package.json"
  run sh "$REPO_ROOT/scripts/ms-project.sh" "$TEST_ROOT" existing
  [ "$status" -eq 0 ]
  grep -q '^- Framework: Node.js application$' "$TEST_ROOT/minispec/project.md"
}

@test "detect_python detects FastAPI with ruff" {
  cp "$REPO_ROOT/tests/fixtures/python-fastapi/pyproject.toml" "$TEST_ROOT/pyproject.toml"
  run sh "$REPO_ROOT/scripts/ms-project.sh" "$TEST_ROOT" existing
  [ "$status" -eq 0 ]
  grep -q '^- Framework: FastAPI$' "$TEST_ROOT/minispec/project.md"
  grep -q '^- Lint: ruff check \.$' "$TEST_ROOT/minispec/project.md"
}

@test "fresh project.md has Maintainer Notes with marker" {
  run sh "$REPO_ROOT/scripts/ms-project.sh" "$TEST_ROOT" new
  [ "$status" -eq 0 ]
  grep -q '^## Maintainer Notes' "$TEST_ROOT/minispec/project.md"
  grep -q 'manual-managed; preserved across ms-project regenerations' "$TEST_ROOT/minispec/project.md"
}

@test "regenerate preserves user-added Maintainer Notes entries" {
  run sh "$REPO_ROOT/scripts/ms-project.sh" "$TEST_ROOT" new
  [ "$status" -eq 0 ]
  printf '\n- custom maintainer rule\n' >> "$TEST_ROOT/minispec/project.md"
  run sh "$REPO_ROOT/scripts/ms-project.sh" "$TEST_ROOT" new
  [ "$status" -eq 0 ]
  grep -q '^- custom maintainer rule$' "$TEST_ROOT/minispec/project.md"
}
