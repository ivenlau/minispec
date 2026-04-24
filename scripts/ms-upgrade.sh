#!/usr/bin/env sh
# Refresh agent-side minispec files in an existing project from the installed
# CLI share directory. Never touches business data under minispec/.
#
# Usage:
#   ms-upgrade.sh [<target>] [--dry-run] [--include-template]
#                 [--include-gitignore] [--include-canonical-skill]
#                 [--source <share-dir>]
set -eu
unset CDPATH

TARGET="."
DRY_RUN=0
INCLUDE_TEMPLATE=0
INCLUDE_GITIGNORE=0
INCLUDE_CANONICAL_SKILL=0
SOURCE_DIR=""

print_help() {
  cat <<'EOF'
Usage: ms-upgrade.sh [<target>] [options]

Refresh minispec agent files in <target> from the installed share directory
(or from --source). Default refreshes only agent entry + skill files.

Files always refreshed:
  <target>/AGENTS.md
  <target>/CLAUDE.md
  <target>/.agents/skills/minispec/SKILL.md
  <target>/.claude/skills/minispec/SKILL.md

Files NEVER touched (your business data):
  <target>/minispec/project.md
  <target>/minispec/specs/*.md
  <target>/minispec/changes/*.md
  <target>/minispec/archive/*.md

Options:
  --include-template          Also refresh minispec/templates/change.md.
  --include-gitignore         Also refresh minispec/.gitignore.
  --include-canonical-skill   Also drop minispec/SKILL.md (canonical source).
  --source <dir>              Override source. Default: auto-detected from
                              script location ($MINISPEC_HOME or share dir).
  --dry-run                   Print what would change, don't write.
  -h, --help                  This help.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --include-template) INCLUDE_TEMPLATE=1; shift ;;
    --include-gitignore) INCLUDE_GITIGNORE=1; shift ;;
    --include-canonical-skill) INCLUDE_CANONICAL_SKILL=1; shift ;;
    --source) SOURCE_DIR="${2:?missing value}"; shift 2 ;;
    -h|--help) print_help; exit 0 ;;
    -*) echo "ms-upgrade.sh: unknown option '$1'" >&2; exit 1 ;;
    *)  TARGET="$1"; shift ;;
  esac
done

if [ -z "$SOURCE_DIR" ]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
  SOURCE_DIR="${MINISPEC_HOME:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
fi

if [ ! -d "$SOURCE_DIR" ] || [ ! -d "$SOURCE_DIR/.claude/skills/minispec" ]; then
  echo "ms-upgrade: source directory does not look like a minispec install: $SOURCE_DIR" >&2
  exit 1
fi

TARGET="$(cd -- "$TARGET" && pwd)"

if [ ! -d "$TARGET/minispec" ]; then
  echo "ms-upgrade: $TARGET is not a minispec project (no minispec/ directory). Run 'minispec init' first." >&2
  exit 1
fi

copy_file() {
  rel="$1"
  src="$SOURCE_DIR/$rel"
  dst="$TARGET/$rel"
  if [ ! -f "$src" ]; then
    echo "  skip: source missing: $rel"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
      echo "  unchanged: $rel"
    else
      echo "  would update: $rel"
    fi
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  updated: $rel"
}

echo "Upgrading minispec in $TARGET"
echo "Source: $SOURCE_DIR"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "(dry run)"
fi
echo

echo "Agent files:"
copy_file "AGENTS.md"
copy_file "CLAUDE.md"
copy_file ".agents/skills/minispec/SKILL.md"
copy_file ".claude/skills/minispec/SKILL.md"

if [ "$INCLUDE_TEMPLATE" -eq 1 ]; then
  echo
  echo "Template:"
  copy_file "minispec/templates/change.md"
fi

if [ "$INCLUDE_GITIGNORE" -eq 1 ]; then
  echo
  echo "minispec/.gitignore:"
  copy_file "minispec/.gitignore"
fi

if [ "$INCLUDE_CANONICAL_SKILL" -eq 1 ]; then
  echo
  echo "Canonical skill:"
  copy_file "minispec/SKILL.md"
fi

echo
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry-run complete. Re-run without --dry-run to apply."
else
  echo "Upgrade complete. Business data in minispec/project.md, specs/, changes/, archive/ was not touched."
fi
