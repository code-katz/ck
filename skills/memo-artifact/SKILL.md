---
name: memo-artifact
description: The Code Katz contract for a decision memo written by a panel: the ten sections in order and the checklist. Load when writing or validating a memo under docs/decisions/, inside or outside a ck workflow.
user-invocable: false
---

# The decision memo contract (`<project-repo>/docs/decisions/<timestamp>-<slug>.md`)

A memo shows where the lenses disagree and leaves the decision to the author. It never averages positions or picks a winner.

## Section order

Use these headings verbatim, in this order.

1. `## 1. Question and context`: the question; run id and timestamp; a table of lenses with persona, model, and what each read; the statement that all lenses are Claude models from one training pipeline, so decorrelation is partial; any lens that did not answer.
2. `## 2. Recommendations`: table, lens | persona | model | recommendation | one-line position.
3. `## 3. Agreement`: what every lens concurs on, flagged as low-information: is it obviously true, or a shared blind spot, and which.
4. `## 4. Disagreement`: every point where two lenses conflict, both positions at full strength, and the decision the author must make. Not adjudicated.
5. `## 5. Kill conditions`: each lens's kill condition verbatim, with its own answer to whether the material already shows it met (yes, no, unknown) and the evidence.
6. `## 6. Each lens against itself`: each lens's strongest argument against its own recommendation, verbatim.
7. `## 7. Unique findings`: anything only one lens saw.
8. `## 8. What nobody checked`.
9. `## 9. Questions between lenses`: to → question, verbatim.
10. `## 10. Handoff briefs`: verbatim, one per lens.

## Checklist

1. Every section is present, in order, with its heading verbatim.
2. The header names every lens, its model, what it read, and any lens that did not answer.
3. Every kill condition is quoted verbatim with a met, not met, or unknown answer and evidence.
4. The Disagreement section takes no side and names the decision the author must make.
5. `agreementRate` and whether the panel failed to disagree are stated in the header.
6. No em-dashes in prose.
