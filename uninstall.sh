#!/usr/bin/env sh
# minispec system-wide uninstaller (Linux / macOS / WSL / git-bash).
#
# Removes:
#   - The `minispec` launcher at <prefix>/bin/minispec
#   - The share directory at <prefix>/share/minispec
#
# One-line uninstall:
#   curl -fsSL https://raw.githubusercontent.com/ivenlau/minispec/main/uninstall.sh | sh -s -- --yes
set -eu
unset CDPATH

PREFIX="${MINISPEC_PREFIX:-$HOME/.local}"
YES=0
DRY_RUN=0

print_help() {
  cat <<EOF
Usage: uninstall.sh [options]

Remove the globally-installed minispec command. Does NOT touch any
project directory that uses minispec — run 'minispec remove <dir>'
for that.

Options:
  --prefix <dir>   Install prefix. Default: \$HOME/.local
  --yes            Skip interactive confirmation.
  --dry-run        Print what would be removed, don't touch anything.
  -h, --help       This help.

Environment:
  MINISPEC_PREFIX  Same as --prefix.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix) PREFIX="${2:?missing value}"; shift 2 ;;
    --yes|-y) YES=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "uninstall.sh: unknown argument '$1'" >&2; exit 1 ;;
  esac
done

SHARE_DIR="$PREFIX/share/minispec"
LAUNCHER="$PREFIX/bin/minispec"

has_anything=0
[ -d "$SHARE_DIR" ] && has_anything=1
[ -f "$LAUNCHER" ] && has_anything=1

if [ "$has_anything" -eq 0 ]; then
  echo "uninstall.sh: nothing to remove at prefix $PREFIX"
  exit 0
fi

echo "Uninstall minispec from $PREFIX"
echo
echo "Would remove:"
[ -f "$LAUNCHER" ] && echo "  $LAUNCHER"
[ -d "$SHARE_DIR" ] && echo "  $SHARE_DIR"
echo

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry-run complete. Re-run without --dry-run (with --yes or in a TTY) to apply."
  exit 0
fi

if [ "$YES" -eq 0 ]; then
  if [ ! -t 0 ]; then
    echo "uninstall.sh: running non-interactively — pass --yes to proceed." >&2
    exit 1
  fi
  printf 'Continue? [y/N] '
  read -r answer
  case "$answer" in
    y|Y|yes|YES) : ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

if [ -f "$LAUNCHER" ]; then
  rm -f "$LAUNCHER"
  echo "removed: $LAUNCHER"
fi
if [ -d "$SHARE_DIR" ]; then
  rm -rf "$SHARE_DIR"
  echo "removed: $SHARE_DIR"
fi

echo
echo "minispec uninstalled."
echo "Tip: projects that used minispec still contain their minispec/ directory and"
echo "agent files. Run 'minispec remove <dir>' (before uninstalling) if you want"
echo "to clean those up too."
