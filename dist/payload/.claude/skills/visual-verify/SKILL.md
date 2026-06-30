---
name: visual-verify
description: Best-effort visual verification of UI work. Boots the running editor in an isolated stack, generates its own 10–20+ scenarios (weighted to stateful, multi-step sequences), drives agent-browser through each, judges PASS/FAIL/ERROR from screenshots, prints a one-line-per-scenario scorecard, and records a pass (only when clean) for the pre-push deferred gate. Invoke at done-time on UI work; Claude may self-invoke before claiming completion (per ADR-0033).
allowed-tools: Bash(agent-browser *) Bash(make *) Bash(git log:*) Bash(git show:*) Bash(git diff:*) Bash(gh pr view:*) Bash(pnpm *) Bash(lsof:*) Bash(curl:*) Bash(kill:*) Bash(.omakase/bin/omakase-gate.sh:*) Read Grep
context: fork
---

# /visual-verify — Visual Verification

You are the **Evaluator**. You did not write the code. Your job is to drive the
running editor like a skeptical user and report what actually renders — not what
the code "should" do. If you catch yourself reasoning "the code looks fine,"
stop: you are here to look at pixels, not read source.

You drive the UI and judge it; you print a scorecard and, when it renders clean,
**record a pass** that the pre-push deferred gate reads (Step 7). You do not write a
commit or a trailer, and you do not block anything yourself — the gate enforces your
recorded pass at push time (ADR `visual-verify-pre-push-enforcement`). The scorecard is
still for a human to skim; the recorded pass is what the gate checks.

## The one rule: never break

The run must survive anything. The editor failing to boot, one scenario erroring
mid-way, agent-browser losing its session — none of that aborts the run. Mark
that line **ERROR** with a one-line reason and move on. **The scorecard always
prints, a pass is recorded only when clean (Step 7), and cleanup (Step 8) always runs.** A half-finished run that prints 12
honest rows beats a clean crash that prints nothing.

## Procedure

### 1. Orient

Confirm you're in the right tree, and see what changed so you can weight
scenarios toward it (you still generate broadly — the diff only tilts emphasis):

```bash
git rev-parse --show-toplevel
git branch --show-current
git diff --stat origin/master..HEAD -- 'apps/web/' 'packages/' 2>/dev/null
```

If nothing UI-related changed on this branch, say so and exit — there is nothing
to verify. Otherwise note the touched area (e.g. "subgraph collapse",
"right-panel", "floating player") and continue.

### 2. Boot the editor (isolated, parallel-safe)

Each run uses its own port, browser session, and output dir so concurrent runs
across worktrees don't collide. State is written to a per-worktree env file
because each Bash call gets a fresh shell — every later snippet `source`s it.
(Per `ADR verify-ui-parallel-safe`; `pixterm.webapp` honors `PIXTERM_PORT`.)

```bash
PORT=8888
while lsof -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; do PORT=$((PORT+1)); done
SESSION="visual-verify-$(basename "$PWD")"
STATE="/tmp/visual-verify-$(basename "$PWD").env"
export PIXTERM_OUTPUT="$PWD/output"
export PIXTERM_PORT="$PORT"
HEADED_FLAG=""
[ "${VISUAL_VERIFY_HEADED:-}" = "1" ] && HEADED_FLAG="--headed"

PIXTERM_BACKEND=mock .venv/bin/python -m pixterm.webapp &
WEBAPP_PID=$!
disown "$WEBAPP_PID" 2>/dev/null || true

cat > "$STATE" <<EOF
PORT=$PORT
SESSION="$SESSION"
HEADED_FLAG="$HEADED_FLAG"
WEBAPP_PID=$WEBAPP_PID
EOF

until curl -s "http://localhost:$PORT/healthz" > /dev/null; do sleep 0.5; done
echo "visual-verify boot: port=$PORT session=$SESSION pid=$WEBAPP_PID"
```

If the boot loop never becomes ready (e.g. ~30s pass), stop waiting, print the
boot error as a single ERROR scorecard row, record NOTHING (Step 7 — nothing was
verified, so the gate stays blocked), run Step 8 cleanup, and exit.

### 3. Get something to drive

Stateful scenarios need a populated graph. Snapshot first and work with whatever
the editor actually shows — don't assume:

```bash
source "/tmp/visual-verify-$(basename "$PWD").env"
agent-browser open "http://localhost:$PORT" --session "$SESSION" $HEADED_FLAG
agent-browser snapshot --session "$SESSION"
```

- If a graph already exists (sidebar lists one, or the diff added fixtures), open it.
- If the editor is empty, create a graph through the welcome flow and add a few
  poses / an edge so there is real state to exercise (a couple of nodes, one
  edge, and — if the touched area needs it — a folder/subgraph or a filled clip).
- If you can't get any usable graph after a reasonable try, record that as an
  ERROR row and still run whatever scenarios you can (plus cleanup).

Bias the seeded state toward the touched area from Step 1 (subgraph work → make a
folder with members; player work → fill a clip; panel work → open the panel).

### 4. Generate the scenario list (10–20+, weighted stateful)

Write a numbered list of scenarios **before** you run them. Aim for **10–20+,
more if the area is rich.** Weight heavily toward **stateful, multi-step
sequences** — that is where real bugs live, and what single-action checks miss.
For every "does X render?" include several "do X, then Y, then look" chains.

