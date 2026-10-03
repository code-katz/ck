---
name: gallery-artifact
description: The Code Katz contract for a gallery page of labeled variants, used by /ck:brand-guide (brand directions, finalists) and /ck:design (feature screens): banner, variant strip, and per variant the rendering, rationale, trade-off, what it satisfies, and states. Load when writing or validating any gallery.html, inside or outside a ck workflow.
user-invocable: false
---

# The gallery contract (`brand/<round>/gallery.html`, `docs/design/<feature>/gallery.html`)

One page shape for brand galleries and design galleries, so a review is the same every time. The reviewer comments on the page to pick a label and ask for changes.

## The page, in order

1. **Banner**: the product name; what is being reviewed and the round or revision; the four comment steps, verbatim:
   1. Open this link signed in to your Claude account.
   2. Switch the page to comment mode from the bar at the top.
   3. Click the variant or the passage you want to comment on and type. Do not send the comment to Claude; your session reads it.
   4. Say "done" in your Claude Code session when you have finished.
2. **Variant strip**: one button per variant, labeled with consecutive capital letters from A, that scrolls to the variant.
3. **Per variant**, in this order, inside one container with `id="variant-<label>"`:
   1. The label and the variant's name.
   2. The rendering. For a brand direction: the hero mark, a palette of swatches with hex values, a type specimen, and one UI surface in the skin. For a design: the screens in device frames, in the brand skin, or a neutral skin with a note when there is no brand guide.
   3. `Rationale`: why this, in three sentences.
   4. `Trade-off`: what it gives up, in one or two sentences.
   5. `Satisfies`: the positioning line (brand) or the PRD requirement numbers (design) this variant serves.
   6. `States` (design only): empty, loading, and error for each screen.

## Rules

1. Every asset is inline: SVG, CSS, and data URIs. No external images, scripts, or stylesheets. Google Fonts is the one allowed external font source, with a fallback stack.
2. The page uses the Code Katz house tokens for its own chrome and the variant's tokens inside the variant's frame.
3. Light and dark themes: tokens on `:root`, redefined under `prefers-color-scheme: dark` and under `[data-theme="dark"]`.
4. The page is under 16 MB.
5. The page body never scrolls sideways; wide content scrolls inside its own container.

## Checklist

1. Labels are consecutive capital letters from A, and every variant container has the matching `id`.
2. Every variant has every part listed above, in order (States only for design galleries).
3. No external asset references other than Google Fonts.
4. The file is under 16 MB.
5. The banner carries the four steps verbatim.
6. For a design gallery: every PRD requirement named under Satisfies exists in `docs/PRD.md`.
