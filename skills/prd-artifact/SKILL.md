---
name: prd-artifact
description: The Code Katz contract for a PRD: section order, required fields, claim tags, and the checklist it must pass. Load when writing, revising, or validating docs/PRD.md, inside or outside a ck workflow.
user-invocable: false
---

# The PRD contract (`<project-repo>/docs/PRD.md`)

## Section order

1. `## Summary`: three sentences: what, for whom, and the one number that says it worked.
2. `## Problem`: the pain, not the solution. Cite the root-cause chain from the brief and say whether it reached a root cause or a known symptom.
3. `## User`: one main person, from the brief.
4. `## Success metric and leading indicator`: from the brief, restated.
5. `## Scope`: the decision taken (smaller version or full, with the reason) and the smaller version River would still propose: what it keeps, what it leaves out, whether it would still move the number.
6. `## Non-goals`: at least two.
7. `## Requirements`: numbered. Each has at least one acceptance criterion a reader could check without asking the author.
8. `## Sequencing and dependencies`: what must be true before this can ship; what depends on what.
9. `## Assumptions`: every assumption the document rests on, including the one the premortem exposes.
10. `## Risks`: what would cause this to fail, each with a mitigation or an explicit acceptance.
11. `## Open questions`: every decision left to the author.
12. `## Appendix A. Challenged claims`: claim | challenged by | severity | status | resolution. Nothing deleted. The reviewers' disagreements and kill conditions reproduced verbatim below the table.
13. `## Appendix B. Premortem`: the scenario, the exposed assumption, and the question "What went wrong?" verbatim.

## Claim tags

Every claim not taken directly from the brief carries an inline tag `[C1]`, `[C2]`, ... in the body. Appendix A addresses tags by id. A tag no reviewer challenged is listed there as unchallenged.

## Checklist B

1. Every section is present, in order, with its heading verbatim.
2. Problem names the pain, not the solution, and cites the root-cause chain.
3. Success metric is one number with a target and a date, plus one leading indicator.
4. Scope records the decision and the smaller version with what it leaves out.
5. Non-goals has at least two entries.
6. Every requirement has at least one acceptance criterion a reader could check without asking the author.
7. Every claim not from the brief carries a `[C<n>]` tag, and every tag appears in Appendix A or is marked unchallenged.
8. Assumptions includes the assumption the premortem exposed (or, before the premortem exists, says the premortem is pending).
9. Open questions lists every decision left to the author.
10. No em-dashes in prose. Em-dashes are acceptable only as separators in structured lists.
11. The PRD is under 3,000 words unless the author asked for more. Requirements are numbered statements with acceptance criteria, not essays.

## File paths

`<project-repo>/docs/brief.md` and `<project-repo>/docs/PRD.md`, committed with the project. Decision memos from reviewers go to `<project-repo>/docs/decisions/`. The author may choose other paths when running the commands.

## Writing

Plain technical English: name the actor, one instruction per sentence, no filler, no loss of precision. Second person is fine for the reader; third person for the system.