Draw from these families (generalize them to whatever you're verifying):

- **Repetition & churn** — do the same toggle/action 5× fast; does final state +
  any persisted flag agree? Rapid do-then-undo before an async save round-trips —
  any flicker or snap-back?
- **Persistence boundaries** — do X, reload immediately (even mid-action); does
  last-persisted state win, nothing torn? Do X, go Home, re-enter; reloads from
  disk correctly?
- **Multiple instances & nesting** — act on A, act on B, undo A; independent?
  Nested structures toggled in one order then reversed — no orphans?
- **Cross-view convergence** — change in tab 1, switch tabs / open-in-new-tab,
  toggle there, return; do all views converge?
- **Concurrent / external change** — do X, then trigger an unrelated change (a
  job finishes, an edge is added, a filter hides members); is X silently
  reverted? Add/delete a member while X is active — counts/labels update, no
  dangling state?
- **Selection × state interplay** — select something, then mutate its container;
  do selection + detail panel resolve cleanly (no stranded dead node)? Escape
  semantics consistent across states, with and without a selection?

Single-action sanity checks (does the view render, does the modal open/dismiss)
are fine as a few rows — but they are the floor, not the bulk.

### 5. Run each scenario — robustly

For each scenario, in order. Every snippet starts by sourcing the state file
(Bash calls don't share shell state). Pass `--session "$SESSION"` on every
`agent-browser` call so parallel runs stay isolated.

```bash
source "/tmp/visual-verify-$(basename "$PWD").env"
agent-browser snapshot --session "$SESSION"          # refs for this state
agent-browser click @e<N> --session "$SESSION"
agent-browser fill @e<N> "value" --session "$SESSION"
agent-browser screenshot /tmp/visual-verify/<slug>-<step>.png --session "$SESSION"
```

Then **Read the screenshot PNG** with the Read tool. This puts the rendered
pixels in your context — you cannot Read a PNG and credibly deny what's on it.
That is the load-bearing primitive of this skill. Judge:

- **PASS** — rendered behavior matches the scenario's expectation.
- **FAIL** — it doesn't. Record one line "saw" / one line "expected" + the PNG path.
- **ERROR** — the scenario couldn't complete (couldn't reach a control, session
  died, timeout). One line why. Never let an ERROR abort the rest of the run.

Judge only from what you saw on screen — never pass a scenario because the code
"should" work.

### 6. Scorecard

Print one line per scenario, then a tally:

```
visual-verify scorecard — <touched area>   (editor: http://localhost:$PORT)
=========================================================================
  1. [PASS]  Collapse → expand → collapse the same subgraph 5×; final state + flag agree
  2. [FAIL]  Reload mid-churn → last-persisted wins · saw: reverted to box · /tmp/visual-verify/s2.png
  3. [ERROR] Two windows converge on refresh · agent-browser session dropped
  …
-------------------------------------------------------------------------
  N scenarios · P PASS · F FAIL · E ERROR
```

Surface any FAIL/ERROR rows first in your summary. The scorecard is the
deliverable — a legible record for a human to skim, not a proof. An LLM judge can
false-PASS (rubber-stamp, hallucinate "I see X", race a screenshot); say so if a
verdict is shaky rather than rounding up.

### 7. Record the pass (for the pre-push gate)

Record a pass so the pre-push deferred gate can read it (ADR
`visual-verify-pre-push-enforcement`). The gate primitive is injected by the
`pixterm-harness` plugin at `.omakase/bin/` (run `/omakase init` if it is
missing). Record a pass **only** when the UI was actually verified clean. Run
from the repo root:

```bash
.omakase/bin/omakase-gate.sh visual-verify --record
```

- **pass** (record it) — at least one scenario produced a real PASS or FAIL verdict
  (the UI was actually exercised) **and** no FAIL row remains.
- **fail or all-ERROR** — record **nothing**. Any FAIL, or an all-ERROR run that
  verified nothing, must leave the push blocked (no recorded pass = blocked).
  Print why, fix, then re-run (a fresh pass unblocks the re-push at the same commit).
- A FAIL you judge to be a judge error (not a real bug) is just a corrected verdict:
  dismiss it with your reasoning, then record the pass. To push past a block you have
  a documented reason to override, do not fake a pass — use the audited bypass
  `OMAKASE_SKIP_VISUAL_VERIFY=1 git push` (announced at push time, never silent).

Do not record a pass on the early-exit paths in Steps 2–3: if the editor never boots
or no usable graph can be made, nothing was verified, so leave the gate blocked.

### 8. Cleanup — always

Run on every path (PASS, FAIL, ERROR, early exit). Kills the backend from Step 2
and closes the browser session, so leaked processes don't accumulate.

```bash
source "/tmp/visual-verify-$(basename "$PWD").env" 2>/dev/null || exit 0
agent-browser close --session "$SESSION" 2>/dev/null
kill "$WEBAPP_PID" 2>/dev/null
rm -f "/tmp/visual-verify-$(basename "$PWD").env"
```

If interrupted before this runs, the backend leaks until reboot or manual
`pkill -f pixterm.webapp`; the next run's port walk-forward skips the held port.

## Scope

- Runs against `PIXTERM_BACKEND=mock` only. Real backends are out of scope.
- Does not author regression tests (that's the UI-regression suite,
  `make ui-regression`) and does not run other gates.
- If the change is non-UI (no `apps/web/`, `packages/*-control/`, or
  `packages/right-panel-control/` files in the diff), don't invoke this — report
  and exit.

## When this skill struggles

- **Wrong checkout:** Step 1 shows `master`/`main` or commits that aren't the
  work you meant to verify. Recovery: `cd` into the right worktree, re-invoke.
- **agent-browser not installed:** report and ask the user to install it.
- **Editor won't boot / no usable graph:** record it as an ERROR row, run
  cleanup, exit — don't pretend a PASS.
- **A scenario keeps erroring:** mark it ERROR, keep going. Partial honest
  coverage is the goal, not all-green theater.
