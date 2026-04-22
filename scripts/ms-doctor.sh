#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

case "${1:-}" in
  --version|-v)
    if [ -f "$REPO_ROOT/VERSION" ]; then
      cat "$REPO_ROOT/VERSION"
    else
      echo "unknown"
    fi
    exit 0
    ;;
esac

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

echo ""
echo "Semantic checks:"

sem_warn() {
  echo "[WARN] $1"
}

# 1. TBD placeholders in project.md
if [ -f "$ROOT/minispec/project.md" ]; then
  if grep -qE '\bTBD\b' "$ROOT/minispec/project.md"; then
    sem_warn "minispec/project.md: still contains TBD placeholders."
  fi
fi

# Compute staleness cutoff (14 days ago in YYYYMMDD). Skip staleness check if neither GNU nor BSD date supports the flag.
CUTOFF_YMD=""
if cutoff_try="$(date -d '14 days ago' +%Y%m%d 2>/dev/null)"; then
  CUTOFF_YMD="$cutoff_try"
elif cutoff_try="$(date -v -14d +%Y%m%d 2>/dev/null)"; then
  CUTOFF_YMD="$cutoff_try"
fi

# Iterate change cards
if [ -d "$ROOT/minispec/changes" ]; then
  for f in "$ROOT"/minispec/changes/*.md; do
    [ -f "$f" ] || continue
    bn="$(basename "$f" .md)"
    rel="minispec/changes/$bn.md"

    if ! printf '%s' "$bn" | grep -Eq '^[0-9]{8}-[a-z0-9-]+$'; then
      sem_warn "$rel: filename does not match YYYYMMDD-slug pattern."
    fi

    status="$(awk '
      NR==1 && $0=="---" { in_fm=1; next }
      in_fm && $0=="---" { exit }
      in_fm && /^status:[[:space:]]*/ {
        sub(/^status:[[:space:]]*/, "")
        print
        exit
      }
    ' "$f")"

    case "$status" in
      draft|in_progress|closed|"") : ;;
      *) sem_warn "$rel: unknown status '$status' (expected draft|in_progress|closed)." ;;
    esac

    if [ -z "$status" ]; then
      sem_warn "$rel: frontmatter has no status field."
    fi

    if [ "$status" = "draft" ] && [ -n "$CUTOFF_YMD" ]; then
      date_part="$(printf '%s' "$bn" | cut -c1-8)"
      if printf '%s' "$date_part" | grep -Eq '^[0-9]{8}$' && [ "$date_part" -lt "$CUTOFF_YMD" ]; then
        sem_warn "$rel: draft since $date_part (>14 days); consider closing or updating."
      fi
    fi
  done
fi

# SKILL Guardrails parity across canonical + mirrors
skill_paths="$ROOT/minispec/SKILL.md $ROOT/.claude/skills/minispec/SKILL.md $ROOT/.agents/skills/minispec/SKILL.md"
extract_guardrails() {
  awk '
    /^## Guardrails[[:space:]]*$/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section { print }
  ' "$1"
}
guard_hashes=""
for sp in $skill_paths; do
  if [ -f "$sp" ]; then
    h="$(extract_guardrails "$sp" | tr -d '\r' | sha256sum 2>/dev/null | awk '{print $1}')"
    guard_hashes="${guard_hashes}${h}
"
  fi
done
unique_count=$(printf '%s' "$guard_hashes" | sed '/^$/d' | sort -u | wc -l | tr -d ' ')
if [ "${unique_count:-0}" -gt 1 ]; then
  sem_warn "SKILL files have out-of-sync '## Guardrails' sections (canonical: minispec/SKILL.md)."
fi

# Cross-ref archive vs specs
if [ -d "$ROOT/minispec/archive" ]; then
  for f in "$ROOT"/minispec/archive/*.md; do
    [ -f "$f" ] || continue
    bn="$(basename "$f" .md)"
    found=0
    if [ -d "$ROOT/minispec/specs" ]; then
      for sf in "$ROOT"/minispec/specs/*.md; do
        [ -f "$sf" ] || continue
        if grep -Eq "^##[[:space:]]+Change[[:space:]]+$bn([[:space:]]|$)" "$sf"; then
          found=1
          break
        fi
      done
    fi
    if [ "$found" -eq 0 ]; then
      sem_warn "minispec/archive/$bn.md: no matching '## Change $bn' in any minispec/specs/*.md."
    fi
  done
fi

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "Result: FAIL"
  exit 2
fi

echo ""
echo "Result: PASS"
exit 0

