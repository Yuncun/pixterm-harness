---
name: pixterm-free-bug-hunt
description: Untargeted UI bug hunt against the editor. Use when the user says "find UI bugs", "look for issues", "hunt for problems" without naming a specific area. Drives agent-browser through the editor curiosity-first, dedupes against the rolling bug-hunt log so each session covers different ground, presents findings sorted for human triage before any fix-team spawn.
allowed-tools: Bash Read Write Edit Grep Glob
---

# /pixterm-free-bug-hunt

Curiosity-driven bug hunt. There is no pre-committed checklist. The only constraint is **don't repeat what was exercised recently** — that's what `.claude/state/bug-hunt-log.txt` is for.

## Procedure

### 1. Pre-flight

- Read `.claude/state/bug-hunt-log.txt` — the recent tail (last 30-ish entries) is your "already covered" set. Anything in the log is fair to skip; anything not in it is fair to chase.
- If `:8888` is already serving a pixterm editor (`curl -sI http://localhost:8888/` → 200 HTML), reuse it. Otherwise boot:

  ```bash
  PIXTERM_BACKEND=mock \
    PIXTERM_OUTPUT=$(git rev-parse --show-toplevel)/output \
    .venv/bin/python -m pixterm.webapp >/tmp/pixterm-bughunt-logs/server.log 2>&1 &
  ```

  Wait for `Application startup complete`. If `GET /` returns 404, kill and restart (known race with `_DIST_DIR` resolution).

- Pick a character. `lofi-girl-induced-v5` is the default test character; switch if the user named one.

### 2. Hunt

Free exploration via `agent-browser`. No fixed sequence. Use the recent log to _avoid_ repeats, not to dictate moves. Productive things to try when stuck for ideas:

- A panel / tab you haven't seen recently per the log.
- A user gesture nobody's tested (drag, multi-select, keyboard shortcut, escape).
- An edge case: empty graph, longest character name, special chars, very-zoomed-out, very-zoomed-in.
- A boundary condition: rapid clicks, state during navigation, mid-playback edits.
- Inspect: `agent-browser console`, `agent-browser network requests`, HTTP cache headers.
- Cross-reference: API behavior vs UI display (today's biggest wins came from this).

As you exercise something, **immediately append a one-liner to the log** so the next session knows:

```
echo "$(date +%Y-%m-%d)  <freeform description of what was poked>" >> .claude/state/bug-hunt-log.txt
```

### 3. Stop conditions

Stop when **any** of these hit:

- **8–15 findings** filed (with severity), AND no obvious next thing screaming "look at me."
- **15 scenarios in a row** exercised cleanly with no finding (diminishing returns).
- **Context approaching 300k tokens** (safety cap — leaves room for the triage handoff).

Don't extend past 15 findings just because you can — quality > volume, and the triage step gets harder as the list grows.

### 4. Prune the log

After hunting, before writing findings, trim `.claude/state/bug-hunt-log.txt` to the most recent 200 data lines (preserve header):

```bash
log=.claude/state/bug-hunt-log.txt
{ head -n 5 "$log"; grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}" "$log" | tail -n 200; } > "$log.tmp" && mv "$log.tmp" "$log"
```

### 5. Write findings

`/tmp/pixterm-bughunt/FINDINGS-YYYY-MM-DD.md`. Group by severity (High / Medium / Low). Each finding:

- one-line repro
- expected vs observed
- file:line citation when you can trace it
- screenshot path if useful

Mirror the shape of prior sessions in `/tmp/pixterm-bughunt/`. Inline screenshots are fine when they make a point.

### 6. Triage checkpoint (REQUIRED — do not skip)

Present the findings to the user as a numbered list, sorted High → Low. For each:

- one-line summary
- severity
- (if known) the smallest plausible fix location

Then **stop and ask**:

> "Which of these should the fix team pick up? (e.g. `1,3,7` or `all high` or `none`)"

Wait for the answer. Do not spawn a fix team without explicit user selection.

### 7. Fix-team handoff (only when user has selected)

If the user picked findings to fix:

- Write a focused brief at `/tmp/pixterm-bughunt/FIXLIST-YYYY-MM-DD.md` with only the selected findings, file:line cites, and any constraints (e.g. "don't refactor surrounding code").
- Spawn a fix team via `agent-teams:team-feature` (or `agent-teams:team-spawn` with appropriate preset), pointing it at the FIXLIST and a fresh worktree.
- Hand control back; don't follow the team yourself.

If the user said "none," stop. Findings file stays on disk for later.

## Anti-patterns

- **Don't follow a pre-made checklist.** The whole point of this skill is that today's hunt looks different from yesterday's. The log is a dedup filter, not a script.
- **Don't fix bugs in this skill.** Hunt-then-write. Fixes happen in the spawned team.
- **Don't skip the triage checkpoint.** Auto-spawning a fix team on every finding burns cycles on noise. The human decides what's worth a code change.
- **Don't claim coverage you don't have.** "Exercised" means you reproduced the user gesture and observed the result. Reading the code doesn't count.
- **Don't pad the log.** One entry per genuinely-distinct surface. "I clicked Settings" is one entry; "I tested Settings backend dropdown, credentials, ComfyUI status, theme, FPS, duration" is also one entry (the panel).
