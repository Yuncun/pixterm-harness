---
paths:
  - "packages/*-adapter/**"
---

# Adapter tier (`@pixterm/*-adapter`)

Adapter packages wrap third-party imperative libraries behind a Vue props-in / events-out surface. They expose an imperative API via `defineExpose` for a companion control to call.

## Allowed imports

- `vue`
- The third-party library being wrapped (e.g. `cytoscape`, `cytoscape-fcose`, `cytoscape-dagre`)
- Sibling `@pixterm/*` ui-tier packages (for constants, types)
- `@app/types` — frontend type definitions (read-only; no store imports)
- `@app/shared/*` — constants (e.g. `fcose-config`)

(`@app/types` and `@app/shared/*` are types and constants only — no runtime side effects, no value imports that could create cycles.)

## Banned imports

Enforced structurally and via ESLint:

- `@app/stores/*` — Pinia stores. Emit events instead of writing to a store.
- `@app/data/*` — data hooks. Emit events instead of calling a hook.
- `vue-router` — adapters are reusable across pages.

## Pattern

The adapter is a pure bridge. All state coupling lives in the companion `@pixterm/*-control` package.

The current adapter tier has one member: `@pixterm/cytoscape-adapter`. Future imperative-library integrations follow the same `*-adapter` / `*-control` naming pair.

Tier overview: see `.claude/rules/packages-overview.md`.
