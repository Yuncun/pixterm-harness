---
paths:
  - 'apps/web/src/routes/**'
---

# Routes tier — top-level page composition

Routes own page composition: which controls render where, what's the
top-level layout, what gets passed down as props. This is the only layer
permitted to import `vue-router`. Everything else receives route-derived
values as props or through store state. The vue-router boundary is
enforced by `apps/web/eslint.config.js` (`no-restricted-imports`).

## Router

`router.ts` uses hash mode (`createWebHashHistory`). Hash routing avoids
the FastAPI catch-all rewrite that `createWebHistory` would require, and
it works with the in-process `TestClient` used by `make smoke`. A
catch-all redirects unknown paths to `/`.

| Path          | Name      | Component          |
| ------------- | --------- | ------------------ |
| `/`           | `welcome` | `WelcomeRoute.vue` |
| `/graph/:dir` | `graph`   | `GraphRoute.vue`   |

## Route components

- **`App.vue`** is the layout shell. It renders `<RouterView />` and
  `<Toasts />` and is route-agnostic. Overlays that need graph context
  (for example `<FloatingPlayer />`) live in `GraphRoute.vue`, not in
  `App.vue`.
- **`WelcomeRoute.vue`** wires `WelcomeOverlay` create/load events to
  `useCreateGraph()` / `useLoadGraphDir()` and navigates to
  `/graph/:dir` on success.
- **`GraphRoute.vue`** is the main workspace. It receives `:dir` via
  `props: true` and loads the graph on mount and whenever `:dir`
  changes.

## State resets on navigation

Leaving `/graph/:dir` is explicit-emit, not data-driven: the Toolbar's
Home button emits `home`, and `GraphRoute.vue`'s handler does
`uiStore.clearSelection()` → `await graphStore.closeGraph()` →
`router.push({ name: 'welcome' })` in that order. Don't reintroduce a
`watch(graph, ...)` that navigates on `graph → null`: when
`WelcomeRoute.useLoadGraphDir` pre-populates the cache before
`GraphRoute` mounts, the initial value is non-null and Vue's `watch`
skips it, so `hadGraph` never flips — `closeGraph` then writes null and
the watcher no-ops. That was gh #122.

When `:dir` changes within `/graph/:dir`, `GraphRoute.vue` reloads the
graph and calls `uiStore.hidePanel()` to clear panel state from the
previous graph.

## Adding a new route

1. Create a `<Name>Route.vue` in `apps/web/src/routes/`.
2. Add the route record to `router.ts`.
3. If the route needs to reset state on exit, add a watcher or
   navigation guard in the route component (not in controls or stores).
4. Update the route table above.
