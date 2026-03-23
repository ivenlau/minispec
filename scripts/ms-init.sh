#!/usr/bin/env sh
set -eu

ROOT="${1:-.}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

if [ ! -d "$ROOT" ]; then
  mkdir -p "$ROOT"
fi

ensure_text_file() {
  rel_path="$1"
  src_rel="$2"
  default_content="$3"
  target_path="$ROOT/$rel_path"
  src_path="$REPO_ROOT/$src_rel"

  if [ -f "$target_path" ]; then
    return
  fi

  parent_dir="$(dirname "$target_path")"
  mkdir -p "$parent_dir"

  if [ -f "$src_path" ]; then
    cp "$src_path" "$target_path"
    return
  fi

  printf '%s\n' "$default_content" > "$target_path"
}

mkdir -p \
  "$ROOT/minispec/specs" \
  "$ROOT/minispec/changes" \
  "$ROOT/minispec/archive" \
  "$ROOT/minispec/templates" \
  "$ROOT/.agents/skills/minispec" \
  "$ROOT/.claude/skills/minispec"

ensure_text_file "minispec/templates/change.md" "minispec/templates/change.md" "$(cat <<'EOF'
---
id: YYYYMMDD-short-slug
status: draft
owner: your-name
---

# Why

Describe the problem and business impact in one short paragraph.

# Scope

- In:
- Out:

# Acceptance

- [ ] Given ... When ... Then ...
- [ ] Given ... When ... Then ...

# Plan

- [ ] T1 Update files:
  - Expected output:
- [ ] T2 Add or adjust tests:
  - Expected output:
- [ ] T3 Update docs/spec:
  - Expected output:

# Risks and Rollback

- Risk:
- Rollback:

# Notes

- Optional implementation notes.
EOF
)"

ensure_text_file "minispec/specs/README.md" "minispec/specs/README.md" "$(cat <<'EOF'
# Canonical Specs

Store shipped behavior here by domain.
EOF
)"

ensure_text_file "minispec/changes/.gitkeep" "minispec/changes/.gitkeep" ""
ensure_text_file "minispec/archive/.gitkeep" "minispec/archive/.gitkeep" ""
ensure_text_file ".agents/skills/minispec/SKILL.md" ".agents/skills/minispec/SKILL.md" "# minispec

Lightweight spec-first workflow for code changes."
ensure_text_file ".claude/skills/minispec/SKILL.md" ".claude/skills/minispec/SKILL.md" "# minispec

Lightweight spec-first workflow for code changes."
ensure_text_file "AGENTS.md" "AGENTS.md" "# AGENTS"
ensure_text_file "CLAUDE.md" "CLAUDE.md" "# CLAUDE"

echo "minispec directories and scaffold files ensured at: $ROOT"
