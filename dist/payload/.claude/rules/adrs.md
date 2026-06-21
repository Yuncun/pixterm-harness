---
paths:
  - 'docs/adr/**'
---

# ADRs — Architecture Decision Records

ADRs are append-only records of architectural decisions in Michael Nygard's
format. They live in `docs/adr/` — legacy files use `NNNN-slug.md`, new files
use `YYYY-MM-DD-slug.md`. Cite legacy ADRs by number (e.g. `ADR-0007`); cite
date-prefixed ADRs by slug (e.g. `ADR verify-ui-model-invocable`).

## Format

Every ADR follows `docs/adr/template.md`. Required sections:

- **Title** — `# <Decision title>` (legacy ADRs use `# ADR-NNNN: <Title>`)
- **Date** — `Date: YYYY-MM-DD`
- **Status** — `Proposed | Accepted | Superseded by <ADR ref> | Deprecated`
- **Context** — the problem; what made this decision necessary
- **Decision** — what we're doing (concrete, unambiguous)
- **Consequences** — what changes because of this; what we gain and give up

## Rules

1. **Don't rewrite an Accepted ADR's Context, Decision, or Consequences.**
   The semantic content is the decision record — if it's wrong, write a new
   ADR superseding the old. Mechanical fixes are allowed without ceremony:
   typos, broken links, updated file/line pointers when code moves, renamed-
   ADR cross-references. The test: does the edit change what was decided or
   why? If yes → new ADR. If no → just commit the fix.
2. **Filenames use date-prefixed slugs.** New ADRs are named
   `YYYY-MM-DD-slug.md` (e.g.
   `docs/adr/2026-05-17-narrow-architectural-files.md`). Legacy numbered
   ADRs (`NNNN-slug.md`) are left untouched and remain valid. The date
   prefix sorts chronologically and eliminates the parallel-session
   collision class without coordination.
3. **Status transitions:**
   - `Proposed` → `Accepted` when implemented
   - `Accepted` → `Superseded by <ADR ref>` when explicitly replaced
     (also add a `Supersedes: <ADR ref>` line). Use `ADR-NNNN` for legacy
     ADRs, or the slug for date-prefixed ADRs.
   - `Accepted` → `Deprecated` when no longer relevant and no replacement
4. **One decision per ADR.** Two decisions = two ADRs.
5. **Cite by ADR number or slug, not file path or line.** For legacy ADRs, write
   `ADR-0007`. For date-prefixed ADRs, cite by slug: `ADR verify-ui-model-invocable`
   or just `the verify-ui-model-invocable ADR`. Do NOT cite a file path with a line number.

## When to write one

Write an ADR for any decision that touches more than one file,
establishes or changes a pattern future code will follow, reverses a
prior decision, or resolves a long-debated question. Skip if the
decision is local (one file, one feature, easily reversed) — `git log`
is sufficient.

## Architectural files that require a paired ADR

The list of architectural files (currently `ARCHITECTURE.md AGENTS.md`) is
declared as the `HARNESS_ARCH_FILES` env on the `adr-required` job in the
injected `lefthook-local.yml`. The guard itself is injected by the
`pixterm-harness` plugin at `.omakase/gates/adr-required.sh` — personal and
gitignored, not committed (`ADR 2026-06-03-pixterm-dogfoods-via-injection`). When
the harness is installed, the pre-commit hook rejects any commit that modifies one
of those files without also adding a new ADR. Override (rare, for typo fixes only): set `SKIP_ADR_CHECK=1`
and document the reason in the commit body.
