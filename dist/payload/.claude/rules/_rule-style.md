---
paths:
  - '.claude/rules/**'
---

# How rules are written in this project

This rule loads when Claude is editing files in `.claude/rules/`. It codifies the conventions for rules in this project — what to include, what to avoid, and where each convention comes from. The leading underscore marks this as a meta-rule (about the rule system itself), distinct from object-rules (about code).

## Mechanism (background)

Rules live in `.claude/rules/<topic>.md` with optional YAML `paths:` frontmatter. Without `paths:`, the rule loads at every session start. With `paths:`, the rule loads only when Claude reads files matching one of the globs. Canonical: <https://code.claude.com/docs/en/memory#path-specific-rules>.

ADR-0018 introduced this pattern. ADR-0024 applied it per-tier in `packages/`.

## What goes in a rule (canonical patterns)

These are externally validated — not project-specific.

- **Specificity over vagueness.** _"React 18 with TypeScript, Vite, Tailwind"_ — not _"React project"_. (GitHub 2,500-repo agents.md study.)
- **Reference files, don't copy them inline.** If an example exists in the codebase, link to it: _"See `packages/right-panel-control/tsconfig.json`."_ Inline copies drift the moment the original changes; pointers auto-track. (Cursor docs, explicit.)
- **Add rules from observed mistakes, not theory.** Rules earn their place by preventing bugs that actually shipped. (Cursor docs, explicit.)
- **Use linters where possible.** Don't document style rules a linter can enforce. (Cursor docs.)
- **Keep focused and scoped.** One topic per file. Split if it grows past ~200 lines. (Anthropic CLAUDE.md guidance applies by analogy.)

## Project-specific conventions

These are our additions, not externally documented as canonical patterns. Use them when they fit; don't force them.

- **WHY block** when the rule has a real postmortem origin. The May 2026 close-button bug story in `ui-regression-tests.md` is the model — future Claude can judge edge cases when they understand _why_ the rule exists. WHY blocks are not required when the rule is purely structural (e.g. import contracts).
- **ADR pointer (number-only)**, e.g. _"permitted by ADR-0014"_. Don't restate the ADR's narrative — just the number. ADRs are append-only, so number references don't rot.
- **Footer pointer** like _"Tier overview: see `.claude/rules/packages-overview.md`"_ for navigation in tier-scoped rules.
- **Underscore-prefix for meta-rules** (`_rule-style.md`). Distinguishes infrastructure-about-the-system from rules-about-the-code at a glance.

## Anti-patterns

- **Inline code examples that duplicate a real file.** If the example is the source of truth, OK. If it's a snapshot of something that lives in code, link instead.
- **Phase / migration mentions** that age into history (_"Phase 7 has repointed `@app/data`..."_). When the phase ships, the mention rots.
- **"Members today" lists** when a `paths:` enumeration above is the actual source of truth — duplicated lists guarantee drift.
- **Version-pinned facts** without a tracking issue. If you say _"Storybook 8.6 has bug X,"_ link a GH issue so future readers know what triggers re-evaluation.
- **Restating an ADR's reasoning** in a rule. The ADR is the rationale; the rule is the operational guidance. Pointer-only.

## When to update this file

- Adding a new convention: edit and run `/review` per the CLAUDE.md harness-changes convention.
- Removing a convention: requires a follow-up audit pass on existing rules to drop instances. Treat removals like deprecations.
- Major shifts (e.g. abandoning the path-scoped pattern): write a new ADR superseding ADR-0018; update this file and existing rules.

## Drift catchers

- `/review` on harness changes — fresh-context reviewer catches obvious staleness.
- A future structural lint could verify that `paths:` globs match real files and that pointer destinations exist (deferred per ADR-0024's future-work section).
- This file itself loads on every `.claude/rules/**` edit, so future Claude editing a rule sees these conventions automatically.
