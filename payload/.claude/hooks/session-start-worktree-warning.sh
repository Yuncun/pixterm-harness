#!/usr/bin/env bash
# When the session starts in the main repo checkout AND other worktrees exist,
# emit a system reminder telling Claude to use a worktree before implementation.
# Wired in .claude/settings.json as a SessionStart hook. See ADR-0034.
set -euo pipefail

git rev-parse --show-toplevel >/dev/null 2>&1 || exit 0

WORKTREE_COUNT=$(git worktree list --porcelain | grep -c '^worktree ' || echo 0)
[ "$WORKTREE_COUNT" -le 1 ] && exit 0

# Main checkout is conventionally the first entry from `git worktree list`.
THIS_ROOT=$(git rev-parse --show-toplevel)
MAIN_ROOT=$(git worktree list --porcelain | awk '/^worktree / {sub(/^worktree /, ""); print; exit}')

# In a worktree already — nothing to warn about.
[ "$THIS_ROOT" != "$MAIN_ROOT" ] && exit 0

OTHER_COUNT=$((WORKTREE_COUNT - 1))

cat <<EOF
## Other worktrees are active

You are in the **main repo checkout** with ${OTHER_COUNT} other active worktree(s). For implementation work (anything beyond \`CLAUDE.md\`, \`.claude/\`, or root-level doc edits), use the \`superpowers:using-git-worktrees\` skill to create a worktree first. The main checkout is for harness/config coordination when others are working — branches you create here can pick up uncommitted work from concurrent sessions.

Active worktrees:
EOF

git worktree list | sed 's/^/- `/' | sed 's/$/`/'
