---
name: architecture-artifact
description: The Code Katz contract for an architecture document: context, quality attributes, the recommended architecture with a diagram, components, data, integrations, alternatives, decision record, sequencing, risks, challenged claims, premortem, and the checklist. Load when writing or validating docs/ARCHITECTURE.md, inside or outside a ck workflow.
user-invocable: false
---

# The architecture contract (`<project-repo>/docs/ARCHITECTURE.md`)

The PRD and the roadmap in; a recommended architecture out, with the alternatives considered and the decision record.

## Section order

Use these headings verbatim, in this order.

1. `## Context and constraints`: what the PRD and roadmap fix: users, scale, platforms, budget, deadlines, what already exists.
2. `## Quality attributes`: ranked; the top three named with the reason each ranks where it does.
3. `## Recommended architecture`: one paragraph and a Mermaid diagram.
4. `## Components`: table, component | responsibility | owner persona (from `docs/TEAM.md` when it exists).
5. `## Data model sketch`: the main entities and their relationships.
6. `## Integration points and external dependencies`.
7. `## Alternatives considered`: table, alternative | what it would gain | why not. At least two rows.
8. `## Decision record`: date, decision, deciders, consequences.
9. `## Sequencing against the roadmap`: which components each Tier 1 roadmap item needs, in order.
10. `## Risks`: each with a mitigation or an explicit acceptance.
11. `## Open questions`: every decision left to the author.
12. `## Appendix A. Challenged claims`: claim | challenged by | severity | status | resolution. Nothing deleted. The reviewers' disagreements and kill conditions reproduced verbatim below the table.
13. `## Appendix B. Premortem`: the scenario in which this shipped and fell over in production in its first month, the exposed assumption, and the question "What went wrong?" verbatim.

## Claim tags

Every claim not taken directly from the PRD or the roadmap carries an inline tag `[C1]`, `[C2]`, ... in the body. Appendix A addresses tags by id. A tag no reviewer challenged is listed there as unchallenged.

## Checklist

1. Every section is present, in order, with its heading verbatim.
2. The Mermaid diagram is present and renders.
3. Alternatives considered has at least two rows.
4. Every Tier 1 roadmap item appears in Sequencing against the roadmap.
5. Every component has a responsibility.
6. The decision record has a date.
7. Every claim not from the PRD or roadmap carries a `[C<n>]` tag, and every tag appears in Appendix A or is marked unchallenged.
8. Assumptions exposed by the premortem appear in Risks or Context and constraints.
9. No em-dashes in prose.
10. The document is under 3,000 words unless the author asked for more.
