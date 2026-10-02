---
name: opportunity-artifact
description: The Code Katz contract for an opportunity analysis: verdict, concept, sourced market context, one section per contributing lens, stage gates, monetization, risks, open questions, sources, and the checklist. Load when writing or validating docs/opportunity.md, inside or outside a ck workflow.
user-invocable: false
---

# The opportunity analysis contract (`<project-repo>/docs/opportunity.md`)

The first document on a new product: is this worth doing, for whom, in what market, in what technical shape, and what would have to be true. A multi-persona document: each lens writes its own section, and River holds the frame, the stage gates, and the risks.

## Section order

Use these headings verbatim, in this order.

1. `## Executive summary`: the verdict in one paragraph: worth doing, worth doing smaller, or not now, with the one number that decides it.
2. `## Concept statement`: what it is and for whom, in two sentences.
3. `## Problem and root-cause chain`: the person's pain, not the solution; the chain written out (idea, why, why, why), ending at a root cause or at "this addresses a symptom", and saying which.
4. `## Market context`: size, trends, and comparable products; every claim about the world carries a source number that appears in Sources.
5. One section per contributing lens, in the order the frame chose them, each headed `## <Lens>: <title>`. For example `## Game design: core loops`, `## Marketing: positioning and go-to-market`, `## Architecture: technical shape`, `## Business: model and stage economics`. Each section is written by the persona the frame chose and ends with that persona's Handoff Brief.
6. `## Stage gates`: at least three stages; for each, what must be true to proceed and the kill condition that stops it.
7. `## Monetization and business model`.
8. `## Risks`: each with a mitigation or an explicit acceptance.
9. `## Open questions`: present even when empty.
10. `## Sources`: numbered; URL, title, date accessed.

## Checklist

1. Every section is present, in order, with its heading verbatim.
2. The executive summary names a verdict and a number.
3. Every market claim carries a source number that exists in Sources.
4. Every contributing lens named in the frame has a section, and every lens section was written by that persona (checked from the run's `sections/` files).
5. At least three stage gates, each with a kill condition.
6. Every risk carries a mitigation or an explicit acceptance.
7. Open questions is present even when empty.
8. The document is under 4,000 words before Sources (four contributor sections of up to 600 words each, plus the fixed sections).
9. No em-dashes in prose.

## Writing

Plain technical English: name the actor, one instruction per sentence, no filler, no loss of precision.
