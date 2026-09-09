---
name: team-artifact
description: The Code Katz contract for a product's team document: cast, roles and responsibilities matrix, hand-off order, needs, missing seats, declined nominations, and the checklist. Load when writing or validating docs/TEAM.md, inside or outside a ck workflow.
user-invocable: false
---

# The team contract (`<project-repo>/docs/TEAM.md`)

Which personas are on this product, who owns which document and stage, who reviews, and which seat is missing.

## Section order

Use these headings verbatim, in this order.

1. `## Cast`: table, persona | role | tier model | why on this product.
2. `## Roles and responsibilities`: matrix, one row per pipeline document and stage (opportunity, market research, brief, PRD, roadmap, architecture, brand guide, design, and any build stages the documents imply), and one row per PRD requirement area when a PRD exists; columns owner | contributors | reviewers. Exactly one owner per row.
3. `## Hand-off order`: who hands to whom, in the pipeline's order, and what each hand-off carries.
4. `## Needs`: per persona, what it needs from whom before it can start.
5. `## Missing seats`: needs no persona covers; what a person in that seat would own; the recommendation: recruit, cover from an existing seat (named), or accept the gap. Present even when empty.
6. `## Declined nominations`: persona | responsibility | reason | replacement. Present even when empty.

## Checklist

1. Every section is present, in order, with its heading verbatim.
2. Every pipeline document has exactly one owner in the matrix.
3. Every persona in Cast appears in the matrix at least once, and every persona in the matrix is in Cast.
4. Missing seats and Declined nominations are present even when empty.
5. Every declined nomination has a replacement or an explicit gap.
6. No em-dashes in prose.
