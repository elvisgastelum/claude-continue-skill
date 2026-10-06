#!/usr/bin/env bash
# Installs the `/continue` action skill for Claude Code at user (system) level.
# Idempotent: re-run any time to resync with the repo; an unchanged file is left alone.
#
#   curl -fsSL https://raw.githubusercontent.com/elvisgastelum/claude-continue-skill/main/install.sh | bash
#
# Options (env vars):
#   CLAUDE_DIR=~/.claude   target Claude config directory
#   REPO=owner/name        GitHub repo to download from
#   REF=main               branch or tag to download from
#
# Uninstall:
#   curl -fsSL .../install.sh | bash -s -- --uninstall
set -euo pipefail

REPO="${REPO:-elvisgastelum/claude-continue-skill}"
REF="${REF:-main}"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
RAW="https://raw.githubusercontent.com/$REPO/$REF"

SKILL_DIR="$CLAUDE_DIR/skills/continue"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/claude-continue-skill.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

# Use local files when run from a clone, otherwise download them.
SRC_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/skills/continue/SKILL.md" ]; then
  SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

fetch() { # fetch <repo-relative-path> <dest>
  mkdir -p "$(dirname "$2")"
  if [ -n "$SRC_DIR" ]; then
    cp "$SRC_DIR/$1" "$2"
  else
    curl -fsSL "$RAW/$1" -o "$2" || die "failed to download $RAW/$1"
  fi
}

replace_if_changed() { # replace_if_changed <new> <dest>: back up and rewrite dest only when content differs
  if [ -f "$2" ] && cmp -s "$1" "$2"; then
    return 1
  fi
  [ -f "$2" ] && cp "$2" "$2.bak.$(date +%Y%m%d%H%M%S)"
  mkdir -p "$(dirname "$2")"
  # Write through instead of mv so a symlinked dest (e.g. from a dotfiles repo) stays a symlink.
  cat "$1" > "$2" || die "failed to write $2"
}

uninstall() {
  info "Removing $SKILL_DIR"
  rm -rf "$SKILL_DIR"
  info "Uninstalled."
}

install() {
  info "Installing continue skill to $SKILL_DIR"
  fetch skills/continue/SKILL.md "$TMP_DIR/SKILL.md"
  replace_if_changed "$TMP_DIR/SKILL.md" "$SKILL_DIR/SKILL.md" || info "$SKILL_DIR/SKILL.md already up to date"
  info "Done. Restart Claude Code, then run /continue."
}

case "${1:-}" in
  --uninstall|uninstall) uninstall ;;
  ""|--install|install) install ;;
  *) die "unknown argument: $1 (use --uninstall)" ;;
esac
