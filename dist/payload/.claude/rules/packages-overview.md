---
paths:
  - "packages/**"
---

# packages/ — workspace packages

This directory contains extracted workspace packages (`@pixterm/*`). Each
package is `private: true` and referenced by workspace members via
`workspace:*` deps.

## Tier overview

| Tier         | Path pattern                   | What it owns                                                                           |
| ------------ | ------------------------------ | -------------------------------------------------------------------------------------- |
| **tokens**   | `packages/design-system/`      | CSS custom-property tokens (colors, spacing, typography). No Vue. Loaded globally.     |
| **ui**       | `packages/{leaf-name}/`        | Pure-UX leaf components: props in, callbacks out. No app state.                        |
| **controls** | `packages/*-control/`          | Wires ui-tier leaves to Pinia stores + TanStack Query data hooks.                      |
| **adapter**  | `packages/*-adapter/`          | Wraps imperative third-party libraries (e.g. cytoscape) behind props/events.           |
| **data**     | `packages/data/`               | All server-state operations via TanStack Vue Query. Only tier allowed to call `api()`. |
| **runtime**  | `packages/{simulator,player}/` | Pure-TS, host-agnostic. No Vue, no DOM (except `renderers/` subdirs), no app coupling. |

Each tier's import contract — what it may import, what's banned, and
tier-specific gotchas — lives in `.claude/rules/packages-<tier>-tier.md`.
Only the relevant tier's rule loads when Claude reads files matching that
tier. See ADR-0024 for the rationale.

## Package anatomy

```
packages/<kebab-name>/
  package.json         name: @pixterm/<kebab-name>, private, exports: ./src/index.ts
  tsconfig.json        extends ../../tsconfig.base.json + @vue/tsconfig/tsconfig.dom.json
  README.md            purpose, public API (props/events/slots), usage example
  src/
    index.ts           re-exports from <Name>.vue (+ prop types if needed)
    <Name>.vue         component with <style module> (CSS Modules)
    <Name>.test.ts     Vitest unit tests
    <Name>.stories.ts  Storybook stories (discovered via packages/*/src/*.stories.ts glob)
```

Tests run via `apps/web`'s workspace vitest config
(`packages/*/src/**/*.test.ts` glob); per-package vitest configs are not
needed.

## Adding a new package

1. Create `packages/<name>/` following the anatomy above.
2. Run `pnpm install --no-frozen-lockfile` from the repo root.
3. Add `"@pixterm/<name>": "workspace:*"` to `apps/web/package.json`
   dependencies.
4. Add a row to `packages/README.md`.
5. Import from `'@pixterm/<name>'` in consumer files.
6. **If the package is ui-tier**, add its directory name to
   `.claude/rules/packages-ui-tier.md`'s `paths:` enumeration. Other
   tiers use glob patterns (`*-control`, `*-adapter`, etc.) and need no
   rule update.
