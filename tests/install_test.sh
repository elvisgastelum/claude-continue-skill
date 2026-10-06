#!/usr/bin/env bash
# Exercises install.sh against throwaway CLAUDE_DIRs.
#   ./tests/install_test.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
SKILL=skills/continue/SKILL.md
FAILS=0

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; FAILS=$((FAILS + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

run() { CLAUDE_DIR="$1" "$ROOT/install.sh" "${@:2}" >/dev/null 2>&1; }
fresh() { rm -rf "$WORK/$1"; mkdir -p "$WORK/$1"; echo "$WORK/$1"; }
backups() { find "$1" -name '*.bak.*' | wc -l | tr -d ' '; }

# Fresh install into an empty dir.
d="$(fresh empty)"
run "$d"
check "fresh install copies the skill" "cmp -s '$ROOT/$SKILL' '$d/$SKILL'"
check "skill is manual only" "grep -qx 'disable-model-invocation: true' '$d/$SKILL'"

# Re-run is a no-op.
n="$(backups "$d")"
run "$d"
check "re-run makes no new backups" "[ \"\$(backups '$d')\" = '$n' ]"

# Local edits are resynced, with a backup.
echo 'tampered' > "$d/$SKILL"
run "$d"
check "edited skill is restored" "cmp -s '$ROOT/$SKILL' '$d/$SKILL'"
check "edited skill is backed up" "[ \"\$(backups '$d')\" = 1 ]"

# Uninstall removes the skill and leaves the rest alone.
d="$(fresh roundtrip)"
mkdir -p "$d/skills/other" && echo keep > "$d/skills/other/SKILL.md"
run "$d" && run "$d" --uninstall
check "uninstall removes the skill" "[ ! -e '$d/skills/continue' ]"
check "uninstall keeps other skills" "grep -qx keep '$d/skills/other/SKILL.md'"

# A symlinked skill file stays a symlink.
d="$(fresh symlink)"
mkdir -p "$WORK/dotfiles" "$d/skills/continue"
echo old > "$WORK/dotfiles/SKILL.md"
ln -s "$WORK/dotfiles/SKILL.md" "$d/$SKILL"
run "$d"
check "symlinked skill stays a symlink" "[ -L '$d/$SKILL' ] && cmp -s '$ROOT/$SKILL' '$WORK/dotfiles/SKILL.md'"

# Unknown arguments fail.
check "unknown argument is rejected" "! run '$(fresh badarg)' --bogus"

# No temp files leak.
mkdir -p "$WORK/tmp"
TMPDIR="$WORK/tmp" run "$(fresh tmpcheck)"
check "no temp files left behind" "[ -z \"\$(ls -A '$WORK/tmp')\" ]"

echo
[ "$FAILS" = 0 ] && echo "all tests passed" || { echo "$FAILS test(s) failed"; exit 1; }
