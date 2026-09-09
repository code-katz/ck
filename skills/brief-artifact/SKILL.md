---
name: brief-artifact
description: The Code Katz contract for a product brief: section order, required fields, and the checklist it must pass. Load when writing, revising, or validating docs/brief.md, inside or outside a ck workflow.
user-invocable: false
---

# The brief contract (`<project-repo>/docs/brief.md`)

A document written to this contract has the same shape every time, in every project. Consistency comes from this file, not from who writes it. Plain words throughout.

## Section order

Use these headings verbatim, in this order.

1. `## Idea`: the author's idea, in their words, one paragraph.
2. `## Problem and root-cause chain`: the person's pain, not the solution. The chain written out (idea, why, why, why), each step more specific, ending at a root cause or at "this addresses a symptom", and saying which.
3. `## User`: one main person, specific enough to recognize.
4. `## Success metric and leading indicator`: one number, a target, a date; one early sign to watch.
5. `## Comparable products`: three to five products, each in one paragraph: what it does, who it is for, its price or model, and the gap this idea fills, with one source; then one paragraph on how crowded the space is. Attributed to the market pass. Cites `docs/market-research.md` when it exists. May be marked pending, with the reason, when the market pass did not run.
6. `## Scope`: the smaller first version (what it keeps, what it leaves out, whether it would still move the number) and River's recommendation, with the decision marked open unless the author has made it.
7. `## Non-goals`: at least two things this will not do.
8. `## Open questions for the author`: anything River could not answer, each with the assumption used meanwhile. Present even when empty.

## Checklist A

1. Every section is present, in order, with its heading verbatim.
2. Problem names the person's pain and the chain reaches a root cause or says it stops at a symptom.
3. User is one person, not a category.
4. Success metric has a number, a target, and a date, plus one leading indicator.
5. Comparable products has three to five entries with a source each, or is marked pending with a reason.
6. Scope names what the smaller version leaves out and carries a recommendation.
7. Non-goals has at least two entries.
8. The whole brief is under 1,200 words. It is the short document that governs the long one.

## Writing

Plain technical English: name the actor, one instruction per sentence, no filler, no loss of precision. No em-dashes in prose.
