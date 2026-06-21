---
paths:
  - "packages/player/src/**"
---

# `@pixterm/player` — internal layering

`@pixterm/player` is a single workspace package internally subdivided into three concept layers. The layering is enforced structurally (`src/<layer>/`) and via path-scoped ESLint `no-restricted-imports` rules in `apps/web/eslint.config.js`. Subdivide-vs-split rationale: ADR `subdivide-player-internals-rather-than-split`.

## Layers

| Layer        | Path                             | Owns                                                                   |
| ------------ | -------------------------------- | ---------------------------------------------------------------------- |
| `engine/`    | `packages/player/src/engine/`    | `Player` class — idle/loading/playing/paused/error state machine.      |
| `traverser/` | `packages/player/src/traverser/` | `Traverser` class — queue + Promise adapter over `@pixterm/simulator`. |
| `renderers/` | `packages/player/src/renderers/` | DOM-aware `ClipRenderer` implementations (e.g. `HtmlVideoRenderer`).   |

The shared kernel (`emitter.ts`, `types.ts`, `test-fakes.ts`) sits at `packages/player/src/` and is reachable from any layer. `types.ts` is the single source for `Clip`, `ClipRenderer`, `ClipSource`, `PlayerState`, etc.; `emitter.ts` is the `TypedEventEmitter` base; `test-fakes.ts` provides cross-layer testing primitives.

## Import direction (enforced)

```
   engine/  ──>  traverser/  ──>  @pixterm/simulator
      │              │
      └──────────────┴──>  shared kernel (types.ts, emitter.ts)
                           ▲
                           │
                    renderers/  ──>  DOM (opt-in via subdir tsconfig)
```

The arrows show the only allowed cross-layer dependencies. Banned, with the ESLint message that fires:

- `engine/` may not import from `renderers/` — Player consumes `ClipRenderer` through its constructor as an injected dependency; reaching into `renderers/` by path would couple the engine to one specific renderer.
- `traverser/` may not import from `engine/` or `renderers/` — Traverser produces clips; both other layers consume it, not the other way around.
- `renderers/` may not import from `traverser/` — renderers implement `ClipRenderer` and consume `Clip` payloads from any source (including future non-graph sources). Depending on `traverser/` would couple rendering to one specific producer.

The runtime-tier restrictions (no Vue, no `@app/*`, no upper-tier `@pixterm/*` packages, no `@tanstack/*`, no direct `api()`) continue to apply on top of the sublayer rules — see `.claude/rules/packages-runtime-tier.md`.

## Public surface

`packages/player/src/index.ts` re-exports the cross-layer surface — `Player`, `Traverser`, the type kernel — so consumers (`apps/web/src/stores/traverser.ts`, `apps/standalone/src/stores/player.ts`, `packages/floating-player-control/`) import from `@pixterm/player` and never reach into a sublayer path. Browser-only exports stay on the `@pixterm/player/browser` subpath; the test fakes stay on `@pixterm/player/test-fakes`.

When growing the package, add the new file under the appropriate layer directory and re-export from `index.ts` if it belongs on the public surface. Adding a new layer (e.g. a future `recorder/`) means: create the directory, add a sibling block in `apps/web/eslint.config.js` mirroring the existing per-sublayer pattern, and extend the table above.

Background: ADR `subdivide-player-internals-rather-than-split` (this layering's rationale + deferred Option B). Tier rationale ADR-0007 + ADR-0014 (runtime tier). The subdivision is the internal-organization mirror of ADR-0026's path-scoped enforcement pattern, applied within a single package.
