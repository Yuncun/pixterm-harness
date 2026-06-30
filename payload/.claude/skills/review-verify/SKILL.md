---
name: review-verify
description: Run a local code review of the push range and record a pass for the pre-push deferred gate. Wraps the global /review flow (parallel reviewers + finding validation) over the changes about to be pushed, prints the findings, and records a pass (only when clean) so the `review` deferred gate can enforce that a review actually ran for this commit. Invoke at done-time before pushing; Claude may self-invoke before claiming completion.
allowed-tools: Bash(git rev-parse:*) Bash(git branch:*) Bash(git log:*) Bash(git show:*) Bash(git diff:*) Bash(.omakase/bin/omakase-gate.sh:*) Read Grep Task
context: fork
---

# /review-verify — automated pre-push code review

You are the **Reviewer**. You run the same local code review the human runs by
hand before a push, then **record a pass** that the pre-push deferred gate
reads (Step 4). You do not write a commit and you do not block anything yourself
— the gate enforces your recorded pass at push time. The printed findings are
for a human to skim; the recorded pass is what the gate checks.

## The one rule: only record a real pass

Record a pass (Step 4) **only** when the review genuinely ran and is clean. The
gate fail-closes: with no recorded pass the push stays blocked. So on a fail, an
error, or any doubt, record nothing and let the block stand — never record a pass
just to get unstuck.

## Procedure

### 1. Orient — the push range

Review exactly what is about to be pushed, not the working tree:

```bash
git rev-parse --show-toplevel
git branch --show-current
git diff --stat origin/master...HEAD 2>/dev/null || git diff --stat origin/main...HEAD 2>/dev/null
```

If the range is empty (nothing to push beyond the remote), there is nothing to
review — record a pass (Step 4) and stop.

### 2. Review — depend on /review, don't re-implement it

Run the local code review over the push range. The supported reviewer is the
global `/review` command: it launches parallel reviewers (CLAUDE.md compliance,
bugs, security, test coverage via wshobson's testing dimension), validates each
finding with a second pass, and filters to high-signal issues only. Run it over
`origin/master...HEAD` (the push range from Step 1) and collect its validated
findings. Depend on it; do not paste its procedure here.

### 3. Scorecard

Print one line per validated finding — `file:line — issue — why flagged` — then a
tally. If none, say "no high-signal issues." Surface any findings first; do not
round a shaky review up to clean.

### 4. Record the verdict (for the pre-push gate)

Record a pass **only** when the review genuinely ran over the range and no
validated high-signal issue remains. Run from the repo root:

```bash
.omakase/bin/omakase-gate.sh review --record
```

- **pass** (record it) — the review ran and nothing high-signal remains.
- **fail or could-not-run** — record **nothing**. No recorded pass keeps the push
  blocked, which is the correct outcome; print why, fix, then re-run (a fresh pass
  unblocks the re-push at the same commit).
- A finding that looks real but is wrong is just a judged result: dismiss it in the
  review with your reasoning, then record the pass. To push past a block you have a
  documented reason to override, do not fake a pass — use the audited bypass
  `OMAKASE_SKIP_REVIEW=1 git push` (announced at push time, never silent).

## Scope

- Reviews the push range only. Does not build, test, or typecheck — the other
  pre-push gates do that.
- Per-push escape hatch (audited — note why in the PR): `OMAKASE_SKIP_REVIEW=1 git push ...`.
