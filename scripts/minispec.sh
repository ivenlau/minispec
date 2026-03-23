#!/usr/bin/env sh
set -eu

ACTION="${1:-}"

if [ -z "$ACTION" ]; then
  echo "Usage: minispec.sh <init|doctor|project|close> [args...]"
  exit 1
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

run_ps() {
  if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -File "$@"
    return
  fi
  if command -v powershell >/dev/null 2>&1; then
    powershell -NoProfile -File "$@"
    return
  fi
  echo "PowerShell is required to run this command." >&2
  exit 2
}

run_sh_or_ps() {
  sh_script="$1"
  shift
  if [ -f "$sh_script" ]; then
    sh "$sh_script" "$@"
    return
  fi
  run_ps "$@"
}

case "$ACTION" in
  init)
    ROOT="${2:-.}"
    run_sh_or_ps "$SCRIPT_DIR/ms-init.sh" "$SCRIPT_DIR/ms-init.ps1" -Root "$ROOT"
    ;;
  doctor)
    ROOT="${2:-.}"
    run_sh_or_ps "$SCRIPT_DIR/ms-doctor.sh" "$SCRIPT_DIR/ms-doctor.ps1" -Root "$ROOT"
    ;;
  project)
    ROOT="${2:-.}"
    CONTEXT=""
    MODE="auto"
    if [ "$#" -ge 3 ]; then
      case "${3:-}" in
        auto|existing|new)
          MODE="$3"
          if [ "$#" -gt 3 ]; then
            shift 3
            CONTEXT="$*"
          fi
          ;;
        *)
          shift 2
          CONTEXT="$*"
          ;;
      esac
    fi
    if [ -f "$SCRIPT_DIR/ms-project.sh" ]; then
      if [ -n "$CONTEXT" ]; then
        sh "$SCRIPT_DIR/ms-project.sh" "$ROOT" "$MODE" "$CONTEXT"
      else
        sh "$SCRIPT_DIR/ms-project.sh" "$ROOT" "$MODE"
      fi
    else
      run_ps "$SCRIPT_DIR/ms-project.ps1" -Root "$ROOT" -Mode "$MODE" -Context "$CONTEXT"
    fi
    ;;
  close)
    CHANGE_ID="${2:-}"
    DOMAIN="${3:-}"
    ROOT="${4:-.}"
    if [ -z "$CHANGE_ID" ] || [ -z "$DOMAIN" ]; then
      echo "Usage: minispec.sh close <change-id> <domain> [root]"
      exit 1
    fi
    if [ -f "$SCRIPT_DIR/ms-close.sh" ]; then
      sh "$SCRIPT_DIR/ms-close.sh" "$CHANGE_ID" "$DOMAIN" "$ROOT"
    else
      run_ps "$SCRIPT_DIR/ms-close.ps1" -ChangeId "$CHANGE_ID" -Domain "$DOMAIN" -Root "$ROOT"
    fi
    ;;
  *)
    echo "Unknown action '$ACTION'. Use: init | doctor | project | close"
    exit 1
    ;;
esac
