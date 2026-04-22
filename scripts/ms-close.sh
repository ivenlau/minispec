#!/usr/bin/env sh
set -eu

CHANGE_ID="${1:-}"
DOMAIN="${2:-}"
ROOT="${3:-.}"

if [ -z "$CHANGE_ID" ] || [ -z "$DOMAIN" ]; then
  echo "Usage: ms-close.sh <change-id> <domain> [root]"
  exit 1
fi

ROOT="$(cd "$ROOT" && pwd)"
CHANGE_PATH="$ROOT/minispec/changes/$CHANGE_ID.md"
ARCHIVE_PATH="$ROOT/minispec/archive/$CHANGE_ID.md"
SPEC_PATH="$ROOT/minispec/specs/$DOMAIN.md"

if [ ! -f "$CHANGE_PATH" ]; then
  echo "Change file not found: $CHANGE_PATH" >&2
  exit 1
fi

extract_section() {
  heading="$1"
  file="$2"
  awk -v h="$heading" '
    $0 ~ "^# " h "[[:space:]]*$" { in_section=1; next }
    in_section && $0 ~ "^# " { exit }
    in_section { print }
  ' "$file"
}

ACCEPTANCE_BLOCK="$(extract_section "Acceptance" "$CHANGE_PATH")"
if printf '%s' "$ACCEPTANCE_BLOCK" | grep -Eq '^[[:space:]]*-[[:space:]]*\[[[:space:]]\][[:space:]]+'; then
  echo "Cannot close change. Acceptance section has unchecked items." >&2
  exit 1
fi

trim_trailing_blank_lines() {
  awk '
    { lines[NR] = $0 }
    END {
      last = NR
      while (last > 0 && lines[last] ~ /^[[:space:]]*$/) { last-- }
      for (i = 1; i <= last; i++) print lines[i]
    }
  '
}

WHY="$(extract_section "Why" "$CHANGE_PATH" | trim_trailing_blank_lines)"
SCOPE="$(extract_section "Scope" "$CHANGE_PATH" | trim_trailing_blank_lines)"
ACCEPTANCE="$(extract_section "Acceptance" "$CHANGE_PATH" | trim_trailing_blank_lines)"
NOTES="$(extract_section "Notes" "$CHANGE_PATH" | trim_trailing_blank_lines)"
DATE_TEXT="$(date +%Y-%m-%d)"

mkdir -p "$(dirname "$SPEC_PATH")" "$(dirname "$ARCHIVE_PATH")"

if [ ! -f "$SPEC_PATH" ]; then
  {
    echo "# $DOMAIN"
    echo
    echo "Canonical shipped behavior for domain: $DOMAIN"
    echo
  } > "$SPEC_PATH"
fi

if grep -Eq "^##[[:space:]]+Change[[:space:]]+$CHANGE_ID([[:space:]]|$)" "$SPEC_PATH"; then
  echo "Change '$CHANGE_ID' already merged in spec file: $SPEC_PATH" >&2
  exit 1
fi

{
  echo
  echo "## Change $CHANGE_ID ($DATE_TEXT)"
  echo
  echo "### Why"
  if [ -n "$WHY" ]; then printf '%s\n' "$WHY"; fi
  echo
  echo "### Scope"
  if [ -n "$SCOPE" ]; then printf '%s\n' "$SCOPE"; fi
  echo
  echo "### Acceptance"
  if [ -n "$ACCEPTANCE" ]; then printf '%s\n' "$ACCEPTANCE"; fi
  echo
  echo "### Notes"
  echo "- Auto-merged from \`minispec/changes/$CHANGE_ID.md\`"
  echo "- See \`minispec/archive/$CHANGE_ID.md\` for plan and risk notes."
  if [ -n "$NOTES" ]; then
    printf '%s\n' "$NOTES"
  else
    echo "- No additional notes."
  fi
} >> "$SPEC_PATH"

TMP_CHANGE="$(mktemp "${TMPDIR:-/tmp}/ms-close-change.XXXXXX")"

if awk 'NR==1 && $0=="---" { exit 0 } NR==1 { exit 1 } END { if (NR==0) exit 1 }' "$CHANGE_PATH"; then
  awk '
    BEGIN { in_fm = 0; status_set = 0 }
    NR == 1 && $0 == "---" { in_fm = 1; print; next }
    in_fm == 1 {
      if ($0 ~ /^status:[[:space:]]*/) { print "status: closed"; status_set = 1; next }
      if ($0 == "---") {
        if (status_set == 0) print "status: closed"
        print
        in_fm = 0
        next
      }
      print
      next
    }
    { print }
  ' "$CHANGE_PATH" > "$TMP_CHANGE"
else
  {
    echo "---"
    echo "status: closed"
    echo "---"
    echo
    cat "$CHANGE_PATH"
  } > "$TMP_CHANGE"
fi

mv "$TMP_CHANGE" "$CHANGE_PATH"

if [ -e "$ARCHIVE_PATH" ]; then
  echo "Archive target already exists: $ARCHIVE_PATH" >&2
  exit 1
fi

mv "$CHANGE_PATH" "$ARCHIVE_PATH"

echo "Closed change: $CHANGE_ID"
echo "Merged spec: minispec/specs/$DOMAIN.md"
echo "Archived card: minispec/archive/$CHANGE_ID.md"

