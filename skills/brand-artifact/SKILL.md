---
name: brand-artifact
description: The Code Katz contract for the two brand documents: the brand direction record (the decision and the locked system) and the brand identity guide (overview, architecture, logo system, color, typography, UI surfaces, art direction, app icon, legal), with the checklist. Load when writing or validating docs/decisions/<timestamp>-brand-direction.md or docs/brand-guide.md, inside or outside a ck workflow.
user-invocable: false
---

# The brand contracts

Two documents, written at the end of `/ck:brand-guide` after the finalists gallery is chosen. Assets live under `<project-repo>/brand/final/`.

# Part A: the brand direction record (`<project-repo>/docs/decisions/<timestamp>-brand-direction.md`)

## Section order

Use these headings verbatim, in this order.

1. `## Decision`: the chosen direction by label and name; each rejected finalist by label with the reason.
2. `## Locked layout system`: grid, spacing scale, radii, elevation.
3. `## House tokens`: table, token | value | role, covering background, ink, accents, and functional colors.
4. `## Theme lineup`: variants of the skin, if any, and when each is used. Present even when there is one theme.
5. `## Rationale`: why this direction serves the positioning line, in one paragraph.
6. `## Open items`: present even when empty.
7. `## Asset list`: every file under `brand/final/` with its purpose.

## Checklist A

1. Every section is present, in order, with its heading verbatim.
2. Decision names the chosen label and every rejected finalist with a reason.
3. Every token in House tokens exists in `brand/final/tokens.json` with the same value.
4. Every file named in Asset list exists under `brand/final/`, and every file there is named.
5. No em-dashes in prose.

# Part B: the brand identity guide (`<project-repo>/docs/brand-guide.md`)

## Section order

Use these headings verbatim, in this order.

1. `## Brand overview and personality`: the positioning line; personality in three to five words, each with what it rules out.
2. `## Brand architecture`: product, publisher, sub-brands, and how they relate.
3. `## Logo system`: primary mark, secondary mark, lockups, color variants, clear space, minimum size, misuse (at least one example).
4. `## Color system`: the tokens; contrast ratio for every text-on-background pair; functional colors; product-specific color classes when the product has them (class or faction colors, for example).
5. `## Typography`: families, scale, weights, usage per role.
6. `## UI surface system`: cards, panels, buttons, inputs, and their states, in the skin.
7. `## Art direction`: illustration style, imagery rules, iconography, and the asset list.
8. `## Product-specific sections`: map overlay, in-game HUD, print, or whatever the product needs. Present even when empty, saying so.
9. `## App icon`.
10. `## Publisher credit and legal`: credit line, trademark and copyright notices.

## Checklist B

1. Every section is present, in order, with its heading verbatim.
2. Every color token in Color system exists in `brand/final/tokens.json` with the same value.
3. Every text-on-background pair states its contrast ratio and meets 4.5:1, or is marked decorative.
4. Every asset named in the guide exists under `brand/final/`.
5. The logo section shows at least one misuse example.
6. The personality words match the direction record.
7. No em-dashes in prose.

## Writing

Plain technical English: name the actor, one instruction per sentence, no filler, no loss of precision.
