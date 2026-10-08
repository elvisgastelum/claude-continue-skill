# claude-continue-skill

A user-level [Claude Code](https://claude.com/claude-code) action skill that picks up the next Kaneo ticket. Run `/continue` and Claude receives:

```text
/implement Continue next kaneo ticket work, move it to in progress, then commit and create the mr

Name this session as soon as you understand its goal, before starting any work. When a Kaneo ticket is selected, base the name on that ticket: its identifier plus a short description of the work, such as `FEX-2: Add login rate limiting`. When no Kaneo ticket is selected, base the name on the current work being done.
```

The skill sets `disable-model-invocation: true`, so Claude never loads it on its own. It runs only when you type `/continue`.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/elvisgastelum/claude-continue-skill/main/install.sh | bash
```

Restart Claude Code afterwards. The installer is idempotent: re-run the same command any time to resync with the repo. If the installed file already matches, it is left untouched and no backup is made.

## What it installs

| Piece | Location | Purpose |
| --- | --- | --- |
| `continue` skill | `~/.claude/skills/continue/SKILL.md` | Manual `/continue` action. It is never auto-invoked. |

## Options

```bash
# Install from a fork or tag
curl -fsSL .../install.sh | REPO=you/claude-continue-skill REF=v1.0.0 bash

# Custom Claude config directory
curl -fsSL .../install.sh | CLAUDE_DIR=/path/to/.claude bash
```

Requires `bash` and `curl`.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/elvisgastelum/claude-continue-skill/main/install.sh | bash -s -- --uninstall
```

## Local development

```bash
git clone https://github.com/elvisgastelum/claude-continue-skill
cd claude-continue-skill
./install.sh              # copies local files instead of downloading
./tests/install_test.sh   # installs into throwaway dirs and checks idempotency
```
