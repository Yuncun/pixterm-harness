---
name: review-verify
description: Run a local code review of the push range and record its verdict for the pre-push deferred gate. Wraps the global /review flow (parallel reviewers + finding validation) over the changes about to be pushed, prints the findings, and records pass/fail so the `review` deferred gate can enforce that a review actually ran for this commit. Invoke at done-time before pushing; Claude may self-invoke before claiming completion.
allowed-tools: Bash(git rev-parse:*) Bash(git branch:*) Bash(git log:*) Bash(git show:*) Bash(git diff:*) Bash(.omakase/bin/omakase-record.sh:*) Read Grep Task
context: fork
---

# /review-verify — automated pre-push code review

You are the **Reviewer**. You run the same local code review the human runs by
hand before a push, then **record a verdict** that the pre-push deferred gate
reads (Step 4). You do not write a commit and you do not block anything yourself
— the gate enforces your recorded verdict at push time. The printed findings are
for a human to skim; the record is what the gate checks.

## The one rule: always record

Whatever happens, end by recording a verdict (Step 4). The gate fail-closes on a
missing record, so a run that records an honest **fail** with a reason is far
better than a crash that records nothing.

## Procedure

### 1. Orient — the push range

Review exactly what is about to be pushed, not the working tree:

```bash
git rev-parse --show-toplevel
git branch --show-current
git diff --stat origin/master...HEAD 2>/dev/null || git diff --stat origin/main...HEAD 2>/dev/null
```

If the range is empty (nothing to push beyond the remote), record
`--verdict pass --reason "no changes to review"` and stop.

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

Run from the repo root:

```bash
.omakase/bin/omakase-record.sh --check review --verdict <pass|fail> [--reason "..."]
```

- **pass** — the review genuinely ran over the range and no validated high-signal
  issue remains.
- **fail** — a validated high-signal issue remains (name it in `--reason`), or the
  review could not run. Re-run after fixing, which records a fresh pass.
- **waiver** — a finding that looks real but is wrong: record
  `--verdict pass --original-verdict fail --reason "<why the finding is wrong>"`.
  The reason prints as a WAIVED banner at push; never use it to wave through a
  real issue.

Record on **every** path, including early exits — if the review cannot run,
record `--verdict fail` with a reason so the gate reflects that nothing was
reviewed.

## Scope

- Reviews the push range only. Does not build, test, or typecheck — the other
  pre-push gates do that.
- Per-push escape hatch (audited — note why in the PR): `OMAKASE_SKIP_REVIEW=1 git push ...`.
