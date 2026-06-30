#!/usr/bin/env bash
# Refuse commits in the main repo checkout when other worktrees are active,
# unless every staged file is in the harness/coordination allowlist.
#
# Why: branches cut in the main checkout inherit uncommitted work from
# concurrent worktree sessions, which then leaks into your PR. The main
# checkout is for harness/config coordination; implementation goes in a
# worktree (the superpowers:using-git-worktrees skill creates one).
set -euo pipefail

# Bypass is uniform via the omakase-gate.sh wrapper: OMAKASE_SKIP_WORKTREE_DISCIPLINE=1
# skips this gate (audited) before the step runs — no in-script escape hatch needed.

# Only fires inside a git repo.
git rev-parse --show-toplevel >/dev/null 2>&1 || exit 0

# Need at least 2 worktrees (main + at least one other) for this to fire.
WORKTREE_COUNT=$(git worktree list --porcelain | grep -c '^worktree ' || echo 0)
[ "$WORKTREE_COUNT" -le 1 ] && exit 0

# Main checkout is the first entry from `git worktree list`.
THIS_ROOT=$(git rev-parse --show-toplevel)
MAIN_ROOT=$(git worktree list --porcelain | awk '/^worktree / {sub(/^worktree /, ""); print; exit}')

# In a linked worktree — let the commit proceed.
[ "$THIS_ROOT" != "$MAIN_ROOT" ] && exit 0

# We're in the main checkout AND other worktrees are active.
# Every staged path must be in the allowlist — including deletions (D) and
# renames (R), which leak from concurrent worktrees the same way adds/mods do.
STAGED=$(git diff --cached --name-only --diff-filter=ACMRD)
[ -z "$STAGED" ] && exit 0

DISALLOWED=()
while IFS= read -r f; do
  case "$f" in
    AGENTS.md|CLAUDE.md)
      ;;
    .claude/*)
      ;;
    *)
      # Allow root-level *.md (no slash in the path).
      if [[ "$f" == *.md && "$f" != *"/"* ]]; then
        :
      else
        DISALLOWED+=("$f")
      fi
      ;;
  esac
done <<< "$STAGED"

[ "${#DISALLOWED[@]}" -eq 0 ] && exit 0

OTHER_COUNT=$((WORKTREE_COUNT - 1))
echo "" >&2
echo "ERROR: Commits in the main checkout are restricted while ${OTHER_COUNT} other worktree(s) are active." >&2
echo "" >&2
echo "Allowed in the main checkout: AGENTS.md, CLAUDE.md, .claude/**, root-level *.md" >&2
echo "Disallowed files in this commit:" >&2
for f in "${DISALLOWED[@]}"; do
  echo "  - $f" >&2
done
echo "" >&2
echo "Branches cut in the main checkout inherit unpushed work from concurrent sessions," >&2
echo "which leaks into your PR. For implementation work, create a worktree:" >&2
echo "" >&2
echo "    Use the superpowers:using-git-worktrees skill" >&2
echo "" >&2
echo "Escape hatch (rare, document the reason in the commit body):" >&2
echo "    OMAKASE_SKIP_WORKTREE_DISCIPLINE=1 git commit ..." >&2
echo "" >&2
exit 1
