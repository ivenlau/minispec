#!/usr/bin/env sh
set -eu

ROOT="${1:-.}"
ROOT="$(cd "$ROOT" && pwd)"

fail=0

check_required() {
  path="$1"
  kind="$2"
  label="$3"
  full="$ROOT/$path"
  if [ "$kind" = "dir" ]; then
    if [ -d "$full" ]; then
      echo "[OK] $path ($label)"
    else
      echo "[MISSING] $path ($label)"
      fail=1
    fi
    return
  fi

  if [ -f "$full" ]; then
    echo "[OK] $path ($label)"
  else
    echo "[MISSING] $path ($label)"
    fail=1
  fi
}

check_optional() {
  path="$1"
  kind="$2"
  label="$3"
  full="$ROOT/$path"
  if [ "$kind" = "dir" ]; then
    if [ -d "$full" ]; then
      echo "[OK] $path ($label)"
    else
      echo "[WARN] $path ($label)"
    fi
    return
  fi

  if [ -f "$full" ]; then
    echo "[OK] $path ($label)"
  else
    echo "[WARN] $path ($label)"
  fi
}

echo "minispec doctor"
echo "root: $ROOT"

check_required "minispec" "dir" "minispec root"
check_required "minispec/project.md" "file" "project contract"
check_required "minispec/specs" "dir" "canonical specs directory"
check_required "minispec/changes" "dir" "active changes directory"
check_required "minispec/archive" "dir" "archive directory"
check_required "minispec/templates/change.md" "file" "change template"

check_optional "AGENTS.md" "file" "Codex workflow entry"
check_optional "CLAUDE.md" "file" "Claude workflow entry"
check_optional ".agents/skills/minispec/SKILL.md" "file" "Codex minispec skill"
check_optional ".claude/skills/minispec/SKILL.md" "file" "Claude minispec skill"

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "Result: FAIL"
  exit 2
fi

echo ""
echo "Result: PASS"
exit 0

