#!/usr/bin/env sh
# Pause the minispec workflow for the current project.
#
# Creates minispec/.paused (a two-line YAML-ish file with paused_at and
# optional reason). While the marker exists, agents should treat user
# requests as normal coding tasks and skip the new/apply/check/close
# ceremony. See SKILL.md "Pause Awareness".
#
# Usage:
#   ms-pause.sh [<root>] [--reason "<text>"]
set -eu
unset CDPATH

ROOT="."
REASON=""

while [ $# -gt 0 ]; do
  case "$1" in
    --reason) REASON="${2:-}"; shift 2 ;;
    --reason=*) REASON="${1#--reason=}"; shift ;;
    -h|--help)
      cat <<'EOF'
Usage: ms-pause.sh [<root>] [--reason "<text>"]

Pause minispec ceremony for <root> (default: .). Creates
<root>/minispec/.paused so subsequent agent interactions treat
requests as normal coding tasks. Use ms-resume.sh to undo.
EOF
      exit 0
      ;;
    -*) echo "ms-pause.sh: unknown option '$1'" >&2; exit 1 ;;
    *)  ROOT="$1"; shift ;;
  esac
done

ROOT="$(cd -- "$ROOT" && pwd)"
MARKER="$ROOT/minispec/.paused"

fmt_duration() {
  secs="$1"
  hours=$(( secs / 3600 ))
  minutes=$(( (secs % 3600) / 60 ))
  printf '%dh %dm' "$hours" "$minutes"
}

parse_epoch() {
  ts="$1"
  if e="$(date -u -d "$ts" +%s 2>/dev/null)"; then
    printf '%s' "$e"; return 0
  fi
  if e="$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null)"; then
    printf '%s' "$e"; return 0
  fi
  return 1
}

if [ ! -d "$ROOT/minispec" ]; then
  echo "ms-pause: no minispec/ directory at $ROOT (run 'minispec init' first)" >&2
  exit 1
fi

if [ -f "$MARKER" ]; then
  existing_ts="$(awk -F': ' '$1=="paused_at"{print $2; exit}' "$MARKER")"
  if [ -n "$existing_ts" ]; then
    now_epoch="$(date -u +%s)"
    if prev_epoch="$(parse_epoch "$existing_ts")"; then
      dur="$(fmt_duration $(( now_epoch - prev_epoch )))"
      echo "minispec already paused since $existing_ts ($dur ago)."
    else
      echo "minispec already paused since $existing_ts."
    fi
  else
    echo "minispec already paused (marker exists)."
  fi
  exit 0
fi

paused_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  printf 'paused_at: %s\n' "$paused_at"
  if [ -n "$REASON" ]; then
    printf 'reason: %s\n' "$REASON"
  fi
} > "$MARKER"

if [ -n "$REASON" ]; then
  echo "minispec paused at $paused_at (reason: $REASON)."
else
  echo "minispec paused at $paused_at."
fi
echo "Run 'minispec resume' to re-enable the workflow."
