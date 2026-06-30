# pixterm-engine — Project Instructions

## Verification (the 5-gate — only definition of "done")

All five must exit 0 before any change ships:

```bash
make typecheck     # vue-tsc strict
make test-frontend # vitest unit tests (<10s)
make smoke         # FastAPI + Vue dist + mock backend (<30s)
make ui-regression # deterministic Playwright behavioral specs (also runs in Linux CI)
make lint          # ruff, vulture, import-linter, stylelint, eslint (incl. layer rules)
```

After UI work, run Visual Verify (`/visual-verify`) — an AI scorecard that drives the editor through self-generated stateful scenarios and records its verdict. For UI changes it is enforced at pre-push (ADR `visual-verify-pre-push-enforcement`): a push touching the UI is blocked unless `/visual-verify` recorded a fresh PASS for the commit. The judge is best-effort, not a proof; the deterministic `ui-regression` layer stays gate #4. See ADRs ui-verification-two-layers and omakase-deferred-gate-scaffold.

## Routing — where things live

- Decision needing Eric → ADR (`/adr-new "Title"`)
- Active bug → gh issue
- Deferred work tied to a file → inline `# TODO(when: <trigger>): ...`
- Exploration / drafts → `docs/notes/`

Don't halt waiting for input — file it, continue with what's unblocked.

## Documentation

- **Decisions** → `docs/adr/` (Nygard, date-prefixed slugs, semantic append-only — see `.claude/rules/adrs.md`)
- **Conceptual** → `docs/model/` (long-form, one concept per file)
- **Scratch** → `docs/notes/` (labeled exploration, not load-bearing)
- **Reference** → generated only; hand-written reference forbidden

Architectural changes to `ARCHITECTURE.md` or `AGENTS.md` require a paired ADR (pre-commit hook enforces). Personal preferences: `CLAUDE.local.md` (gitignored, concatenated after this file).

## Worktree discipline

Implementation work uses `superpowers:using-git-worktrees` (ADR-0034 — main-checkout branches inherit other sessions' WIP). Hooks warn + block; escape: `OMAKASE_SKIP_WORKTREE_DISCIPLINE=1`.

## Harness changes

After editing `AGENTS.md`, `.claude/rules/`, `.claude/hooks/`, or `.ast-grep/` — run `/review` to catch drift. `CLAUDE.md` is a symlink to this file (ADR-0037); Claude resolves it transparently, non-Claude agents read `AGENTS.md` directly.

## What This Project Is

pixterm-engine builds **pose graphs** — directed graphs where nodes are character poses and edges are short FLF clips. A character lives by traversing: pick edge, play clip, land on next pose, repeat.

- **Why** → `VISION.md`
- **System design** → `ARCHITECTURE.md`
- **Runtime model** → `docs/model/dimensional-state-graph.md`
- **Data shape** → `docs/model/data-structures.md`

## Layer contracts

Per-tier import contracts and other path-scoped rules live in `.claude/rules/` (ADR-0026), each loading when Claude reads matching files. ESLint `no-restricted-imports` (`apps/web/eslint.config.js`) is the source of truth for `ui`/`controls`/`data`/`adapters` tier boundaries. Full harness map: `HARNESS.md`.

## Related ADRs

Topic-map for ADRs outside the recency window. Add a row when adding a `.claude/rules/<slug>.md`.

| Subsystem | Governing ADR(s) | Surfacing rule |
|-----------|------------------|----------------|
| Right-panel composition | `ADR-0023` (panel-blocks) | `.claude/rules/packages-right-panel.md` |
| Server-state cache keys | `ADR-0002` (TanStack Query) + `ADR query-key-scope-discipline` (2026-05-23) | `.claude/rules/packages-data.md` |
| Path-scoped rules pattern | `ADR-0018`, `ADR-0024`, `ADR-0026`, `2026-05-24-topical-adr-surfacing-via-path-scoped-rules` | `.claude/rules/_rule-style.md` (meta) |

## Where to look

| Task | Location | Notes |
|------|----------|-------|
| Right-anchored panel | `packages/right-panel-control/src/panels/*.vue` | 13 panels — copy nearest match |
| Wrap imperative library | `@pixterm/cytoscape-adapter` + `@pixterm/graph-canvas-control` | Adapter + control pair |
| Server-data hook | `packages/data/src/use-*.ts` | TanStack Query, see `query-keys.ts` for cache scope |
| ComfyUI workflow | `pixterm/workflows/*.json` | Reference via `connected_workflow.py` |

## Frontend dev (mock backend)

```bash
PIXTERM_BACKEND=mock PIXTERM_OUTPUT=$(pwd)/output .venv/bin/python -m pixterm.webapp
```

Real backends: `fal`, `comfyui`, `alibaba`, `hybrid`.

## Versioning

Canonical version: `pixterm/__init__.py` `__version__`. Bump via `make bump-{patch,minor,major}`. Conventional commits drive the category.

## Repo location

All work in `~/Claude/pixterm-engine/` (standalone). Never edit `~/Claude/storymode/pixterm-engine/` (submodule).
