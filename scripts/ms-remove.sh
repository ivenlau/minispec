#!/usr/bin/env sh
# Completely remove minispec scaffolding from a project.
#
# Deletes (by default, all of):
#   <target>/AGENTS.md
#   <target>/CLAUDE.md
#   <target>/.agents/
#   <target>/.claude/
#   <target>/minispec/            (including project.md, specs/, changes/, archive/)
# And strips the `# >>> minispec` ... `# <<< minispec` marker block from
# <target>/.gitignore if present.
#
# Usage:
#   ms-remove.sh [<target>] [--yes] [--keep-archive] [--keep-specs] [--dry-run]
set -eu
unset CDPATH

TARGET="."
YES=0
KEEP_ARCHIVE=0
KEEP_SPECS=0
DRY_RUN=0

print_help() {
  cat <<'EOF'
Usage: ms-remove.sh [<target>] [options]

Completely remove minispec from <target>. Interactive by default — you will
see what will be deleted and confirm y/N. Non-TTY environments require --yes.

Options:
  --yes            Skip interactive confirmation.
  --keep-archive   Preserve minispec/archive/ (historical change cards).
  --keep-specs     Preserve minispec/specs/ (domain spec files).
  --dry-run        Print what would be removed, don't delete anything.
  -h, --help       This help.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y) YES=1; shift ;;
    --keep-archive) KEEP_ARCHIVE=1; shift ;;
    --keep-specs) KEEP_SPECS=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) print_help; exit 0 ;;
    -*) echo "ms-remove.sh: unknown option '$1'" >&2; exit 1 ;;
    *)  TARGET="$1"; shift ;;
  esac
done

TARGET="$(cd -- "$TARGET" && pwd)"

if [ ! -d "$TARGET/minispec" ] && [ ! -f "$TARGET/AGENTS.md" ] && [ ! -f "$TARGET/CLAUDE.md" ]; then
  echo "ms-remove: $TARGET has no minispec scaffolding to remove."
  exit 0
fi

# Enumerate what will be touched.
PATHS_TO_DELETE=""
add_delete() {
  p="$1"
  if [ -e "$TARGET/$p" ]; then
    PATHS_TO_DELETE="${PATHS_TO_DELETE}${p}
"
  fi
}

add_delete "AGENTS.md"
add_delete "CLAUDE.md"
add_delete ".agents"
add_delete ".claude"

# Inside minispec/: delete whole tree, optionally preserving subtrees.
if [ "$KEEP_ARCHIVE" -eq 1 ] || [ "$KEEP_SPECS" -eq 1 ]; then
  # Enumerate items inside minispec/ individually, respecting keeps.
  if [ -d "$TARGET/minispec" ]; then
    for entry in "$TARGET/minispec"/* "$TARGET/minispec"/.[!.]*; do
      [ -e "$entry" ] || continue
      name="$(basename "$entry")"
      case "$name" in
        archive)
          [ "$KEEP_ARCHIVE" -eq 1 ] && continue ;;
        specs)
          [ "$KEEP_SPECS" -eq 1 ] && continue ;;
      esac
      PATHS_TO_DELETE="${PATHS_TO_DELETE}minispec/$name
"
    done
  fi
else
  add_delete "minispec"
fi

# Marker block in root .gitignore.
STRIP_MARKER=0
if [ -f "$TARGET/.gitignore" ] && grep -q '^# >>> minispec' "$TARGET/.gitignore"; then
  STRIP_MARKER=1
fi

# Present plan.
echo "Remove minispec scaffolding from $TARGET"
echo
if [ -n "$PATHS_TO_DELETE" ]; then
  echo "Would delete:"
  printf '%s' "$PATHS_TO_DELETE" | sed 's/^/  /'
fi
if [ "$STRIP_MARKER" -eq 1 ]; then
  echo "Would strip:"
  echo "  .gitignore block between '# >>> minispec' and '# <<< minispec'"
fi
if [ "$KEEP_ARCHIVE" -eq 1 ] && [ -d "$TARGET/minispec/archive" ]; then
  echo "Would keep: minispec/archive/ (--keep-archive)"
fi
if [ "$KEEP_SPECS" -eq 1 ] && [ -d "$TARGET/minispec/specs" ]; then
  echo "Would keep: minispec/specs/ (--keep-specs)"
fi
echo

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry-run complete. Re-run without --dry-run (with --yes or in a TTY) to apply."
  exit 0
fi

if [ "$YES" -eq 0 ]; then
  if [ ! -t 0 ]; then
    echo "ms-remove: running non-interactively — pass --yes to proceed." >&2
    exit 1
  fi
  printf 'Continue? [y/N] '
  read -r answer
  case "$answer" in
    y|Y|yes|YES) : ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

# Execute.
printf '%s' "$PATHS_TO_DELETE" | while IFS= read -r p; do
  [ -n "$p" ] || continue
  rm -rf "${TARGET:?}/${p:?}"
  echo "removed: $p"
done

if [ "$STRIP_MARKER" -eq 1 ]; then
  tmp="$(mktemp)"
  awk '
    /^# >>> minispec/ { in_block=1; next }
    in_block && /^# <<< minispec/ { in_block=0; next }
    in_block { next }
    { print }
  ' "$TARGET/.gitignore" > "$tmp"
  # Collapse trailing blank lines.
  awk '
    { lines[NR]=$0 }
    END {
      last=NR
      while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--
      for (i=1; i<=last; i++) print lines[i]
    }
  ' "$tmp" > "$TARGET/.gitignore"
  rm -f "$tmp"
  echo "stripped: .gitignore minispec marker block"
fi

echo
echo "minispec removed from $TARGET."
