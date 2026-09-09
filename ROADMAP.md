# ck — Product Roadmap

## Current Roadmap

## Current State Snapshot

The skeleton is committed: 21 personas as subagents and switch commands on three tiers, four of nine workflow scripts (`panel`, `brief`, `draft`, `team`), the `prd`, `next`, and `review-page` skills, five of ten document contracts, two hooks, and the static test suite. Nothing has run end to end on a real project yet. Phase 0 answered seven of eight spikes (see the PRD's §8.0).

## Opportunities — Prioritized

### Tier 1 — Ship Next

| # | Opportunity | Why Now | Success Signal |
|---|---|---|---|
| 1 | End-to-end drill of `/ck:next`, `/ck:brief`, `/ck:panel` on the fixtures, then on a real project | These three exercise every mechanism Phase 0 proved; nothing else is trusted until they run | PRD §9 test 13 log committed under `tests/drill/` |
| 2 | `/ck:prd` drill, including the review page and a `startAt` resume | The flagship document | Test 13's `/ck:prd` rows pass; a review page with two applied comments |
| 3 | The remaining contracts: `opportunity`, `market-research`, `roadmap`, `brand`, `design`, `gallery` | Every script needs its contract before it is written | Test 7 passes for every workflow |
| 4 | The remaining scripts: `opportunity-draft`, `market-research`, `roadmap`, `brand`, `design-round`, and the gate-owning skills `opportunity`, `architecture`, `brand-guide`, `design` | Phase one is the whole pipeline | Test 9 passes for nine scripts; J1 and J2 drills complete |
| 5 | Marketplace entry in `code-katz/claude-plugins` and the install drill on Clare's machine | Distribution | `/plugin install ck@code-katz` then `/ck:next` on a second machine |

### Tier 2 — High Value, Plan for Next Sprint

| # | Opportunity | User Need | Assumptions to Validate |
|---|---|---|---|
| 1 | `/ck:feature`, `/ck:bugfix`, `/ck:gtm` (phase two) | Build from the definition | Worktree isolation for persona agents works inside a workflow |
| 2 | `/ck:map` and `/ck:report` | See the catalog and the spend | Thirty days of usage log exist |
| 3 | Routines for `market-research` | Scheduled research | The workflow has run by hand three times |

### Tier 3 — Strategic / Longer Horizon

| # | Opportunity | Strategic Value | Why Not Now |
|---|---|---|---|
| 1 | The Workbench (phase three): a rewrite replacing the conductor dashboard | See and edit everything in one local place | The catalog and run data it shows do not exist yet |
| 2 | The 90-day persona prune with the three scopes | A roster sized by evidence | No usage data yet |

## Recommended Sequencing

Tier 1 in order: the three-command drill first, because a failure there is a failure everywhere; then the PRD drill; then contracts before scripts, one command at a time; the marketplace entry last, once the drills pass.

## Open Questions

- Which permission mode do Clare's sessions run in, and does a manual-mode session prompt for the nested panel (PRD §8.0, S3)?
- Clare's Claude Code version and CPU count (PRD §8.0, S5 and S8).

## OKR

| Key Result | Target | Current |
|---|---|---|
| J1 completes on a real project from the README alone | 1 | 0 |
| J2 completes in one command and one review | 1 | 0 |
| Panel runs with real disagreement | more than half | none yet |

## Revision History

## [2026-09-09] First roadmap, from the phase-one PRD

### What Changed
Created with the skeleton commit.

### Why
The PRD's §10 phasing, translated into the roadmap skill's tiers.

### Open Questions Resolved / Added
Added the two Clare checks and the manual-mode consent question.

### Change Types
- [x] New opportunity added

### Triggered By
The `ck` repository's first commit.
