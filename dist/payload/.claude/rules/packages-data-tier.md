---
paths:
  - "packages/data/**"
---

# Data tier (`@pixterm/data`)

The data tier owns all server-state operations via TanStack Vue Query. It is the only tier permitted to call `api()` (the typed `fetch` wrapper). Controls-tier packages consume this tier via the `@app/data/*` alias.

**Package:** `packages/data/` — name `@pixterm/data`.

## Allowed imports

- `vue`
- `@tanstack/vue-query`
- `@app/types` — frontend type definitions (read-only)

## Banned imports

- `@app/stores/*` — data hooks are stateless from the consumer's perspective; they do not own or read UI state.
- Any `@pixterm/*` UI package — data is headless.
- `vue-router` — data hooks are reusable across pages.
- Raw `fetch()` — all network calls go through `api.ts`.

## The `api()` ban

ESLint blocks `import { api } from '@app/data/api'` (or any `**/data/api*` pattern, `@app/data/api`, or `@pixterm/data/src/api`) outside `packages/data/src/`. This forces all callers to use hooks instead of the wrapper directly. `BASE_URL` is exempt — it is a config constant for `<img>`/`<video>` src URLs and is allowed at any layer.

## The `@app/data/*` alias

Controls-tier packages import data hooks as `@app/data/use-graph`, `@app/data/use-jobs`, etc. This alias resolves to `packages/data/src/` (set in `apps/web/vite.config.js` and in each control package's `tsconfig.json`). The package's public name is `@pixterm/data`; the alias is the load-bearing interface — direct `@pixterm/data` imports are not currently in use.

Tier overview: see `.claude/rules/packages-overview.md`.
