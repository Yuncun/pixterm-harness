---
paths:
  - "packages/{simulator,player}/**"
---

# Runtime tier (`@pixterm/simulator`, `@pixterm/player`)

The runtime tier is the floor of the dependency graph: pure-TS libraries with no Vue, no DOM, no app coupling. They run unchanged in Node, in a browser worker, and in the editor.

**Members today:** `@pixterm/simulator` (TypeScript port of `pixterm/player/simulator.py`) and `@pixterm/player` (the unified-player engine — Player class, Traverser, ClipRenderer interface). Future codecs, validators, and other host-agnostic libraries belong here.

## Allowed imports

- TypeScript standard library
- Sibling runtime-tier packages (e.g. `@pixterm/player` may import `@pixterm/simulator`); permitted by ADR-0014.

## Banned imports

Enforced via ESLint `no-restricted-imports` on `packages/{simulator,player}/src/**` (see `apps/web/eslint.config.js`); declared explicitly here so the contract is reviewable in code-review:

- `vue`, `vue-router`, `@vue/*` — runtime tier is host-agnostic
- DOM globals from outside an explicit `renderers/` subdirectory of a package (the renderer subdir's `tsconfig` opts in to `lib: ["dom"]`)
- Any controls/ui/data/adapter-tier package
- `@app/*` — runtime tier may not depend on app-internal modules
- `@tanstack/*` — runtime tier does not own server state
- `fetch` (and any network primitive) — the runtime accepts data via function arguments

## Package structure

A runtime package's `package.json` carries no Vue/DOM/app deps; only sibling runtime packages and runtime devDependencies (e.g. `tsx`, `vitest`). The package's `tsconfig.json` extends `../../tsconfig.base.json` only — never `@vue/tsconfig`.

Background: ADR-0007 (runtime tier introduction), ADR-0014 (runtime→runtime imports).

Tier overview: see `.claude/rules/packages-overview.md`.
