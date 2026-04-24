#!/usr/bin/env sh
# Resume the minispec workflow for the current project.
#
# Removes minispec/.paused. Reports how long the pause lasted.
#
# Usage:
#   ms-resume.sh [<root>]
set -eu
unset CDPATH

ROOT="."
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      cat <<'EOF'
Usage: ms-resume.sh [<root>]

Resume minispec ceremony by removing <root>/minispec/.paused.
If there is nothing to resume, prints a friendly notice and exits 0.
EOF
      exit 0
      ;;
    -*) echo "ms-resume.sh: unknown option '$1'" >&2; exit 1 ;;
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

if [ ! -f "$MARKER" ]; then
  echo "minispec is not paused."
  exit 0
fi

paused_ts="$(awk -F': ' '$1=="paused_at"{print $2; exit}' "$MARKER")"
rm -f "$MARKER"

if [ -n "$paused_ts" ]; then
  now_epoch="$(date -u +%s)"
  if prev_epoch="$(parse_epoch "$paused_ts")"; then
    dur="$(fmt_duration $(( now_epoch - prev_epoch )))"
    echo "minispec resumed (was paused for $dur)."
    exit 0
  fi
fi

echo "minispec resumed."
