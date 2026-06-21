---
paths:
  - 'apps/web/tests/ui-regression/**/*.ts'
  - 'apps/web/playwright.ui-regression.config.ts'
---

# UI-regression tests — what good looks like

UI-regression specs boot the live editor under Playwright and drive it through
real user interactions. When these pass, a human should be able to use the
feature. They are gate #4 of the 5-gate (`make ui-regression`) and run in
Linux CI on every change.

## Rules

1. **Drive through visible UI, never synthetic events.** Use `page.click()`,
   `page.fill()`, `page.keyboard.press()`. The ast-grep rule
   `no-synthetic-events-in-ui-regression-tests` blocks `dispatchEvent` and
   `new MouseEvent / KeyboardEvent / PointerEvent` constructors here.

2. **Assertions must be observable by a real user.** Visible state, text,
   attributes, video frames advancing. Reading `window.__PIXTERM_PLAYER__`
   internals is allowed as a _secondary_ signal — never the sole proof that
   a feature works.

3. **Test the user-visible effect of each interactive element**, not just
   that it rendered. "Close button works" means clicking it makes the player
   disappear, not that the handler was called.

4. **Before claiming done, exercise the feature via `agent-browser`** (CLI,
   not Playwright MCP). Click buttons, watch results. Visual catches layout,
   z-index, and disconnected-control bugs that selector tests miss.

## Why

In May 2026 three bugs shipped past green gates: the FloatingPlayer close
button had no `@close` handler in `GraphRoute.vue` (the test asserted the
button rendered, not that clicking it closed); Media Chrome controls were
siblings-not-nested with `<video>` (`currentTime` advanced via the engine,
but the play button was disconnected from the video); and the panel
overlapped the canvas (the visual baseline locked in the broken state). All
were findable in 30 seconds with `agent-browser`. The tests asserted engine
internals, not what users see. The rules above are the discipline that
would have caught them.

## Helpful tools

- `@pixterm/test-utils/player` — `attachMediaWatch`, `expectVideoAdvancing`,
  `expectVisualMotion`, `expectClipTransition`. Assert user-visible output.
- `agent-browser open <url>` + `agent-browser snapshot` — the manual
  validation pass before "done." Fast, CLI, no MCP.
- `make ui-regression` — run the UI-regression Playwright suite locally.
