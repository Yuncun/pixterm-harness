# pixterm-harness

pixterm's personal harness, packaged as a Claude Code plugin. It is built on the
[omakase-harness](https://github.com/Yuncun/omakase-harness) injector: the `bin/` and
`commands/` are vendored from that base unchanged; the harness content lives in `payload/`.

`/omakase-init` overlays the payload into the repo at real paths, records every placed path
in `.git/info/exclude` (so nothing is committed and `.gitignore` is untouched), installs
lefthook, and wires worktree self-arm. `/omakase-remove` reverses it. The injected wiring
(`lefthook-local.yml`) merges *over* a committed `lefthook.yml`, so a repo's own stack gates
stay committed while these guards ride on top, personally.

## What it injects

| Guard | Hook | What it does |
| ----- | ---- | ------------ |
| `worktree-discipline` | pre-commit | Blocks a main-checkout commit that would inherit another worktree's uncommitted work. Pure git; dormant unless more than one worktree is active. |
| `adr-required` | pre-commit | Requires a paired decision record (a new `docs/adr/*.md`) when a declared architectural file changes. Reads `HARNESS_ARCH_FILES`; dormant if unset. |
| `deferred-check` (visual-verify) | pre-push | Confirms a producer recorded a fresh PASS for the code being pushed, and blocks otherwise. For verdicts a hook cannot compute itself — here, the visual-verify scorecard. Dormant unless the pushed range touches the UI globs. |
| `omakase-record` | — | The producer helper the visual-verify skill calls to stamp its verdict. Writes a commit-keyed record inside `.git/` (never committed, never shipped to CI). |

The wiring lives in `payload/lefthook-local.yml`. Escape hatches: `SKIP_WORKTREE_CHECK=1`,
`SKIP_ADR_CHECK=1`, `OMAKASE_SKIP_VISUAL_VERIFY=1`.

## Relationship to omakase-harness

`omakase-harness` is the generic base — a content-free additive file-tree injector with one
example gate. `pixterm-harness` is a fork that keeps the base mechanism byte-identical and
replaces the example payload with pixterm's real guards. Base fixes are pulled forward by
re-syncing `bin/` and `commands/`; the only intentional diffs are `payload/`, `plugin.json`,
and this README.

## Tests

```
bash tests/inject.test.sh          # the vendored injector mechanism (must print ALL PASS)
bash tests/deferred-gates.test.sh  # the deferred-gate scaffold
```

## License

MIT. See `LICENSE`.
