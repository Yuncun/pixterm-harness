---
paths:
  - 'apps/web/tests/ui-regression/*player*.spec.ts'
  - 'packages/test-utils/src/player-helpers.ts'
---

# Player tests — motion assertions, not screenshots

When a Playwright test exercises the `@pixterm/player` engine or any UI that renders video, a single screenshot is not proof the feature works. A screenshot can render correctly while the video is paused, stuck on frame 0, or frozen behind an overlay. Assert motion or state transition with the helpers below.

## Helpers

All helpers live in `@pixterm/test-utils/player` (subpath import — never the package root). Full signatures, options, and threshold values: `packages/test-utils/README.md` (Player motion helpers section).

| Concern                                 | Helper                                              |
| --------------------------------------- | --------------------------------------------------- |
| Did the pipeline decode any frames?     | `attachMediaWatch` → `snapshot().decodedFrames > 0` |
| Is `video.currentTime` ticking forward? | `expectVideoAdvancing`                              |
| Are pixels actually changing on screen? | `expectVisualMotion`                                |
| Did the player load or switch clips?    | `expectClipTransition`                              |
| Need footage when assertions fail?      | `recordPlayback`                                    |

Use `expectVisualMotion` + `expectVideoAdvancing` together — they catch different failure modes. Add `attachMediaWatch` when codec error capture matters (Chrome only).

Canonical example: `apps/web/tests/ui-regression/floating-player.spec.ts`.

## Anti-patterns

- **`expect(video.paused).toBe(false)`** proves the element is in a non-paused state, not that frames are decoding. A stalled video is not paused.
- **`toHaveScreenshot()` alone** — Playwright's anti-aliasing tolerance (`threshold: 0.1`) absorbs the inter-frame deltas real video produces. A frozen frame passes.
- **Synthesizing `new Event('mediaplayrequest')` to bypass UX** — fires the store action directly and hides hit-test or event-routing bugs in the UI layer. Fix the UX bug instead.

## Why

A May 2026 incident shipped a play-button overlap with the player viewport that was silently bypassed by a synthesized `mediaplayrequest` in tests; fixing the hit-test required restructuring the DOM. Three sibling incidents in the same window (no `@close` handler on FloatingPlayer, Media Chrome controls siblings-not-nested with `<video>`, baseline locked in a broken layout) all shipped past green gates because the assertions watched engine internals or rendered frames in isolation rather than motion-on-screen. The rule above is the discipline that would have caught them. The same incidents motivated visual verification (`/visual-verify`, `ADR ui-verification-two-layers`); this rule is the test-authoring side of that gap.

UI-regression spec conventions (drive through visible UI, no synthetic events, etc.): see `.claude/rules/ui-regression-tests.md`.
