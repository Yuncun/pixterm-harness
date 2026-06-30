#!/usr/bin/env bash
# Reject commits that modify a declared architectural file without a paired new
# ADR (a new docs/adr/*.md added in the same commit).
#
# PROJECT-AGNOSTIC by parameterization: the list of architectural files is read
# from $HARNESS_ARCH_FILES (space-separated). UNSET OR EMPTY = DORMANT (exit 0
# immediately), so a project that keeps no ADRs is opted out by doing nothing.
# A project opts in by declaring the files via a per-script env override in its
# lefthook.yml — see AGENTS.md and HARNESS.md. Create ADRs
# with /adr-new.
set -euo pipefail

# Bypass is uniform via the omakase-gate.sh wrapper: OMAKASE_SKIP_ADR_REQUIRED=1 skips
# this gate (audited) before the step runs — no in-script escape hatch needed.

# Dormant unless the project declares its architectural files.
read -r -a ARCHITECTURAL_FILES <<< "${HARNESS_ARCH_FILES:-}"
[[ ${#ARCHITECTURAL_FILES[@]} -eq 0 ]] && exit 0

# Staged files, including Deleted (D) and Renamed (R): deleting or renaming an
# architectural file is itself an architectural change that needs an ADR.
STAGED=$(git diff --cached --name-only --diff-filter=ACMRD)

TOUCHED_ARCH=()
for f in "${ARCHITECTURAL_FILES[@]}"; do
  if echo "$STAGED" | grep -qx "$f"; then
    TOUCHED_ARCH+=("$f")
  fi
done

# Nothing architectural touched — pass.
[[ ${#TOUCHED_ARCH[@]} -eq 0 ]] && exit 0

# Architectural files touched — require a NEW ADR file (Added) in this commit.
NEW_ADR=$(git diff --cached --name-only --diff-filter=A | grep -E '^docs/adr/[^/]+\.md$' || true)
if [[ -n "$NEW_ADR" ]]; then
  exit 0
fi

# Fail loud.
echo "" >&2
echo "ERROR: This commit modifies architectural files without a paired ADR." >&2
echo "" >&2
echo "Architectural files modified:" >&2
for f in "${TOUCHED_ARCH[@]}"; do
  echo "  - $f" >&2
done
echo "" >&2
echo "Architectural changes require an ADR documenting the decision." >&2
echo "Run:    /adr-new \"Decision title\"" >&2
echo "Then:   git add docs/adr/<filename>.md && git commit ..." >&2
echo "" >&2
echo "Override (rare, for trivial edits): OMAKASE_SKIP_ADR_REQUIRED=1 git commit ..." >&2
echo "Document the override reason in the commit body." >&2
echo "" >&2
exit 1
