#!/usr/bin/env sh
# minispec system-wide installer for Linux / macOS / git-bash / WSL.
#
# One-line install:
#   curl -fsSL https://raw.githubusercontent.com/ivenlau/minispec/main/install.sh | sh
#
# Customise:
#   curl -fsSL .../install.sh | sh -s -- --prefix "$HOME/.local" --ref v0.1.0
#   MINISPEC_REPO=myfork/minispec curl -fsSL .../install.sh | sh
set -eu

REPO_SLUG="${MINISPEC_REPO:-ivenlau/minispec}"
REF="${MINISPEC_REF:-main}"
PREFIX="${MINISPEC_PREFIX:-$HOME/.local}"

print_help() {
  cat <<EOF
minispec installer

Usage: install.sh [options]

Options:
  --prefix <dir>   Install prefix. Default: \$HOME/.local
                   Scripts go to <prefix>/share/minispec,
                   launcher to <prefix>/bin/minispec.
  --repo <slug>    GitHub repo slug. Default: $REPO_SLUG
  --ref <ref>      Git tag or branch to fetch. Default: $REF
  -h, --help       Print this help.

Environment variables (lower precedence than flags):
  MINISPEC_REPO    Same as --repo.
  MINISPEC_REF     Same as --ref.
  MINISPEC_PREFIX  Same as --prefix.

After install:
  minispec --version
  minispec init .
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix) PREFIX="${2:?missing value}"; shift 2 ;;
    --repo)   REPO_SLUG="${2:?missing value}"; shift 2 ;;
    --ref)    REF="${2:?missing value}"; shift 2 ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "install.sh: unknown argument '$1'" >&2; print_help >&2; exit 1 ;;
  esac
done

SHARE_DIR="$PREFIX/share/minispec"
BIN_DIR="$PREFIX/bin"

echo "Installing minispec ($REPO_SLUG@$REF) to $PREFIX ..."

# Pick fetcher
if command -v curl >/dev/null 2>&1; then
  FETCHER="curl"
elif command -v wget >/dev/null 2>&1; then
  FETCHER="wget"
else
  echo "Error: neither curl nor wget is available." >&2
  exit 1
fi

# Need tar to unpack
if ! command -v tar >/dev/null 2>&1; then
  echo "Error: tar is required." >&2
  exit 1
fi

case "$REF" in
  v*|[0-9]*) URL="https://github.com/$REPO_SLUG/archive/refs/tags/$REF.tar.gz" ;;
  *)         URL="https://github.com/$REPO_SLUG/archive/refs/heads/$REF.tar.gz" ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

TARBALL="$TMP/minispec.tar.gz"
case "$FETCHER" in
  curl) curl -fsSL "$URL" -o "$TARBALL" ;;
  wget) wget -q "$URL" -O "$TARBALL" ;;
esac

tar -xzf "$TARBALL" -C "$TMP"
EXTRACTED="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d ! -name '.*' | head -n 1)"
if [ -z "$EXTRACTED" ]; then
  echo "Error: downloaded archive has no top-level directory." >&2
  exit 1
fi

mkdir -p "$BIN_DIR"

# Replace old install atomically-ish: move aside, then install fresh, then drop aside.
if [ -d "$SHARE_DIR" ]; then
  ASIDE="$SHARE_DIR.old.$(date +%s)"
  mv "$SHARE_DIR" "$ASIDE"
fi

mkdir -p "$SHARE_DIR"

for item in scripts minispec .agents .claude bin AGENTS.md CLAUDE.md README.md README.zh-CN.md VERSION LICENSE; do
  src="$EXTRACTED/$item"
  if [ -e "$src" ]; then
    cp -R "$src" "$SHARE_DIR/"
  fi
done

# Drop the previous install once the new one is in place.
if [ -n "${ASIDE:-}" ] && [ -d "$ASIDE" ]; then
  rm -rf "$ASIDE"
fi

# Install the launcher (copy, not symlink — less assumption about filesystems).
cp "$SHARE_DIR/bin/minispec" "$BIN_DIR/minispec"
chmod +x "$BIN_DIR/minispec"

VERSION_STR="$(head -n 1 "$SHARE_DIR/VERSION" 2>/dev/null || echo unknown)"

echo ""
echo "minispec $VERSION_STR installed."
echo "  share:    $SHARE_DIR"
echo "  launcher: $BIN_DIR/minispec"
echo ""

# PATH hint
case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "Next:"
    echo "  minispec --version"
    echo "  minispec init ."
    ;;
  *)
    SHELL_NAME="$(basename "${SHELL:-sh}")"
    case "$SHELL_NAME" in
      zsh) RC="$HOME/.zshrc" ;;
      bash) RC="$HOME/.bashrc" ;;
      fish) RC="$HOME/.config/fish/config.fish" ;;
      *)   RC="your shell rc" ;;
    esac
    echo "Warning: $BIN_DIR is not on your PATH."
    echo "Add this line to $RC (then restart the shell):"
    if [ "$SHELL_NAME" = "fish" ]; then
      echo "  fish_add_path $BIN_DIR"
    else
      echo "  export PATH=\"$BIN_DIR:\$PATH\""
    fi
    echo ""
    echo "After that:"
    echo "  minispec --version"
    echo "  minispec init ."
    ;;
esac
