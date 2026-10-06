---
name: roadmap-artifact
description: The Code Katz contract for ROADMAP.md, which is the roadmap skill's structure verbatim so the two stay interchangeable: current state, opportunities in three tiers, sequencing, open questions, OKRs, and a revision history. Load when writing or validating ROADMAP.md, inside or outside a ck workflow.
user-invocable: false
---

# The roadmap contract (`<project-repo>/ROADMAP.md`)

The file has two parts: Section 1, the current roadmap, which is rewritten on every update; and Section 2, the revision history, which only grows. The skeleton below is the structure, verbatim, including the dashes in its headings; those headings come from the roadmap skill and are not prose.

## Section order

```markdown
# <Project Name> — Product Roadmap

## Current Roadmap

## Current State Snapshot

<one paragraph: what exists today, what is in flight, what is blocked>

## Opportunities — Prioritized

### Tier 1 — Ship Next

| # | Opportunity | Why Now | Success Signal |
|---|---|---|---|

### Tier 2 — High Value, Plan for Next Sprint

| # | Opportunity | User Need | Assumptions to Validate |
|---|---|---|---|

### Tier 3 — Strategic / Longer Horizon

| # | Opportunity | Strategic Value | Why Not Now |
|---|---|---|---|

## Recommended Sequencing

<ordered list with dependencies and what each step unblocks>

## Open Questions

## OKR

| Key Result | Target | Current |
|---|---|---|

## Revision History

## [YYYY-MM-DD] <brief title of what changed>

### What Changed

### Why

### Open Questions Resolved / Added

### Change Types
- [ ] New opportunity added
- [ ] Priority changed
- [ ] Opportunity removed or deferred
- [ ] Sequencing changed
- [ ] OKR changed

### Triggered By
```

Every update rewrites everything above Revision History and prepends one new entry below it, dated with the run's timestamp.

## Checklist

1. The skeleton's headings are all present, in order, verbatim.
2. Every Tier 1 row names a success signal and traces to a numbered PRD requirement.
3. Recommended Sequencing orders every Tier 1 item and names what each unblocks.
4. The OKR table has at least one key result with a target.
5. The newest revision-history entry is dated with the run's timestamp and has every subsection.
6. The roadmap skill's lint check passes when that skill is installed.
7. No em-dashes in prose outside the skeleton's own headings.
8. The document is under 2,500 words. The current-state snapshot is one short paragraph, and Open Questions points to the PRD's open questions by number instead of restating them; only questions the roadmap itself raises are written out.
