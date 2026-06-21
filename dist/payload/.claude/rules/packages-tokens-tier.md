---
paths:
  - "packages/design-system/**"
---

# Tokens tier (`@pixterm/design-system`)

CSS custom-property tokens (colors, spacing, typography, layout, motion). Loaded globally by the host app.

## Constraints

- **No Vue components.** Tokens are CSS-only — variables, no `<script>`, no `<template>`.
- Token definitions are the source of truth for visual values; downstream tiers reference them via `var(--token-name)`.
- Stylelint's "no hardcoded hex" rule excludes this tier — token files declare raw values by definition.

Tier overview: see `.claude/rules/packages-overview.md`.
