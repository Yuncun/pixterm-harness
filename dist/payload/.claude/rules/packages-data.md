---
paths:
  - "packages/data/**"
---

# Data-tier — governing ADRs

The data tier (`@pixterm/data`) is governed by two ADRs that fall
outside the session-start top-five window:

- `ADR-0002` — TanStack Vue Query is the server-state library.
  All server reads/writes go through hooks in `packages/data/src/*`;
  the `api()` wrapper is the only permitted `fetch` caller.
- `ADR query-key-scope-discipline` (2026-05-23) — query keys that
  vary by scope (route param, character dir, tab) **must** encode
  that scope. Function-form key factories take the scope as a
  required argument; parameterless factories are reserved for
  genuinely global data. Regressions are blocked by
  `.ast-grep/no-parameterless-graph-key.yml`.

Tier import contract: see `.claude/rules/packages-data-tier.md`.
Topic map: `AGENTS.md` `## Related ADRs`.
