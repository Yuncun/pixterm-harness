---
paths:
  - 'packages/*-control/**'
---

# Controls tier (`@pixterm/*-control`)

Controls-tier packages wire `@pixterm/*` ui-tier leaves to application state and server data.

## Allowed imports

- `vue`
- `@pixterm/*` ui-tier packages
- `@app/stores/*` — Pinia stores
- `@app/data/*` — TanStack Vue Query hooks
- `@app/composables/*` — non-adapter reusable logic
- `@app/shared/*` — constants
- `@app/types` — frontend type definitions

## Banned imports

ESLint contract; enforced from the workspace-root `eslint.config.js` so the rules actually fire on `packages/*-control/src/**`:

- `vue-router` — route-level values come down as props from `routes/`
- Direct `fetch()` calls — use the `api.ts` wrapper or data hooks
- `@pixterm/*/adapters/*` — adapters are app-internal; wrap them via controls

## `@app/*` aliases

Controls-tier packages import from `apps/web/src/` modules via the `@app/*` alias family:

| Alias              | Resolves to                 |
| ------------------ | --------------------------- |
| `@app/stores`      | `apps/web/src/stores/`      |
| `@app/data`        | `packages/data/src/`        |
| `@app/composables` | `apps/web/src/composables/` |
| `@app/shared`      | `apps/web/src/shared/`      |
| `@app/types`       | `apps/web/src/types.ts`     |

Two locations must declare the aliases:

1. **`apps/web/vite.config.js`** — `resolve.alias` block (Vite resolves at build/test time)
2. **Each control package's `tsconfig.json`** — `compilerOptions.baseUrl + paths` (vue-tsc resolves at typecheck time)

This pattern is acceptable because controls packages are app-internal (private, never published).

See `packages/right-panel-control/tsconfig.json` for a current control-package tsconfig with the `@app/*` paths mapping. Imports use the alias directly: `import { useGraphStore } from "@app/stores/graph"`.

## globals.css class references

Controls packages may reference classes defined in `apps/web/src/styles/globals.css` as string class literals (e.g. `class="panel-btn secondary"`). These are the host app's visual contract; they are NOT migrated to CSS Modules. Only component-local classes (defined solely within the package) belong in `<style module>`.

When a global class has a local state modifier (e.g. `tb-btn.active`), use a split binding: `class="tb-btn" :class="{ [$style.active]: condition }"` with `.active { }` in the style block.

## Testing controls-tier packages

`@pixterm/test-utils` is the canonical harness for any test or Storybook story that imports a controls-tier component. Controls packages add it as a `devDependency` (`"@pixterm/test-utils": "workspace:*"`). Both entry points share one internal `installAppPlugins` so a story and its paired test never drift on what plugins are installed (Pinia via `@pinia/testing`, TanStack Vue Query with a fresh `QueryClient`). See ADR-0011 for the why; see `packages/test-utils/README.md` for the full API.

**Vitest:** mount with `mountWithApp(component, opts)`; read the store back via `useUiStore()` to assert on state transitions. See `packages/right-panel-control/src/RightPanel.test.ts` for the current pattern (parameterised routing cases, `vi.mock('@app/data/api')` for network stubbing, `findComponent` identity checks).

The two non-obvious knobs:

- `createSpy: vi.fn` — `apps/web`'s vitest config sets `globals: false`, so `@pinia/testing` v1.x cannot auto-detect `vi`. The harness installs a no-op spy by default; pass `vi.fn` when you need real call-tracking.
- `stubActions: false` — actions are stubbed by default. Opt out when the test depends on the action actually mutating store state (e.g. `pushPanel` / `popPanel` / `hidePanel` transitions).

**Storybook:** apply `appDecorator()` per-meta and put per-story state under `parameters.appState`. See `packages/right-panel-control/src/RightPanel.stories.ts` for the current pattern.

Per-story state flows through `parameters.appState`, NOT directly through `appDecorator(opts)`. `@storybook/vue3` 8.6 does not populate `context.app` on the decorator's `storyContext`, so the decorator silently no-ops in real Storybook today. The host's `apps/web/.storybook/preview.ts` `setup()` hook reads `parameters.appState` and installs the same plugin stack as a workaround. Tracked as a known limitation in GH #13; the proper fix moves the install path back into `@pixterm/test-utils`.

Tier overview: see `.claude/rules/packages-overview.md`.
