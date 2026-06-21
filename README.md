# pixterm-harness

pixterm's personal harness, as a payload-only stack source. The machinery (the `/omakase`
command and its scripts) lives in [omakase-harness](https://github.com/Yuncun/omakase-harness),
not here; the build copies it in and writes the installable plugin to `dist/`.

Activate it in a repo with `/omakase init` (Claude Code) or `bash bin/init.sh` (any shell,
including GitHub Copilot CLI): it overlays the payload at real paths, records each placed path
in `.git/info/exclude` so nothing is committed, installs lefthook, and arms new worktrees.
`/omakase remove` reverses it. The injected `lefthook-local.yml` is the only local hook config
and carries pixterm's full gate suite: scoped checkers (prettier, stylelint; per-commit),
complete checkers (typecheck, lint, test, the validators; per-push), and the guards below.

## Guards

| Guard | Hook | What it does |
| ----- | ---- | ------------ |
| `worktree-discipline` | pre-commit | Blocks a main-checkout commit that would inherit another worktree's uncommitted work. Dormant unless more than one worktree is active. |
| `adr-required` | pre-commit | Requires a paired decision record when a declared architectural file changes. Reads `HARNESS_ARCH_FILES`; dormant if unset. |
| `visual-verify` (deferred gate) | pre-push | Blocks unless the visual-verify skill recorded a fresh PASS for the pushed code. Dormant unless the pushed range touches the UI globs. |
| `review` (deferred gate) | pre-push | Blocks unless the review-verify job recorded a PASS for the pushed code. Dormant unless the pushed range touches the app/package globs. |

The wiring lives in `payload/lefthook-local.yml`. A deferred gate reads a commit-keyed record
its job writes into `.git/`, never committed. Escape hatches: `SKIP_WORKTREE_CHECK=1`,
`SKIP_ADR_CHECK=1`, `OMAKASE_SKIP_VISUAL_VERIFY=1`, `OMAKASE_SKIP_REVIEW=1`.

## Relationship to omakase-harness

`omakase-harness` is the generic base: the install machinery plus a generic example payload.
`pixterm-harness` holds only pixterm's content (`payload/`, `plugin.json`); the build
(`tools/build.sh` in omakase-harness) copies the machinery in and writes the self-contained
bundle to `dist/`. Nothing is vendored or hand-synced, so the machinery cannot drift from base.

## License

MIT. See `LICENSE`.
