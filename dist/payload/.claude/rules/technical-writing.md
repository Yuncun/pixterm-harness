---
paths:
  - 'README.md'
  - 'HARNESS.md'
  - 'ARCHITECTURE.md'
  - 'VISION.md'
  - 'docs/adr/**/*.md'
  - 'docs/model/**/*.md'
  - 'docs/superpowers/specs/**/*.md'
---

# Technical writing: RFC voice

Loads when editing shipped technical docs (READMEs, ADRs, model docs, specs, the
plugin docs). Scratch notes in `docs/notes/` are exempt — they are thinking, not
shipped writing (see `.claude/rules/docs-notes.md`).

The standard: **every sentence states a fact, a constraint, or an instruction.**
If a sentence survives deletion without losing information, delete it. Draft as an
RFC, not a product landing page.

## Cut

- **Reassurance and sign-offs.** "That's it — you're enforced." "And you're done!"
  The preceding instruction already established the state; the closer adds nothing.
- **Hype register.** "simply," "just," "easy," "powerful," "seamless,"
  "blazing-fast," "robust," "delightful." They assert quality instead of showing it.
- **Restatement for emphasis.** Repeating the prior sentence in different words.
- **Second-person salesmanship.** Copy that sells the reader on the thing rather
  than stating how it works.

## Structure

- **State first, name second.** Introduce a term after the sentence that motivates
  it, not before. Define `deferred gate` once the reader has seen what it does.
- **Minimize assumed vocabulary.** Prefer the phrasing a reader parses with the
  fewest prior terms; gloss the terms that remain. A sentence that needs six prior
  definitions to parse is a password, not an explanation.

## WHY (origin)

2026-06-02: the `omakase-harness/README.md` quickstart closed with "That's it —
you're enforced" — a sentence carrying no information past the instruction before
it. Marketing sign-off mistaken for documentation. Clean, dense docs lower the
barrier to adopting the harness; slop is an adoption cost.

## Enforcement

Judgment, mostly — not lint-able. The hype-word list could become a `vale` or
`proselint` rule later (deferred; no prose linter is installed today).
