---
paths:
  - "packages/right-panel-control/**"
---

# Right-panel composition — governing ADR

The right panel is composed via the **panel-blocks** system defined
in `ADR-0023`. Before changing the chrome (sections, expand/collapse
state, slot layout), read that ADR — it locks in the block model
and the rules for adding new sections.

Each concrete panel lives at `packages/right-panel-control/src/panels/*.vue`
and composes from `<PanelBlock>` building blocks. New panels copy
an existing one rather than introducing a parallel composition.

Tier import contract: see `.claude/rules/packages-controls-tier.md`.
Topic map: `AGENTS.md` `## Related ADRs`.
