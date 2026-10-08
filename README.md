# claude-continue-skill

A user-level [Claude Code](https://claude.com/claude-code) action skill that picks up the next Kaneo ticket. Run `/continue` and Claude receives:

```text
/implement Continue next kaneo ticket work, move it to in progress, then commit and create the mr
```

The skill sets `disable-model-invocation: true`, so Claude never loads it on its own. It runs only when you type `/continue`.

## Parallel mode

| Invocation | What happens |
| --- | --- |
| `/continue` | Works the next ticket (default). |
| `/continue parallel` | Works up to 4 independent tickets at once. |
| `/continue parallel <n>` | Works up to `<n>` independent tickets at once. |

In parallel mode Claude:

1. Picks open tickets that are not blocked and should not touch the same area, then shows them with the merge order.
2. Creates one worktree per ticket at `<repo-parent>/<repo-name>-worktrees/<IDENTIFIER>-<desc>`, on branch `<IDENTIFIER>/<desc>`, and moves each ticket to In Progress.
3. Runs one subagent per worktree at the same time. Each one implements, tests, commits, pushes, and opens a PR.
4. Merges the PRs one at a time. Before each merge it pulls the latest default branch into the branch, resolves conflicts, re-runs checks, and waits for CI. Then it moves the ticket to Done.
5. Removes merged worktrees and reports each ticket as merged, open, or blocked.

If a conflict is unclear, checks keep failing, or a PR cannot be merged, the merge loop stops and leaves the remaining PRs open.

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
