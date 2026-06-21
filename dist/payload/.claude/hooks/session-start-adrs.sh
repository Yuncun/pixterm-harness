#!/usr/bin/env bash
# Print the 5 most recent live ADRs as session context.
# Wired in .claude/settings.json as a SessionStart hook.
# "Live" = Status is Accepted or Proposed. Superseded and Deprecated ADRs
# are historical and should not be framed as "don't contradict".
set -euo pipefail

ADR_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/docs/adr"
[[ -d "$ADR_DIR" ]] || exit 0

# Walk ADR files (legacy NNNN-* and new YYYY-MM-DD-*) newest first, keeping
# only Accepted/Proposed, until we have 5.
ADRS=""
count=0
for adr in $(ls "$ADR_DIR" 2>/dev/null | grep -E '^[0-9]{4}-.+\.md$' | sort -nr); do
  file="$ADR_DIR/$adr"
  status=$(grep -m1 '^Status: ' "$file" 2>/dev/null | sed 's/^Status: //' || echo "")
  case "$status" in
    Accepted|Proposed)
      ADRS+="$adr"$'\n'
      count=$((count + 1))
      [[ $count -ge 5 ]] && break
      ;;
  esac
done

[[ -n "$ADRS" ]] || exit 0

# Reverse so the list reads oldest → newest within the 5-window.
ADRS=$(printf '%s' "$ADRS" | tail -r 2>/dev/null || printf '%s' "$ADRS" | awk '{a[NR]=$0} END {for(i=NR;i>0;i--) print a[i]}')

echo "## Recent architectural decisions (ADRs)"
echo ""
echo "The 5 most recent live ADRs (Accepted/Proposed) from \`docs/adr/\`. Read the full file before contradicting any of these — if you need to deviate, write a new ADR explicitly superseding the old one. Run \`/adr-new \"Title\"\` to create one."
echo ""

while IFS= read -r adr; do
  [[ -z "$adr" ]] && continue
  file="$ADR_DIR/$adr"
  title=$(grep -m1 '^# ' "$file" 2>/dev/null | sed 's/^# //' || echo "$adr")
  status=$(grep -m1 '^Status: ' "$file" 2>/dev/null | sed 's/^Status: //' || echo "Unknown")
  date=$(grep -m1 '^Date: ' "$file" 2>/dev/null | sed 's/^Date: //' || echo "")
  echo "- **${title}** (${date}, ${status}) — \`docs/adr/${adr}\`"
done <<< "$ADRS"

echo ""
echo "Format: see \`.claude/rules/adrs.md\`. Full list: \`ls docs/adr/\`."
