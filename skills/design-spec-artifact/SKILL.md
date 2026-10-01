---
name: design-spec-artifact
description: The Code Katz contract for a feature design spec, written after the chosen variant: feature, chosen variant, screens, components, interactions, states, copy, accessibility, requirement traceability, acceptance, and the checklist. Load when writing or validating docs/design/<feature>/spec.md, inside or outside a ck workflow.
user-invocable: false
---

# The design spec contract (`<project-repo>/docs/design/<feature>/spec.md`)

Written by Kai after the reviewer chose a variant, with Robin's acceptance checks appended. Sits beside `gallery.html` and `chosen.html`.

## Section order

Use these headings verbatim, in this order.

1. `## Feature`: name; the PRD requirement numbers it implements; the user; the success metric it serves.
2. `## Chosen variant`: the label and one paragraph on why, from the review.
3. `## Screens`: one `### <screen name>` subsection per screen: purpose, layout, components, copy.
4. `## Components`: table, component | brand token or surface it uses | states.
5. `## Interactions`: table, trigger | response | transition.
6. `## States`: per screen: empty, loading, error, success.
7. `## Copy`: every string, with its screen.
8. `## Accessibility`: focus order, contrast, labels, motion.
9. `## Requirement traceability`: table, acceptance criterion | screen | how it is satisfied. One row per acceptance criterion of every requirement named under Feature.
10. `## Acceptance`: Robin's checks, one per screen, each a statement a tester could verify without asking the designer.

## Checklist

1. Every section is present, in order, with its heading verbatim.
2. Every acceptance criterion of every requirement named under Feature appears in the traceability table.
3. Every screen in Screens has a row in States and at least one check in Acceptance.
4. Every component names a token or surface from the brand guide, or "neutral" when there is no guide.
5. The document is under 2,500 words.
6. No em-dashes in prose.

## Writing

Plain technical English: name the actor, one instruction per sentence, no filler, no loss of precision.
