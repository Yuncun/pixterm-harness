---
paths:
  - "packages/{asset-grid,context-menu,empty-state,eval-badge,eval-scores,form-field,job-status-block,loading-state,pixel-thumb,player-ui,preview-media,prompt-block,resolved-prompts,status-dot}/**"
---

# UI tier — pure leaf components

Pure-UX leaf components: props in, callbacks out. They render and emit; they do not own application state.

The `paths:` enumeration above is the canonical list of ui-tier packages.

## Allowed imports

- `vue`
- Sibling `@pixterm/*` ui packages (for composition; e.g. `@pixterm/asset-grid` depends on `@pixterm/loading-state`)
- CSS custom properties from `@pixterm/design-system` (provided by the host app at runtime — do NOT import the CSS inside the package)

## Banned imports

These deps are not in the package.json, enforced structurally:

- Pinia stores
- TanStack Vue Query hooks / `api()`
- Vue Router
- Cytoscape or other imperative adapters

If a ui-tier package ever needs any of those, promote it to a controls-tier package and document the move.

## When adding a new ui-tier package

Add its directory name to the `paths:` enumeration above. The enumeration is explicit because ui-tier packages don't share a naming pattern (unlike `*-control` or `*-adapter`).

Tier overview: see `.claude/rules/packages-overview.md`.
